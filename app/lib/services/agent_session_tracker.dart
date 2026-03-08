import 'package:flutter/foundation.dart';

class AgentSessionTracker extends ChangeNotifier {
  final List<String> _sessionIndexMap = [];

  void clearSessionIndex() {
    _sessionIndexMap.clear();
    notifyListeners();
  }

  int addToSessionIndex(String id) {
    final index = _sessionIndexMap.indexOf(id);
    if (index != -1) return index + 1;
    _sessionIndexMap.add(id);
    notifyListeners();
    return _sessionIndexMap.length;
  }

  String? getIdFromSessionIndex(int index) {
    if (index < 1 || index > _sessionIndexMap.length) return null;
    return _sessionIndexMap[index - 1];
  }
}
