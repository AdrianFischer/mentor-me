import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../models/models.dart';
import 'data_provider.dart';

class TaskFilterState {
  final bool showCompletedTasks;
  final bool showCompletedSubtasks;
  
  TaskFilterState({this.showCompletedTasks = true, this.showCompletedSubtasks = true});
  
  TaskFilterState copyWith({bool? showCompletedTasks, bool? showCompletedSubtasks}) {
    return TaskFilterState(
      showCompletedTasks: showCompletedTasks ?? this.showCompletedTasks,
      showCompletedSubtasks: showCompletedSubtasks ?? this.showCompletedSubtasks,
    );
  }
}

class TaskFilterNotifier extends StateNotifier<TaskFilterState> {
  TaskFilterNotifier() : super(TaskFilterState());
  
  void toggleTasks() => state = state.copyWith(showCompletedTasks: !state.showCompletedTasks);
  void toggleSubtasks() => state = state.copyWith(showCompletedSubtasks: !state.showCompletedSubtasks);
}

final taskFilterProvider = StateNotifierProvider<TaskFilterNotifier, TaskFilterState>((ref) => TaskFilterNotifier());

/// Provider for filtered projects
final filteredProjectsProvider = Provider<List<Project>>((ref) {
  final projects = ref.watch(dataServiceProvider.select((ds) => ds.projects));
  return projects;
});

/// Provider for tasks of a specific project, filtered by completion status
final filteredTasksProvider = Provider.family<List<Task>, String>((ref, projectId) {
  final projects = ref.watch(dataServiceProvider.select((ds) => ds.projects));
  final showCompleted = ref.watch(taskFilterProvider.select((s) => s.showCompletedTasks));
  
  final project = projects.firstWhereOrNull((p) => p.id == projectId);
  if (project == null) return [];

  if (showCompleted) {
    return project.tasks;
  } else {
    return project.tasks.where((t) => !t.isCompleted).toList();
  }
});

/// Provider for subtasks of a specific task, filtered by completion status
final filteredSubtasksProvider = Provider.family<List<Subtask>, String>((ref, taskId) {
  final projects = ref.watch(dataServiceProvider.select((ds) => ds.projects));
  final showCompleted = ref.watch(taskFilterProvider.select((s) => s.showCompletedSubtasks));

  for (final project in projects) {
    final task = project.tasks.firstWhereOrNull((t) => t.id == taskId);
    if (task != null) {
      if (showCompleted) {
        return task.subtasks;
      } else {
        return task.subtasks.where((s) => !s.isCompleted).toList();
      }
    }
  }
  return [];
});
