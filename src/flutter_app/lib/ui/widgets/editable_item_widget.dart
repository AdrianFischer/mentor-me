import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditableItem {
  final String id;
  final String text;
  final bool isCompleted;

  EditableItem({
    required this.id, 
    required this.text, 
    this.isCompleted = false
  });
}

class EditableItemWidget extends StatefulWidget {
  final EditableItem item;
  final bool isSelected;
  final bool isActiveColumn;
  final int index;
  final ValueChanged<String> onChanged;
  final VoidCallback onTap;
  final VoidCallback onSubmitted;
  final VoidCallback onToggleCheck;
  final VoidCallback onDelete;
  final bool showDeleteButton;
  final VoidCallback? onNavigateLeft;
  final VoidCallback? onNavigateRight;

  const EditableItemWidget({
    Key? key,
    required this.item,
    required this.isSelected,
    required this.isActiveColumn,
    required this.index,
    required this.onChanged,
    required this.onTap,
    required this.onSubmitted,
    required this.onToggleCheck,
    required this.onDelete,
    this.showDeleteButton = false,
    this.onNavigateLeft,
    this.onNavigateRight,
  }) : super(key: key);

  @override
  State<EditableItemWidget> createState() => _EditableItemWidgetState();
}

class _EditableItemWidgetState extends State<EditableItemWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item.text);
    _focusNode = FocusNode(onKeyEvent: _handleKeyEvent);

    if (widget.isSelected && widget.isActiveColumn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }



  @override
  void didUpdateWidget(EditableItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Sync Logic: Only update text from upstream if we don't have focus.
    // This prevents the "fight" between local typing and remote updates.
    if (!_focusNode.hasFocus) {
      if (widget.item.text != _controller.text) {
        _controller.text = widget.item.text;
      }
    }

    // Focus Logic: If we are selected and active, ensure we have focus.
    if (widget.isActiveColumn && widget.isSelected) {
      if (!_focusNode.hasFocus) {
        // Use post-frame to ensure we don't fight with unmount/remount
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_focusNode.hasFocus) {
            _focusNode.requestFocus();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isChecked = widget.item.isCompleted;

    return Container(
      key: ValueKey(widget.item.id),
      margin: const EdgeInsets.only(bottom: 4),
      child: GestureDetector(
        onTap: () {
          widget.onTap();
          _focusNode.requestFocus();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: widget.isSelected ? Colors.black.withOpacity(0.06) : Colors.black.withOpacity(0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Drag Handle
              ReorderableDragStartListener(
                index: widget.index,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(Icons.drag_indicator, size: 16, color: Colors.grey[300]),
                ),
              ),

              // Checkbox
              GestureDetector(
                onTap: widget.onToggleCheck,
                child: Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.only(right: 12),
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
              // Text Field
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: widget.isSelected && widget.isActiveColumn,
                  style: TextStyle(
                    fontSize: 15,
                    color: isChecked ? Colors.grey : Colors.black87,
                    decoration: isChecked ? TextDecoration.lineThrough : null,
                    fontWeight: FontWeight.normal,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4), // Slight padding for comfort
                    hintText: 'New Item',
                    hintStyle: TextStyle(color: Colors.black26),
                  ),
                  maxLines: null, // Allow multi-line input
                  minLines: 1,
                  textInputAction: TextInputAction.newline, // Allows new lines within the field
                  onChanged: widget.onChanged,
                  onTap: widget.onTap,
                  onSubmitted: (_) {
                    // This is handled by _handleKeyEvent
                  },
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
        ),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        if (_controller.selection.isValid &&
            _controller.selection.isCollapsed &&
            _controller.selection.baseOffset == 0) {
          widget.onNavigateLeft?.call();
          return KeyEventResult.handled;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        if (_controller.selection.isValid &&
            _controller.selection.isCollapsed &&
            _controller.selection.baseOffset == _controller.text.length) {
          widget.onNavigateRight?.call();
          return KeyEventResult.handled;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_controller.text.isEmpty) {
            widget.onDelete();
            return KeyEventResult.handled;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (HardwareKeyboard.instance.isShiftPressed) {
          return KeyEventResult.ignored; // Allow TextField to handle Shift+Enter for new line
        } else if (HardwareKeyboard.instance.isMetaPressed) {
            widget.onToggleCheck();
            return KeyEventResult.handled;
        } else {
          widget.onSubmitted();
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }
}
