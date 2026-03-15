import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/node.dart';
import 'data_provider.dart';
import 'filtered_data_providers.dart';

/// Children of a given parent node, filtered by completion status.
/// Pass null for root-level nodes.
final filteredChildrenProvider = Provider.family<List<Node>, String?>((ref, parentId) {
  final nodeService = ref.watch(nodeServiceProvider);
  final filter = ref.watch(taskFilterProvider);
  final children = nodeService.getChildren(parentId);
  // Use the general showCompletedTasks filter for all non-root levels
  if (parentId == null) {
    if (filter.showCompletedProjects) return children;
    return children.where((n) => !n.isCompleted).toList();
  }
  if (filter.showCompletedTasks) return children;
  return children.where((n) => !n.isCompleted).toList();
});
