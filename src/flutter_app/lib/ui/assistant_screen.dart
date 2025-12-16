import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/assistant_service.dart';
import '../models/ai_models.dart';
import '../ai_tools/tool_registry.dart';
import '../providers/data_provider.dart';

// Provider definition
final assistantServiceProvider = ChangeNotifierProvider<AssistantService>((ref) {
  final dataService = ref.watch(dataServiceProvider);
  final registry = ToolRegistry(dataService);
  return AssistantService(dataService, registry);
});

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus the input field when Assistant Screen loads
    // Force rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit(AssistantService assistant) {
    if (_textController.text.isNotEmpty) {
      print("[VERIFY_FLOW] UI Submit: ${_textController.text}");
      assistant.sendMessage(_textController.text);
      _textController.clear();
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final assistant = ref.watch(assistantServiceProvider);

    return Row(
      children: [
        // Column 2: Conversation
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                _buildHeader("Conversation"),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: assistant.messages.length,
                    itemBuilder: (context, index) {
                      final msg = assistant.messages[index];
                      return _buildMessageBubble(msg);
                    },
                  ),
                ),
                if (assistant.isLoading)
                  const LinearProgressIndicator(minHeight: 2),
                _buildInputArea(assistant),
              ],
            ),
          ),
        ),
        
        // Vertical Divider
        const VerticalDivider(width: 1),

        // Column 3: Action History
        Expanded(
          flex: 1,
          child: Container(
            color: const Color(0xFFF5F5F7), // Light grey background
            child: Column(
              children: [
                _buildHeader("Action Log"),
                Expanded(
                  child: assistant.executedActions.isEmpty
                      ? const Center(
                          child: Text(
                            "No actions performed yet",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          reverse: true, // Show newest at bottom (or top? usually log is top-down, but chat is bottom-up. Let's do standard top-down for log)
                          itemCount: assistant.executedActions.length,
                          itemBuilder: (context, index) {
                            // Reverse index to show newest at top if we want, or just standard.
                            // Let's show newest at the top for visibility.
                            final reversedIndex = assistant.executedActions.length - 1 - index;
                            return _buildLogCard(
                              assistant.executedActions[reversedIndex]
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String title) {
    return Container(
      height: 50,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.2)),
      ),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: msg.isUser ? Colors.blue.shade100 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(msg.text),
      ),
    );
  }

  Widget _buildInputArea(AssistantService assistant) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey, width: 0.2)),
      ),
      child: Row(
        children: [
          FloatingActionButton.small(
            elevation: 0,
            backgroundColor: assistant.isListening ? Colors.red : Colors.blue,
            onPressed: () => assistant.toggleRecording(),
            child: Icon(assistant.isListening ? Icons.mic : Icons.mic_none),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: assistant.isListening
                ? Text(
                    assistant.currentSpeech.isEmpty 
                      ? "Listening..." 
                      : assistant.currentSpeech,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  )
                : TextField(
                    key: const ValueKey('assistant_input_field'),
                    controller: _textController,
                    focusNode: _focusNode,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _handleSubmit(assistant),
                  ),
          ),
          if (!assistant.isListening)
             IconButton(
               key: const ValueKey('assistant_send_btn'),
               icon: const Icon(Icons.send),
               color: Colors.blue,
               onPressed: () => _handleSubmit(assistant),
             ),
        ],
      ),
    );
  }

  Widget _buildLogCard(ProposedAction action) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.shade200), // Green border for success
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, size: 14, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  "EXECUTED: ${action.toolName.replaceAll('_', ' ').toUpperCase()}",
                  style: const TextStyle(
                    fontSize: 10, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.green
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              action.description,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // Legacy method kept if needed for reference, but unused in new UI
  // Widget _buildActionCard(BuildContext context, AssistantService assistant, ProposedAction action) {
  //   return Card(
  //     elevation: 0,
  //     margin: const EdgeInsets.only(bottom: 12),
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(12),
  //       side: BorderSide(color: Colors.grey.shade300),
  //     ),
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Row(
  //             children: [
  //               const Icon(Icons.auto_fix_high, size: 16, color: Colors.blue),
  //               const SizedBox(width: 8),
  //               Text(
  //                 action.toolName.replaceAll('_', ' ').toUpperCase(),
  //                 style: const TextStyle(
  //                   fontSize: 10, 
  //                   fontWeight: FontWeight.bold, 
  //                   color: Colors.blue
  //                 ),
  //               ),
  //             ],
  //           ),
  //           const SizedBox(height: 8),
  //           Text(
  //             action.description,
  //             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
  //           ),
  //           const SizedBox(height: 16),
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.end,
  //             children: [
  //               TextButton(
  //                 onPressed: () => assistant.declineAction(action),
  //                 style: TextButton.styleFrom(foregroundColor: Colors.red),
  //                 child: const Text("Decline"),
  //               ),
  //               const SizedBox(width: 8),
  //               ElevatedButton.icon(
  //                 onPressed: () {
  //                   print("[VERIFY_FLOW] UI Interaction: User accepted action ${action.toolName}");
  //                   assistant.acceptAction(action);
  //                 },
  //                 icon: const Icon(Icons.check, size: 16),
  //                 label: const Text("Accept"),
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: Colors.black,
  //                   foregroundColor: Colors.white,
  //                   elevation: 0,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}

