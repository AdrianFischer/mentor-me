import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../models/ai_models.dart';
import '../providers/data_provider.dart';
import 'widgets/editable_column.dart';
import 'widgets/editable_item_widget.dart';

final knowledgeProvider = FutureProvider.autoDispose<List<Knowledge>>((
  ref,
) async {
  final dataService = ref.watch(dataServiceProvider);
  return dataService.getAllKnowledge();
});

class KnowledgeScreen extends ConsumerStatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  ConsumerState<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends ConsumerState<KnowledgeScreen> {
  int? _selectedIndex;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final knowledgeAsync = ref.watch(knowledgeProvider);

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;

        final knowledgeAsync = ref.watch(knowledgeProvider);
        final items = knowledgeAsync.maybeWhen(
          data: (items) => items,
          orElse: () => <Knowledge>[],
        );

        if (event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.pop(context);
          return KeyEventResult.handled;
        }

        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          setState(
            () => _selectedIndex = min(
              (_selectedIndex ?? -1) + 1,
              items.length - 1,
            ),
          );
          return KeyEventResult.handled;
        }

        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          setState(() => _selectedIndex = max((_selectedIndex ?? 0) - 1, 0));
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: Colors
            .white, // Match EditableColumn background assumption or pass it
        body: SafeArea(
          child: knowledgeAsync.when(
            data: (items) {
              final editableItems = items
                  .map(
                    (k) => EditableItem(
                      id: k.id,
                      text: k.content,
                      isCompleted: false, // Knowledge doesn't have completion
                    ),
                  )
                  .toList();

              return EditableColumn(
                title: 'Knowledge Base',
                backgroundColor: Colors.white,
                items: editableItems,
                isActiveColumn: true,
                selectedIndex: _selectedIndex,
                showDeleteButton: true,
                onBack: () => Navigator.pop(context),
                onAdd: (val) {
                  ref.read(dataServiceProvider).saveKnowledge(val);
                  setState(() {
                    // Select the new item? Ideally we get the ID back.
                    // For now, we just add it.
                  });
                },
                onUpdate: (index, val) {
                  final item = items[index];
                  final newItem = item.copyWith(
                    content: val,
                    updatedAt: DateTime.now(),
                  );
                  ref.read(dataServiceProvider).updateKnowledge(newItem);
                },
                onDelete: (index) {
                  final item = items[index];
                  // Show confirmation or just delete? To-Do deletes immediately usually,
                  // but let's stick to the "Delete" action.
                  // EditableColumn expects int index.
                  ref.read(dataServiceProvider).deleteKnowledge(item.id);
                },
                onItemSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                onCheckChanged: (index, isChecked) {
                  // No-op for knowledge
                },
                onReorder: (oldIndex, newIndex) {
                  // No reorder support in backend for Knowledge yet
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ),
      ),
    );
  }
}
