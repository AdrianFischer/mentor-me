import 'dart:io';

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../models/models.dart';

class GoalMetadata {
  final double? progress; // 0.0 - 1.0
  final String? label; 
  final List<bool>? recentHabitHistory; // last 7 days

  GoalMetadata({this.progress, this.label, this.recentHabitHistory});
}

class EditableItem {
  final String id;
  final String text;
  final String? notes;
  final bool isCompleted;
  final GoalMetadata? goal;
  final AiStatus aiStatus;
  final List<String> localImagePaths;

  EditableItem({
    required this.id, 
    required this.text, 
    this.notes,
    this.isCompleted = false,
    this.goal,
    this.aiStatus = AiStatus.notReady,
    this.localImagePaths = const [],
  });
}

class EditableItemWidget extends StatefulWidget {
  final EditableItem item;
  final bool isSelected;
  final bool isActiveColumn;
  final bool isEditing;
  final int index;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onNotesChanged;
  final VoidCallback onTap;
  final VoidCallback onSubmitted;
  final VoidCallback onToggleCheck;
  final VoidCallback? onToggleAiStatus;
  final VoidCallback onDelete;
  final VoidCallback? onExitEdit;
  final bool showDeleteButton;
  final VoidCallback? onNavigateLeft;
  final VoidCallback? onNavigateRight;

  const EditableItemWidget({
    Key? key,
    required this.item,
    required this.isSelected,
    required this.isActiveColumn,
    this.isEditing = false,
    required this.index,
    required this.onChanged,
    this.onNotesChanged,
    required this.onTap,
    required this.onSubmitted,
    required this.onToggleCheck,
    this.onToggleAiStatus,
    required this.onDelete,
    this.onExitEdit,
    this.showDeleteButton = false,
    this.onNavigateLeft,
    this.onNavigateRight,
  }) : super(key: key);

  @override
  State<EditableItemWidget> createState() => _EditableItemWidgetState();
}

