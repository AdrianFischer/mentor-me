import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../editable_column.dart';
import '../editable_item_widget.dart';
import '../../actions/selection_actions.dart';
import '../../../providers/data_provider.dart';
import '../../../providers/selection_provider.dart';
import '../../../providers/filtered_data_providers.dart';
import '../../../models/models.dart';

class TaskColumn extends ConsumerWidget {
  final String projectId;
  final VoidCallback? onBack;

  const TaskColumn({
    super.key, 
    required this.projectId, 
    this.onBack
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectionState = ref.watch(selectionProvider);
    final visibleTasks = ref.watch(filteredTasksProvider(projectId));
    final showCompleted = ref.watch(taskFilterProvider.select((s) => s.showCompletedTasks));
    final dataService = ref.watch(dataServiceProvider);

    // Resolve selection index
    int? filteredIndex;
    if (selectionState.selectedTaskId != null) {
      filteredIndex = visibleTasks.indexWhere((t) => t.id == selectionState.selectedTaskId);
      if (filteredIndex == -1) filteredIndex = null;
    }

    return EditableColumn(
      key: ValueKey('tasks_$projectId'),
      title: 'Tasks',
      backgroundColor: Colors.white,
      selectedIndex: filteredIndex,
      isActiveColumn: selectionState.focusedColumnIndex == 1,
      showCompleted: showCompleted,
      onToggleShowCompleted: () => ref.read(taskFilterProvider.notifier).toggleTasks(),
      items: visibleTasks.map((t) {
         return EditableItem(
           id: t.id, 
           text: t.title, 
           isCompleted: t.isCompleted, 
           goal: t.goalMetadata, 
           notes: t.notes,
           aiStatus: t.aiStatus,
           localImagePaths: t.localImagePaths,
         );
      }).toList(),
      editingItemId: selectionState.editingItemId,
      onNotesUpdate: (index, val) {
        dataService.updateNotes(visibleTasks[index].id, val);
      },
      onExitEdit: () => Actions.invoke(context, const StopEditIntent()),
      onCheckChanged: (index, isChecked) {
        dataService.setItemStatus(visibleTasks[index].id, isChecked);
      },
      onAiStatusChanged: (index) {
        final task = visibleTasks[index];
        dataService.setAiStatus(task.id, task.aiStatus.nextStatus);
      },
      onItemSelected: (index) {
        ref.read(selectionProvider.notifier).selectTask(visibleTasks[index].id);
      },
      onAdd: (val) async {
        Actions.invoke(context, const AddNewItemIntent());
      },
      onUpdate: (index, val) {
        dataService.updateTitle(visibleTasks[index].id, val);
      },
      onDelete: (index) {
        Actions.invoke(context, const DeleteItemIntent());
      },
      onReorder: (oldIndex, newIndex) {
        final projects = ref.read(filteredProjectsProvider);
        // Map filtered indices back to original indices for reordering
        final oldTaskId = visibleTasks[oldIndex].id;
        final newTaskId = visibleTasks[newIndex].id;
        final project = projects.firstWhere((p) => p.id == projectId);
        final oldOriginalIndex = project.tasks.indexWhere((t) => t.id == oldTaskId);
        final newOriginalIndex = project.tasks.indexWhere((t) => t.id == newTaskId);
        if (oldOriginalIndex != -1 && newOriginalIndex != -1) {
          dataService.reorderTasks(project.id, oldOriginalIndex, newOriginalIndex);
        }
      },
      onBack: onBack,
      onNavigateLeft: () => Actions.invoke(context, const ChangeColumnIntent(-1)),
      onNavigateRight: () => Actions.invoke(context, const ChangeColumnIntent(1)),
      onColumnTap: () => ref.read(selectionProvider.notifier).setFocusedColumn(1),
    );
  }
}
