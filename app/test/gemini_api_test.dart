import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/node_service.dart';
import 'helpers/fake_storage_repository.dart';

void main() {
  group('NodeService Initialization', () {
    late NodeService nodeService;

    setUp(() async {
      final repository = FakeStorageRepository();
      nodeService = NodeService(repository);
      await nodeService.initData();
    });

    test('NodeService initializes with empty root nodes', () {
      expect(nodeService.rootNodes, isEmpty);
    });
  });
}
