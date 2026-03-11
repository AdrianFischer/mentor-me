import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/data_service.dart';
import '../services/project_service.dart';
import '../models/models.dart';
import 'data_provider.dart';
import 'filtered_data_providers.dart';

class SelectionState {
  final String? selectedProjectId;
  final String? selectedTaskId;
  final String? selectedSubtaskId;
  final String? selectedConversationId;
  final String? selectedTag;
  final TaggedItem? selectedTaggedItem;
  final int
  focusedColumnIndex; // 0: Projects, 1: Tasks/Conversations, 2: Details/Chat
  final bool isAssistantActive;
  final String? editingItemId;

  SelectionState({
    this.selectedProjectId,
    this.selectedTaskId,
    this.selectedSubtaskId,
    this.selectedConversationId,
    this.selectedTag,
    this.selectedTaggedItem,
    this.focusedColumnIndex = 0,
    this.isAssistantActive = false,
    this.editingItemId,
  });

  SelectionState copyWith({
    String? selectedProjectId,
    String? selectedTaskId,
    String? selectedSubtaskId,
    String? selectedConversationId,
    String? selectedTag,
    TaggedItem? selectedTaggedItem,
    int? focusedColumnIndex,
    bool? isAssistantActive,
    String? editingItemId,
    // Special flags to allow setting null
    bool clearProject = false,
    bool clearTask = false,
    bool clearSubtask = false,
    bool clearConversation = false,
    bool clearTag = false,
    bool clearTaggedItem = false,
    bool clearEditing = false,
  }) {
    return SelectionState(
      selectedProjectId: clearProject
          ? null
          : (selectedProjectId ?? this.selectedProjectId),
      selectedTaskId: clearTask
          ? null
          : (selectedTaskId ?? this.selectedTaskId),
      selectedSubtaskId: clearSubtask
          ? null
          : (selectedSubtaskId ?? this.selectedSubtaskId),
      selectedConversationId: clearConversation
          ? null
          : (selectedConversationId ?? this.selectedConversationId),
      selectedTag: clearTag ? null : (selectedTag ?? this.selectedTag),
      selectedTaggedItem: clearTaggedItem
          ? null
          : (selectedTaggedItem ?? this.selectedTaggedItem),
      focusedColumnIndex: focusedColumnIndex ?? this.focusedColumnIndex,
      isAssistantActive: isAssistantActive ?? this.isAssistantActive,
      editingItemId: clearEditing
          ? null
          : (editingItemId ?? this.editingItemId),
    );
  }
}

class SelectionNotifier extends Notifier<SelectionState> {
  @override
  SelectionState build() {
    return SelectionState();
  }

  // --- Basic Setters ---

  void selectProject(String? projectId) {
    state = state.copyWith(
      selectedProjectId: projectId,
      clearProject: projectId == null,
      clearTask: true,
      clearSubtask: true,
      isAssistantActive: false,
      clearTag: true,
      clearTaggedItem: true,
      focusedColumnIndex: 0,
    );
    if (projectId != null) {
      ref.invalidate(filteredTasksProvider(projectId));
    }
  }

  void selectTask(String? taskId) {
    state = state.copyWith(
      selectedTaskId: taskId,
      clearTask: taskId == null,
      clearSubtask: true,
      focusedColumnIndex: 1,
    );
    if (taskId != null) {
      ref.invalidate(filteredSubtasksProvider(taskId));
    }
  }

  void selectSubtask(String? subtaskId) {
    state = state.copyWith(
      selectedSubtaskId: subtaskId,
      clearSubtask: subtaskId == null,
      focusedColumnIndex: 2,
    );
  }

  void selectConversation(String? conversationId) {
    state = state.copyWith(
      selectedConversationId: conversationId,
      clearConversation: conversationId == null,
      focusedColumnIndex: 1,
    );
  }

  void setAssistantActive(bool isActive) {
    if (isActive) {
      final data = ref.read(dataServiceProvider);
      String? convId = state.selectedConversationId;
      if (convId == null && data.conversations.isNotEmpty) {
        convId = data.conversations.first.id;
      }
      state = state.copyWith(
        isAssistantActive: true,
        clearProject: true,
        clearTask: true,
        clearSubtask: true,
        clearTag: true,
        focusedColumnIndex: 1, // Focus conversation list
        selectedConversationId: convId,
      );
    } else {
      state = state.copyWith(isAssistantActive: false);
    }
  }

  void setEditingItem(String? itemId) {
    state = state.copyWith(editingItemId: itemId, clearEditing: itemId == null);
  }

  void selectTag(String tag) {
    state = state.copyWith(
      selectedTag: tag,
      isAssistantActive: false,
      clearProject: true,
      clearTask: true,
      clearSubtask: true,
      clearTaggedItem: true,
      focusedColumnIndex: 1,
    );
  }

