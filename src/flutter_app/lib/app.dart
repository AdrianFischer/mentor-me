import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/widgets/editable_column.dart';
import 'ui/widgets/debug_overlay.dart';
import 'ui/assistant_screen.dart';
import 'models/models.dart';
import 'providers/data_provider.dart';
import 'services/debug_data_service.dart';

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  // Selection State (IDs for stability)
  String? _selectedProjectId;
  String? _selectedTaskId;
  String? _selectedSubtaskId;
  bool _isAssistantActive = false;

  int _focusedColumnIndex = 0;
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Request focus initially for keyboard shortcuts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardFocusNode.requestFocus();

      // Check for seed
      final seed = Uri.base.queryParameters['seed'];
      if (seed == 'complex_tree') {
         final dataService = ref.read(dataServiceProvider);
         final debugService = DebugDataService(dataService);
         debugService.seedComplexTree();
         
         // Reset selection to first project
         if (mounted && dataService.projects.isNotEmpty) {
           setState(() {
              _selectedProjectId = dataService.projects.first.id;
              _selectedTaskId = null;
              _selectedSubtaskId = null;
              _isAssistantActive = false;
           });
         }
      }
    });
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      print('Key event: ${event.logicalKey}, AssistantActive: $_isAssistantActive');
    }
    
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _moveSelection(1);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _moveSelection(-1);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _changeColumn(1);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _changeColumn(-1);
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        // Do not handle Enter globally if Assistant is active (let the input field handle it)
        if (!_isAssistantActive) {
          _handleEnterKey();
        }
      }
    }
  }

  void _handleEnterKey() {
    final dataService = ref.read(dataServiceProvider);
    final projects = dataService.projects;

    // Resolve Indices
    int? projectIndex = projects.indexWhere((p) => p.id == _selectedProjectId);
    if (projectIndex == -1) projectIndex = null;
    
    int? taskIndex;
    if (projectIndex != null) {
      taskIndex = projects[projectIndex].tasks.indexWhere((t) => t.id == _selectedTaskId);
      if (taskIndex == -1) taskIndex = null;
    }

    _cleanupEmptyItemsExcludingSelected(projects, projectIndex, taskIndex); // Pass indices/data?

    setState(() {
      if (_focusedColumnIndex == 0) {
        String newId = dataService.addProject("");
        _selectedProjectId = newId;
        _isAssistantActive = false;
        _selectedTaskId = null;
        _selectedSubtaskId = null;
      } else if (_focusedColumnIndex == 1) {
        if (_selectedProjectId != null) {
           String? newId = dataService.addTask(_selectedProjectId!, "");
           if (newId != null) {
             _selectedTaskId = newId;
             _selectedSubtaskId = null;
           }
        }
      } else if (_focusedColumnIndex == 2) {
        if (_selectedTaskId != null) {
           String? newId = dataService.addSubtask(_selectedTaskId!, "");
           if (newId != null) {
             _selectedSubtaskId = newId;
           }
        }
      }
    });
  }

  // Helper to resolve current selection indices
  (int?, int?, int?) _getSelectionIndices(List<Project> projects) {
    int? pIndex = projects.indexWhere((p) => p.id == _selectedProjectId);
    if (pIndex == -1) pIndex = null;

    int? tIndex;
    if (pIndex != null) {
      tIndex = projects[pIndex].tasks.indexWhere((t) => t.id == _selectedTaskId);
      if (tIndex == -1) tIndex = null;
    }

    int? sIndex;
    if (pIndex != null && tIndex != null) {
      sIndex = projects[pIndex].tasks[tIndex].subtasks.indexWhere((s) => s.id == _selectedSubtaskId);
      if (sIndex == -1) sIndex = null;
    }
    return (pIndex, tIndex, sIndex);
  }

  void _cleanupEmptyItemsExcludingSelected(List<Project> projects, int? curPIndex, int? curTIndex) {
    // This logic is tricky with IDs. For now, we'll skip rigorous cleanup to simplify migration.
    // The "AI-First" approach tolerates empty items more than strict UI rules.
    // If strict cleanup is needed, it should be a service method: dataService.cleanupEmpty(...)
    // Let's implement a simple version that removes empty items that are NOT selected.
    
    // Note: modifying the list while iterating is handled by index management usually.
    // Since we are using IDs for selection, we can iterate and delete safely, 
    // as long as we don't delete the ID that matches _selectedProjectId.
    
    // We need to defer this or be careful because we are reading `projects` from provider.
    // We shouldn't modify `projects` list directly. We MUST use `dataService.deleteItem`.
    
    // Iterate copies to avoid concurrent modification
    for (var p in List.of(projects)) {
       // Clean tasks
       for (var t in List.of(p.tasks)) {
         // Clean subtasks
         for (var s in List.of(t.subtasks)) {
           if (s.title.isEmpty && s.id != _selectedSubtaskId) {
             ref.read(dataServiceProvider).deleteItem(s.id);
           }
         }
         
         if (t.title.isEmpty && t.subtasks.isEmpty && t.id != _selectedTaskId) {
            ref.read(dataServiceProvider).deleteItem(t.id);
         }
       }
       
       if (p.title.isEmpty && p.tasks.isEmpty && p.id != _selectedProjectId) {
         ref.read(dataServiceProvider).deleteItem(p.id);
       }
    }
  }

  void _moveSelection(int delta) {
    final dataService = ref.read(dataServiceProvider);
    final projects = dataService.projects;
    var (pIndex, tIndex, sIndex) = _getSelectionIndices(projects);

    setState(() {
      if (_focusedColumnIndex == 0) {
        // Special handling for Assistant item at index 0
        int currentIndex = _isAssistantActive ? 0 : (pIndex != null ? pIndex + 1 : -1);
        
        // Remove current if empty (Navigation cleanup) - Only for actual projects
        if (!_isAssistantActive && pIndex != null && projects[pIndex].title.isEmpty && projects[pIndex].tasks.isEmpty) {
           dataService.deleteItem(projects[pIndex].id);
           
           if (projects.isEmpty) {
             _selectedProjectId = null;
             // Only assistant remains
             _isAssistantActive = true;
             return;
           }
           
           if (delta > 0) {
             // Stay at pIndex (which is now next item).
             // pIndex is already verified not null by the if condition
             int safePIndex = pIndex;
             if (safePIndex >= projects.length) safePIndex = projects.length - 1;
             _selectedProjectId = projects[safePIndex].id;
           } else {
             // Move up.
             int newIndex = pIndex - 1;
             if (newIndex < 0) {
               // Move to assistant
               _selectedProjectId = null;
               _isAssistantActive = true;
             } else {
               _selectedProjectId = projects[newIndex].id;
             }
           }
           _selectedTaskId = null;
           _selectedSubtaskId = null;
           return;
        }

        int nextIndex = currentIndex + delta;
        int maxIndex = projects.length; // 0 for Assistant + length projects

        if (nextIndex < 0) nextIndex = 0;
        if (nextIndex > maxIndex) nextIndex = maxIndex;

        if (nextIndex == 0) {
          _isAssistantActive = true;
          _selectedProjectId = null;
        } else {
          _isAssistantActive = false;
          _selectedProjectId = projects[nextIndex - 1].id;
        }
        _selectedTaskId = null;
        _selectedSubtaskId = null;
      } 
      else if (_focusedColumnIndex == 1) {
         if (pIndex == null) return;
         var tasks = projects[pIndex].tasks;
         
         // Cleanup current task if empty
         if (tIndex != null && tasks[tIndex].title.isEmpty && tasks[tIndex].subtasks.isEmpty) {
            dataService.deleteItem(tasks[tIndex].id);
            if (tasks.isEmpty) {
              _selectedTaskId = null;
              return;
            }
            if (delta > 0) {
               // tIndex is verified not null
               int safeTIndex = tIndex;
               if (safeTIndex >= tasks.length) safeTIndex = tasks.length - 1;
               _selectedTaskId = tasks[safeTIndex].id;
            } else {
               int newIndex = tIndex - 1;
               if (newIndex < 0) newIndex = 0;
               _selectedTaskId = tasks[newIndex].id;
            }
            _selectedSubtaskId = null;
            return;
         }

         int newIndex = (tIndex ?? -1) + delta;
         if (newIndex < 0) newIndex = 0;
         if (newIndex >= tasks.length) newIndex = tasks.length - 1;
         
         if (tasks.isNotEmpty) {
           _selectedTaskId = tasks[newIndex].id;
           _selectedSubtaskId = null;
         }
      }
      else if (_focusedColumnIndex == 2) {
        if (pIndex == null || tIndex == null) return;
        var subtasks = projects[pIndex].tasks[tIndex].subtasks;
        
        // Cleanup subtask
        if (sIndex != null && subtasks[sIndex].title.isEmpty) {
           dataService.deleteItem(subtasks[sIndex].id);
           if (subtasks.isEmpty) {
             _selectedSubtaskId = null;
             return;
           }
           if (delta > 0) {
             int safeSIndex = sIndex;
             if (safeSIndex >= subtasks.length) safeSIndex = subtasks.length - 1;
             _selectedSubtaskId = subtasks[safeSIndex].id;
           } else {
             int newIndex = sIndex - 1;
             if (newIndex < 0) newIndex = 0;
             _selectedSubtaskId = subtasks[newIndex].id;
           }
           return;
        }

        int newIndex = (sIndex ?? -1) + delta;
        if (newIndex < 0) newIndex = 0;
        if (newIndex >= subtasks.length) newIndex = subtasks.length - 1;

        if (subtasks.isNotEmpty) {
          _selectedSubtaskId = subtasks[newIndex].id;
        }
      }
    });
  }

  void _changeColumn(int delta) {
    if (_isAssistantActive) {
      return; 
    }

    // 1. Cleanup before calculating anything
    final dataService = ref.read(dataServiceProvider);
    final projects = dataService.projects; // Reference to live list
    
    var (pIndex, tIndex, _) = _getSelectionIndices(projects);
    _cleanupEmptyItemsExcludingSelected(projects, pIndex, tIndex);
    
    // 2. Re-fetch fresh indices because cleanup might have shifted things
    var (freshPIndex, freshTIndex, _) = _getSelectionIndices(projects);

    setState(() {
      int nextColumn = _focusedColumnIndex + delta;
      
      if (nextColumn == 1 && _selectedProjectId == null) return;
      if (nextColumn == 2 && _selectedTaskId == null) return;
      
      if (nextColumn >= 0 && nextColumn <= 2) {
        _focusedColumnIndex = nextColumn;
        
        // Auto-create item logic
        if (nextColumn == 1 && freshPIndex != null) {
           if (projects[freshPIndex].tasks.isEmpty) {
              String? newId = dataService.addTask(_selectedProjectId!, "");
              if (newId != null) _selectedTaskId = newId;
              _selectedSubtaskId = null;
           } else if (_selectedTaskId == null) {
              if (projects[freshPIndex].tasks.isNotEmpty) {
                _selectedTaskId = projects[freshPIndex].tasks.first.id;
                _selectedSubtaskId = null;
              }
           }
        } else if (nextColumn == 2 && freshTIndex != null && freshPIndex != null) {
           if (projects[freshPIndex].tasks[freshTIndex].subtasks.isEmpty) {
              String? newId = dataService.addSubtask(_selectedTaskId!, "");
              if (newId != null) _selectedSubtaskId = newId;
           } else if (_selectedSubtaskId == null) {
              if (projects[freshPIndex].tasks[freshTIndex].subtasks.isNotEmpty) {
                _selectedSubtaskId = projects[freshPIndex].tasks[freshTIndex].subtasks.first.id;
              }
           }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dataService = ref.watch(dataServiceProvider);
    final projects = dataService.projects;
    
    // Resolve Indices for Widget Binding
    var (pIndex, tIndex, sIndex) = _getSelectionIndices(projects);

    // Projects list with Assistant injected at top
    final projectDisplayItems = ['✨ AI Assistant', ...projects.map((p) => p.title)];
    final projectSelectedIndex = _isAssistantActive 
        ? 0 
        : (pIndex != null ? pIndex + 1 : null);

    return MaterialApp(
      title: 'Design Specs App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: DebugOverlay(
        child: KeyboardListener(
          focusNode: _keyboardFocusNode,
          onKeyEvent: _handleKeyEvent,
          child: Scaffold(
            body: Row(
            children: [
              // Project Column
              Expanded(
                child: EditableColumn(
                  key: const ValueKey('projects'),
                  title: 'Projects',
                  backgroundColor: const Color(0xFFF5F5F7),
                  selectedIndex: projectSelectedIndex,
                  isActiveColumn: _focusedColumnIndex == 0,
                  items: projectDisplayItems,
                  onItemSelected: (index) {
                    setState(() {
                      if (index == 0) {
                        _isAssistantActive = true;
                        _selectedProjectId = null;
                      } else {
                        _isAssistantActive = false;
                        _selectedProjectId = projects[index - 1].id;
                      }
                      _focusedColumnIndex = 0;
                      _selectedTaskId = null;
                      _selectedSubtaskId = null;
                    });
                  },
                  onAdd: (val) {
                    // This callback is usually from UI "+" button.
                    String newId = dataService.addProject(val);
                    setState(() {
                      _isAssistantActive = false;
                      _selectedProjectId = newId;
                      _focusedColumnIndex = 0;
                      _selectedTaskId = null;
                      _selectedSubtaskId = null;
                    });
                  },
                  onUpdate: (index, val) {
                    if (index == 0) return; // Can't rename Assistant
                    dataService.updateTitle(projects[index - 1].id, val);
                  },
                  onDelete: (index) {
                    if (index == 0) return; // Can't delete Assistant
                    
                    // Logic to adjust selection if we delete selected
                    String idToDelete = projects[index - 1].id;
                    bool isSelected = (_selectedProjectId == idToDelete);
                    
                    dataService.deleteItem(idToDelete);
                    
                    if (isSelected) {
                       setState(() {
                         _selectedProjectId = null; 
                         _isAssistantActive = true; // Fallback to assistant?
                         _selectedTaskId = null;
                         _selectedSubtaskId = null;
                       });
                    }
                  },
                ),
              ),
              
              if (_isAssistantActive)
                const Expanded(
                  flex: 2,
                  child: AssistantScreen(),
                )
              else ...[
                // Task Column
                if (pIndex != null)
                  Expanded(
                    child: EditableColumn(
                      key: ValueKey('tasks_$_selectedProjectId'), 
                      title: 'Tasks',
                      backgroundColor: Colors.white,
                      selectedIndex: tIndex,
                      isActiveColumn: _focusedColumnIndex == 1,
                      items: projects[pIndex].tasks.map((t) => t.title).toList(),
                      itemCheckedState: projects[pIndex].tasks.map((t) => t.isCompleted).toList(),
                      onCheckChanged: (index, isChecked) {
                         dataService.setItemStatus(projects[pIndex].tasks[index].id, isChecked);
                      },
                      onItemSelected: (index) {
                        setState(() {
                          _selectedTaskId = projects[pIndex].tasks[index].id;
                          _focusedColumnIndex = 1;
                          _selectedSubtaskId = null;
                        });
                      },
                      onAdd: (val) {
                        String? newId = dataService.addTask(_selectedProjectId!, val);
                        if (newId != null) {
                          setState(() {
                            _selectedTaskId = newId;
                            _focusedColumnIndex = 1;
                            _selectedSubtaskId = null;
                          });
                        }
                      },
                      onUpdate: (index, val) {
                        dataService.updateTitle(projects[pIndex].tasks[index].id, val);
                      },
                      onDelete: (index) {
                         dataService.deleteItem(projects[pIndex].tasks[index].id);
                      },
                    ),
                  )
                else
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: const Center(
                        child: Text('Select a Project', style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                  ),

                // Subtask Column
                if (pIndex != null && tIndex != null)
                  Expanded(
                    child: EditableColumn(
                      key: ValueKey('subtasks_${_selectedProjectId}_$_selectedTaskId'),
                      title: 'Subtasks',
                      backgroundColor: const Color(0xFFFAFAFA),
                      selectedIndex: sIndex,
                      isActiveColumn: _focusedColumnIndex == 2,
                      items: projects[pIndex].tasks[tIndex].subtasks.map((s) => s.title).toList(),
                      itemCheckedState: projects[pIndex].tasks[tIndex].subtasks.map((s) => s.isCompleted).toList(),
                      onCheckChanged: (index, isChecked) {
                         dataService.setItemStatus(projects[pIndex].tasks[tIndex].subtasks[index].id, isChecked);
                      },
                      onItemSelected: (index) {
                        setState(() {
                          _selectedSubtaskId = projects[pIndex].tasks[tIndex].subtasks[index].id;
                          _focusedColumnIndex = 2;
                        });
                      },
                      onAdd: (val) {
                         String? newId = dataService.addSubtask(_selectedTaskId!, val);
                         if (newId != null) {
                           setState(() {
                             _selectedSubtaskId = newId;
                             _focusedColumnIndex = 2;
                           });
                         }
                      },
                      onUpdate: (index, val) {
                         dataService.updateTitle(projects[pIndex].tasks[tIndex].subtasks[index].id, val);
                      },
                      onDelete: (index) {
                        dataService.deleteItem(projects[pIndex].tasks[tIndex].subtasks[index].id);
                      },
                    ),
                  )
                else
                  Expanded(
                    child: Container(
                      color: const Color(0xFFFAFAFA),
                      child: const Center(
                        child: Text('Select a Task', style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
      ),
    );
  }
}
