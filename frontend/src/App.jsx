import { Component } from "react";
import { Navigate, Route, Routes } from "react-router-dom";
import { AuthProvider } from "./contexts/AuthContext.jsx";
import OnboardingPage from "./pages/OnboardingPage.jsx";
import AuthPage from "./pages/AuthPage.jsx";
import DashboardPage from "./pages/DashboardPage.jsx";
import PreArrivalPage from "./pages/PreArrivalPage.jsx";
import ChatPage from "./pages/ChatPage.jsx";
import ConnectionsPage from "./pages/ConnectionsPage.jsx";
import FeedPage from "./pages/FeedPage.jsx";
import MentorsPage from "./pages/MentorsPage.jsx";
import BecomeMentorPage from "./pages/BecomeMentorPage.jsx";
import PublicProfilePage from "./pages/PublicProfilePage.jsx";
import DocumentsPage from "./pages/DocumentsPage.jsx";

class ErrorBoundary extends Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError() {
    return { hasError: true };
  }

  componentDidCatch(error, info) {
    console.error("Globalदोस्त uncaught error:", error, info);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="gb-app" style={{ display: "flex", alignItems: "center", justifyContent: "center", minHeight: "100dvh" }}>
          <div className="gb-card" style={{ maxWidth: 400, textAlign: "center", padding: "2rem" }}>
            <h2 style={{ marginBottom: "0.75rem" }}>Something went wrong</h2>
            <p style={{ color: "var(--gb-muted)", marginBottom: "1.5rem" }}>
              Please refresh the page to continue. If the problem persists, try clearing your browser data.
            </p>
            <button
              type="button"
              className="gb-btn gb-btn-primary"
              onClick={() => window.location.reload()}
            >
              Refresh page
            </button>
          </div>
        </div>
      );
    }
    return this.props.children;
  }
}

export default function App() {
  return (
    <ErrorBoundary>
      <AuthProvider>
        <Routes>
          <Route path="/" element={<OnboardingPage />} />
          <Route path="/onboarding" element={<Navigate to="/" replace />} />
          <Route path="/auth" element={<AuthPage />} />
          <Route path="/dashboard" element={<DashboardPage />} />
          <Route path="/profile/:id" element={<PublicProfilePage />} />
          <Route path="/pre-arrival" element={<PreArrivalPage />} />
          <Route path="/chat" element={<ChatPage />} />
          <Route path="/connections" element={<ConnectionsPage />} />
          <Route path="/feed" element={<FeedPage />} />
          <Route path="/saved" element={<FeedPage savedOnly />} />
          <Route path="/mentors" element={<MentorsPage />} />
          <Route path="/become-mentor" element={<BecomeMentorPage />} />
          <Route path="/documents" element={<DocumentsPage />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </AuthProvider>
    </ErrorBoundary>
  );
}