  void selectTaggedItem(TaggedItem item) {
    state = state.copyWith(selectedTaggedItem: item, focusedColumnIndex: 2);
  }

  void setFocusedColumn(int index) {
    state = state.copyWith(focusedColumnIndex: index);
  }

  // --- Logic Operations ---

  void moveSelection(int delta) {
    final dataService = ref.read(dataServiceProvider);

    // AI Mode Logic
    if (state.isAssistantActive) {
      if (state.focusedColumnIndex == 0 && delta > 0) {
        // Leave Assistant Header
        setAssistantActive(false);
        if (dataService.projects.isNotEmpty) {
          state = state.copyWith(
            selectedProjectId: dataService.projects.first.id,
            focusedColumnIndex: 0,
          );
        }
        return;
      }

      if (state.focusedColumnIndex == 1) {
        // Conversation List
        final conversations = dataService.conversations;
        if (conversations.isEmpty) return;

        int currentIndex = conversations.indexWhere(
          (c) => c.id == state.selectedConversationId,
        );
        int nextIndex = currentIndex + delta;
        if (nextIndex < 0) nextIndex = 0;
        if (nextIndex >= conversations.length)
          nextIndex = conversations.length - 1;

        state = state.copyWith(
          selectedConversationId: conversations[nextIndex].id,
        );
      }
      return;
    }

    // Standard Mode Logic
    // dataService already defined at top of method

    // Cleanup empty items before moving selection
    _cleanupEmptyItems(dataService);

    final projects = dataService.projects;
    var (pIndex, tIndex, sIndex) = _getSelectionIndices(projects);

    // Clear editing on move
    if (state.editingItemId != null) {
      state = state.copyWith(clearEditing: true);
    }

    if (state.focusedColumnIndex == 0) {
      // Project List
      int conceptualIndex = state.isAssistantActive
          ? 0
          : (pIndex != null ? pIndex + 1 : -1);

      // Handling empty project deletion logic (moved here or handled in actions? For now just navigation)
      // If current selection is invalid, reset?

      int nextIndex = conceptualIndex + delta;
      int maxIndex = projects.length;

      if (nextIndex < 0) nextIndex = 0;
      if (nextIndex > maxIndex) nextIndex = maxIndex;

      if (nextIndex == 0) {
        setAssistantActive(true);
      } else {
        state = state.copyWith(
          selectedProjectId: projects[nextIndex - 1].id,
          isAssistantActive: false,
          clearTask: true,
          clearSubtask: true,
        );
      }
    } else if (state.focusedColumnIndex == 1) {
      // Task Column
      if (pIndex == null) return;
      final filter = ref.read(taskFilterProvider);
      final allTasks = projects[pIndex].tasks;
      final tasks = filter.showCompletedTasks
          ? allTasks
          : allTasks.where((t) => !t.isCompleted).toList();
      if (tasks.isEmpty) return;

      // Find current index in filtered list
      int currentFilteredIndex = -1;
      if (state.selectedTaskId != null) {
        currentFilteredIndex = tasks.indexWhere(
          (t) => t.id == state.selectedTaskId,
        );
      }

      int newIndex = currentFilteredIndex + delta;
      if (newIndex < 0) newIndex = 0;
      if (newIndex >= tasks.length) newIndex = tasks.length - 1;

      state = state.copyWith(
        selectedTaskId: tasks[newIndex].id,
        clearSubtask: true,
      );
      ref.invalidate(filteredTasksProvider(projects[pIndex].id));
    } else if (state.focusedColumnIndex == 2) {
      // Subtask Column
      if (pIndex == null || tIndex == null) return;
      final filter = ref.read(taskFilterProvider);
      final allSubtasks = projects[pIndex].tasks[tIndex].subtasks;
      final subtasks = filter.showCompletedSubtasks
          ? allSubtasks
          : allSubtasks.where((s) => !s.isCompleted).toList();
      if (subtasks.isEmpty) return;

      // Find current index in filtered list
      int currentFilteredIndex = -1;
      if (state.selectedSubtaskId != null) {
        currentFilteredIndex = subtasks.indexWhere(
          (s) => s.id == state.selectedSubtaskId,
        );
      }

      int newIndex = currentFilteredIndex + delta;
      if (newIndex < 0) newIndex = 0;
      if (newIndex >= subtasks.length) newIndex = subtasks.length - 1;

      state = state.copyWith(selectedSubtaskId: subtasks[newIndex].id);
      ref.invalidate(
        filteredSubtasksProvider(projects[pIndex].tasks[tIndex].id),
      );
    }
  }

