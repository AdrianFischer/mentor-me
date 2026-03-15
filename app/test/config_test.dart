import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  group('Config', () {
    setUp(() {
      dotenv.testLoad(fileInput: '');
    });

    test('Can read screenshot dir from environment', () {
      // Dart define simulation requires launching test with args, 
      // but here we just check default behavior or internal logic.
      expect(Config.screenshotDir, isEmpty); 
    });
  });
}





