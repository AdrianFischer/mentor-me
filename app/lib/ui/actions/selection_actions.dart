import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/selection_provider.dart';
import '../../providers/data_provider.dart';
import '../../models/models.dart';

// --- Intents ---

class MoveSelectionIntent extends Intent {
  final int delta;
  const MoveSelectionIntent(this.delta);
}

class ChangeColumnIntent extends Intent {
  final int delta;
  const ChangeColumnIntent(this.delta);
}

class ToggleCompletionIntent extends Intent {
  const ToggleCompletionIntent();
}

class StartEditIntent extends Intent {
  const StartEditIntent();
}

class StopEditIntent extends Intent {
  const StopEditIntent();
}

class AddNewItemIntent extends Intent {
  const AddNewItemIntent();
}

class DeleteItemIntent extends Intent {
  const DeleteItemIntent();
}

// --- Actions ---

class SelectionAction extends Action<MoveSelectionIntent> {
  final WidgetRef ref;
  SelectionAction(this.ref);

  @override
  void invoke(MoveSelectionIntent intent) {
    print("[DEBUG] SelectionAction invoked with delta ${intent.delta}");
    ref.read(selectionProvider.notifier).moveSelection(intent.delta);
  }
}

class ColumnAction extends Action<ChangeColumnIntent> {
  final WidgetRef ref;
  ColumnAction(this.ref);

  @override
  void invoke(ChangeColumnIntent intent) {
    ref.read(selectionProvider.notifier).changeColumn(intent.delta);
  }
}

class ToggleCompletionAction extends Action<ToggleCompletionIntent> {
  final WidgetRef ref;
  ToggleCompletionAction(this.ref);

  @override
  void invoke(ToggleCompletionIntent intent) {
    final selectionState = ref.read(selectionProvider);
    final dataService = ref.read(dataServiceProvider);
    
    if (selectionState.isAssistantActive) return;

    // 1. Check Subtask Toggle
    if (selectionState.focusedColumnIndex == 2 && selectionState.selectedSubtaskId != null) {
       _toggleById(dataService, selectionState.selectedSubtaskId!);
       return;
    } 
    
    // 2. Check Task Toggle
    bool isTaskTarget = (selectionState.focusedColumnIndex == 1 && selectionState.selectedTaskId != null) || 
                        (selectionState.focusedColumnIndex == 2 && selectionState.selectedTaskId != null && selectionState.selectedSubtaskId == null);

    if (isTaskTarget && selectionState.selectedTaskId != null) {
       _toggleById(dataService, selectionState.selectedTaskId!);
    }
  }

  void _toggleById(dynamic dataService, String id) {
     // We need to find the item to know its current state.
     // Since DataService doesn't expose "getItem(id)", we have to iterate or change DataService.
     // Iterating...
     for(final p in dataService.projects) {
       for(final t in p.tasks) {
         if (t.id == id) {
           dataService.setItemStatus(id, !t.isCompleted);
           return;
         }
         for(final s in t.subtasks) {
           if (s.id == id) {
             dataService.setItemStatus(id, !s.isCompleted);
             return;
           }
         }
       }
     }
  }
}

class StartEditAction extends Action<StartEditIntent> {
  final WidgetRef ref;
  StartEditAction(this.ref);

  @override
  void invoke(StartEditIntent intent) {
    final state = ref.read(selectionProvider);
    String? idToEdit;
    
    if (state.isAssistantActive) {
       if (state.focusedColumnIndex == 1) idToEdit = state.selectedConversationId;
    } else {
      if (state.focusedColumnIndex == 0) idToEdit = state.selectedProjectId;
      else if (state.focusedColumnIndex == 1) idToEdit = state.selectedTaskId;
      else if (state.focusedColumnIndex == 2) idToEdit = state.selectedSubtaskId;
    }

    if (idToEdit != null) {
      ref.read(selectionProvider.notifier).setEditingItem(idToEdit);
    }
  }
}

class StopEditAction extends Action<StopEditIntent> {
  final WidgetRef ref;
  StopEditAction(this.ref);

  @override
  void invoke(StopEditIntent intent) {
    ref.read(selectionProvider.notifier).setEditingItem(null);
  }
}

