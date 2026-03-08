import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../models/ai_models.dart';
import '../data/repository/storage_repository.dart';

class KnowledgeService extends ChangeNotifier {
  final StorageRepository _repository;

  KnowledgeService(this._repository);

  Future<void> saveKnowledge(String content) async {
    print("[VERIFY_FLOW] Saving knowledge: $content");
    final knowledge = Knowledge(content: content);
    await _repository.saveKnowledge(knowledge);
    notifyListeners();
  }

  Future<void> updateKnowledge(Knowledge knowledge) async {
    await _repository.saveKnowledge(knowledge);
    notifyListeners();
  }

  Future<void> deleteKnowledge(String id) async {
    await _repository.deleteKnowledge(id);
    notifyListeners();
  }

  Future<List<Knowledge>> getAllKnowledge() async {
    return _repository.getAllKnowledge();
  }
}
