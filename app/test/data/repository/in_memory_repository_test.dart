import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/data/repository/in_memory_repository.dart';
import 'package:flutter_app/models/models.dart';
import 'package:flutter_app/services/file_persistence_service.dart';
import 'package:mocktail/mocktail.dart';
import 'dart:io';

class MockFilePersistence extends Mock implements FilePersistenceService {}
class FakeProject extends Fake implements Project {}

void main() {
  group('InMemoryRepository Bootstrap', () {
    late InMemoryRepository repository;
    late MockFilePersistence mockFileService;

    setUpAll(() {
      registerFallbackValue(FakeProject());
    });

    setUp(() async {
      mockFileService = MockFilePersistence();
      when(() => mockFileService.watchProjects()).thenAnswer((_) => Stream.empty());
      when(() => mockFileService.loadAllProjects()).thenAnswer((_) async => []);
      when(() => mockFileService.saveProject(any())).thenAnswer((_) async {});
      
      repository = InMemoryRepository(mockFileService);
    });

    test('init() should load projects from FilePersistenceService', () async {
      final project = Project(id: '1', title: 'Test', tasks: []);
      when(() => mockFileService.loadAllProjects()).thenAnswer((_) async => [project]);
      
      await repository.init();
      
      final projects = await repository.getAllProjects();
      expect(projects.length, 1);
      expect(projects.first.id, '1');
    });
    
    test('saveProject should delegate to FilePersistenceService', () async {
      final project = Project(id: '1', title: 'Test', tasks: []);
      await repository.saveProject(project);
      
      verify(() => mockFileService.saveProject(project)).called(1);
    });
  });
}
