import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_app/models/models.dart';
import 'package:flutter_app/services/file_persistence_service.dart';

// Create a Mock class to verify the interface can be implemented
class MockFilePersistenceService extends Mock implements FilePersistenceService {}

class FakeProject extends Fake implements Project {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeProject());
  });

  test('FilePersistenceService interface should be implementable', () {
    final service = MockFilePersistenceService();
    expect(service, isA<FilePersistenceService>());
  });

  test('FilePersistenceService should have required methods', () async {
    final service = MockFilePersistenceService();
    final project = FakeProject();

    // Verify method signatures exist by mocking them
    when(() => service.loadAllProjects()).thenAnswer((_) async => []);
    when(() => service.saveProject(any())).thenAnswer((_) async {});
    when(() => service.deleteProject(any())).thenAnswer((_) async {});

    await service.loadAllProjects();
    await service.saveProject(project);
    await service.deleteProject('some-id');
    
    verify(() => service.loadAllProjects()).called(1);
    verify(() => service.saveProject(project)).called(1);
    verify(() => service.deleteProject('some-id')).called(1);
  });
}
