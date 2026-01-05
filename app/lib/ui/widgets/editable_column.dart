import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'editable_item_widget.dart';
import '../actions/selection_actions.dart';

class EditableColumn extends StatefulWidget {
  final String title;
  final Color backgroundColor;
  final ValueChanged<int>? onItemSelected;
  final int? selectedIndex;
  final bool isActiveColumn;
  final List<EditableItem> items;
  final Function(String) onAdd;
  final Function(int, String) onUpdate;
  final Function(int)? onDelete;
  final Function(int, bool)? onCheckChanged;
  final Function(int, int)? onReorder;
  final Widget? header;
  final VoidCallback? onBack;
  final bool showDeleteButton;
  final VoidCallback? onNavigateLeft;
  final VoidCallback? onNavigateRight;
  final String? editingItemId;
  final Function(int, String)? onNotesUpdate;
  final VoidCallback? onExitEdit;
  final bool showCompleted;
  final VoidCallback? onToggleShowCompleted;
  final Function(int)? onAiStatusChanged;

  const EditableColumn({
    super.key,
    required this.title,
    this.backgroundColor = Colors.white,
    this.onItemSelected,
    this.selectedIndex,
    this.isActiveColumn = false,
    required this.items,
    required this.onAdd,
    required this.onUpdate,
    this.onDelete,
    this.onCheckChanged,
    this.onReorder,
    this.header,
    this.onBack,
    this.showDeleteButton = false,
    this.onNavigateLeft,
    this.onNavigateRight,
    this.editingItemId,
    this.onNotesUpdate,
    this.onExitEdit,
    this.showCompleted = true,
    this.onToggleShowCompleted,
    this.onAiStatusChanged,
  });

  @override
  State<EditableColumn> createState() => _EditableColumnState();
}

class _EditableColumnState extends State<EditableColumn> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _addNewItem() {
    widget.onAdd("");
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      debugLabel: "EditableColumn_${widget.title}",
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          debugPrint("Key Event (${widget.title}): ${event.logicalKey.debugName} | isActive: ${widget.isActiveColumn} | editing: ${widget.editingItemId}");
        }
        if (event is KeyDownEvent && widget.isActiveColumn && widget.editingItemId == null) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft && widget.onNavigateLeft != null) {
            widget.onNavigateLeft!();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowRight && widget.onNavigateRight != null) {
            widget.onNavigateRight!();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.space) {
            Actions.invoke(context, AddNewItemIntent());
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () {
           _focusNode.requestFocus();
           if (widget.onItemSelected != null && widget.selectedIndex != null) {
              widget.onItemSelected!(widget.selectedIndex!);
           }
        },
        child: Container(
          color: widget.backgroundColor,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (Title + Add)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 40, 20, 20),
              child: Row(
                children: [
                  if (widget.onBack != null)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      onPressed: widget.onBack,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  if (widget.onBack != null) const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: widget.isActiveColumn ? Colors.black : Colors.grey[600],
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.onToggleShowCompleted != null)
                    IconButton(
                      key: ValueKey('${widget.title.toLowerCase()}_archive_btn'),
                      icon: Icon(
                        widget.showCompleted ? Icons.visibility : Icons.visibility_off,
                        color: widget.showCompleted ? Colors.grey[600] : Colors.blue[600],
                      ),
                      onPressed: widget.onToggleShowCompleted,
                      tooltip: widget.showCompleted ? 'Hide Completed' : 'Show Completed',
                    ),
                  IconButton(
                    key: ValueKey('${widget.title.toLowerCase()}_add_btn'),
                    icon: Icon(Icons.add_circle, color: Colors.blue[600]),
                    onPressed: _addNewItem,
                    tooltip: 'Add Item',
                  ),
                ],
              ),
            ),
            
            // Custom Header Widget
            if (widget.header != null)
               Padding(
                 padding: const EdgeInsets.only(left: 12, right: 12, bottom: 4),
                 child: widget.header!,
               ),
  
    // List
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: widget.items.length,
                onReorder: (oldIndex, newIndex) {
                   widget.onReorder?.call(oldIndex, newIndex);
                },
                proxyDecorator: (child, index, animation) {
                  return Material(
                    elevation: 0,
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  );
                },
                buildDefaultDragHandles: false, // We use custom handles
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  final isSelected = widget.selectedIndex == index;
                  final isEditing = widget.editingItemId == item.id;
  
                  return EditableItemWidget(
                      key: ValueKey(item.id),
                      item: item,
                      index: index,
                      isSelected: isSelected,
                      isActiveColumn: widget.isActiveColumn,
                      isEditing: isEditing,
                      onChanged: (val) => widget.onUpdate(index, val),
                      onNotesChanged: (val) => widget.onNotesUpdate?.call(index, val),
                      onTap: () => widget.onItemSelected?.call(index),
                      onSubmitted: _addNewItem,
                      onToggleCheck: () => widget.onCheckChanged?.call(index, !item.isCompleted),
                      onToggleAiStatus: widget.onAiStatusChanged != null 
                          ? () => widget.onAiStatusChanged?.call(index)
                          : null,
                      onDelete: () => widget.onDelete?.call(index),
                      onExitEdit: widget.onExitEdit,
                      showDeleteButton: widget.showDeleteButton,
                      onNavigateLeft: widget.onNavigateLeft,
                      onNavigateRight: widget.onNavigateRight,
                  );
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
