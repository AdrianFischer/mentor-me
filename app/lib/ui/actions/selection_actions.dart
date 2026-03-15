import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/selection_provider.dart';
import '../../providers/data_provider.dart';

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
  bool isEnabled(ToggleCompletionIntent intent) {
    return ref.read(selectionProvider).editingItemId == null;
  }

  @override
  void invoke(ToggleCompletionIntent intent) {
    final state = ref.read(selectionProvider);
    if (state.isAssistantActive) return;
    if (state.editingItemId != null) return;

    final nodeId = state.selectedNodeIdAtColumn(state.focusedColumnIndex);
    if (nodeId != null) {
      final nodeService = ref.read(nodeServiceProvider);
      final node = nodeService.findNode(nodeId);
      if (node != null) {
        nodeService.setNodeStatus(nodeId, !node.isCompleted);
        return;
      }
    }

    // Fallback to Add
    final addAction = AddNewItemAction(ref);
    if (addAction.isEnabled(const AddNewItemIntent())) {
      addAction.invoke(const AddNewItemIntent());
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
      idToEdit = state.selectedNodeIdAtColumn(state.focusedColumnIndex);
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
    return ref.read(selectionProvider).editingItemId == null;
  }

  @override
  Future<void> invoke(AddNewItemIntent intent) async {
    final selectionState = ref.read(selectionProvider);
    if (selectionState.editingItemId != null) return;

    // AI Mode: Add Conversation
    if (selectionState.isAssistantActive &&
        selectionState.focusedColumnIndex == 1) {
      final dataService = ref.read(dataServiceProvider);
      final newId = dataService.createConversation("New Chat");
      ref.read(selectionProvider.notifier).selectConversation(newId);
      return;
    }

    // Node Mode: add child to the parent of the current column
    final nodeService = ref.read(nodeServiceProvider);
    final parentId =
        selectionState.parentIdForColumn(selectionState.focusedColumnIndex);
    final children = nodeService.getChildren(parentId);

    // Insert after current selection
    int targetIndex = children.length;
    final currentId =
        selectionState.selectedNodeIdAtColumn(selectionState.focusedColumnIndex);
    if (currentId != null) {
      final idx = children.indexWhere((n) => n.id == currentId);
      if (idx != -1) targetIndex = idx + 1;
    }

    final newId = await nodeService.insertChild(parentId, "", targetIndex);
    if (newId != null) {
      ref
          .read(selectionProvider.notifier)
          .selectNodeInColumn(selectionState.focusedColumnIndex, newId);
      ref.read(selectionProvider.notifier).setEditingItem(newId);
    }
  }
}

class DeleteItemAction extends Action<DeleteItemIntent> {
  final WidgetRef ref;
  DeleteItemAction(this.ref);

  @override
  bool isEnabled(DeleteItemIntent intent) => true;

  @override
  void invoke(DeleteItemIntent intent) {
    final state = ref.read(selectionProvider);

    if (state.editingItemId != null) {
      ref.read(selectionProvider.notifier).setEditingItem(null);
    }

    // Conversation
    if (state.isAssistantActive &&
        state.focusedColumnIndex == 1 &&
        state.selectedConversationId != null) {
      final dataService = ref.read(dataServiceProvider);
      dataService.deleteConversation(state.selectedConversationId!);
      ref.read(selectionProvider.notifier).selectConversation(null);
      return;
    }

    if (state.isAssistantActive) return;

    // Node deletion
    final currentId =
        state.selectedNodeIdAtColumn(state.focusedColumnIndex);
    if (currentId == null) return;

    final nodeService = ref.read(nodeServiceProvider);
    final parentId = state.parentIdForColumn(state.focusedColumnIndex);
    final children = nodeService.getChildren(parentId);
    final currentIndex = children.indexWhere((n) => n.id == currentId);

    // Select previous item (or null if first)
    String? nextId;
    if (currentIndex > 0) {
      nextId = children[currentIndex - 1].id;
    }

    final currentFocus = state.focusedColumnIndex;
    nodeService.deleteNode(currentId);
    ref
        .read(selectionProvider.notifier)
        .selectNodeInColumn(currentFocus, nextId);
    ref.read(selectionProvider.notifier).setFocusedColumn(currentFocus);
  }
}
