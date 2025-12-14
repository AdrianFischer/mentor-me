import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets/editable_column.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int? _selectedProjectIndex;
  int? _selectedTaskIndex;
  int? _selectedSubtaskIndex;

  // Track the currently focused column: 0=Projects, 1=Tasks, 2=Subtasks
  int _focusedColumnIndex = 0;

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
      }
    }
  }

  void _moveSelection(int delta) {
    setState(() {
      if (_focusedColumnIndex == 0) {
        _selectedProjectIndex = (_selectedProjectIndex ?? -1) + delta;
        if (_selectedProjectIndex! < 0) _selectedProjectIndex = 0;
        // Logic to clamp to max length would require lifting state or callback
        // For now, we assume standard movement. Real impl needs list length.
        // We'll update children on selection change
        _selectedTaskIndex = null;
        _selectedSubtaskIndex = null;
      } else if (_focusedColumnIndex == 1) {
        if (_selectedProjectIndex == null) return;
        _selectedTaskIndex = (_selectedTaskIndex ?? -1) + delta;
        if (_selectedTaskIndex! < 0) _selectedTaskIndex = 0;
        _selectedSubtaskIndex = null;
      } else if (_focusedColumnIndex == 2) {
        if (_selectedTaskIndex == null) return;
        _selectedSubtaskIndex = (_selectedSubtaskIndex ?? -1) + delta;
        if (_selectedSubtaskIndex! < 0) _selectedSubtaskIndex = 0;
      }
    });
  }

  void _changeColumn(int delta) {
    setState(() {
      int nextColumn = _focusedColumnIndex + delta;
      
      // Validation: Can't go to Tasks if no Project selected
      if (nextColumn == 1 && _selectedProjectIndex == null) return;
      // Validation: Can't go to Subtasks if no Task selected
      if (nextColumn == 2 && _selectedTaskIndex == null) return;
      
      if (nextColumn >= 0 && nextColumn <= 2) {
        _focusedColumnIndex = nextColumn;
        
        // Auto-select first item if entering a column with no selection
        if (_focusedColumnIndex == 1 && _selectedTaskIndex == null) {
          _selectedTaskIndex = 0;
          _selectedSubtaskIndex = null;
        } else if (_focusedColumnIndex == 2 && _selectedSubtaskIndex == null) {
          _selectedSubtaskIndex = 0;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Design Specs App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKeyEvent: _handleKeyEvent,
        child: Scaffold(
          body: Row(
            children: [
              Expanded(
                child: EditableColumn(
                  title: 'Projects',
                  backgroundColor: Colors.grey[200]!,
                  selectedIndex: _selectedProjectIndex,
                  isActiveColumn: _focusedColumnIndex == 0,
                  onItemSelected: (index) {
                    setState(() {
                      _selectedProjectIndex = index;
                      _focusedColumnIndex = 0;
                      _selectedTaskIndex = null;
                      _selectedSubtaskIndex = null;
                    });
                  },
                ),
              ),
              if (_selectedProjectIndex != null)
                Expanded(
                  child: EditableColumn(
                    title: 'Tasks',
                    backgroundColor: Colors.white,
                    selectedIndex: _selectedTaskIndex,
                    isActiveColumn: _focusedColumnIndex == 1,
                    onItemSelected: (index) {
                      setState(() {
                        _selectedTaskIndex = index;
                        _focusedColumnIndex = 1;
                        _selectedSubtaskIndex = null;
                      });
                    },
                  ),
                )
              else
                Expanded(child: Container(color: Colors.white)),
              if (_selectedTaskIndex != null)
                Expanded(
                  child: EditableColumn(
                    title: 'Subtasks',
                    backgroundColor: Colors.grey[200]!,
                    selectedIndex: _selectedSubtaskIndex,
                    isActiveColumn: _focusedColumnIndex == 2,
                    onItemSelected: (index) {
                      setState(() {
                        _selectedSubtaskIndex = index;
                        _focusedColumnIndex = 2;
                      });
                    },
                  ),
                )
              else
                Expanded(child: Container(color: Colors.grey[200]!)),
            ],
          ),
        ),
      ),
    );
  }
}
