---
name: Globalदोस्त
description: A calm, frosted-glass companion that walks international students through high-stakes documents.
colors:
  page-aqua: "#e8f7f6"
  page-sky: "#eef6ff"
  ink: "#0f172a"
  muted: "#4f6479"
  accent-teal: "#0ea5a4"
  accent-sky: "#0284c7"
  success-ink: "#0f766e"
  warning-ink: "#d97706"
  danger: "#b91c1c"
  border: "rgba(15, 23, 42, 0.12)"
  border-strong: "rgba(14, 165, 164, 0.3)"
  surface: "rgba(255, 255, 255, 0.82)"
  surface-strong: "rgba(255, 255, 255, 0.94)"
typography:
  display:
    fontFamily: "Sora, Nunito, sans-serif"
    fontSize: "clamp(1.45rem, 4vw, 2.1rem)"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "-0.02em"
  title:
    fontFamily: "Sora, Nunito, sans-serif"
    fontSize: "1rem"
    fontWeight: 700
    lineHeight: 1.3
    letterSpacing: "-0.01em"
  body:
    fontFamily: "Nunito, system-ui, sans-serif"
    fontSize: "0.95rem"
    fontWeight: 400
    lineHeight: 1.45
    letterSpacing: "normal"
  label:
    fontFamily: "Nunito, system-ui, sans-serif"
    fontSize: "0.78rem"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "0.06em"
rounded:
  input: "10px"
  sm: "12px"
  md: "18px"
  pill: "999px"
spacing:
  xs: "0.35rem"
  sm: "0.6rem"
  md: "0.85rem"
  lg: "1.25rem"
  xl: "2.5rem"
components:
  button-primary:
    backgroundColor: "{colors.accent-teal}"
    textColor: "#ffffff"
    rounded: "{rounded.pill}"
    padding: "0.62rem 1rem"
  button-secondary:
    backgroundColor: "rgba(14, 165, 164, 0.09)"
    textColor: "{colors.ink}"
    rounded: "{rounded.pill}"
    padding: "0.62rem 1rem"
  button-ghost:
    backgroundColor: "rgba(255, 255, 255, 0.72)"
    textColor: "{colors.ink}"
    rounded: "{rounded.pill}"
    padding: "0.62rem 1rem"
  card:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.md}"
    padding: "1.3rem"
  input:
    backgroundColor: "{colors.surface-strong}"
    textColor: "{colors.ink}"
    rounded: "{rounded.input}"
    padding: "0.6rem 0.72rem"
  chip:
    backgroundColor: "rgba(45, 212, 191, 0.11)"
    textColor: "{colors.success-ink}"
    rounded: "{rounded.pill}"
    padding: "0.3rem 0.62rem"
  badge:
    backgroundColor: "rgba(125, 211, 252, 0.18)"
    textColor: "{colors.accent-sky}"
    rounded: "{rounded.pill}"
    padding: "0.2rem 0.45rem"
---

# Design System: Globalदोस्त

## Overview

**Creative North Star: "Clear Water"**

Globalदोस्त looks and feels like clear water over a calm aqua-to-sky floor. Frosted-glass surfaces float above a soft two-radial gradient; you can see the light coming through everything, and nothing is hidden behind an opaque panel. That translucency is not decoration — it is the product thesis made visible. This is an app where a machine extracts a legal document, admits exactly how sure it is about each field, cites the source region it read, and refuses to proceed when it isn't sure. The interface earns trust by being see-through: confidence shown, sources cited, gates visible. The palette is unhurried teal and sky, never clinical white-on-grey, because the primary user is often a non-native English speaker doing an unfamiliar, status-determining task under pressure, and the surface should steady them rather than intimidate.

The system is **airy and floating**. Surfaces are translucent white (82–94% opacity) with a real `backdrop-filter` blur, rounded generously (18px), and lifted on soft, low, wide shadows that read as diffuse daylight rather than hard drop-shadow. Interactive controls are pill-shaped (`999px`) and rise 1px on hover. Density is comfortable, not compact: generous internal padding, rem-based rhythm, one accent gradient (teal → sky) reserved for the single most important action on a screen. Type pairs **Sora** (display, tight tracking, confident headings) with **Nunito** (body, warm and highly legible). Uppercase micro-labels with wide tracking carry structure without shouting.

