import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditableColumn extends StatefulWidget {
  final String title;
  final Color backgroundColor;
  final ValueChanged<int>? onItemSelected;
  final int? selectedIndex;
  final bool isActiveColumn;
  final List<String> items;
  final List<bool>? itemCheckedState; // Optional checked state
  final Function(String) onAdd;
  final Function(int, String) onUpdate;
  final Function(int)? onDelete;
  final Function(int, bool)? onCheckChanged; // Callback for check toggle

  const EditableColumn({
    super.key,
    required this.title,
    this.backgroundColor = Colors.white,
    this.onItemSelected,
    this.selectedIndex,
    this.isActiveColumn = false,
    required this.items,
    this.itemCheckedState,
    required this.onAdd,
    required this.onUpdate,
    this.onDelete,
    this.onCheckChanged,
  });

  @override
  State<EditableColumn> createState() => _EditableColumnState();
}

class _EditableColumnState extends State<EditableColumn> {
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];
  final List<bool> _checkedItems = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initData();
    if (widget.isActiveColumn && widget.selectedIndex != null) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
         if (mounted && widget.selectedIndex! >= 0 && widget.selectedIndex! < _focusNodes.length) {
            _focusNodes[widget.selectedIndex!].requestFocus();
         }
       });
    }
  }

  void _initData() {
    _controllers.clear();
    _focusNodes.clear();
    _checkedItems.clear();
    for (int i = 0; i < widget.items.length; i++) {
      _addItemInternal(widget.items[i], checked: widget.itemCheckedState != null && i < widget.itemCheckedState!.length ? widget.itemCheckedState![i] : false);
    }
  }

  void _addItemInternal(String text, {bool checked = false}) {
    var controller = TextEditingController(text: text);
    // Listen for changes to notify parent
    controller.addListener(() {
      int index = _controllers.indexOf(controller);
      if (index != -1) {
        // Only notify if text changed?
        // Actually, we can just notify on every change or on submit.
        // For real-time updates:
        widget.onUpdate(index, controller.text);
      }
    });
    _controllers.add(controller);
    _focusNodes.add(FocusNode(onKeyEvent: (node, event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.backspace) {
          if (controller.text.isEmpty) {
            int index = _controllers.indexOf(controller);
            if (index != -1) {
              _handleDelete(index);
              return KeyEventResult.handled;
            }
          }
        } else if (event.logicalKey == LogicalKeyboardKey.enter) {
          if (HardwareKeyboard.instance.isMetaPressed) {
            int index = _controllers.indexOf(controller);
            if (index != -1) {
              _toggleCheckbox(index);
              return KeyEventResult.handled;
            }
          } else {
            _addNewItem();
            return KeyEventResult.handled;
          }
        }
      }
      return KeyEventResult.ignored;
    }));
    _checkedItems.add(checked);
  }

  void _handleDelete(int index) {
    if (index >= 0 && index < _controllers.length) {
      // 1. Move focus to previous item if possible, or keep focus on same index (which becomes next item) 
      //    or loose focus?
      //    Usually backspace merge: focus goes to previous item.
      int focusIndex = index > 0 ? index - 1 : (index < _controllers.length - 1 ? index : -1);
      
      if (focusIndex != -1) {
        _focusNodes[focusIndex].requestFocus();
        widget.onItemSelected?.call(focusIndex);
      }

      // 2. Remove locally
      setState(() {
        _controllers[index].dispose();
        _focusNodes[index].dispose();
        
        _controllers.removeAt(index);
        _focusNodes.removeAt(index);
        _checkedItems.removeAt(index);
      });

      // 3. Notify parent
      widget.onDelete?.call(index);
    }
  }

  @override
  void didUpdateWidget(EditableColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.length != _controllers.length) {
       print("[VERIFY_FLOW] UI Rebuild: Column ${widget.title} items changed from ${_controllers.length} to ${widget.items.length}");
    }
    // Sync items if parent added new ones (e.g. via empty column Enter key)
    // Also sync if parent REMOVED items (e.g. cleanup)
    if (widget.items.length != _controllers.length) {
      // Re-initialize to match parent state
      // We must dispose old ones to avoid leaks, but maybe we can reuse some?
      // Simple approach: Dispose all and Re-init.
      // This is drastic but safe for consistency.
      // We rely on `widget.selectedIndex` to restore focus.
      
      for (var controller in _controllers) {
        controller.dispose();
      }
      for (var node in _focusNodes) {
        node.dispose();
      }
      _initData();
    } else {
       // Check for updates?
       // If length is same, maybe content changed?
       // For now, let's assume length check covers add/remove scenarios.
    }

    if (widget.isActiveColumn && widget.selectedIndex != null) {
      if (widget.selectedIndex! >= 0 && widget.selectedIndex! < _focusNodes.length) {
        if (!oldWidget.isActiveColumn || oldWidget.selectedIndex != widget.selectedIndex || widget.items.length != oldWidget.items.length) {
           _focusNodes[widget.selectedIndex!].requestFocus();
        }
      }
    }
    
    // Note: We are NOT syncing widget.items back to controllers fully here to avoid cursor jumps on existing items.
    // We rely on ValueKey in parent to reset us if the LIST context changes (e.g. Project switch).
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _addNewItem() {
    // Determine the string to add (empty)
    String newItemText = "";
    
    // Add locally to UI
    setState(() {
      _addItemInternal(newItemText);
    });
    
    // Notify parent
    widget.onAdd(newItemText);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleCheckbox(int index) {
    setState(() {
      _checkedItems[index] = !_checkedItems[index];
    });
    widget.onCheckChanged?.call(index, _checkedItems[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (Things 3 style: Large, Bold, bottom padding)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 24, // Larger title
                      fontWeight: FontWeight.w800, // Thicker font
                      color: widget.isActiveColumn ? Colors.black : Colors.grey[600],
                      letterSpacing: -0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  key: ValueKey('${widget.title.toLowerCase()}_add_btn'),
                  icon: Icon(Icons.add_circle, color: Colors.blue[600]), // Blue add icon
                  onPressed: _addNewItem,
                  tooltip: 'Add Item',
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _controllers.length,
              itemBuilder: (context, index) {
                final isSelected = widget.selectedIndex == index;
                final isChecked = _checkedItems[index];

                Widget child = GestureDetector(
                  key: ValueKey('${widget.title.toLowerCase()}_item_$index'),
                  onTap: () {
                    widget.onItemSelected?.call(index);
                    _focusNodes[index].requestFocus();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isSelected 
                          ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))] 
                          : [],
                      border: isSelected && widget.isActiveColumn
                          ? Border.all(color: Colors.blue.withOpacity(0.3), width: 1) // Subtle blue border for active focus
                          : null,
                    ),
                    child: Row(
                      children: [
                        // Checkbox
                        GestureDetector(
                          key: ValueKey('${widget.title.toLowerCase()}_check_$index'),
                          onTap: () => _toggleCheckbox(index),
                          child: Container(
                            width: 18,
                            height: 18,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isChecked ? Colors.blue : Colors.transparent,
                              border: Border.all(
                                color: isChecked ? Colors.blue : (isSelected ? Colors.blue : Colors.grey[400]!),
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
                            key: ValueKey('${widget.title.toLowerCase()}_input_$index'),
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                              style: TextStyle(
                              fontSize: 15,
                              color: isChecked ? Colors.grey : Colors.black87,
                              decoration: isChecked ? TextDecoration.lineThrough : null,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
                            onTap: () => widget.onItemSelected?.call(index),
                            onSubmitted: (_) {
                              _focusNodes[index].requestFocus();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );

                if (_controllers[index].text.contains('AI Assistant')) {
                   return Semantics(
                     label: 'AI_Assistant_Item',
                     button: true,
                     child: child,
                   );
                }
                return child;
              },
            ),
          ),
        ],
      ),
    );
  }
}