class AddNewItemAction extends Action<AddNewItemIntent> {
  final WidgetRef ref;
  AddNewItemAction(this.ref);

  @override
  Future<void> invoke(AddNewItemIntent intent) async {
    final selectionState = ref.read(selectionProvider);
    final dataService = ref.read(dataServiceProvider);
    
    // AI Mode: Add Conversation
    if (selectionState.isAssistantActive && selectionState.focusedColumnIndex == 1) {
       final newId = dataService.createConversation("New Chat");
       ref.read(selectionProvider.notifier).selectConversation(newId);
       return;
    }

    // Task Mode
    final projects = dataService.projects;
    // ... Cleanup empty logic would be good here too, but maybe separate concern ...

    if (selectionState.focusedColumnIndex == 0) {
      String newId = await dataService.addProject("");
      ref.read(selectionProvider.notifier).selectProject(newId);
      ref.read(selectionProvider.notifier).setEditingItem(newId);
    } else if (selectionState.focusedColumnIndex == 1) {
      if (selectionState.selectedProjectId != null) {
         String? newId = await dataService.addTask(selectionState.selectedProjectId!, "");
         if (newId != null) {
           ref.read(selectionProvider.notifier).selectTask(newId);
           ref.read(selectionProvider.notifier).setEditingItem(newId);
         }
      }
    } else if (selectionState.focusedColumnIndex == 2) {
      if (selectionState.selectedTaskId != null) {
         String? newId = await dataService.addSubtask(selectionState.selectedTaskId!, "");
         if (newId != null) {
           ref.read(selectionProvider.notifier).selectSubtask(newId);
           ref.read(selectionProvider.notifier).setEditingItem(newId);
         }
      }
    }
  }
}

class DeleteItemAction extends Action<DeleteItemIntent> {
  final WidgetRef ref;
  DeleteItemAction(this.ref);

  @override
  void invoke(DeleteItemIntent intent) {
     final state = ref.read(selectionProvider);
     final dataService = ref.read(dataServiceProvider);
     
     // Conversation
     if (state.isAssistantActive && state.focusedColumnIndex == 1 && state.selectedConversationId != null) {
        final id = state.selectedConversationId!;
        dataService.deleteConversation(id);
        ref.read(selectionProvider.notifier).selectConversation(null); // Or select next?
        return;
     }

     if (state.isAssistantActive) return;

     // Logic to delete and select next
     if (state.focusedColumnIndex == 0 && state.selectedProjectId != null) {
       _deleteAndSelectNext(ref, dataService, dataService.projects, state.selectedProjectId!, (id) => ref.read(selectionProvider.notifier).selectProject(id));
     } else if (state.focusedColumnIndex == 1 && state.selectedTaskId != null) {
       // Need to find tasks list
       final p = dataService.projects.firstWhere((p) => p.id == state.selectedProjectId);
       _deleteAndSelectNext(ref, dataService, p.tasks, state.selectedTaskId!, (id) => ref.read(selectionProvider.notifier).selectTask(id));
     } else if (state.focusedColumnIndex == 2 && state.selectedSubtaskId != null) {
        final p = dataService.projects.firstWhere((p) => p.id == state.selectedProjectId);
        final t = p.tasks.firstWhere((t) => t.id == state.selectedTaskId);
        _deleteAndSelectNext(ref, dataService, t.subtasks, state.selectedSubtaskId!, (id) => ref.read(selectionProvider.notifier).selectSubtask(id));
     }
  }

  void _deleteAndSelectNext(WidgetRef ref, dynamic dataService, List<dynamic> items, String currentId, Function(String?) onSelect) {
     final index = items.indexWhere((i) => i.id == currentId);
     if (index == -1) return;

     String? nextId;
     if (index > 0) nextId = items[index - 1].id;
     else if (items.length > 1) nextId = items[1].id;

     // Capture current focus column before selection changes it (if selectX forces jump)
     final currentFocus = ref.read(selectionProvider).focusedColumnIndex;

     dataService.deleteItem(currentId);
     onSelect(nextId);
     
     // Ensure we stay on the list column after deletion, instead of jumping to details/chat
     if (nextId != null) {
       ref.read(selectionProvider.notifier).setFocusedColumn(currentFocus);
     }
  }
}