The one place the airiness must yield is the confidence and review surfaces of the document pipeline: there, the glass stays but the information hardens — a low-confidence field, an always-review high-stakes field, and a policy-forced re-review each get an unambiguous, color-coded state. Calm is the resting tone; it is never allowed to soften a warning into ambiguity.

**Key Characteristics:**
- Frosted-glass translucent surfaces over a soft aqua→sky radial-gradient page
- One teal→sky accent gradient, spent only on the primary action per screen
- Pill-shaped controls (999px) and generously rounded cards (18px)
- Soft, wide, low-opacity shadows — daylight, not drop-shadow
- Sora display + Nunito body; wide-tracked uppercase micro-labels
- Warmth at rest, unambiguous color the moment stakes or uncertainty appear

## Colors

A restrained two-hue world — teal and sky-blue accents over near-white glass, with semantic ink colors reserved strictly for state.

### Primary
- **Companion Teal** (`#0ea5a4`): the core brand accent. Anchors the primary-button gradient (with Accent Sky), active/selected states, chip text, and focus glows. The warmer, more human half of the palette.
- **Signal Sky** (`#0284c7`): the second accent, used as `accent-strong`. Closes the primary-button gradient, colors links, kickers, badges, and "info" emphasis. Cooler and more authoritative than teal.

### Neutral
- **Deep Slate Ink** (`#0f172a`): primary text and high-contrast headings. Never pure black — slate keeps the calm.
- **Muted Harbor** (`#4f6479`): secondary text, captions, uppercase micro-labels, helper copy.
- **Frosted Surface** (`rgba(255,255,255,0.82)` / strong `0.94`): every card and panel. The translucency is load-bearing — it is the "clear water" thesis.
- **Aqua Floor / Sky Floor** (`#e8f7f6` / `#eef6ff`): the page background gradient stops, warmed further by two teal/sky radial washes at the top.
- **Hairline Border** (`rgba(15,23,42,0.12)`, strong `rgba(14,165,164,0.3)`): 1px separators. The strong (teal-tinted) variant marks focus and active edges.

### Semantic
- **Success Ink** (`#0f766e`): confirmed / accepted / done — a deep teal-green, not a generic green, so success stays inside the palette.
- **Warning Ochre** (`#d97706`): elevated-but-not-critical priority (e.g. "high" priority badges).
- **Danger Red** (`#b91c1c`): errors, rejected states, critical priority, and — in the pipeline — a field forced back to review by a live policy change.

### Named Rules
**The One Gradient Rule.** The teal→sky gradient (`linear-gradient(135deg, accent-teal, accent-sky)`) appears once per screen, on the single primary action. Everything else is flat translucent glass. Its scarcity is what makes the primary action unmistakable.

**The Palette-Locked State Rule.** Success is deep teal-green (`#0f766e`), never a stock `#22c55e`; info is sky (`#0284c7`); warning is ochre; danger is `#b91c1c`. State colors are chosen to belong to this palette, so a green checkmark never looks imported from another app.

## Typography

**Display Font:** Sora (with Nunito, sans-serif fallback)
**Body Font:** Nunito (with system-ui, sans-serif fallback)

**Character:** Sora brings geometric confidence and tight tracking to headings and titles; Nunito's rounded, friendly letterforms carry all body and control text. The pairing is precise-but-warm — authoritative enough for a legal document, soft enough for a companion.

### Hierarchy
- **Display** (Sora 700, `clamp(1.45rem, 4vw, 2.1rem)`, line-height 1.2, tracking `-0.02em`): hero headlines (`.gb-hero h1`). One per view.
- **Title** (Sora 700, `1rem`, tracking `-0.01em`): card and section headers (`.gb-section-title`), stepper titles.
- **Body** (Nunito 400, `0.92–0.95rem`, line-height 1.45): all prose; cap measure at ~68ch (`.gb-hero p` uses `max-width: 68ch`).
- **Label** (Nunito 700, `0.78rem`, tracking `0.06em`, uppercase): field labels, kickers, step indices, meta. The wide tracking + uppercase is the system's structural voice.
- **Micro-badge** (Nunito 800, `0.67–0.72rem`, tracking `0.07em`, uppercase): pills and badges.

