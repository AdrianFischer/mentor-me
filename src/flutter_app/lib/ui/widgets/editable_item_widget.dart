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

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_controller.text.isEmpty) {
            widget.onDelete();
            return KeyEventResult.handled;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (HardwareKeyboard.instance.isMetaPressed) {
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
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: widget.isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: widget.isSelected 
                ? [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))] 
                : [],
            border: widget.isSelected && widget.isActiveColumn
                ? Border.all(color: Colors.blue.withOpacity(0.3), width: 1)
                : null,
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
                      color: isChecked ? Colors.blue : (widget.isSelected ? Colors.blue : Colors.grey[400]!),
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
                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'New Item',
                    hintStyle: TextStyle(color: Colors.black26),
                  ),
                  maxLines: 1,
                  textInputAction: TextInputAction.done,
                  onChanged: widget.onChanged,
                  onTap: widget.onTap,
                  onSubmitted: (_) {
                    widget.onSubmitted();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
