import 'package:freezed_annotation/freezed_annotation.dart';
import 'models.dart';

part 'node.freezed.dart';
part 'node.g.dart';

@freezed
class Node with _$Node {
  const Node._();

  const factory Node({
    required String id,
    required String title,
    @Default(false) bool isCompleted,
    @Default(0.0) double order,
    @Default([]) List<String> tags,
    String? notes,
    String? parentId,
    @Default(AiStatus.notReady) AiStatus aiStatus,
    @Default([]) List<String> localImagePaths,
    @Default([]) List<Node> children,
    TaskGoal? goal,
  }) = _Node;

  factory Node.fromJson(Map<String, dynamic> json) => _$NodeFromJson(json);

  /// Recursively find a node by ID in this subtree (including self).
  Node? findById(String targetId) {
    if (id == targetId) return this;
    for (final child in children) {
      final found = child.findById(targetId);
      if (found != null) return found;
    }
    return null;
  }

  /// Returns the path of IDs from this node to the target (including both).
  /// Returns null if not found.
  List<String>? pathTo(String targetId) {
    if (id == targetId) return [id];
    for (final child in children) {
      final childPath = child.pathTo(targetId);
      if (childPath != null) return [id, ...childPath];
    }
    return null;
  }

  /// Computed goal metadata (progress from children or explicit goal).
  GoalMetadata? get goalMetadata {
    if (goal != null) {
      return goal!.map(
        numeric: (n) {
          final pct = n.target == 0 ? 0.0 : (n.current / n.target).clamp(0.0, 1.0);
          return GoalMetadata(
            progress: pct,
            label: "${n.current}${n.unit ?? ''} / ${n.target}${n.unit ?? ''}",
          );
        },
        habit: (h) {
          final today = DateTime.now();
          final recent = <bool>[];
          for (int i = 4; i >= 0; i--) {
            final d = today.subtract(Duration(days: i));
            final entry = h.history
                .where((r) =>
                    r.date.year == d.year &&
                    r.date.month == d.month &&
                    r.date.day == d.day)
                .firstOrNull;
            recent.add(entry?.isSuccess ?? false);
          }
          final successCount = h.history.where((r) => r.isSuccess).length;
          final totalCount = h.history.length;
          final pct =
              totalCount > 0 ? (successCount / totalCount * 100).toInt() : 0;
          return GoalMetadata(
            recentHabitHistory: recent,
            label:
                "${(h.targetFrequency * 100).toInt()}% Target | $pct% Actual",
          );
        },
      );
    } else if (children.isNotEmpty) {
      final total = children.length;
      final completed = children.where((c) => c.isCompleted).length;
      if (total > 0) {
        return GoalMetadata(
          progress: completed / total,
          label: "$completed/$total",
        );
      }
    }
    return null;
  }
}
