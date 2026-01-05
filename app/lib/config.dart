import 'dart:io';

class Config {
  static String get screenshotDir {
    const fromEnv = String.fromEnvironment('SCREENSHOT_DIR');
    if (fromEnv.isNotEmpty) return fromEnv;
    return ''; // Default empty if not from environment
  }

  static String? get dataDir {
    const fromEnv = String.fromEnvironment('DATA_DIR');
    if (fromEnv.isNotEmpty) return fromEnv;
    
    // Do not use defaults in test environment to avoid interfering with real data
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return null;
    }

    // Default for local development if running from project root or app folder
    if (Directory('../data').existsSync()) {
      return '../data';
    }
    if (Directory('data').existsSync()) {
      return 'data';
    }
    return null;
  }
}
