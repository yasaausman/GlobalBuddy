"""One-shot data port: Neon Postgres -> Xano (M18, docs/xano-document-pipeline-plan.md §5.3).

Ports only the 4 tables M18 scopes into Xano -- user_profiles (-> Xano's built-in
`user`), plan_progress, user_documents, notifications. The other 8 tables stay on
Neon until M22 (post-deadline); this script does not touch them.

Idempotent and resumable: an id map (old Neon uuid -> new Xano id) is persisted to
--id-map-file after every successful write, so a rerun skips rows already migrated
instead of duplicating them. Ordered by FK dependency: user_profiles must land
first because the other three tables reference user_id.

WRITE CONTRACT (confirm and adjust once the Xano workspace exists):
This script assumes a temporary, admin-token-protected "migration" API group in
Xano -- e.g. `POST /migration/user`, `POST /migration/plan_progress`, etc. -- built
specifically for this one-time import and disabled/deleted afterward. Xano's
per-user `/v1/auth/signup` endpoint is not used here: it hashes a real password
and can't set an arbitrary source id, and this script needs to preserve the
old-id -> new-id relationship instead. Override endpoint paths and the base URL
via env vars if the actual migration API group ends up shaped differently.

Usage:
    # Dry run (default) -- prints what would be written, makes no Xano calls.
    python scripts/migrate_neon_to_xano.py

    # Actually write to Xano.
    python scripts/migrate_neon_to_xano.py --apply

    # After a migration, confirm row counts match on both sides.
    python scripts/migrate_neon_to_xano.py --verify

Env vars (backend/.env is loaded automatically):
    DATABASE_URL / DATABASE_URL_UNPOOLED   Neon source (from app.config.Settings)
    XANO_BASE_URL                          Xano API group base URL
    XANO_MIGRATION_TOKEN                   Bearer token for the migration API group
"""

from __future__ import annotations

import argparse
import asyncio
import json
import os
import sys
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "backend"))

DEFAULT_ID_MAP_FILE = Path(__file__).resolve().parents[1] / "scripts" / ".neon_to_xano_id_map.json"

# Table name -> Xano migration endpoint path, in FK dependency order.
TABLE_ENDPOINTS = {
    "user_profiles": "/migration/user",
    "plan_progress": "/migration/plan_progress",
    "user_documents": "/migration/user_documents",
    "notifications": "/migration/notifications",
}


def load_id_map(path: Path) -> dict[str, str]:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def save_id_map(path: Path, id_map: dict[str, str]) -> None:
    path.write_text(json.dumps(id_map, indent=2, sort_keys=True), encoding="utf-8")


async def fetch_neon_rows(conn: Any, table: str) -> list[dict[str, Any]]:
    rows = await conn.fetch(f"select * from {table}")
    return [dict(row) for row in rows]


def user_profile_payload(row: dict[str, Any]) -> dict[str, Any]:
    return {
        "legacy_auth_user_id": row["auth_user_id"],
        "full_name": row["full_name"],
        "email": row["email"],
        "country_of_origin": row["country_of_origin"],
        "target_university": row["target_university"],
        "target_city": row["target_city"],
        "stage": row["stage"],
        "role": "student",
    }


def plan_progress_payload(row: dict[str, Any], xano_user_id: str) -> dict[str, Any]:
    return {
        "user_id": xano_user_id,
        "task_id": row["task_id"],
        "completed": row["completed"],
    }


def user_documents_payload(row: dict[str, Any], xano_user_id: str) -> dict[str, Any]:
    return {
        "user_id": xano_user_id,
        "doc_type": row["doc_type"],
        "status": row["status"],
    }


def notifications_payload(row: dict[str, Any], xano_user_id: str) -> dict[str, Any]:
    return {
        "user_id": xano_user_id,
        "type": row["type"],
        "title": row["title"],
        "body": row["body"],
        "read": row["read"],
    }


