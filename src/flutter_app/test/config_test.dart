import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_app/config.dart';

void main() {
  group('Config', () {
    test('Reads API key from dotenv', () {
      // Setup mock env
      dotenv.testLoad(fileInput: '''
GEMINI_API_KEY=test_api_key
SCREENSHOT_DIR=test_screenshot_dir
''');

      expect(Config.geminiApiKey, equals('test_api_key'));
      expect(Config.hasGeminiKey, isTrue);
      expect(Config.screenshotDir, equals('test_screenshot_dir'));
    });

    test('Handles missing API key gracefully', () {
      // Setup empty env
      dotenv.testLoad(fileInput: '');

      // Depending on implementation, it might return empty string or fall back to dart-define
      // Since we are not passing --dart-define in test, it should be empty
      expect(Config.geminiApiKey, isEmpty);
      expect(Config.hasGeminiKey, isFalse);
    });
  });
}