### Named Rules
**The Sora-For-Structure Rule.** Sora is only for display and titles (headings, hero, section titles, step titles). Body, labels, controls, and data are always Nunito. Don't set paragraphs or buttons in Sora.

## Layout

A single centered column governs the app: `.gb-main` is `max-width: 1150px`, centered, `padding: 1.25rem 1rem 2.5rem`, laid out as a vertical `grid` with `gap: 1rem`. The nav (`.gb-nav`) is sticky, translucent (`rgba(240,253,250,0.82)` + blur), with a 1px bottom hairline. Content is card-based: most surfaces are `.gb-card` panels stacked or arranged in responsive grids (`.gb-form-grid`, `.gb-explore-grid`, `.gb-feed-grid`).

Spacing rhythm is rem-based and comfortable: `0.35 / 0.6 / 0.85 / 1.25 / 2.5rem` recur as gaps and padding. Cards carry `~1.3rem` internal padding; controls `~0.6rem` vertical.

Responsive behavior uses three breakpoints: **`max-width: 600px`** (mobile: single-column collapse, tighter padding), **`max-width: 820px`** (tablet: multi-column grids fold), and **`min-width: 980px`** (desktop: side-by-side split layouts like Explore's left/right panels engage). Below 820px, multi-column grids (journey track, form grid) collapse to one column.

## Elevation & Depth

Depth is **airy and layered**, built from translucency + blur + soft wide shadows rather than hard borders. Every floating surface combines three things: a translucent white fill, a `backdrop-filter: blur(8–10px)`, and a single soft shadow. Shadows are low-opacity, large-radius, and cool-tinted (navy/teal), so surfaces read as lit by diffuse daylight and lifted off the gradient floor — never stamped onto it. Depth increases toward interaction: rest → hover (1px lift) → active/focus (teal ring).

### Shadow Vocabulary
- **Card Lift** (`box-shadow: 0 18px 40px rgba(8, 47, 73, 0.12)`, token `--gb-shadow`): the default for `.gb-card` and every floating panel.
- **Accent Lift** (`box-shadow: 0 10px 20px rgba(3, 105, 161, 0.25)`): under the primary gradient button — sky-tinted so the shadow belongs to the button's own color.
- **Brand Mark Lift** (`box-shadow: 0 10px 22px rgba(14, 165, 164, 0.28)`): the teal logo tile.
- **Focus / Active Ring** (`box-shadow: 0 0 0 2–3px rgba(45, 212, 191, 0.14–0.18)`): a soft teal halo on focused inputs and active steps — the state signal, not a hard outline.

### Named Rules
**The Glass-Over-Gradient Rule.** Surfaces are translucent white with a real backdrop blur, always floating over the aqua→sky gradient — never opaque, never flat-white. If a surface can't show the gradient faintly through it, it's too opaque.

**The Lift-On-Hover Rule.** Buttons and interactive cards rise `translateY(-1px)` on hover with an eased transition; the resting state is calm, motion confirms interactivity.

## Shapes

Two radii define the form language: **generously rounded cards** (`--gb-radius: 18px`) and **softly rounded sub-elements** (`--gb-radius-sm: 12px`, inputs `10px`). Every pill-shaped control — buttons, chips, badges, pills, status tags, avatars — is fully round (`999px`). Borders are 1px hairlines (`rgba(15,23,42,0.12)`), thickening in color, not weight, to mark state (the teal-tinted `border-strong` for focus/active). There are no sharp corners anywhere in the system; the softness is intentional and companion-like.

## Components

### Buttons
- **Shape:** fully pill (`999px`), 1px transparent border, `0.62rem 1rem` padding, weight 700.
- **Primary** (`.gb-btn-primary`): the teal→sky gradient (`linear-gradient(135deg, #0ea5a4, #0284c7)`), white text, sky-tinted Accent Lift shadow. One per screen (see The One Gradient Rule).
- **Secondary** (`.gb-btn-secondary`): translucent teal wash (`rgba(14,165,164,0.09)`), teal border, ink text.
- **Ghost** (`.gb-btn-ghost`): translucent white (`rgba(255,255,255,0.72)`), hairline border, ink text.
- **Sizes/variants:** `.gb-btn-sm` (compact), `.gb-btn-full` (100% width), `.gb-btn-linkedin` (brand).
- **Hover:** `translateY(-1px)` + shadow shift (all variants). **Disabled:** `opacity: 0.6`, `not-allowed`.

### Chips
- **Style:** pill, translucent teal fill (`rgba(45,212,191,0.11)`), teal border, Success-Ink text, weight 700, `0.78rem`.
- **Variants:** `--soft` (sky-tinted, non-interactive), `--action` (sky-tinted, clickable). Interactive chips use `cursor: pointer`; display chips `cursor: default`.

### Badges & Pills
- **Badge** (`.gb-badge`): tiny uppercase pill, sky-tinted fill, weight 800, `0.67rem`, wide tracking — for inline meta ("NEW", counts, trust tags).
- **Pill** (`.gb-pill`): status pill with a `.gb-pill-dot` (currentColor dot); `--ok` teal-green, `--bad` red.
- **Priority badge** (`.gb-priority-badge`): `--critical` red, `--high` ochre, `--medium` teal, `--low` muted. Uppercase, weight 800.
- **Status pill** (`.gb-status-pill`): `--accepted` teal, `--declined` red, default muted.

### Cards / Containers
- **Corner:** 18px (`--gb-radius`). **Background:** Frosted Surface (`rgba(255,255,255,0.82)`) + `backdrop-filter: blur(10px)`.
- **Border:** 1px Hairline. **Shadow:** Card Lift (see Elevation). **Padding:** `~1.3rem`.

### Inputs / Fields
- **Field** (`.gb-field`): a `grid`/`flex` stack — an uppercase label (`0.78rem`, tracking `0.06em`, Muted) over the control, with optional `small` helper text.
- **Input/select:** full-width, `10px` radius, hairline border, near-opaque white fill (`rgba(255,255,255,0.95)`), `0.6rem 0.72rem` padding.
- **Focus:** teal `border-strong` + soft teal ring (`0 0 0 3px rgba(45,212,191,0.14)`); never a browser default outline.

### Navigation
- **Style:** sticky top bar, translucent mint (`rgba(240,253,250,0.82)`) + blur, 1px bottom hairline. Brand = a gradient teal→sky rounded tile (`.gb-mark`, 12px radius) beside the Sora wordmark. Right side holds the notification bell and user chip.

### Stepper (signature)
- The onboarding/pipeline **stepper** (`.gb-stepper`, `.gb-journey-*`) renders numbered steps with an uppercase step index (teal), a Sora title, and a state on the right. Active step: `border-strong` + soft teal ring; done: teal wash; locked: `opacity 0.5` + `not-allowed`. This is the spine of every multi-step flow, including the document pipeline's five stages.

## Do's and Don'ts

### Do:
- **Do** keep every surface translucent glass over the gradient — `rgba(255,255,255,0.82–0.94)` + `backdrop-filter: blur()`. The see-through quality is the "Clear Water" thesis.
- **Do** spend the teal→sky gradient on exactly one primary action per screen; everything else is flat glass.
- **Do** set headings and titles in Sora, everything else in Nunito.
- **Do** use fully-round pills (`999px`) for all buttons, chips, badges, and status tags; 18px for cards, 10–12px for inputs.
- **Do** signal focus and active state with the soft teal ring + teal-tinted `border-strong`, never a hard outline.
- **Do** keep semantic colors inside the palette: Success-Ink teal-green, Signal Sky info, ochre warning, `#b91c1c` danger.
- **Do** harden the confidence/review surfaces: an uncertain, high-stakes, or policy-flagged field must be unambiguously color-coded, even though the resting tone is calm.

### Don't:
- **Don't** use opaque flat-white panels or hard drop-shadows; if the gradient can't glow faintly through a surface, it's wrong.
- **Don't** introduce a second accent gradient or a third accent hue — the world is teal + sky only.
- **Don't** set body text, buttons, or labels in Sora.
- **Don't** use pure black (`#000`) for text — ink is Deep Slate (`#0f172a`).
- **Don't** show a raw confidence number as if it were a probability; it is Nutrient's uncalibrated signal and must carry its match label and cited source region (product constraint).
- **Don't** let the calm palette soften a warning: a needs-review or policy-change state is never rendered in a reassuring color.
