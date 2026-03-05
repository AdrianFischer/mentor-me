import 'package:collection/collection.dart';
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
  final FocusNode? rootFocusNode;
  StopEditAction(this.ref, {this.rootFocusNode});

  @override
  void invoke(StopEditIntent intent) {
    ref.read(selectionProvider.notifier).setEditingItem(null);
    rootFocusNode?.requestFocus();
  }
}

class AddNewItemAction extends Action<AddNewItemIntent> {
  final WidgetRef ref;
  AddNewItemAction(this.ref);

  @override
  bool isEnabled(AddNewItemIntent intent) {
    final selectionState = ref.read(selectionProvider);
    return selectionState.editingItemId == null;
  }

  @override
  Future<void> invoke(AddNewItemIntent intent) async {
    final selectionState = ref.read(selectionProvider);
    
    // Abort if currently editing an item (prevents Space key from creating new items while typing)
    if (selectionState.editingItemId != null) return;

    final dataService = ref.read(dataServiceProvider);
    
    // AI Mode: Add Conversation
    if (selectionState.isAssistantActive && selectionState.focusedColumnIndex == 1) {
       final newId = dataService.createConversation("New Chat");
       ref.read(selectionProvider.notifier).selectConversation(newId);
       return;
    }

    // Task Mode
    final projects = dataService.projects;

    if (selectionState.focusedColumnIndex == 0 || projects.isEmpty) {
      // Insertion logic for projects
      int targetIndex = projects.length;
      if (selectionState.selectedProjectId != null) {
        final currentIdx = projects.indexWhere((p) => p.id == selectionState.selectedProjectId);
        if (currentIdx != -1) targetIndex = currentIdx + 1;
      }
      
      String newId = await dataService.insertProject("", targetIndex);
      ref.read(selectionProvider.notifier).selectProject(newId);
      ref.read(selectionProvider.notifier).setEditingItem(newId);
    } else if (selectionState.focusedColumnIndex == 1) {
      if (selectionState.selectedProjectId != null) {
         final p = projects.firstWhereOrNull((p) => p.id == selectionState.selectedProjectId);
         if (p == null) {
            // Fallback: create project if selection invalid
            String newId = await dataService.insertProject("", projects.length);
            ref.read(selectionProvider.notifier).selectProject(newId);
            ref.read(selectionProvider.notifier).setEditingItem(newId);
            return;
         }
         int targetIndex = p.tasks.length;
         if (selectionState.selectedTaskId != null) {
            final currentIdx = p.tasks.indexWhere((t) => t.id == selectionState.selectedTaskId);
            if (currentIdx != -1) targetIndex = currentIdx + 1;
         }

         String? newId = await dataService.insertTask(selectionState.selectedProjectId!, "", targetIndex);
         if (newId != null) {
           ref.read(selectionProvider.notifier).selectTask(newId);
           ref.read(selectionProvider.notifier).setEditingItem(newId);
         }
      } else {
         // No project selected, create one
         String newId = await dataService.insertProject("", projects.length);
         ref.read(selectionProvider.notifier).selectProject(newId);
         ref.read(selectionProvider.notifier).setEditingItem(newId);
      }
    } else if (selectionState.focusedColumnIndex == 2) {
      if (selectionState.selectedTaskId != null) {
         final p = projects.firstWhereOrNull((p) => p.id == selectionState.selectedProjectId);
         final t = p?.tasks.firstWhereOrNull((t) => t.id == selectionState.selectedTaskId);
         
         if (t == null) return;

         int targetIndex = t.subtasks.length;
         if (selectionState.selectedSubtaskId != null) {
            final currentIdx = t.subtasks.indexWhere((s) => s.id == selectionState.selectedSubtaskId);
            if (currentIdx != -1) targetIndex = currentIdx + 1;
         }

         String? newId = await dataService.insertSubtask(selectionState.selectedTaskId!, "", targetIndex);
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
  bool isEnabled(DeleteItemIntent intent) {
    final selectionState = ref.read(selectionProvider);
    return selectionState.editingItemId == null;
  }

  @override
  void invoke(DeleteItemIntent intent) {
     final state = ref.read(selectionProvider);
     final dataService = ref.read(dataServiceProvider);
     
     // Conversation
     if (state.isAssistantActive && state.focusedColumnIndex == 1 && state.selectedConversationId != null) {
        final id = state.selectedConversationId!;
        dataService.deleteConversation(id);
        ref.read(selectionProvider.notifier).selectConversation(null); 
        return;
     }

     if (state.isAssistantActive) return;

     if (state.focusedColumnIndex == 0 && state.selectedProjectId != null) {
       _deleteAndSelectNext(ref, dataService, dataService.projects, state.selectedProjectId!, (id) => ref.read(selectionProvider.notifier).selectProject(id));
     } else if (state.focusedColumnIndex == 1 && state.selectedTaskId != null) {
       final p = dataService.projects.firstWhereOrNull((p) => p.id == state.selectedProjectId);
       if (p != null) {
         _deleteAndSelectNext(ref, dataService, p.tasks, state.selectedTaskId!, (id) => ref.read(selectionProvider.notifier).selectTask(id));
       }
     } else if (state.focusedColumnIndex == 2 && state.selectedSubtaskId != null) {
        final p = dataService.projects.firstWhereOrNull((p) => p.id == state.selectedProjectId);
        final t = p?.tasks.firstWhereOrNull((t) => t.id == state.selectedTaskId);
        if (t != null) {
          _deleteAndSelectNext(ref, dataService, t.subtasks, state.selectedSubtaskId!, (id) => ref.read(selectionProvider.notifier).selectSubtask(id));
        }
     }
  }

  void _deleteAndSelectNext(WidgetRef ref, dynamic dataService, List<dynamic> items, String currentId, Function(String?) onSelect) {
     final index = items.indexWhere((i) => i.id == currentId);
     if (index == -1) return;

     String? nextId;
     if (index > 0) nextId = items[index - 1].id;

     final currentFocus = ref.read(selectionProvider).focusedColumnIndex;

     dataService.deleteItem(currentId);
     onSelect(nextId);
     ref.read(selectionProvider.notifier).setFocusedColumn(currentFocus);
  }
}