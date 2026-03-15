import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../editable_column.dart';
import '../editable_item_widget.dart';
import '../../actions/selection_actions.dart';
import '../../../providers/data_provider.dart';
import '../../../providers/node_provider.dart';
import '../../../providers/selection_provider.dart';
import '../../../providers/filtered_data_providers.dart';
import '../../../models/models.dart';

class NodeColumn extends ConsumerWidget {
  final int columnIndex;
  final VoidCallback? onBack;

  const NodeColumn({super.key, required this.columnIndex, this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectionState = ref.watch(selectionProvider);
    final nodeService = ref.watch(nodeServiceProvider);

    // Parent ID for this column's items
    final parentId = selectionState.parentIdForColumn(columnIndex);

    // If this column needs a parent selection but none exists, show placeholder
    if (columnIndex > 0 && parentId == null) {
      return Container(
        color: columnIndex == 2 ? const Color(0xFFFAFAFA) : Colors.white,
        child: const Center(child: Text("Select an item")),
      );
    }

    // Get filtered children
    final children = ref.watch(filteredChildrenProvider(parentId));

    // Resolve selected index
    final selectedNodeId = selectionState.selectedNodeIdAtColumn(columnIndex);
    int? selectedIndex;
    if (selectedNodeId != null) {
      selectedIndex = children.indexWhere((n) => n.id == selectedNodeId);
      if (selectedIndex == -1) selectedIndex = null;
    }

    // Description header from parent's notes
    Widget? descriptionHeader;
    if (parentId != null) {
      final parentNode = nodeService.findNode(parentId);
      if (parentNode != null &&
          parentNode.notes != null &&
          parentNode.notes!.trim().isNotEmpty) {
        descriptionHeader = _buildDescriptionHeader(parentNode.notes!);
      }
    }

    // Special header for root-level column 0 (AI Assistant + Tags)
    Widget? header;
    if (columnIndex == 0 && selectionState.windowOffset == 0) {
      header = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AiAssistantHeader(),
          _TagsList(),
          if (descriptionHeader != null) descriptionHeader,
        ],
      );
    } else {
      header = descriptionHeader;
    }

    // Show completed toggle
    final filter = ref.watch(taskFilterProvider);
    final showCompleted =
        parentId == null ? filter.showCompletedProjects : filter.showCompletedTasks;

    // Column title
    String title;
    if (columnIndex == 0 && selectionState.windowOffset == 0) {
      title = 'Projects';
    } else if (parentId != null) {
      final parent = nodeService.findNode(parentId);
      title = parent?.title ?? 'Items';
    } else {
      title = 'Items';
    }

    return EditableColumn(
      key: ValueKey('node_${columnIndex}_${parentId ?? "root"}'),
      title: title,
      backgroundColor: _bgColor(),
      selectedIndex:
          (selectionState.isAssistantActive && columnIndex == 0)
              ? null
              : selectedIndex,
      isActiveColumn: selectionState.focusedColumnIndex == columnIndex,
      showCompleted: showCompleted,
      onToggleShowCompleted: () => _toggleCompleted(ref, parentId),
      header: header,
      items: children
          .map((n) => EditableItem(
                id: n.id,
                text: n.title,
                isCompleted: n.isCompleted,
                notes: n.notes,
                goal: n.goalMetadata,
                aiStatus: n.aiStatus,
                localImagePaths: n.localImagePaths,
              ))
          .toList(),
      editingItemId: selectionState.editingItemId,
      showNotesInline: columnIndex == 2,
      onNotesUpdate: (index, val) =>
          nodeService.updateNotes(children[index].id, val),
      onExitEdit: () => Actions.invoke(context, const StopEditIntent()),
      onCheckChanged: (index, isChecked) =>
          nodeService.setNodeStatus(children[index].id, isChecked),
      onAiStatusChanged: (index) {
        final node = children[index];
        nodeService.setAiStatus(node.id, node.aiStatus.nextStatus);
      },
      onItemSelected: (index) {
        ref
            .read(selectionProvider.notifier)
            .selectNodeInColumn(columnIndex, children[index].id);
      },
      onAdd: (_) async =>
          Actions.invoke(context, const AddNewItemIntent()),
      onUpdate: (index, val) =>
          nodeService.updateTitle(children[index].id, val),
      onDelete: (_) =>
          Actions.invoke(context, const DeleteItemIntent()),
      onReorder: (oldIndex, newIndex) {
        nodeService.reorderChildren(parentId, oldIndex, newIndex);
      },
      onBack: onBack,
      onNavigateLeft: columnIndex > 0 || selectionState.windowOffset > 0
          ? () => Actions.invoke(context, const ChangeColumnIntent(-1))
          : null,
      onNavigateRight: () =>
          Actions.invoke(context, const ChangeColumnIntent(1)),
      onColumnTap: () =>
          ref.read(selectionProvider.notifier).setFocusedColumn(columnIndex),
    );
  }

  Color _bgColor() {
    switch (columnIndex) {
      case 0:
        return const Color(0xFFF5F5F7);
      case 2:
        return const Color(0xFFFAFAFA);
      default:
        return Colors.white;
    }
  }

  void _toggleCompleted(WidgetRef ref, String? parentId) {
    if (parentId == null) {
      ref.read(taskFilterProvider.notifier).toggleProjects();
    } else {
      ref.read(taskFilterProvider.notifier).toggleTasks();
    }
  }

  static Widget _buildDescriptionHeader(String notes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'DESCRIPTION',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: MarkdownBody(
                data: notes,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                      fontSize: 13, color: Colors.black87, height: 1.4),
                  h1: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                  h2: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                  h3: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                  code: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      backgroundColor: Color(0xFFF5F5F5)),
                  codeblockDecoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  listBullet: const TextStyle(
                      fontSize: 13, color: Colors.black87),
                  strong: const TextStyle(fontWeight: FontWeight.bold),
                  em: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Special widgets ───

class _AiAssistantHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectionState = ref.watch(selectionProvider);

    return GestureDetector(
      key: const ValueKey('ai_assistant_header'),
      onTap: () =>
          ref.read(selectionProvider.notifier).setAssistantActive(true),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: selectionState.isAssistantActive
              ? Colors.white
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selectionState.isAssistantActive
              ? [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: const Row(children: [
          Icon(Icons.auto_awesome, size: 16, color: Colors.purple),
          SizedBox(width: 8),
          Text("AI Assistant",
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple)),
        ]),
      ),
    );
  }
}

class _TagsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodeService = ref.watch(nodeServiceProvider);
    final state = ref.watch(selectionProvider);
    final tags = nodeService.allTags;
    if (tags.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 4, left: 4),
            child: Text(
              "TAGS",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...tags.map((tag) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: InkWell(
                  onTap: () =>
                      ref.read(selectionProvider.notifier).selectTag(tag),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (state.selectedTag == tag)
                          ? Colors.blue.withOpacity(0.2)
                          : Colors.blueGrey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: (state.selectedTag == tag)
                          ? Border.all(color: Colors.blue.withOpacity(0.5))
                          : null,
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 13,
                        color: (state.selectedTag == tag)
                            ? Colors.blue.shade800
                            : Colors.blueGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              )),
          const Divider(height: 24, thickness: 0.5),
        ],
      ),
    );
  }
}
