import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ai_tools/tool_registry.dart';
import 'data_provider.dart';

final toolRegistryProvider = Provider<ToolRegistry>((ref) {
  final dataService = ref.read(dataServiceProvider);
  return ToolRegistry(dataService);
});
