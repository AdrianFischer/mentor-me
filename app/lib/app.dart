import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/widgets/debug_overlay.dart';
import 'ui/assistant_screen.dart';
import 'ui/actions/selection_actions.dart';
import 'ui/widgets/columns/project_column.dart';
import 'ui/widgets/columns/task_column.dart';
import 'ui/widgets/columns/subtask_column.dart';
import 'ui/widgets/columns/conversation_column.dart';
import 'ui/widgets/columns/tag_results_column.dart';
import 'models/models.dart';
import 'providers/data_provider.dart';
import 'providers/mcp_provider.dart';
import 'providers/selection_provider.dart';
import 'providers/filtered_data_providers.dart';
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
    final selectionState = ref.watch(selectionProvider);
    final projects = ref.watch(filteredProjectsProvider);

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
            StopEditIntent: StopEditAction(ref, rootFocusNode: _rootFocusNode),
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
              LogicalKeySet(LogicalKeyboardKey.space): const ToggleCompletionIntent(),
              LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.backspace): const DeleteItemIntent(),
            },
            child: Focus(
              key: const ValueKey('rootFocus'),
              focusNode: _rootFocusNode,
              autofocus: true,
              child: Builder(
                builder: (context) => LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    if (isMobile) {
                      return _buildMobileLayout(context, isMobile, selectionState, projects);
                    }
                    return Scaffold(
                      body: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Column 0: Projects or Chat History
                          SizedBox(
                            width: 280,
                            child: ProjectColumn(isMobile: isMobile),
                          ),
                          const VerticalDivider(width: 1, thickness: 1),
                          
                          // Column 1: Tasks or Conversations
                          Expanded(
                            child: _buildMiddleColumn(context, selectionState, projects),
                          ),
                          const VerticalDivider(width: 1, thickness: 1),
                          
                          // Column 2: Subtasks or Chat
                          Expanded(
                            child: _buildRightColumn(context, selectionState, projects),
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

  Widget _buildMiddleColumn(BuildContext context, SelectionState state, List<Project> projects) {
    if (state.isAssistantActive) {
      return const ConversationColumn();
    }
    
    if (state.selectedTag != null) {
      return const TagResultsColumn();
    }

    if (state.selectedProjectId != null) {
      return TaskColumn(projectId: state.selectedProjectId!);
    }
    
    return Container(color: Colors.white, child: const Center(child: Text("Select a Project")));
  }

  Widget _buildRightColumn(BuildContext context, SelectionState state, List<Project> projects) {
    if (state.isAssistantActive) {
      if (state.selectedConversationId == null) {
        return Container(color: const Color(0xFFFAFAFA), child: const Center(child: Text("Select a Conversation")));
      }
      return AssistantScreen(conversationId: state.selectedConversationId!);
    }
    
    if (state.selectedTag != null) {
       return _buildTaggedItemContext(context, state);
    }

    if (state.selectedTaskId != null && state.selectedProjectId != null) {
      return SubtaskColumn(projectId: state.selectedProjectId!, taskId: state.selectedTaskId!);
    }
    
    return Container(color: const Color(0xFFFAFAFA), child: const Center(child: Text("Select a Task")));
  }

  Widget _buildTaggedItemContext(BuildContext context, SelectionState state, {VoidCallback? onBack}) {
    if (state.selectedTaggedItem == null) return Container(color: const Color(0xFFFAFAFA));
    final projects = ref.watch(filteredProjectsProvider);
    
    if (state.selectedTaggedItem!.type == 'project') {
       final pIdx = projects.indexWhere((p) => p.id == state.selectedTaggedItem!.id);
       if (pIdx == -1) return const Center(child: Text("Project not found"));
       return TaskColumn(projectId: projects[pIdx].id, onBack: onBack);
    }
    
    if (state.selectedTaggedItem!.type == 'task') {
       for (final p in projects) {
          final tIdx = p.tasks.indexWhere((t) => t.id == state.selectedTaggedItem!.id);
          if (tIdx != -1) {
             return SubtaskColumn(projectId: p.id, taskId: p.tasks[tIdx].id, onBack: onBack);
          }
       }
       return const Center(child: Text("Task not found"));
    }

    return const Center(child: Text("No further details"));
  }

  Widget _buildMobileLayout(BuildContext context, bool isMobile, SelectionState state, List<Project> projects) {
     if (state.isAssistantActive) {
        if (state.focusedColumnIndex == 1 || state.selectedConversationId == null) {
           return Scaffold(
             appBar: AppBar(
               leading: IconButton(icon: const Icon(Icons.close), onPressed: () => ref.read(selectionProvider.notifier).setAssistantActive(false)),
               title: const Text("Conversations"),
             ),
             body: const ConversationColumn(),
             floatingActionButton: FloatingActionButton(
               onPressed: () {
                  Actions.invoke(context, const AddNewItemIntent());
               },
               child: const Icon(Icons.add_comment),
             ),
           );
        } else {
           return Scaffold(
             appBar: AppBar(
               leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => ref.read(selectionProvider.notifier).setFocusedColumn(1)),
               title: const Text("Chat"),
             ),
             body: AssistantScreen(conversationId: state.selectedConversationId!),
           );
        }
     }
     
     Widget mobileBody;
     if (state.focusedColumnIndex == 0) {
       mobileBody = ProjectColumn(isMobile: true);
     } else if (state.focusedColumnIndex == 1) {
       if (state.selectedTag != null) {
         mobileBody = const TagResultsColumn();
       } else {
         mobileBody = state.selectedProjectId != null 
           ? TaskColumn(projectId: state.selectedProjectId!, onBack: () => ref.read(selectionProvider.notifier).setFocusedColumn(0))
           : const Center(child: Text('Select a Project'));
       }
     } else {
       if (state.selectedTag != null) {
          mobileBody = _buildTaggedItemContext(context, state, onBack: () => ref.read(selectionProvider.notifier).setFocusedColumn(1));
       } else {
          mobileBody = (state.selectedProjectId != null && state.selectedTaskId != null)
            ? SubtaskColumn(projectId: state.selectedProjectId!, taskId: state.selectedTaskId!, onBack: () => ref.read(selectionProvider.notifier).setFocusedColumn(1))
            : const Center(child: Text('Select a Task'));
       }
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