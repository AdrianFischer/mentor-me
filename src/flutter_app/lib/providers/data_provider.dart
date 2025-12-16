import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/data_service.dart';

final dataServiceProvider = ChangeNotifierProvider<DataService>((ref) {
  final service = DataService();
  service.initData(); // Initialize with dummy data for now
  return service;
});
