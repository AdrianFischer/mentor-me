import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../editable_column.dart';
import '../editable_item_widget.dart';
import '../../actions/selection_actions.dart';
import '../../../providers/data_provider.dart';
import '../../../providers/selection_provider.dart';
import '../../../providers/filtered_data_providers.dart';
import '../../../models/models.dart';

class SubtaskColumn extends ConsumerWidget {
  final String projectId;
  final String taskId;
  final VoidCallback? onBack;

  const SubtaskColumn({
    super.key, 
    required this.projectId, 
    required this.taskId, 
    this.onBack
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectionState = ref.watch(selectionProvider);
    final visibleSubtasks = ref.watch(filteredSubtasksProvider(taskId));
    final showCompleted = ref.watch(taskFilterProvider.select((s) => s.showCompletedSubtasks));
    final dataService = ref.watch(dataServiceProvider);

    // Resolve selection index
    int? filteredIndex;
    if (selectionState.selectedSubtaskId != null) {
      filteredIndex = visibleSubtasks.indexWhere((s) => s.id == selectionState.selectedSubtaskId);
      if (filteredIndex == -1) filteredIndex = null;
    }

    return EditableColumn(
      key: ValueKey('subtasks_${projectId}_$taskId'),
      title: 'Subtasks',
      backgroundColor: const Color(0xFFFAFAFA),
      selectedIndex: filteredIndex,
      isActiveColumn: selectionState.focusedColumnIndex == 2,
      showCompleted: showCompleted,
      onToggleShowCompleted: () => ref.read(taskFilterProvider.notifier).toggleSubtasks(),
      items: visibleSubtasks.map((s) => EditableItem(
        id: s.id, 
        text: s.title, 
        isCompleted: s.isCompleted, 
        notes: s.notes,
        aiStatus: s.aiStatus,
        localImagePaths: s.localImagePaths,
      )).toList(),
      editingItemId: selectionState.editingItemId,
      onNotesUpdate: (index, val) {
        dataService.updateNotes(visibleSubtasks[index].id, val);
      },
      onExitEdit: () => Actions.invoke(context, const StopEditIntent()),
      onCheckChanged: (index, isChecked) {
        dataService.setItemStatus(visibleSubtasks[index].id, isChecked);
      },
      onAiStatusChanged: (index) {
        final subtask = visibleSubtasks[index];
        dataService.setAiStatus(subtask.id, subtask.aiStatus.nextStatus);
      },
      onItemSelected: (index) {
        ref.read(selectionProvider.notifier).selectSubtask(visibleSubtasks[index].id);
      },
      onAdd: (val) async {
        Actions.invoke(context, const AddNewItemIntent());
      },
      onUpdate: (index, val) {
        dataService.updateTitle(visibleSubtasks[index].id, val);
      },
      onDelete: (index) {
        Actions.invoke(context, const DeleteItemIntent());
      },
      onReorder: (oldIndex, newIndex) {
        dataService.reorderSubtasks(taskId, oldIndex, newIndex);
      },
      onBack: onBack,
      onNavigateLeft: () => Actions.invoke(context, const ChangeColumnIntent(-1)),
      onColumnTap: () => ref.read(selectionProvider.notifier).setFocusedColumn(2),
    );
  }
}
