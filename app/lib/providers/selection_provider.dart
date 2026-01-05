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
  final bool showCompletedTasks;
  final bool showCompletedSubtasks;

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
    this.showCompletedTasks = true,
    this.showCompletedSubtasks = true,
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
    bool? showCompletedTasks,
    bool? showCompletedSubtasks,
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
      showCompletedTasks: showCompletedTasks ?? this.showCompletedTasks,
      showCompletedSubtasks: showCompletedSubtasks ?? this.showCompletedSubtasks,
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
      clearTask: taskId == null,
      clearSubtask: true,
      focusedColumnIndex: 1,
    );
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

  void toggleShowCompletedTasks() {
    state = state.copyWith(showCompletedTasks: !state.showCompletedTasks);
  }

  void toggleShowCompletedSubtasks() {
    state = state.copyWith(showCompletedSubtasks: !state.showCompletedSubtasks);
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
       // Filter tasks based on showCompletedTasks state
       var allTasks = projects[pIndex].tasks;
       var tasks = state.showCompletedTasks 
           ? allTasks 
           : allTasks.where((t) => !t.isCompleted).toList();
       
       if (tasks.isEmpty) return;
       
       // Find current index in filtered list
       int currentFilteredIndex = -1;
       if (tIndex != null && tIndex < allTasks.length) {
         final currentTaskId = allTasks[tIndex].id;
         currentFilteredIndex = tasks.indexWhere((t) => t.id == currentTaskId);
       }
       
       int newIndex = currentFilteredIndex + delta;
       if (newIndex < 0) newIndex = 0;
       if (newIndex >= tasks.length) newIndex = tasks.length - 1;
       
       state = state.copyWith(
         selectedTaskId: tasks[newIndex].id,
         clearSubtask: true
       );
    }
    else if (state.focusedColumnIndex == 2) { // Subtask Column
      if (pIndex == null || tIndex == null) return;
      // Filter subtasks based on showCompletedSubtasks state
      var allSubtasks = projects[pIndex].tasks[tIndex].subtasks;
      var subtasks = state.showCompletedSubtasks 
          ? allSubtasks 
          : allSubtasks.where((s) => !s.isCompleted).toList();
      
      if (subtasks.isEmpty) return;
      
      // Find current index in filtered list
      int currentFilteredIndex = -1;
      if (sIndex != null && sIndex < allSubtasks.length) {
        final currentSubtaskId = allSubtasks[sIndex].id;
        currentFilteredIndex = subtasks.indexWhere((s) => s.id == currentSubtaskId);
      }
      
      int newIndex = currentFilteredIndex + delta;
      if (newIndex < 0) newIndex = 0;
      if (newIndex >= subtasks.length) newIndex = subtasks.length - 1;

      state = state.copyWith(selectedSubtaskId: subtasks[newIndex].id);
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
       // Moving Right Logic
       if (delta > 0) {
          if (nextColumn == 1 && pIndex != null) {
             var tasks = state.showCompletedTasks 
                 ? projects[pIndex].tasks 
                 : projects[pIndex].tasks.where((t) => !t.isCompleted).toList();
             
             if (tasks.isEmpty) {
                // Auto-create task
                dataService.addTask(projects[pIndex].id, "").then((newId) {
                   if (newId != null) {
                      selectTask(newId);
                      setEditingItem(newId);
                   }
                });
                return; // State will be updated by the async calls
             } else {
                // BUG FIX: Even if state.selectedTaskId is already set, we MUST ensure 
                // focusedColumnIndex is updated. If NOT set, we pick first.
                final targetId = state.selectedTaskId ?? tasks.first.id;
                state = state.copyWith(selectedTaskId: targetId, focusedColumnIndex: nextColumn);
                return;
             }
          } else if (nextColumn == 2 && pIndex != null && tIndex != null) {
             var subtasks = state.showCompletedSubtasks 
                 ? projects[pIndex].tasks[tIndex].subtasks 
                 : projects[pIndex].tasks[tIndex].subtasks.where((s) => !s.isCompleted).toList();
             
             if (subtasks.isEmpty) {
                // Auto-create subtask
                dataService.addSubtask(projects[pIndex].tasks[tIndex].id, "").then((newId) {
                   if (newId != null) {
                      selectSubtask(newId);
                      setEditingItem(newId);
                   }
                });
                return;
             } else {
                // BUG FIX: Ensure focusedColumnIndex is updated and subtask is selected.
                final targetId = state.selectedSubtaskId ?? subtasks.first.id;
                state = state.copyWith(selectedSubtaskId: targetId, focusedColumnIndex: nextColumn);
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
    print("[DEBUG] Cleanup Start. Selected: ${state.selectedProjectId}, Editing: ${state.editingItemId}");
    
    final projects = dataService.projects;
    for (var p in List.of(projects)) {
       // ...
       
       if (p.title.isEmpty && p.tasks.isEmpty) {
          print("[DEBUG] Checking Project ${p.id}. Selected? ${p.id == state.selectedProjectId} Editing? ${p.id == state.editingItemId}");
          if (p.id != state.selectedProjectId && p.id != state.editingItemId) {
             print("[DEBUG] Deleting Project ${p.id}");
             dataService.deleteItem(p.id);
          }
       }
    }
  }
}

final selectionProvider = NotifierProvider<SelectionNotifier, SelectionState>(SelectionNotifier.new);
