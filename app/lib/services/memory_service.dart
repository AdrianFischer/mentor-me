import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../models/ai_models.dart';
import '../data/repository/storage_repository.dart';

class MemoryService extends ChangeNotifier {
  final StorageRepository _repository;
  List<Memory> _memories = [];
  bool _isInitialized = false;
  StreamSubscription? _dataSubscription;

  MemoryService(this._repository);

  List<Memory> get memories => _memories;

  Future<void> initData() async {
    if (_isInitialized) return;
    _isInitialized = true;
    
    _dataSubscription = _repository.onDataChanged.listen((_) {
      print("Data change detected. Reloading...");
      _reloadMemories();
    });
    
    await _reloadMemories();
  }

  Future<void> _reloadMemories() async {
    final list = await _repository.getAllMemories();
    _memories = List.from(list);
    notifyListeners();
  }

  Future<void> saveMemory(String fact) async {
    final memory = Memory(fact: fact);
    _memories = List<Memory>.from(_memories)..insert(0, memory);
    notifyListeners();
    await _repository.saveMemory(memory);
  }

  Future<void> deleteMemory(String id) async {
    _memories = List<Memory>.from(_memories)..removeWhere((m) => m.id == id);
    notifyListeners();
    await _repository.deleteMemory(id);
  }
  
  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }
}
