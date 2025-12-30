import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/data_service.dart';
import 'package:flutter_app/services/markdown_persistence_service.dart';
import 'package:flutter_app/data/repository/storage_repository.dart';
import 'package:flutter_app/models/models.dart';
import 'package:flutter_app/models/ai_models.dart';
import 'helpers/fake_storage_repository.dart';

class FakeMarkdownPersistence extends MarkdownPersistenceService {
  FakeMarkdownPersistence() : super(baseDir: null); // Pass null to disable
  
  @override
  bool get isEnabled => false;
}

void main() {
  group('DataService Initialization', () {
    late DataService dataService;

    setUp(() {
      dataService = DataService(FakeStorageRepository(), FakeMarkdownPersistence());
    });

    test('DataService initializes with empty projects', () {
      expect(dataService.projects, isEmpty);
    });
  });
}