class _EditableItemWidgetState extends State<EditableItemWidget> {
  late TextEditingController _controller;
  late TextEditingController _notesController;
  late FocusNode _focusNode;
  late FocusNode _notesFocusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item.text);
    _notesController = TextEditingController(text: widget.item.notes);
    _focusNode = FocusNode(onKeyEvent: _handleKeyEvent);
    _notesFocusNode = FocusNode(onKeyEvent: _handleNotesKeyEvent);

    if (widget.isEditing && widget.isSelected && widget.isActiveColumn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(EditableItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.item.text != _controller.text) {
      // Only update if we don't have focus to avoid overwriting user input
      if (!_focusNode.hasFocus) {
         _controller.text = widget.item.text;
      }
    }
    
    if (widget.item.notes != _notesController.text) {
      if (!_notesFocusNode.hasFocus) {
        _notesController.text = widget.item.notes ?? "";
      }
    }

    // If we just entered edit mode, focus the title
    if (widget.isEditing && !oldWidget.isEditing) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
         if (mounted) _focusNode.requestFocus();
       });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _notesController.dispose();
    _focusNode.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isChecked = widget.item.isCompleted;

    return Container(
      key: ValueKey(widget.item.id),
      margin: const EdgeInsets.only(bottom: 4),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          widget.onTap();
          // If tapping and in edit mode, focus title. If not, just select (handled by parent).
          if (widget.isEditing) {
             _focusNode.requestFocus();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: widget.isSelected 
                ? (widget.isActiveColumn 
                    ? Colors.blue.withOpacity(0.08) 
                    : Colors.black.withOpacity(0.06))
                : Colors.black.withOpacity(0),
            borderRadius: BorderRadius.circular(8),
            border: widget.isEditing ? Border.all(color: Colors.blue.withOpacity(0.3)) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  ReorderableDragStartListener(
                    index: widget.index,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8, top: 4),
                      child: Icon(Icons.drag_indicator, size: 16, color: Colors.grey[300]),
                    ),
                  ),

                  // Checkbox
                  GestureDetector(
                    key: const Key('item_checkbox'),
                    onTap: widget.onToggleCheck,
                    child: Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsets.only(right: 12, top: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isChecked ? Colors.blue : Colors.transparent,
                        border: Border.all(
                          color: isChecked ? Colors.blue : Colors.grey[400]!,
                          width: 1.5,
                        ),
                      ),
                      child: isChecked 
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : null,
                    ),
                  ),
                  
                  // AI Status Button
                  if (widget.onToggleAiStatus != null)
                    GestureDetector(
                      onTap: widget.onToggleAiStatus,
                      child: Container(
                        width: 18,
                        height: 18,
                        margin: const EdgeInsets.only(right: 12, top: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getAiStatusColor(widget.item.aiStatus),
                          border: Border.all(
                            color: _getAiStatusBorderColor(widget.item.aiStatus),
                            width: 1.5,
                          ),
                        ),
                        child: _getAiStatusIcon(widget.item.aiStatus),
                      ),
                    ),
                  
                  // Title
                  Expanded(
                    child: widget.isEditing 
                      ? TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          autofocus: true,
                          style: TextStyle(
                            fontSize: 15,
                            color: isChecked ? Colors.grey : Colors.black87,
                            decoration: isChecked ? TextDecoration.lineThrough : null,
                            fontWeight: FontWeight.normal,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            hintText: 'New Item',
                            hintStyle: TextStyle(color: Colors.black26),
                          ),
                          maxLines: null,
                          minLines: 1,
                          textInputAction: TextInputAction.next,
                          onChanged: widget.onChanged,
                        )
                      : Text(
                          widget.item.text.isEmpty ? "New Item" : widget.item.text,
                          style: TextStyle(
                            fontSize: 15,
                            color: widget.item.text.isEmpty ? Colors.grey : (isChecked ? Colors.grey : Colors.black87),
                            decoration: isChecked ? TextDecoration.lineThrough : null,
                          ),
                        ),
                  ),
                  
                  if (widget.showDeleteButton)
                     IconButton(
                       icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                       onPressed: widget.onDelete,
                       tooltip: 'Delete',
                       padding: EdgeInsets.zero,
                       constraints: const BoxConstraints(),
                     ),
                ],
              ),
              
              // Goals visualization
              if (widget.item.goal != null)
                Padding(
                  padding: const EdgeInsets.only(left: 44, right: 12, top: 4),
                  child: _buildGoalVisualization(widget.item.goal!),
                ),

              // Image Artifacts
              if (widget.item.localImagePaths.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 44, top: 8),
                  child: SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.item.localImagePaths.length,
                      itemBuilder: (context, idx) {
                        final path = widget.item.localImagePaths[idx];
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                            image: DecorationImage(
                              image: FileImage(File(path)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // Notes Section
              if (widget.item.notes != null && widget.item.notes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 44, top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("NOTES", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 4),
                      widget.isEditing
                          ? TextField(
                              controller: _notesController,
                              focusNode: _notesFocusNode,
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                hintText: 'Add notes...',
                                hintStyle: TextStyle(color: Colors.black26),
                              ),
                              maxLines: null,
                              minLines: 2,
                              onChanged: (val) => widget.onNotesChanged?.call(val),
                            )
                          : Container(
                              constraints: const BoxConstraints(maxHeight: 300),
                              child: SingleChildScrollView(
                                child: MarkdownBody(
                                  data: widget.item.notes!,
                                  styleSheet: MarkdownStyleSheet(
                                    p: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                                    h1: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                    h2: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                    h3: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                                    code: const TextStyle(fontSize: 12, fontFamily: 'monospace', backgroundColor: Color(0xFFF5F5F5)),
                                    codeblockDecoration: BoxDecoration(
                                      color: const Color(0xFFF5F5F5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    blockquote: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black54),
                                    listBullet: const TextStyle(fontSize: 13, color: Colors.black87),
                                    strong: const TextStyle(fontWeight: FontWeight.bold),
                                    em: const TextStyle(fontStyle: FontStyle.italic),
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                )
              // Show notes field in edit mode even if empty
              else if (widget.isEditing)
                Padding(
                  padding: const EdgeInsets.only(left: 44, top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("NOTES", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _notesController,
                        focusNode: _notesFocusNode,
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: 'Add notes...',
                          hintStyle: TextStyle(color: Colors.black26),
                        ),
                        maxLines: null,
                        minLines: 2,
                        onChanged: (val) => widget.onNotesChanged?.call(val),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalVisualization(GoalMetadata goal) {
    if (goal.recentHabitHistory != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: goal.recentHabitHistory!.map((success) => Container(
              width: 8, height: 8,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: success ? Colors.green[400] : Colors.grey[300],
              ),
            )).toList(),
          ),
          if (goal.label != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(goal.label!, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ),
        ],
      );
    } else if (goal.progress != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: goal.progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[300]!),
              minHeight: 4,
            ),
          ),
          if (goal.label != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(goal.label!, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
       if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          if (_controller.selection.isCollapsed && _controller.selection.baseOffset == 0) {
             widget.onNavigateLeft?.call();
             return KeyEventResult.handled;
          }
       }
       
       if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          if (_controller.selection.isCollapsed && _controller.selection.baseOffset == _controller.text.length) {
             widget.onNavigateRight?.call();
             return KeyEventResult.handled;
          }
       }
       
       if (event.logicalKey == LogicalKeyboardKey.escape) {
          widget.onExitEdit?.call();
          return KeyEventResult.handled;
       }
       
       if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.tab) {
          if (!HardwareKeyboard.instance.isShiftPressed) {
             // Enter or Tab in Title -> Focus Notes?
             if (widget.isEditing) {
               _notesFocusNode.requestFocus();
               return KeyEventResult.handled;
             }
          }
       }
       
       if (event.logicalKey == LogicalKeyboardKey.backspace) {
          if (_controller.text.isEmpty) {
             widget.onDelete();
             return KeyEventResult.handled;
          }
       }
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleNotesKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
          widget.onExitEdit?.call();
          return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  Color _getAiStatusColor(AiStatus status) {
    switch (status) {
      case AiStatus.notReady:
        return Colors.transparent;
      case AiStatus.ready:
        return Colors.green;
      case AiStatus.inProgress:
        return Colors.blue;
      case AiStatus.done:
        return Colors.green;
    }
  }

  Color _getAiStatusBorderColor(AiStatus status) {
    switch (status) {
      case AiStatus.notReady:
        return Colors.grey[400]!;
      case AiStatus.ready:
        return Colors.green;
      case AiStatus.inProgress:
        return Colors.blue;
      case AiStatus.done:
        return Colors.green;
    }
  }

  Widget? _getAiStatusIcon(AiStatus status) {
    switch (status) {
      case AiStatus.notReady:
        return Icon(Icons.pause, size: 10, color: Colors.grey[600]);
      case AiStatus.ready:
        return const Icon(Icons.play_arrow, size: 10, color: Colors.white);
      case AiStatus.inProgress:
        return const Icon(Icons.sync, size: 10, color: Colors.white);
      case AiStatus.done:
        return const Icon(Icons.check, size: 10, color: Colors.white);
    }
  }
}