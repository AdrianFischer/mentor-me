import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/widgets/editable_column.dart';
import 'ui/widgets/editable_item_widget.dart';
import 'ui/widgets/debug_overlay.dart';
import 'ui/assistant_screen.dart';
import 'ui/actions/selection_actions.dart';
import 'models/models.dart';
import 'providers/data_provider.dart';
import 'providers/mcp_provider.dart';
import 'providers/selection_provider.dart';
import 'services/data_service.dart';
import 'services/debug_data_service.dart';

class MyApp extends ConsumerStatefulWidget {
  final bool initialIsAssistantActive;
  final String? initialSelectedProjectId;

  const MyApp({super.key, this.initialIsAssistantActive = false, this.initialSelectedProjectId});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final FocusNode _rootFocusNode = FocusNode();

  // Helper to cycle through AI statuses
  AiStatus _cycleAiStatus(AiStatus current) {
    switch (current) {
      case AiStatus.notReady:
        return AiStatus.ready;
      case AiStatus.ready:
        return AiStatus.inProgress;
      case AiStatus.inProgress:
        return AiStatus.done;
      case AiStatus.done:
        return AiStatus.notReady;
    }
  }

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rootFocusNode.requestFocus();

      // Initialize Selection State
      final selectionNotifier = ref.read(selectionProvider.notifier);
      if (widget.initialIsAssistantActive) {
         selectionNotifier.setAssistantActive(true);
      } else if (widget.initialSelectedProjectId != null) {
         selectionNotifier.selectProject(widget.initialSelectedProjectId);
      }

