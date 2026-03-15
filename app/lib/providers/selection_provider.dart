import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/node.dart';
import '../services/node_service.dart';
import 'data_provider.dart';
import 'filtered_data_providers.dart';

class SelectionState {
  final List<String> selectionPath;
  final int windowOffset;
  final int focusedColumnIndex;
  final String? selectedConversationId;
  final String? selectedTag;
  final TaggedItem? selectedTaggedItem;
  final bool isAssistantActive;
  final String? editingItemId;

  SelectionState({
    this.selectionPath = const [],
    this.windowOffset = 0,
    this.focusedColumnIndex = 0,
    this.selectedConversationId,
    this.selectedTag,
    this.selectedTaggedItem,
    this.isAssistantActive = false,
    this.editingItemId,
  });

  /// Node ID selected in a specific visible column.
  String? selectedNodeIdAtColumn(int col) {
    final idx = windowOffset + col;
    return idx < selectionPath.length ? selectionPath[idx] : null;
  }

  /// Compatibility getter for legacy tests
  String? get selectedProjectId => selectionPath.isNotEmpty ? selectionPath[0] : null;

  /// Compatibility getter for legacy tests
  String? get selectedTaskId => selectionPath.length > 1 ? selectionPath[1] : null;

  /// Compatibility getter for legacy tests
  String? get selectedSubtaskId => selectionPath.length > 2 ? selectionPath[2] : null;

  /// Parent ID whose children are shown in a specific column.
  /// Returns null for root-level items.
  String? parentIdForColumn(int col) {
    final idx = windowOffset + col - 1;
    if (idx < 0) return null;
    return idx < selectionPath.length ? selectionPath[idx] : null;
  }

  SelectionState copyWith({
    List<String>? selectionPath,
    int? windowOffset,
    int? focusedColumnIndex,
    String? selectedConversationId,
    String? selectedTag,
    TaggedItem? selectedTaggedItem,
    bool? isAssistantActive,
    String? editingItemId,
    bool clearConversation = false,
    bool clearTag = false,
    bool clearTaggedItem = false,
    bool clearEditing = false,
  }) {
    return SelectionState(
      selectionPath: selectionPath ?? this.selectionPath,
      windowOffset: windowOffset ?? this.windowOffset,
      focusedColumnIndex: focusedColumnIndex ?? this.focusedColumnIndex,
      selectedConversationId: clearConversation
          ? null
          : (selectedConversationId ?? this.selectedConversationId),
      selectedTag: clearTag ? null : (selectedTag ?? this.selectedTag),
      selectedTaggedItem: clearTaggedItem
          ? null
          : (selectedTaggedItem ?? this.selectedTaggedItem),
      isAssistantActive: isAssistantActive ?? this.isAssistantActive,
      editingItemId:
          clearEditing ? null : (editingItemId ?? this.editingItemId),
    );
  }
}

class SelectionNotifier extends Notifier<SelectionState> {
  @override
  SelectionState build() => SelectionState();

  // ─── General Node Selection ───

  /// Select a node in a visible column. Truncates deeper selections.
  void selectNodeInColumn(int col, String? nodeId) {
    final depth = state.windowOffset + col;
    List<String> newPath;
    if (nodeId != null) {
      newPath = [...state.selectionPath.take(depth), nodeId];
    } else {
      newPath = state.selectionPath.take(depth).toList();
    }
    state = state.copyWith(
      selectionPath: newPath,
      focusedColumnIndex: col,
    );
  }

  /// Select a specific root node by ID.
  void selectRootNode(String? nodeId) {
    state = state.copyWith(
      selectionPath: nodeId != null ? [nodeId] : [],
      windowOffset: 0,
      focusedColumnIndex: 0,
      isAssistantActive: false,
      clearTag: true,
      clearTaggedItem: true,
    );
  }

  /// Compatibility alias for legacy tests
  void selectProject(String? nodeId) => selectRootNode(nodeId);

