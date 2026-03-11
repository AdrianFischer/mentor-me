import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../editable_column.dart';
import '../editable_item_widget.dart';
import '../../actions/selection_actions.dart';
import '../../../providers/data_provider.dart';
import '../../../providers/selection_provider.dart';
import '../../../models/models.dart';

class TagResultsColumn extends ConsumerWidget {
  const TagResultsColumn({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataService = ref.watch(dataServiceProvider);
    final state = ref.watch(selectionProvider);
    if (state.selectedTag == null) return const SizedBox.shrink();

    final items = dataService.getItemsWithTag(state.selectedTag!);

    // Convert TaggedItems to EditableItems for display
    final displayItems = items.map((item) {
      String displayText = item.title;
      bool isCompleted = false;

      if (item.type == 'project') {
        displayText = "📦 $displayText";
      } else if (item.type == 'task') {
        displayText = "✅ $displayText";
        isCompleted = (item.originalObject as Task).isCompleted;
      } else if (item.type == 'subtask') {
        displayText = "🔹 $displayText";
        isCompleted = (item.originalObject as Subtask).isCompleted;
      }

      return EditableItem(
        id: item.id,
        text: displayText,
        isCompleted: isCompleted,
      );
    }).toList();

    int? selectedIndex;
    if (state.selectedTaggedItem != null) {
      selectedIndex = items.indexWhere(
        (i) => i.id == state.selectedTaggedItem!.id,
      );
      if (selectedIndex == -1) selectedIndex = null;
    }

    return EditableColumn(
      key: ValueKey('tag_results_${state.selectedTag}'),
      title: state.selectedTag ?? 'Tags',
      backgroundColor: Colors.white,
      selectedIndex: selectedIndex,
      isActiveColumn: state.focusedColumnIndex == 1,
      items: displayItems,
      onItemSelected: (index) {
        ref.read(selectionProvider.notifier).selectTaggedItem(items[index]);
      },
      onCheckChanged: (index, val) {
        dataService.setItemStatus(items[index].id, val);
      },
      onAdd: (_) {},
      onUpdate: (index, val) {
        dataService.updateTitle(items[index].id, val);
      },
      onDelete: (index) {
        dataService.deleteItem(items[index].id);
      },
      onReorder: (_, __) {},
      onNavigateLeft: () =>
          Actions.invoke(context, const ChangeColumnIntent(-1)),
      onNavigateRight: () =>
          Actions.invoke(context, const ChangeColumnIntent(1)),
      onExitEdit: () => Actions.invoke(context, const StopEditIntent()),
    );
  }
}