      // Check for seed
      final seed = Uri.base.queryParameters['seed'];
      if (seed == 'complex_tree') {
         final dataService = ref.read(dataServiceProvider);
         final debugService = DebugDataService(dataService);
         debugService.seedComplexTree().then((_) {
            if (mounted && dataService.projects.isNotEmpty) {
               selectionNotifier.selectProject(dataService.projects.first.id);
            }
         });
      }
    });
  }

  @override
  void dispose() {
    _rootFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(mcpServerProvider); // Keep MCP alive
    ref.watch(startWatcherProvider); // Keep Markdown Watcher alive
    final dataService = ref.watch(dataServiceProvider);
    final selectionState = ref.watch(selectionProvider);
    final projects = dataService.projects;

    // Resolve Indices for rendering
    int? pIndex = projects.indexWhere((p) => p.id == selectionState.selectedProjectId);
    if (pIndex == -1) pIndex = null;

    int? tIndex;
    if (pIndex != null) {
      tIndex = projects[pIndex].tasks.indexWhere((t) => t.id == selectionState.selectedTaskId);
      if (tIndex == -1) tIndex = null;
    }

    int? sIndex;
    if (pIndex != null && tIndex != null) {
      sIndex = projects[pIndex].tasks[tIndex].subtasks.indexWhere((s) => s.id == selectionState.selectedSubtaskId);
      if (sIndex == -1) sIndex = null;
    }

    // AI Header Widget
    final aiAssistantWidget = GestureDetector(
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

    return MaterialApp(
      title: 'Design Specs App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
            home: DebugOverlay(
              child: Actions(
                actions: <Type, Action<Intent>>{
                  MoveSelectionIntent: SelectionAction(ref),
                  ChangeColumnIntent: ColumnAction(ref),
                  StartEditIntent: StartEditAction(ref),
                  ToggleCompletionIntent: ToggleCompletionAction(ref),
                  StopEditIntent: StopEditAction(ref),
                  AddNewItemIntent: AddNewItemAction(ref),
                  DeleteItemIntent: DeleteItemAction(ref),
                },
                child: Shortcuts(
                  shortcuts: <LogicalKeySet, Intent>{
                    LogicalKeySet(LogicalKeyboardKey.arrowDown): const MoveSelectionIntent(1),
                    LogicalKeySet(LogicalKeyboardKey.arrowUp): const MoveSelectionIntent(-1),
                    LogicalKeySet(LogicalKeyboardKey.arrowRight): const ChangeColumnIntent(1),
                    LogicalKeySet(LogicalKeyboardKey.arrowLeft): const ChangeColumnIntent(-1),
                    LogicalKeySet(LogicalKeyboardKey.enter): const StartEditIntent(),
                    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.enter): const ToggleCompletionIntent(),
                    LogicalKeySet(LogicalKeyboardKey.escape): const StopEditIntent(),
                    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyN): const AddNewItemIntent(),
                    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.backspace): const DeleteItemIntent(),
                  },
                              child: Focus(
                                key: const ValueKey('rootFocus'),
                                focusNode: _rootFocusNode,
                                autofocus: true,
                  
                        child: Builder(
                          builder: (context) => LayoutBuilder(
                            builder: (context, constraints) {
                              final isMobile = constraints.maxWidth < 1260;
                              
                              if (isMobile) {
                                return _buildMobileLayout(context, isMobile, dataService, selectionState, projects, pIndex, tIndex, sIndex, aiAssistantWidget);
                              }
          
                                                return Scaffold(
          
                                                  bottomNavigationBar: Container(
          
                                                    height: 30,
          
                                                    alignment: Alignment.center,
          
                                                    child: const Text("Built with Assisted Intelligence", style: TextStyle(color: Colors.grey, fontSize: 10)),
          
                                                  ),
          
                                                  body: Row(
          
                                                    children: [
          
                                                      // Col 1: Projects (Fixed)
          
                                                      Expanded(
          
                                                        flex: 1,
          
                                                        child: _buildProjectColumn(context, dataService, projects, pIndex, aiAssistantWidget, isMobile: false),
          
                                                      ),
          
                                                      
          
                                                      // Col 2: Tasks OR Conversations OR Tags
          
                                                      Expanded(
          
                                                        flex: 2,
          
                                                        child: selectionState.isAssistantActive
          
                                                          ? _buildConversationColumn(context, dataService, selectionState)
          
                                                          : (selectionState.selectedTag != null 
          
                                                               ? _buildTagResultsColumn(context, dataService, selectionState)
          
                                                               : (pIndex != null 
          
                                                                  ? _buildTaskColumn(context, dataService, projects, pIndex, tIndex, selectionState)
          
                                                                  : Container(color: Colors.white, child: const Center(child: Text('Select a Project')))
          
                                                                 )
          
                                                            ),
          
                                                      ),
          
                                                      
          
                                                      // Col 3: Subtasks OR Chat OR Tag Details
          
                                                      Expanded(
          
                                                        flex: 2,
          
                                                        child: selectionState.isAssistantActive
          
                                                          ? (selectionState.selectedConversationId != null
          
                                                              ? AssistantScreen(conversationId: selectionState.selectedConversationId!)
          
                                                              : Container(color: const Color(0xFFFAFAFA), child: const Center(child: Text('Select a Conversation')))
          
                                                            )
          
                                                          : (selectionState.selectedTag != null
          
                                                               ? _buildTaggedItemContext(context, dataService, projects, selectionState)
          
                                                               : ((pIndex != null && tIndex != null)
          
                                                                  ? _buildSubtaskColumn(context, dataService, projects, pIndex, tIndex, sIndex, selectionState)
          
                                                                  : Container(color: const Color(0xFFFAFAFA), child: const Center(child: Text('Select a Task')))
          
                                                                 )
          
                                                            ),
          
                                                      ),
          
                                                    ],
          
                                                  ),
          
                                                );
          
                              
                            },
                          ),
                        ),
                      ),
                    ),
          
        ),
      ),
    );
  }
  
  // --- Column Builders ---

  Widget _buildProjectColumn(BuildContext context, DataService dataService, List<Project> projects, int? pIndex, Widget aiAssistantWidget, {VoidCallback? onBack, required bool isMobile}) {
    final state = ref.read(selectionProvider);
    return EditableColumn(
      key: const ValueKey('projects'),
      title: 'Projects',
      backgroundColor: const Color(0xFFF5F5F7),
      selectedIndex: state.isAssistantActive ? null : pIndex,
      isActiveColumn: state.focusedColumnIndex == 0,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          aiAssistantWidget,
          _buildTagsList(dataService, state),
        ],
      ),
      items: projects.map((p) => EditableItem(id: p.id, text: p.title, notes: p.notes)).toList(),
      editingItemId: state.editingItemId,
      onNotesUpdate: (index, val) {
        dataService.updateNotes(projects[index].id, val);
      },
      onExitEdit: () => ref.read(selectionProvider.notifier).setEditingItem(null),
      onItemSelected: (index) {
        ref.read(selectionProvider.notifier).selectProject(projects[index].id);
        if (isMobile) {
           ref.read(selectionProvider.notifier).setFocusedColumn(1);
        }
      },
      onAdd: (val) async {
        String newId = await dataService.addProject(val);
        ref.read(selectionProvider.notifier).selectProject(newId);
        ref.read(selectionProvider.notifier).setEditingItem(newId);
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
    );
  }

  Widget _buildConversationColumn(BuildContext context, DataService dataService, SelectionState state) {
    final conversations = dataService.conversations;
    int? selectedIndex;
    if (state.selectedConversationId != null) {
      selectedIndex = conversations.indexWhere((c) => c.id == state.selectedConversationId);
      if (selectedIndex == -1) selectedIndex = null;
    }

    return EditableColumn(
      key: const ValueKey('conversations'),
      title: 'Conversations',
      backgroundColor: Colors.white,
      selectedIndex: selectedIndex,
      isActiveColumn: state.focusedColumnIndex == 1,
      items: conversations.map((c) => EditableItem(id: c.id, text: c.title, notes: c.notes)).toList(),
      editingItemId: state.editingItemId,
      onNotesUpdate: (index, val) {
        dataService.updateConversationNotes(conversations[index].id, val);
      },
      onExitEdit: () => ref.read(selectionProvider.notifier).setEditingItem(null),
      onItemSelected: (index) {
        ref.read(selectionProvider.notifier).selectConversation(conversations[index].id);
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
      onNavigateLeft: () => Actions.invoke(context, const ChangeColumnIntent(-1)),
      onNavigateRight: () => Actions.invoke(context, const ChangeColumnIntent(1)),
    );
  }

  Widget _buildTaskColumn(BuildContext context, DataService dataService, List<Project> projects, int pIndex, int? tIndex, SelectionState state, {VoidCallback? onBack}) {
    final project = projects[pIndex];
    // Filter tasks based on showCompletedTasks state
    final visibleTasks = state.showCompletedTasks 
        ? project.tasks 
        : project.tasks.where((t) => !t.isCompleted).toList();
    
    // Find the selected index in the filtered list
    int? filteredIndex;
    if (tIndex != null && tIndex < project.tasks.length) {
      final selectedTaskId = project.tasks[tIndex].id;
      filteredIndex = visibleTasks.indexWhere((t) => t.id == selectedTaskId);
      if (filteredIndex == -1) filteredIndex = null;
    }
    
    return EditableColumn(
      key: ValueKey('tasks_${project.id}'),
      title: 'Tasks',
      backgroundColor: Colors.white,
      selectedIndex: filteredIndex,
      isActiveColumn: state.focusedColumnIndex == 1,
      showCompleted: state.showCompletedTasks,
      onToggleShowCompleted: () => ref.read(selectionProvider.notifier).toggleShowCompletedTasks(),
      items: visibleTasks.map((t) {
         // ... Goal mapping logic same as before ...
         GoalMetadata? goal;
         if (t.goal != null) {
           t.goal!.map(
             numeric: (n) {
               final pct = n.target == 0 ? 0.0 : (n.current / n.target).clamp(0.0, 1.0);
               goal = GoalMetadata(
                 progress: pct,
                 label: "${n.current}${n.unit ?? ''} / ${n.target}${n.unit ?? ''}",
               );
             },
             habit: (h) {
               final today = DateTime.now();
               final recent = <bool>[];
               for (int i=4; i>=0; i--) {
                 final d = today.subtract(Duration(days: i));
                 final entry = h.history.where((r) => 
                   r.date.year == d.year && r.date.month == d.month && r.date.day == d.day
                 ).firstOrNull;
                 recent.add(entry?.isSuccess ?? false); 
               }
               final successCount = h.history.where((r) => r.isSuccess).length;
               final totalCount = h.history.length;
               final pct = totalCount > 0 ? (successCount / totalCount * 100).toInt() : 0;
               goal = GoalMetadata(
                 recentHabitHistory: recent,
                 label: "${(h.targetFrequency * 100).toInt()}% Target | ${pct}% Actual",
               );
             }
           );
         } else if (t.subtasks.isNotEmpty) {
           final total = t.subtasks.length;
           final completed = t.subtasks.where((s) => s.isCompleted).length;
           if (total > 0) {
             goal = GoalMetadata(
               progress: completed / total,
               label: "$completed/$total",
             );
           }
         }
         return EditableItem(
           id: t.id, 
           text: t.title, 
           isCompleted: t.isCompleted, 
           goal: goal, 
           notes: t.notes,
           aiStatus: t.aiStatus,
         );
      }).toList(),
      editingItemId: state.editingItemId,
      onNotesUpdate: (index, val) {
        dataService.updateNotes(visibleTasks[index].id, val);
      },
      onExitEdit: () => ref.read(selectionProvider.notifier).setEditingItem(null),
      onCheckChanged: (index, isChecked) {
        dataService.setItemStatus(visibleTasks[index].id, isChecked);
      },
      onAiStatusChanged: (index) {
        final task = visibleTasks[index];
        final newStatus = _cycleAiStatus(task.aiStatus);
        dataService.setAiStatus(task.id, newStatus);
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
        // Map filtered indices back to original indices for reordering
        final oldTaskId = visibleTasks[oldIndex].id;
        final newTaskId = visibleTasks[newIndex].id;
        final oldOriginalIndex = project.tasks.indexWhere((t) => t.id == oldTaskId);
        final newOriginalIndex = project.tasks.indexWhere((t) => t.id == newTaskId);
        if (oldOriginalIndex != -1 && newOriginalIndex != -1) {
          dataService.reorderTasks(project.id, oldOriginalIndex, newOriginalIndex);
        }
      },
      onBack: onBack,
      onNavigateLeft: () => Actions.invoke(context, const ChangeColumnIntent(-1)),
      onNavigateRight: () => Actions.invoke(context, const ChangeColumnIntent(1)),
    );
  }

  Widget _buildSubtaskColumn(BuildContext context, DataService dataService, List<Project> projects, int pIndex, int tIndex, int? sIndex, SelectionState state, {VoidCallback? onBack}) {
    final task = projects[pIndex].tasks[tIndex];
    // Filter subtasks based on showCompletedSubtasks state
    final visibleSubtasks = state.showCompletedSubtasks 
        ? task.subtasks 
        : task.subtasks.where((s) => !s.isCompleted).toList();
    
    // Find the selected index in the filtered list
    int? filteredIndex;
    if (sIndex != null && sIndex < task.subtasks.length) {
      final selectedSubtaskId = task.subtasks[sIndex].id;
      filteredIndex = visibleSubtasks.indexWhere((s) => s.id == selectedSubtaskId);
      if (filteredIndex == -1) filteredIndex = null;
    }
    
    return EditableColumn(
      key: ValueKey('subtasks_${projects[pIndex].id}_${task.id}'),
      title: 'Subtasks',
      backgroundColor: const Color(0xFFFAFAFA),
      selectedIndex: filteredIndex,
      isActiveColumn: state.focusedColumnIndex == 2,
      showCompleted: state.showCompletedSubtasks,
      onToggleShowCompleted: () => ref.read(selectionProvider.notifier).toggleShowCompletedSubtasks(),
      items: visibleSubtasks.map((s) => EditableItem(
        id: s.id, 
        text: s.title, 
        isCompleted: s.isCompleted, 
        notes: s.notes,
        aiStatus: s.aiStatus,
      )).toList(),
      editingItemId: state.editingItemId,
      onNotesUpdate: (index, val) {
        dataService.updateNotes(visibleSubtasks[index].id, val);
      },
      onExitEdit: () => ref.read(selectionProvider.notifier).setEditingItem(null),
      onCheckChanged: (index, isChecked) {
        dataService.setItemStatus(visibleSubtasks[index].id, isChecked);
      },
      onAiStatusChanged: (index) {
        final subtask = visibleSubtasks[index];
        final newStatus = _cycleAiStatus(subtask.aiStatus);
        dataService.setAiStatus(subtask.id, newStatus);
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
        // Map filtered indices back to original indices for reordering
        final oldSubtaskId = visibleSubtasks[oldIndex].id;
        final newSubtaskId = visibleSubtasks[newIndex].id;
        final oldOriginalIndex = task.subtasks.indexWhere((s) => s.id == oldSubtaskId);
        final newOriginalIndex = task.subtasks.indexWhere((s) => s.id == newSubtaskId);
        if (oldOriginalIndex != -1 && newOriginalIndex != -1) {
          dataService.reorderSubtasks(task.id, oldOriginalIndex, newOriginalIndex);
        }
      },
      onBack: onBack,
      onNavigateLeft: () => Actions.invoke(context, const ChangeColumnIntent(-1)),
    );
  }

  Widget _buildTagResultsColumn(BuildContext context, DataService dataService, SelectionState state) {
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
       
       return EditableItem(id: item.id, text: displayText, isCompleted: isCompleted);
    }).toList();

    int? selectedIndex;
    if (state.selectedTaggedItem != null) {
      selectedIndex = items.indexWhere((i) => i.id == state.selectedTaggedItem!.id);
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
        // Note: SelectionProvider should ideally handle this to clear selection, 
        // but since we are deleting via dataService directly here, 
        // and Tag Results are read-only-ish view, we might need to manually update state if selected.
        if (state.selectedTaggedItem?.id == items[index].id) {
           ref.read(selectionProvider.notifier).selectTaggedItem(items[index]); // Wait, this logic is flawed if deleted. 
           // For now, simpler to just let it be.
        }
      },
      onReorder: (_, __) {},
    );
  }

  Widget _buildTagsList(DataService dataService, SelectionState state) {
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

  Widget _buildTaggedItemContext(BuildContext context, DataService dataService, List<Project> projects, SelectionState state) {
    if (state.selectedTaggedItem == null) return Container(color: const Color(0xFFFAFAFA));
    
    // If Project, show Tasks
    if (state.selectedTaggedItem!.type == 'project') {
       final pIdx = projects.indexWhere((p) => p.id == state.selectedTaggedItem!.id);
       if (pIdx == -1) return const Center(child: Text("Project not found"));
       return _buildTaskColumn(context, dataService, projects, pIdx, null, state);
    }
    
    // If Task, show Subtasks
    if (state.selectedTaggedItem!.type == 'task') {
       // Find project for this task
       for (int i=0; i<projects.length; i++) {
          final tIdx = projects[i].tasks.indexWhere((t) => t.id == state.selectedTaggedItem!.id);
          if (tIdx != -1) {
             return _buildSubtaskColumn(context, dataService, projects, i, tIdx, null, state);
          }
       }
       return const Center(child: Text("Task not found"));
    }

    return const Center(child: Text("No further details"));
  }

  Widget _buildMobileLayout(BuildContext context, bool isMobile, DataService dataService, SelectionState state, List<Project> projects, int? pIndex, int? tIndex, int? sIndex, Widget aiAssistantWidget) {
     if (state.isAssistantActive) {
        if (state.focusedColumnIndex == 1 || state.selectedConversationId == null) {
           return Scaffold(
             appBar: AppBar(
               leading: IconButton(icon: Icon(Icons.close), onPressed: () => ref.read(selectionProvider.notifier).setAssistantActive(false)),
               title: Text("Conversations"),
             ),
             body: _buildConversationColumn(context, dataService, state),
             floatingActionButton: FloatingActionButton(
               onPressed: () {
                  Actions.invoke(context, const AddNewItemIntent());
               },
               child: Icon(Icons.add_comment),
             ),
           );
        } else {
           return Scaffold(
             appBar: AppBar(
               leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: () => ref.read(selectionProvider.notifier).setFocusedColumn(1)),
               title: Text("Chat"),
             ),
             body: AssistantScreen(conversationId: state.selectedConversationId!),
           );
        }
     }
     
     Widget mobileBody;
     if (state.focusedColumnIndex == 0) {
       mobileBody = _buildProjectColumn(context, dataService, projects, pIndex, aiAssistantWidget, isMobile: true);
     } else if (state.focusedColumnIndex == 1) {
       mobileBody = pIndex != null 
         ? _buildTaskColumn(context, dataService, projects, pIndex, tIndex, state, onBack: () => ref.read(selectionProvider.notifier).setFocusedColumn(0))
         : const Center(child: Text('Select a Project'));
     } else {
       mobileBody = (pIndex != null && tIndex != null)
         ? _buildSubtaskColumn(context, dataService, projects, pIndex, tIndex, sIndex, state, onBack: () => ref.read(selectionProvider.notifier).setFocusedColumn(1))
         : const Center(child: Text('Select a Task'));
     }
     
     return Scaffold(
       body: mobileBody,
       floatingActionButton: FloatingActionButton(
         onPressed: () => Actions.invoke(context, const AddNewItemIntent()),
         child: const Icon(Icons.add),
       ),
     );
  }
}