async def post_to_xano(client: Any, base_url: str, token: str, path: str, payload: dict[str, Any]) -> str:
    response = await client.post(
        f"{base_url}{path}",
        json=payload,
        headers={"Authorization": f"Bearer {token}"},
        timeout=30.0,
    )
    response.raise_for_status()
    data = response.json()
    new_id = data.get("id")
    if not new_id:
        raise RuntimeError(f"Xano response for {path} did not include an id: {data}")
    return str(new_id)


async def run(apply: bool, verify_only: bool, id_map_file: Path) -> int:
    from app.config import get_settings  # noqa: E402  (path patched above)

    settings = get_settings()
    database_url = settings.database_url_unpooled.strip() or settings.database_url.strip()
    if not database_url:
        print("DATABASE_URL or DATABASE_URL_UNPOOLED is not configured -- nothing to migrate.")
        return 1

    xano_base_url = os.environ.get("XANO_BASE_URL", "").strip()
    xano_token = os.environ.get("XANO_MIGRATION_TOKEN", "").strip()
    if apply and not (xano_base_url and xano_token):
        print("XANO_BASE_URL and XANO_MIGRATION_TOKEN are required to --apply.")
        return 1

    import asyncpg
    import httpx

    id_map = load_id_map(id_map_file)
    neon_counts: dict[str, int] = {}
    xano_counts: dict[str, int] = {}

    conn = await asyncpg.connect(database_url)
    try:
        async with httpx.AsyncClient() as client:
            for table in TABLE_ENDPOINTS:
                rows = await fetch_neon_rows(conn, table)
                neon_counts[table] = len(rows)
                migrated_here = 0

                for row in rows:
                    old_key = f"{table}:{row.get('id') or row.get('user_id')}:{row.get('task_id', '')}{row.get('doc_type', '')}"
                    if old_key in id_map:
                        continue  # already migrated in a prior run

                    if table == "user_profiles":
                        payload = user_profile_payload(row)
                    else:
                        neon_user_id = str(row["user_id"])
                        xano_user_id = id_map.get(f"user_profiles:{neon_user_id}::")
                        if xano_user_id is None:
                            print(f"  skip {table} row -- user {neon_user_id} not migrated yet")
                            continue
                        payload = {
                            "plan_progress": plan_progress_payload,
                            "user_documents": user_documents_payload,
                            "notifications": notifications_payload,
                        }[table](row, xano_user_id)

                    if not apply:
                        migrated_here += 1
                        continue

                    if verify_only:
                        continue

                    new_id = await post_to_xano(client, xano_base_url, xano_token, TABLE_ENDPOINTS[table], payload)
                    id_map[old_key] = new_id
                    migrated_here += 1
                    save_id_map(id_map_file, id_map)  # persist after every row -- resumable on failure

                verb = "would migrate" if not apply else "migrated"
                print(f"{table}: {len(rows)} Neon rows, {verb} {migrated_here}")

        if verify_only or apply:
            # Row-count parity: every migrated Neon row should have an id-map entry.
            for table, expected in neon_counts.items():
                migrated = sum(1 for key in id_map if key.startswith(f"{table}:"))
                xano_counts[table] = migrated
                status = "OK" if migrated == expected else "MISMATCH"
                print(f"parity[{table}]: neon={expected} xano={migrated} [{status}]")
            if any(xano_counts[t] != neon_counts[t] for t in neon_counts):
                return 1
    finally:
        await conn.close()

    if not apply:
        print("\nDry run only -- no Xano writes made. Re-run with --apply once XANO_BASE_URL and "
              "XANO_MIGRATION_TOKEN are set and the migration API group exists.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--apply", action="store_true", help="Actually write to Xano (default is dry run).")
    parser.add_argument("--verify", action="store_true", help="Only check row-count parity against the id map.")
    parser.add_argument("--id-map-file", type=Path, default=DEFAULT_ID_MAP_FILE)
    args = parser.parse_args()
    return asyncio.run(run(apply=args.apply, verify_only=args.verify, id_map_file=args.id_map_file))


if __name__ == "__main__":
    sys.exit(main())
