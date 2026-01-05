class Config {
  static String get screenshotDir {
    const fromEnv = String.fromEnvironment('SCREENSHOT_DIR');
    if (fromEnv.isNotEmpty) return fromEnv;
    return ''; // Default empty if not from environment
  }

  static String? get dataDir {
    const fromEnv = String.fromEnvironment('DATA_DIR');
    if (fromEnv.isNotEmpty) return fromEnv;
    return null;
  }
}
