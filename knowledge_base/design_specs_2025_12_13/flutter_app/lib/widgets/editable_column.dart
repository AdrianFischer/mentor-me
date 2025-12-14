import 'package:flutter/material.dart';

class EditableColumn extends StatefulWidget {
  final String title;
  final Color backgroundColor;
  final ValueChanged<int>? onItemSelected;
  final int? selectedIndex;
  final bool isActiveColumn;

  const EditableColumn({
    super.key,
    required this.title,
    this.backgroundColor = Colors.white,
    this.onItemSelected,
    this.selectedIndex,
    this.isActiveColumn = false,
  });

  @override
  State<EditableColumn> createState() => _EditableColumnState();
}

class _EditableColumnState extends State<EditableColumn> {
  final List<TextEditingController> _controllers = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 5; i++) {
      _controllers.add(TextEditingController(text: "${widget.title} Item ${i + 1}"));
    }
    _controllers.add(TextEditingController());
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _addNewItem() {
    setState(() {
      _controllers.add(TextEditingController());
    });
    // ... scroll logic ...
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        border: widget.isActiveColumn 
            ? Border.all(color: Colors.blue.withOpacity(0.5), width: 2)
            : null,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.isActiveColumn ? Colors.blue : Colors.black,
                  ),
                ),
                // ...
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _controllers.length,
              itemBuilder: (context, index) {
                final isSelected = widget.selectedIndex == index;
                // Highlight logic:
                // - Active selection (focused column): Strong blue
                // - Inactive selection (parent column): Grey/Light Blue
                final borderColor = isSelected 
                    ? (widget.isActiveColumn ? Colors.blue : Colors.grey)
                    : Colors.transparent;
                
                return GestureDetector(
                  onTap: () => widget.onItemSelected?.call(index),
                  child: Card(
                    elevation: isSelected ? 2 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: borderColor, width: 2),
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: TextField(
                        controller: _controllers[index],
                        enabled: widget.isActiveColumn, // Only editable if column is active? Or always?
                        // Let's keep it always enabled for mouse, but keyboard nav relies on focus logic.
                        // Actually, for arrow navigation to work, we might need to NOT have the TextField focused
                        // capturing the arrow keys.
                        // We set readOnly based on selection to force focus handling?
                        // For now, let's keep it simple.
                        decoration: const InputDecoration(border: InputBorder.none),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
