import '../models/node.dart';

abstract class FilePersistenceService {
  Future<List<Node>> loadAllNodes();
  Future<void> saveNode(Node node);
  Future<void> deleteNode(String nodeId);
  Stream<List<Node>> watchNodes();
}
