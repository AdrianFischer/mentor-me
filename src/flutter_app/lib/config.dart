import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  // Try to get from dart-define first to avoid dotenv crashes if not initialized,
  // and to allow explicit overrides via flags.

  static String get geminiApiKey {
    const fromEnv = String.fromEnvironment('GEMINI_API_KEY');
    if (fromEnv.isNotEmpty) return fromEnv;
    try {
      return dotenv.env['GEMINI_API_KEY'] ?? '';
    } catch (_) {
      return '';
    }
  }
      
  static String get screenshotDir {
    const fromEnv = String.fromEnvironment('SCREENSHOT_DIR');
    if (fromEnv.isNotEmpty) return fromEnv;
    try {
      return dotenv.env['SCREENSHOT_DIR'] ?? '';
    } catch (_) {
      return '';
    }
  }

  static String? get dataDir {
    const fromEnv = String.fromEnvironment('DATA_DIR');
    if (fromEnv.isNotEmpty) return fromEnv;
    try {
      return dotenv.env['DATA_DIR']?.isNotEmpty == true ? dotenv.env['DATA_DIR'] : null;
    } catch (_) {
      return null;
    }
  }
  
  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;
}
