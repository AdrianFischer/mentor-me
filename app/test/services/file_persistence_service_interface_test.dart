import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_app/models/node.dart';
import 'package:flutter_app/services/file_persistence_service.dart';

class MockFilePersistenceService extends Mock implements FilePersistenceService {}

class FakeNode extends Fake implements Node {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeNode());
  });

  test('FilePersistenceService interface should be implementable', () {
    final service = MockFilePersistenceService();
    expect(service, isA<FilePersistenceService>());
  });

  test('FilePersistenceService should have required methods', () async {
    final service = MockFilePersistenceService();
    final node = FakeNode();

    when(() => service.loadAllNodes()).thenAnswer((_) async => []);
    when(() => service.saveNode(any())).thenAnswer((_) async {});
    when(() => service.deleteNode(any())).thenAnswer((_) async {});

    await service.loadAllNodes();
    await service.saveNode(node);
    await service.deleteNode('some-id');

    verify(() => service.loadAllNodes()).called(1);
    verify(() => service.saveNode(node)).called(1);
    verify(() => service.deleteNode('some-id')).called(1);
  });
}
