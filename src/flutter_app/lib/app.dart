import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/widgets/editable_column.dart';
import 'ui/widgets/editable_item_widget.dart';
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

    _cleanupEmptyItemsExcludingSelected(projects, projectIndex, taskIndex); 

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
        // Special handling for Assistant item at index 0 (conceptually)
        // pIndex is index in `projects`. 
        // If _isAssistantActive, conceptual index is 0.
        // If not, conceptual index is pIndex + 1.
        
        int conceptualIndex = _isAssistantActive ? 0 : (pIndex != null ? pIndex + 1 : -1);
        
        // Remove current if empty
        if (!_isAssistantActive && pIndex != null && projects[pIndex].title.isEmpty && projects[pIndex].tasks.isEmpty) {
           dataService.deleteItem(projects[pIndex].id);
           
           if (projects.isEmpty) {
             _selectedProjectId = null;
             _isAssistantActive = true;
             return;
           }
           
           // If we delete, selection logic is handled by re-render usually, but here we manually adjust
           // Assuming deleteItem removes it instantly.
           // Safe fallback to assistant or nearest.
           if (delta > 0) {
              // try select next (which is now at pIndex)
              if (pIndex < projects.length) {
                 _selectedProjectId = projects[pIndex].id;
              } else {
                 _selectedProjectId = projects.last.id;
              }
           } else {
              // move up
              if (pIndex > 0) {
                 _selectedProjectId = projects[pIndex - 1].id;
              } else {
                 _selectedProjectId = null;
                 _isAssistantActive = true;
              }
           }
           return;
        }

        int nextIndex = conceptualIndex + delta;
        int maxIndex = projects.length; // 0..length

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
         
         if (tIndex != null && tasks[tIndex].title.isEmpty && tasks[tIndex].subtasks.isEmpty) {
            dataService.deleteItem(tasks[tIndex].id);
            if (tasks.isEmpty) {
              _selectedTaskId = null;
              return;
            }
            if (delta > 0) {
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
    if (_isAssistantActive) return;

    final dataService = ref.read(dataServiceProvider);
    final projects = dataService.projects;
    
    var (pIndex, tIndex, _) = _getSelectionIndices(projects);
    _cleanupEmptyItemsExcludingSelected(projects, pIndex, tIndex);
    
    var (freshPIndex, freshTIndex, _) = _getSelectionIndices(projects);

    setState(() {
      int nextColumn = _focusedColumnIndex + delta;
      
      if (nextColumn == 1 && _selectedProjectId == null) return;
      if (nextColumn == 2 && _selectedTaskId == null) return;
      
      if (nextColumn >= 0 && nextColumn <= 2) {
        _focusedColumnIndex = nextColumn;
        
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

  Widget _buildProjectColumn(dynamic dataService, List<Project> projects, int? pIndex, Widget aiAssistantWidget, {VoidCallback? onBack}) {
    return EditableColumn(
      key: const ValueKey('projects'),
      title: 'Projects',
      backgroundColor: const Color(0xFFF5F5F7),
      selectedIndex: _isAssistantActive ? null : pIndex,
      isActiveColumn: _focusedColumnIndex == 0,
      header: aiAssistantWidget,
      items: projects.map((p) => EditableItem(id: p.id, text: p.title)).toList(),
      onItemSelected: (index) {
        setState(() {
          _isAssistantActive = false;
          _selectedProjectId = projects[index].id;
          _focusedColumnIndex = 1; // Jump to tasks on mobile selection
          _selectedTaskId = null;
          _selectedSubtaskId = null;
        });
      },
      onAdd: (val) {
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
        dataService.updateTitle(projects[index].id, val);
      },
      onDelete: (index) {
        final idToDelete = projects[index].id;
        String? nextFocusId;
        if (index > 0) {
          nextFocusId = projects[index - 1].id;
        } else if (projects.length > 1) {
          nextFocusId = projects[1].id;
        }
        
        bool willBeEmpty = projects.length == 1;
        bool isSelected = (_selectedProjectId == idToDelete);
        
        dataService.deleteItem(idToDelete);
        
        if (isSelected) {
          setState(() {
            if (willBeEmpty) {
              _selectedProjectId = null;
              _isAssistantActive = true;
            } else {
              _selectedProjectId = nextFocusId;
              if (_selectedProjectId == null) _isAssistantActive = true;
            }
            _selectedTaskId = null;
            _selectedSubtaskId = null;
          });
        }
      },
      onReorder: (oldIndex, newIndex) {
        dataService.reorderProjects(oldIndex, newIndex);
      },
      onBack: onBack,
    );
  }

  Widget _buildTaskColumn(dynamic dataService, List<Project> projects, int pIndex, int? tIndex, {VoidCallback? onBack}) {
    return EditableColumn(
      key: ValueKey('tasks_$_selectedProjectId'),
      title: 'Tasks',
      backgroundColor: Colors.white,
      selectedIndex: tIndex,
      isActiveColumn: _focusedColumnIndex == 1,
      items: projects[pIndex].tasks.map((t) => EditableItem(id: t.id, text: t.title, isCompleted: t.isCompleted)).toList(),
      onCheckChanged: (index, isChecked) {
        dataService.setItemStatus(projects[pIndex].tasks[index].id, isChecked);
      },
      onItemSelected: (index) {
        setState(() {
          _selectedTaskId = projects[pIndex].tasks[index].id;
          _focusedColumnIndex = 2; // Jump to subtasks
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
        final tasks = projects[pIndex].tasks;
        String? nextFocusId;
        if (index > 0) {
          nextFocusId = tasks[index - 1].id;
        } else if (tasks.length > 1) {
          nextFocusId = tasks[1].id;
        }
        
        bool willBeEmpty = tasks.length == 1;
        dataService.deleteItem(tasks[index].id);
        
        if (willBeEmpty) {
          setState(() {
            _selectedTaskId = null;
            _focusedColumnIndex = 0;
          });
        } else if (nextFocusId != null) {
          setState(() {
            _selectedTaskId = nextFocusId;
          });
        }
      },
      onReorder: (oldIndex, newIndex) {
        dataService.reorderTasks(projects[pIndex].id, oldIndex, newIndex);
      },
      onBack: onBack,
    );
  }

  Widget _buildSubtaskColumn(dynamic dataService, List<Project> projects, int pIndex, int tIndex, int? sIndex, {VoidCallback? onBack}) {
    return EditableColumn(
      key: ValueKey('subtasks_${_selectedProjectId}_$_selectedTaskId'),
      title: 'Subtasks',
      backgroundColor: const Color(0xFFFAFAFA),
      selectedIndex: sIndex,
      isActiveColumn: _focusedColumnIndex == 2,
      items: projects[pIndex].tasks[tIndex].subtasks.map((s) => EditableItem(id: s.id, text: s.title, isCompleted: s.isCompleted)).toList(),
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
        final subtasks = projects[pIndex].tasks[tIndex].subtasks;
        String? nextFocusId;
        if (index > 0) {
          nextFocusId = subtasks[index - 1].id;
        } else if (subtasks.length > 1) {
          nextFocusId = subtasks[1].id;
        }
        
        bool willBeEmpty = subtasks.length == 1;
        dataService.deleteItem(subtasks[index].id);
        
        if (willBeEmpty) {
          setState(() {
            _selectedSubtaskId = null;
            _focusedColumnIndex = 1;
          });
        } else if (nextFocusId != null) {
          setState(() {
            _selectedSubtaskId = nextFocusId;
          });
        }
      },
      onReorder: (oldIndex, newIndex) {
        dataService.reorderSubtasks(projects[pIndex].tasks[tIndex].id, oldIndex, newIndex);
      },
      onBack: onBack,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataService = ref.watch(dataServiceProvider);
    final projects = dataService.projects;
    
    // Resolve Indices
    var (pIndex, tIndex, sIndex) = _getSelectionIndices(projects);

    // Header for Assistant
    final aiAssistantWidget = GestureDetector(
       key: const ValueKey('ai_assistant_header'),
       onTap: () {
          setState(() {
            _isAssistantActive = true;
            _selectedProjectId = null;
            _focusedColumnIndex = 0;
            _selectedTaskId = null;
            _selectedSubtaskId = null;
          });
       },
       child: Container(
         padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
         decoration: BoxDecoration(
           color: _isAssistantActive ? Colors.white : Colors.transparent,
           borderRadius: BorderRadius.circular(10),
           boxShadow: _isAssistantActive 
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
        child: KeyboardListener(
          focusNode: _keyboardFocusNode,
          onKeyEvent: _handleKeyEvent,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 1260;
              
              if (isMobile) {
                if (_isAssistantActive) {
                  return Scaffold(
                    appBar: AppBar(
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new),
                        onPressed: () => setState(() => _isAssistantActive = false),
                      ),
                      title: const Text("AI Assistant"),
                    ),
                    body: const AssistantScreen(isMobile: true),
                  );
                }
                
                Widget mobileBody;
                if (_focusedColumnIndex == 0) {
                  mobileBody = _buildProjectColumn(dataService, projects, pIndex, aiAssistantWidget);
                } else if (_focusedColumnIndex == 1) {
                  mobileBody = pIndex != null 
                    ? _buildTaskColumn(dataService, projects, pIndex, tIndex, onBack: () => setState(() => _focusedColumnIndex = 0))
                    : const Center(child: Text('Select a Project'));
                } else {
                  mobileBody = (pIndex != null && tIndex != null)
                    ? _buildSubtaskColumn(dataService, projects, pIndex, tIndex, sIndex, onBack: () => setState(() => _focusedColumnIndex = 1))
                    : const Center(child: Text('Select a Task'));
                }
                
                return Scaffold(
                  body: mobileBody,
                  floatingActionButton: FloatingActionButton(
                    onPressed: _handleEnterKey,
                    child: const Icon(Icons.add),
                  ),
                );
              }

              // Desktop Layout
              return Scaffold(
                bottomNavigationBar: Container(
                  height: 30,
                  alignment: Alignment.center,
                  child: const Text(
                    "Built with Assisted Intelligence", 
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ),
                body: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildProjectColumn(dataService, projects, pIndex, aiAssistantWidget),
                    ),
                    if (_isAssistantActive)
                      const Expanded(
                        flex: 4,
                        child: AssistantScreen(isMobile: false),
                      )
                    else ...[
                      Expanded(
                        flex: 2,
                        child: pIndex != null 
                          ? _buildTaskColumn(dataService, projects, pIndex, tIndex)
                          : Container(color: Colors.white, child: const Center(child: Text('Select a Project'))),
                      ),
                      Expanded(
                        flex: 2,
                        child: (pIndex != null && tIndex != null)
                          ? _buildSubtaskColumn(dataService, projects, pIndex, tIndex, sIndex)
                          : Container(color: const Color(0xFFFAFAFA), child: const Center(child: Text('Select a Task'))),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}