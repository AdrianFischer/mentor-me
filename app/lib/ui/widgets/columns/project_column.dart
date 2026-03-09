import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../editable_column.dart';
import '../editable_item_widget.dart';
import '../../actions/selection_actions.dart';
import '../../../providers/data_provider.dart';
import '../../../providers/selection_provider.dart';
import '../../../providers/filtered_data_providers.dart';
import '../../../models/models.dart';

class ProjectColumn extends ConsumerWidget {
  final VoidCallback? onBack;
  final bool isMobile;

  const ProjectColumn({
    super.key, 
    this.onBack, 
    this.isMobile = false
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectionState = ref.watch(selectionProvider);
    final projects = ref.watch(filteredProjectsProvider);
    final dataService = ref.watch(dataServiceProvider);
    final showCompleted = ref.watch(taskFilterProvider.select((s) => s.showCompletedProjects));

    // Resolve selection index
    int? pIndex;
    if (selectionState.selectedProjectId != null) {
      pIndex = projects.indexWhere((p) => p.id == selectionState.selectedProjectId);
      if (pIndex == -1) pIndex = null;
    }

    return EditableColumn(
      key: const ValueKey('projects'),
      title: 'Projects',
      backgroundColor: const Color(0xFFF5F5F7),
      selectedIndex: selectionState.isAssistantActive ? null : pIndex,
      isActiveColumn: selectionState.focusedColumnIndex == 0,
      showCompleted: showCompleted,
      onToggleShowCompleted: () => ref.read(taskFilterProvider.notifier).toggleProjects(),
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AiAssistantHeader(),
          _TagsList(),
        ],
      ),
      items: projects.map((p) => EditableItem(id: p.id, text: p.title, notes: p.notes, isCompleted: p.isCompleted)).toList(),
      editingItemId: selectionState.editingItemId,
      onNotesUpdate: (index, val) {
        dataService.updateNotes(projects[index].id, val);
      },
      onExitEdit: () => Actions.invoke(context, const StopEditIntent()),
      onCheckChanged: (index, isChecked) {
        dataService.setItemStatus(projects[index].id, isChecked);
      },
      onItemSelected: (index) {
        ref.read(selectionProvider.notifier).selectProject(projects[index].id);
        if (isMobile) {
           ref.read(selectionProvider.notifier).setFocusedColumn(1);
        }
      },
      onAdd: (val) async {
        Actions.invoke(context, const AddNewItemIntent());
      },
      onUpdate: (index, val) {
        dataService.updateTitle(projects[index].id, val);
      },
      onDelete: (index) {
         Actions.invoke(context, const DeleteItemIntent());
      },
      onReorder: (oldIndex, newIndex) {
        dataService.reorderProjects(oldIndex, newIndex);
      },
      onBack: onBack,
      onNavigateRight: () => Actions.invoke(context, const ChangeColumnIntent(1)),
      onColumnTap: () => ref.read(selectionProvider.notifier).setFocusedColumn(0),
    );
  }
}

class _AiAssistantHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectionState = ref.watch(selectionProvider);
    
    return GestureDetector(
       key: const ValueKey('ai_assistant_header'),
       onTap: () {
          ref.read(selectionProvider.notifier).setAssistantActive(true);
       },
       child: Container(
         padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
         decoration: BoxDecoration(
           color: selectionState.isAssistantActive ? Colors.white : Colors.transparent,
           borderRadius: BorderRadius.circular(10),
           boxShadow: selectionState.isAssistantActive 
              ? [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))] 
              : [],
         ),
         child: Row(
            children: [
               const Icon(Icons.auto_awesome, size: 16, color: Colors.purple),
               const SizedBox(width: 8),
               const Text("AI Assistant", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.purple)),
            ]
         )
       )
    );
  }
}

class _TagsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataService = ref.watch(dataServiceProvider);
    final state = ref.watch(selectionProvider);
    final tags = dataService.allTags;
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
              onTap: () {
                ref.read(selectionProvider.notifier).selectTag(tag);
              },
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (state.selectedTag == tag) 
                      ? Colors.blue.withOpacity(0.2) 
                      : Colors.blueGrey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: (state.selectedTag == tag) 
                      ? Border.all(color: Colors.blue.withOpacity(0.5)) 
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tag,
                      style: TextStyle(
                        fontSize: 13,
                        color: (state.selectedTag == tag) ? Colors.blue.shade800 : Colors.blueGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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