  /// Compatibility alias for legacy tests
  void selectTask(String? nodeId) => selectNodeInColumn(1, nodeId);

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
        selectionPath: [],
        windowOffset: 0,
        clearTag: true,
        focusedColumnIndex: 1,
        selectedConversationId: convId,
      );
    } else {
      state = state.copyWith(isAssistantActive: false);
    }
  }

  void setEditingItem(String? itemId) {
    state =
        state.copyWith(editingItemId: itemId, clearEditing: itemId == null);
  }

  void selectTag(String tag) {
    state = state.copyWith(
      selectedTag: tag,
      isAssistantActive: false,
      selectionPath: [],
      windowOffset: 0,
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

  // ─── Navigation ───

  void moveSelection(int delta) {
    final nodeService = ref.read(nodeServiceProvider);

    // AI Mode
    if (state.isAssistantActive) {
      if (state.focusedColumnIndex == 0 && delta > 0) {
        setAssistantActive(false);
        final roots = nodeService.rootNodes;
        if (roots.isNotEmpty) {
          state = state.copyWith(
            selectionPath: [roots.first.id],
            focusedColumnIndex: 0,
          );
        }
        return;
      }
      if (state.focusedColumnIndex == 1) {
        final data = ref.read(dataServiceProvider);
        final conversations = data.conversations;
        if (conversations.isEmpty) return;
        int currentIndex = conversations
            .indexWhere((c) => c.id == state.selectedConversationId);
        int nextIndex = (currentIndex + delta)
            .clamp(0, conversations.length - 1);
        state = state.copyWith(
            selectedConversationId: conversations[nextIndex].id);
      }
      return;
    }

    _cleanupEmptyItems();

    if (state.editingItemId != null) {
      state = state.copyWith(clearEditing: true);
    }

    // Root level column 0 has special AI header at index 0
    if (state.focusedColumnIndex == 0 && state.windowOffset == 0) {
      final roots = _getFilteredChildren(null);

      final selectedId = state.selectedNodeIdAtColumn(0);
      int conceptualIndex = selectedId != null
          ? roots.indexWhere((n) => n.id == selectedId) + 1
          : -1;

      int nextIndex = (conceptualIndex + delta).clamp(0, roots.length);

      if (nextIndex == 0) {
        setAssistantActive(true);
      } else {
        state = state.copyWith(
          selectionPath: [roots[nextIndex - 1].id],
          windowOffset: 0,
        );
      }
    } else {
      // General navigation among siblings
      final parentId = state.parentIdForColumn(state.focusedColumnIndex);
      final children = _getFilteredChildren(parentId);
      if (children.isEmpty) return;

      final currentId =
          state.selectedNodeIdAtColumn(state.focusedColumnIndex);
      int currentIndex =
          currentId != null ? children.indexWhere((n) => n.id == currentId) : -1;

      int newIndex =
          (currentIndex + delta).clamp(0, children.length - 1);

      selectNodeInColumn(state.focusedColumnIndex, children[newIndex].id);
    }
  }

  Future<void> changeColumn(int delta) async {
    // AI Mode
    if (state.isAssistantActive) {
      int next = (state.focusedColumnIndex + delta).clamp(0, 2);
      if (next == 2 && state.selectedConversationId == null) return;
      state = state.copyWith(focusedColumnIndex: next);
      return;
    }

    _cleanupEmptyItems();
    final nodeService = ref.read(nodeServiceProvider);

    if (delta > 0) {
      if (state.focusedColumnIndex < 2) {
        // Moving right within visible window
        final nextCol = state.focusedColumnIndex + 1;
        final parentId =
            state.selectedNodeIdAtColumn(state.focusedColumnIndex);
        if (parentId == null) return;

        final children = _getFilteredChildren(parentId);
        if (children.isEmpty) {
          // Auto-create child
          final newId = await nodeService.addChild(parentId, "");
          if (newId != null) {
            selectNodeInColumn(nextCol, newId);
            setEditingItem(newId);
          }
        } else {
          final currentId = state.selectedNodeIdAtColumn(nextCol);
          final targetId = currentId ?? children.first.id;
          selectNodeInColumn(nextCol, targetId);
        }
      } else {
        // Column 2 → slide window deeper
        final currentId = state.selectedNodeIdAtColumn(2);
        if (currentId == null) return;

        final children = _getFilteredChildren(currentId);
        if (children.isEmpty) {
          final newId = await nodeService.addChild(currentId, "");
          if (newId != null) {
            state = state.copyWith(
              selectionPath: [...state.selectionPath, newId],
              windowOffset: state.windowOffset + 1,
              editingItemId: newId,
            );
          }
        } else {
          state = state.copyWith(
            selectionPath: [...state.selectionPath, children.first.id],
            windowOffset: state.windowOffset + 1,
          );
        }
      }
    } else if (delta < 0) {
      if (state.focusedColumnIndex > 0) {
        state = state.copyWith(
            focusedColumnIndex: state.focusedColumnIndex - 1);
      } else if (state.windowOffset > 0) {
        state = state.copyWith(windowOffset: state.windowOffset - 1);
      }
    }
  }

  // ─── Helpers ───

  List<Node> _getFilteredChildren(String? parentId) {
    final nodeService = ref.read(nodeServiceProvider);
    final filter = ref.read(taskFilterProvider);
    final children = nodeService.getChildren(parentId);
    final showCompleted =
        parentId == null ? filter.showCompletedProjects : filter.showCompletedTasks;
    if (showCompleted) return children;
    return children.where((n) => !n.isCompleted).toList();
  }

  void _cleanupEmptyItems() {
    final nodeService = ref.read(nodeServiceProvider);
    _cleanupChildren(nodeService, null);
  }

  void _cleanupChildren(NodeService nodeService, String? parentId) {
    for (final child in List.of(nodeService.getChildren(parentId))) {
      _cleanupChildren(nodeService, child.id);
      final updatedChildren = nodeService.getChildren(child.id);
      if (child.title.trim().isEmpty &&
          updatedChildren.isEmpty &&
          child.id != state.editingItemId) {
        nodeService.deleteNode(child.id);
        _removeFromPath(child.id);
      }
    }
  }

  void _removeFromPath(String id) {
    final idx = state.selectionPath.indexOf(id);
    if (idx != -1) {
      state =
          state.copyWith(selectionPath: state.selectionPath.sublist(0, idx));
    }
  }
}

final selectionProvider = NotifierProvider<SelectionNotifier, SelectionState>(
  SelectionNotifier.new,
);
