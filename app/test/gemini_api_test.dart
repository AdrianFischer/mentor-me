import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/data_service.dart';
import 'helpers/fake_storage_repository.dart';

void main() {
  group('DataService Initialization', () {
    late DataService dataService;

    setUp(() {
      dataService = DataService(FakeStorageRepository());
    });

    test('DataService initializes with empty projects', () {
      expect(dataService.projects, isEmpty);
    });
  });
}