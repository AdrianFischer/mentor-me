import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/data_service.dart';
import 'package:flutter_app/data/repository/in_memory_repository.dart';
import 'package:flutter_app/services/markdown_persistence_service.dart';
import 'package:flutter_app/models/models.dart';
import 'package:mocktail/mocktail.dart';

class MockMarkdownPersistence extends Mock implements MarkdownPersistenceService {}
class FakeProject extends Fake implements Project {}

void main() {
  group('DataService with InMemoryRepository', () {
    late InMemoryRepository repository;
    late MockMarkdownPersistence markdownPersistence;
    late DataService dataService;

    setUpAll(() {
      registerFallbackValue(FakeProject());
    });

    setUp(() {
      repository = InMemoryRepository();
      markdownPersistence = MockMarkdownPersistence();
      when(() => markdownPersistence.saveProject(any())).thenAnswer((_) async {});
      
      dataService = DataService(repository, markdownPersistence);
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
  });
}
