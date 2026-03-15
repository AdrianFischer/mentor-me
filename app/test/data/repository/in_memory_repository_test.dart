import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/data/repository/in_memory_repository.dart';
import 'package:flutter_app/models/node.dart';
import 'package:flutter_app/services/file_persistence_service.dart';
import 'package:mocktail/mocktail.dart';

class MockFilePersistence extends Mock implements FilePersistenceService {}
class FakeNode extends Fake implements Node {}

void main() {
  group('InMemoryRepository Bootstrap', () {
    late InMemoryRepository repository;
    late MockFilePersistence mockFileService;

    setUpAll(() {
      registerFallbackValue(FakeNode());
    });

    setUp(() async {
      mockFileService = MockFilePersistence();
      when(() => mockFileService.watchNodes()).thenAnswer((_) => Stream.empty());
      when(() => mockFileService.loadAllNodes()).thenAnswer((_) async => []);
      when(() => mockFileService.saveNode(any())).thenAnswer((_) async {});

      repository = InMemoryRepository(mockFileService);
    });

    test('init() should load nodes from FilePersistenceService', () async {
      final node = Node(id: '1', title: 'Test');
      when(() => mockFileService.loadAllNodes()).thenAnswer((_) async => [node]);

      await repository.init();

      final nodes = await repository.getAllNodes();
      expect(nodes.length, 1);
      expect(nodes.first.id, '1');
    });

    test('saveNode should delegate to FilePersistenceService', () async {
      final node = Node(id: '1', title: 'Test');
      await repository.saveNode(node);

      verify(() => mockFileService.saveNode(node)).called(1);
    });
  });
}
