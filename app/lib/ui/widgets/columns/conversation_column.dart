import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../editable_column.dart';
import '../editable_item_widget.dart';
import '../../actions/selection_actions.dart';
import '../../../providers/data_provider.dart';
import '../../../providers/selection_provider.dart';

class ConversationColumn extends ConsumerWidget {
  const ConversationColumn({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataService = ref.watch(dataServiceProvider);
    final selectionState = ref.watch(selectionProvider);
    final conversations = dataService.conversations;

    // Resolve selection index
    int? selectedIndex;
    if (selectionState.selectedConversationId != null) {
      selectedIndex = conversations.indexWhere(
        (c) => c.id == selectionState.selectedConversationId,
      );
      if (selectedIndex == -1) selectedIndex = null;
    }

    return EditableColumn(
      key: const ValueKey('conversations'),
      title: 'Conversations',
      backgroundColor: Colors.white,
      selectedIndex: selectedIndex,
      isActiveColumn: selectionState.focusedColumnIndex == 1,
      items: conversations
          .map((c) => EditableItem(id: c.id, text: c.title, notes: c.notes))
          .toList(),
      editingItemId: selectionState.editingItemId,
      onItemSelected: (index) {
        ref
            .read(selectionProvider.notifier)
            .selectConversation(conversations[index].id);
      },
      onAdd: (val) {
        Actions.invoke(context, const AddNewItemIntent());
      },
      onUpdate: (index, val) {
        dataService.updateConversationTitle(conversations[index].id, val);
      },
      onDelete: (index) {
        Actions.invoke(context, const DeleteItemIntent());
      },
      onReorder: (old, newI) {},
      onNavigateLeft: () =>
          Actions.invoke(context, const ChangeColumnIntent(-1)),
      onNavigateRight: () =>
          Actions.invoke(context, const ChangeColumnIntent(1)),
      onExitEdit: () => Actions.invoke(context, const StopEditIntent()),
      onColumnTap: () =>
          ref.read(selectionProvider.notifier).setFocusedColumn(1),
    );
  }
}
