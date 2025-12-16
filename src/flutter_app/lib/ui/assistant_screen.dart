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
                _buildConversationHeader(assistant),
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
                // Pending Actions Section
                if (assistant.pendingActions.isNotEmpty) ...[
                  _buildHeader("Review Actions (${assistant.pendingActions.length})"),
                  Flexible(
                    flex: 1,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: assistant.pendingActions.length,
                      itemBuilder: (context, index) {
                        return _buildActionCard(context, assistant, assistant.pendingActions[index]);
                      },
                    ),
                  ),
                ],

                // Executed Actions Section
                _buildHeader("Action Log"),
                Expanded(
                  flex: 2,
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

  Widget _buildConversationHeader(AssistantService assistant) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
               Icon(
                 assistant.isMentorMode ? Icons.school : Icons.assistant,
                 color: assistant.isMentorMode ? Colors.deepPurple : Colors.blue,
               ),
               const SizedBox(width: 8),
               Text(
                assistant.isMentorMode ? "Mentor Mode" : "Assistant Mode",
                style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16,
                    color: assistant.isMentorMode ? Colors.deepPurple : Colors.blue,
                ),
              ),
            ],
          ),
          Row(
            children: [
                const Text("Assistant", style: TextStyle(fontSize: 12)),
                Switch(
                  value: assistant.isMentorMode,
                  onChanged: (val) => assistant.toggleMode(),
                  activeColor: Colors.deepPurple,
                  activeTrackColor: Colors.deepPurple.shade100,
                  inactiveThumbColor: Colors.blue,
                  inactiveTrackColor: Colors.blue.shade100,
                ),
                const Text("Mentor", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                const SizedBox(width: 8),
                if (assistant.isMentorMode) 
                  IconButton(
                    icon: Icon(
                      assistant.isVoiceEnabled ? Icons.volume_up : Icons.volume_off, 
                      size: 20, 
                      color: assistant.isVoiceEnabled ? Colors.deepPurple : Colors.grey
                    ),
                    tooltip: 'Toggle Voice Response',
                    onPressed: () => assistant.toggleVoice(),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                  tooltip: 'Clear History',
                  onPressed: () {
                    showDialog(
                      context: context, 
                      builder: (ctx) => AlertDialog(
                        title: Text("Clear ${assistant.isMentorMode ? 'Mentor' : 'Assistant'} History?"),
                        content: const Text("This action cannot be undone."),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                          TextButton(
                            onPressed: () {
                              assistant.clearHistory();
                              Navigator.pop(ctx);
                            }, 
                            child: const Text("Clear", style: TextStyle(color: Colors.red))
                          ),
                        ],
                      )
                    );
                  },
                ),
            ],
          ),
        ],
      ),
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

  Widget _buildActionCard(BuildContext context, AssistantService assistant, ProposedAction action) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade300, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pending_actions, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  "REVIEW: ${action.toolName.replaceAll('_', ' ').toUpperCase()}",
                  style: const TextStyle(
                    fontSize: 10, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.orange
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              action.description,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => assistant.declineAction(action),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text("Decline"),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    print("[VERIFY_FLOW] UI Interaction: User accepted action ${action.toolName}");
                    assistant.acceptAction(action);
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text("Accept"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