  Future<void> changeColumn(int delta) async {
    // AI Mode
    if (state.isAssistantActive) {
      int next = state.focusedColumnIndex + delta;
      if (next < 0) next = 0;
      if (next > 2) next = 2;

      if (next == 2 && state.selectedConversationId == null) return;
      state = state.copyWith(focusedColumnIndex: next);
      return;
    }

    final dataService = ref.read(dataServiceProvider);

    // Cleanup empty items before moving focus
    _cleanupEmptyItems(dataService);

    final projects = dataService.projects;
    final (pIndex, tIndex, _) = _getSelectionIndices(projects);

    // Auto-create/Auto-select logic when moving right
    int nextColumn = state.focusedColumnIndex + delta;

    if (nextColumn >= 0 && nextColumn <= 2) {
      // Moving Right Logic
      if (delta > 0) {
        if (nextColumn == 1) {
          if (pIndex == null) return;
          final filter = ref.read(taskFilterProvider);
          final tasks = filter.showCompletedTasks
              ? projects[pIndex].tasks
              : projects[pIndex].tasks.where((t) => !t.isCompleted).toList();

          if (tasks.isEmpty) {
            // Auto-create task
            final newId = await dataService.addTask(projects[pIndex].id, "");
            if (newId != null) {
              state = state.copyWith(
                selectedTaskId: newId,
                focusedColumnIndex: 1,
                editingItemId: newId,
              );
              ref.invalidate(filteredTasksProvider(projects[pIndex].id));
            }
            return;
          } else {
            final targetId = state.selectedTaskId ?? tasks.first.id;
            state = state.copyWith(
              selectedTaskId: targetId,
              focusedColumnIndex: 1,
            );
            ref.invalidate(filteredTasksProvider(projects[pIndex].id));
            return;
          }
        } else if (nextColumn == 2) {
          if (pIndex == null || tIndex == null) return;
          final task = projects[pIndex].tasks[tIndex];
          final filter = ref.read(taskFilterProvider);
          final subtasks = filter.showCompletedSubtasks
              ? task.subtasks
              : task.subtasks.where((s) => !s.isCompleted).toList();

          if (subtasks.isEmpty) {
            // Auto-create subtask
            final newId = await dataService.addSubtask(task.id, "");
            if (newId != null) {
              state = state.copyWith(
                selectedSubtaskId: newId,
                focusedColumnIndex: 2,
                editingItemId: newId,
              );
              ref.invalidate(filteredSubtasksProvider(task.id));
            }
            return;
          } else {
            final targetId = state.selectedSubtaskId ?? subtasks.first.id;
            state = state.copyWith(
              selectedSubtaskId: targetId,
              focusedColumnIndex: 2,
            );
            ref.invalidate(filteredSubtasksProvider(task.id));
            return;
          }
        }
      }

      state = state.copyWith(focusedColumnIndex: nextColumn);
    }
  }

  // Helper to resolve current selection indices
  (int?, int?, int?) _getSelectionIndices(List<Project> projects) {
    int? pIndex = projects.indexWhere((p) => p.id == state.selectedProjectId);
    if (pIndex == -1) pIndex = null;

    int? tIndex;
    if (pIndex != null) {
      tIndex = projects[pIndex].tasks.indexWhere(
        (t) => t.id == state.selectedTaskId,
      );
      if (tIndex == -1) tIndex = null;
    }

    int? sIndex;
    if (pIndex != null && tIndex != null) {
      sIndex = projects[pIndex].tasks[tIndex].subtasks.indexWhere(
        (s) => s.id == state.selectedSubtaskId,
      );
      if (sIndex == -1) sIndex = null;
    }
    return (pIndex, tIndex, sIndex);
  }

  void _cleanupEmptyItems(DataService dataService) {
    // We use dataService.projects directly in loops to ensure we see updates
    for (var p in List.of(dataService.projects)) {
      // Only cleanup if it's NOT the project we are currently editing
      if (p.title.trim().isEmpty && p.tasks.isEmpty) {
        if (p.id != state.editingItemId) {
          dataService.deleteItem(p.id);
          // If we just deleted the selected project, clear selection
          if (p.id == state.selectedProjectId) {
            state = state.copyWith(
              clearProject: true,
              clearTask: true,
              clearSubtask: true,
            );
          }
          continue; // Project is gone, move to next
        }
      }

      // Cleanup Tasks in this project
      for (var t in List.of(p.tasks)) {
        if (t.title.trim().isEmpty && t.subtasks.isEmpty) {
          if (t.id != state.editingItemId) {
            dataService.deleteItem(t.id);
            if (t.id == state.selectedTaskId) {
              state = state.copyWith(clearTask: true, clearSubtask: true);
            }
            continue;
          }
        }

        // Cleanup Subtasks
        for (var s in List.of(t.subtasks)) {
          if (s.title.trim().isEmpty) {
            if (s.id != state.editingItemId) {
              dataService.deleteItem(s.id);
              if (s.id == state.selectedSubtaskId) {
                state = state.copyWith(clearSubtask: true);
              }
            }
          }
        }
      }
    }
  }
}

final selectionProvider = NotifierProvider<SelectionNotifier, SelectionState>(
  SelectionNotifier.new,
);
