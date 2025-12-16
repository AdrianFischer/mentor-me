import 'dart:async'; // Add import
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DebugOverlay extends StatefulWidget {
  final Widget child;
  
  const DebugOverlay({super.key, required this.child});

  @override
  State<DebugOverlay> createState() => _DebugOverlayState();
}

class _DebugOverlayState extends State<DebugOverlay> {
  bool _isVisible = false;
  String _lastKeyEvent = "None";
  String _currentFocus = "Unknown";
  Timer? _focusTimer; // Timer handle

  @override
  void initState() {
    super.initState();
    // Periodically poll focus
    _focusTimer = Timer.periodic(const Duration(milliseconds: 500), (_) => _pollFocus());
  }
  
  @override
  void dispose() {
    _focusTimer?.cancel();
    super.dispose();
  }

  void _pollFocus() {
    if (mounted) {
      final focusNode = FocusManager.instance.primaryFocus;
      setState(() {
        _currentFocus = focusNode?.debugLabel ?? focusNode.toString();
      });
    }
  }

  void _toggleOverlay() {
    setState(() {
      _isVisible = !_isVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main App Content
        KeyboardListener(
          focusNode: FocusNode(), 
          onKeyEvent: (event) {
            if (event is KeyDownEvent) {
              setState(() {
                _lastKeyEvent = "${event.logicalKey.keyLabel} (${event.logicalKey.keyId})";
              });
              // Toggle on Ctrl+Backtick or similar if needed, 
              // but for agents, we might just want it always visible or toggled via button.
            }
          },
          child: widget.child
        ),

        // Floating Action Button to Toggle
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.small(
            backgroundColor: Colors.redAccent,
            child: const Icon(Icons.bug_report),
            onPressed: _toggleOverlay,
          ),
        ),

        // Overlay Content
        if (_isVisible)
          Positioned(
            bottom: 70,
            right: 16,
            child: Material(
              elevation: 4,
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "DEBUG OVERLAY",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const Divider(color: Colors.white24),
                    _buildInfoRow("Focus:", _currentFocus),
                    _buildInfoRow("Last Key:", _lastKeyEvent),
                    _buildInfoRow("Seed:", Uri.base.queryParameters['seed'] ?? "None"),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("$label ", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Flexible(
            child: Text(
              value, 
              style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontFamily: 'Courier'),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

