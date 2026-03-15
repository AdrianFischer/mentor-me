/// App configuration.
/// Toggle useRemoteBackend to switch between local file-based and REST API backend.
class AppConfig {
  /// When true, Flutter connects to the agent's REST API for all data.
  /// When false, Flutter reads/writes Markdown files directly (legacy behavior).
  static const bool useRemoteBackend = true;

  /// Base URL for the agent's REST API (used when useRemoteBackend is true).
  static const String backendUrl = 'http://localhost:8082/api/v1';
}
