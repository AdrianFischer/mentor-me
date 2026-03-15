import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskFilterState {
  final bool showCompletedProjects;
  final bool showCompletedTasks;

  TaskFilterState({this.showCompletedProjects = true, this.showCompletedTasks = true});

  TaskFilterState copyWith({bool? showCompletedProjects, bool? showCompletedTasks}) {
    return TaskFilterState(
      showCompletedProjects: showCompletedProjects ?? this.showCompletedProjects,
      showCompletedTasks: showCompletedTasks ?? this.showCompletedTasks,
    );
  }
}

class TaskFilterNotifier extends StateNotifier<TaskFilterState> {
  TaskFilterNotifier() : super(TaskFilterState());

  void toggleProjects() => state = state.copyWith(showCompletedProjects: !state.showCompletedProjects);
  void toggleTasks() => state = state.copyWith(showCompletedTasks: !state.showCompletedTasks);
}

final taskFilterProvider = StateNotifierProvider<TaskFilterNotifier, TaskFilterState>((ref) => TaskFilterNotifier());
