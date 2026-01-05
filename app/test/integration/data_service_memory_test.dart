import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/data_service.dart';
import 'package:flutter_app/data/repository/in_memory_repository.dart';
import 'package:flutter_app/services/file_persistence_service.dart';
import 'package:flutter_app/models/models.dart';
import 'package:mocktail/mocktail.dart';

class MockFilePersistence extends Mock implements FilePersistenceService {}
class FakeProject extends Fake implements Project {}

void main() {
  group('DataService with InMemoryRepository', () {
    late InMemoryRepository repository;
    late MockFilePersistence filePersistence;
    late DataService dataService;

    setUpAll(() {
      registerFallbackValue(FakeProject());
    });

    setUp(() {
      filePersistence = MockFilePersistence();
      when(() => filePersistence.watchProjects()).thenAnswer((_) => Stream.empty());
      when(() => filePersistence.loadAllProjects()).thenAnswer((_) async => []);
      when(() => filePersistence.saveProject(any())).thenAnswer((_) async {});

      repository = InMemoryRepository(filePersistence);
      
      dataService = DataService(repository);
    });

    test('addProject should update InMemoryRepository', () async {
      final id = await dataService.addProject('Test Project');
      
      final projects = await repository.getAllProjects();
      expect(projects.length, 1);
      expect(projects.first.id, id);
      expect(projects.first.title, 'Test Project');
    });

    test('addTask should update InMemoryRepository', () async {
      final projectId = await dataService.addProject('Project 1');
      await dataService.addTask(projectId, 'Task 1');
      
      final projects = await repository.getAllProjects();
      expect(projects.first.tasks.length, 1);
      expect(projects.first.tasks.first.title, 'Task 1');
    });

    test('addProject should trigger FilePersistenceService.saveProject', () async {
      await dataService.addProject('Persistent Project');
      
      verify(() => filePersistence.saveProject(any(that: isA<Project>().having((p) => p.title, 'title', 'Persistent Project')))).called(1);
    });
  });
}
