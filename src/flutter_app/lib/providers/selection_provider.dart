import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/data_service.dart';
import '../models/models.dart';
import 'data_provider.dart';

class SelectionState {
  final String? selectedProjectId;
  final String? selectedTaskId;
  final String? selectedSubtaskId;
  final String? selectedConversationId;
  final String? selectedTag;
  final TaggedItem? selectedTaggedItem;
  final int focusedColumnIndex; // 0: Projects, 1: Tasks/Conversations, 2: Details/Chat
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
      selectedProjectId: clearProject ? null : (selectedProjectId ?? this.selectedProjectId),
      selectedTaskId: clearTask ? null : (selectedTaskId ?? this.selectedTaskId),
      selectedSubtaskId: clearSubtask ? null : (selectedSubtaskId ?? this.selectedSubtaskId),
      selectedConversationId: clearConversation ? null : (selectedConversationId ?? this.selectedConversationId),
      selectedTag: clearTag ? null : (selectedTag ?? this.selectedTag),
      selectedTaggedItem: clearTaggedItem ? null : (selectedTaggedItem ?? this.selectedTaggedItem),
      focusedColumnIndex: focusedColumnIndex ?? this.focusedColumnIndex,
      isAssistantActive: isAssistantActive ?? this.isAssistantActive,
      editingItemId: clearEditing ? null : (editingItemId ?? this.editingItemId),
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
      clearTask: true,
      clearSubtask: true,
      isAssistantActive: false,
      clearTag: true,
      clearTaggedItem: true,
      focusedColumnIndex: 0, // When clicking a project, usually we want focus there or next col? 
                             // Keeping it simple: if you select a project, you are focusing the project list or ready to move right.
                             // But consistent with UI: if I click a project, it becomes active.
    );
    // Auto-focus next column usually happens if invoked via keyboard, but via tap we might want to stay.
    // Let's stick to state updates.
  }

  void selectTask(String? taskId) {
    state = state.copyWith(
      selectedTaskId: taskId,
      clearSubtask: true,
      focusedColumnIndex: 1,
    );
  }

  void selectSubtask(String? subtaskId) {
    state = state.copyWith(
      selectedSubtaskId: subtaskId,
      focusedColumnIndex: 2,
    );
  }

  void selectConversation(String? conversationId) {
    state = state.copyWith(
      selectedConversationId: conversationId,
      focusedColumnIndex: 1, // Keep focus on the list to allow navigation/highlight
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
         selectedConversationId: convId
       );
     } else {
       state = state.copyWith(isAssistantActive: false);
     }
  }

  void setEditingItem(String? itemId) {
    state = state.copyWith(
      editingItemId: itemId,
      clearEditing: itemId == null
    );
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
    state = state.copyWith(
      selectedTaggedItem: item,
      focusedColumnIndex: 2,
    );
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
             state = state.copyWith(selectedProjectId: dataService.projects.first.id, focusedColumnIndex: 0);
          }
          return;
       }

       if (state.focusedColumnIndex == 1) { // Conversation List
          final conversations = dataService.conversations;
          if (conversations.isEmpty) return;
          
          int currentIndex = conversations.indexWhere((c) => c.id == state.selectedConversationId);
          int nextIndex = currentIndex + delta;
          if (nextIndex < 0) nextIndex = 0;
          if (nextIndex >= conversations.length) nextIndex = conversations.length - 1;
          
          state = state.copyWith(selectedConversationId: conversations[nextIndex].id);
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
        int conceptualIndex = state.isAssistantActive ? 0 : (pIndex != null ? pIndex + 1 : -1);
        
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
             clearSubtask: true
           );
        }
    } 
    else if (state.focusedColumnIndex == 1) { // Task Column
       if (pIndex == null) return;
       var tasks = projects[pIndex].tasks;
       
       int newIndex = (tIndex ?? -1) + delta;
       if (newIndex < 0) newIndex = 0;
       if (newIndex >= tasks.length) newIndex = tasks.length - 1;
       
       if (tasks.isNotEmpty) {
         state = state.copyWith(
           selectedTaskId: tasks[newIndex].id,
           clearSubtask: true
         );
       }
    }
    else if (state.focusedColumnIndex == 2) { // Subtask Column
      if (pIndex == null || tIndex == null) return;
      var subtasks = projects[pIndex].tasks[tIndex].subtasks;
      
      int newIndex = (sIndex ?? -1) + delta;
      if (newIndex < 0) newIndex = 0;
      if (newIndex >= subtasks.length) newIndex = subtasks.length - 1;

      if (subtasks.isNotEmpty) {
        state = state.copyWith(selectedSubtaskId: subtasks[newIndex].id);
      }
    }
  }

  void changeColumn(int delta) {
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
    var (pIndex, tIndex, sIndex) = _getSelectionIndices(projects);
    
    // Auto-create/Auto-select logic when moving right
    int nextColumn = state.focusedColumnIndex + delta;
    
    if (nextColumn == 1 && state.selectedProjectId == null) return;
    if (nextColumn == 2 && state.selectedTaskId == null) return;

    if (nextColumn >= 0 && nextColumn <= 2) {
       // Logic to auto-select first item if moving into a column
       if (nextColumn == 1 && pIndex != null) {
          if (projects[pIndex].tasks.isNotEmpty && state.selectedTaskId == null) {
             state = state.copyWith(selectedTaskId: projects[pIndex].tasks.first.id, focusedColumnIndex: nextColumn);
             return;
          }
       } else if (nextColumn == 2 && pIndex != null && tIndex != null) {
          if (projects[pIndex].tasks[tIndex].subtasks.isNotEmpty && state.selectedSubtaskId == null) {
             state = state.copyWith(selectedSubtaskId: projects[pIndex].tasks[tIndex].subtasks.first.id, focusedColumnIndex: nextColumn);
             return;
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
      tIndex = projects[pIndex].tasks.indexWhere((t) => t.id == state.selectedTaskId);
      if (tIndex == -1) tIndex = null;
    }

    int? sIndex;
    if (pIndex != null && tIndex != null) {
      sIndex = projects[pIndex].tasks[tIndex].subtasks.indexWhere((s) => s.id == state.selectedSubtaskId);
      if (sIndex == -1) sIndex = null;
    }
    return (pIndex, tIndex, sIndex);
  }

  void _cleanupEmptyItems(DataService dataService) {
    // Prevent modification if we are currently editing an item (though usually this runs on navigation)
    // But if we navigate AWAY while editing, we probably want to keep it if it has content, or delete if empty.
    
    final projects = dataService.projects;
    for (var p in List.of(projects)) {
       // Clean tasks
       for (var t in List.of(p.tasks)) {
         // Clean subtasks
         for (var s in List.of(t.subtasks)) {
           if (s.title.isEmpty && s.id != state.selectedSubtaskId && s.id != state.editingItemId) {
             dataService.deleteItem(s.id);
           }
         }
         
         if (t.title.isEmpty && t.subtasks.isEmpty && t.id != state.selectedTaskId && t.id != state.editingItemId) {
            dataService.deleteItem(t.id);
         }
       }
       
       if (p.title.isEmpty && p.tasks.isEmpty && p.id != state.selectedProjectId && p.id != state.editingItemId) {
         dataService.deleteItem(p.id);
       }
    }
  }
}

final selectionProvider = NotifierProvider<SelectionNotifier, SelectionState>(SelectionNotifier.new);
