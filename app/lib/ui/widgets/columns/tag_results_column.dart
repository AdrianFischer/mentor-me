import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../editable_column.dart';
import '../editable_item_widget.dart';
import '../../actions/selection_actions.dart';
import '../../../providers/data_provider.dart';
import '../../../providers/selection_provider.dart';

class TagResultsColumn extends ConsumerWidget {
  const TagResultsColumn({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodeService = ref.watch(nodeServiceProvider);
    final state = ref.watch(selectionProvider);
    if (state.selectedTag == null) return const SizedBox.shrink();

    final items = nodeService.getItemsWithTag(state.selectedTag!);

    final displayItems = items.map((item) {
      return EditableItem(
        id: item.id,
        text: item.title,
        isCompleted: item.node.isCompleted,
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
        nodeService.setNodeStatus(items[index].id, val);
      },
      onAdd: (_) {},
      onUpdate: (index, val) {
        nodeService.updateTitle(items[index].id, val);
      },
      onDelete: (index) {
        nodeService.deleteNode(items[index].id);
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
