import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_ai/firebase_ai.dart';
import '../services/ai_agent.dart';
import '../services/assistant_service.dart';
import '../models/ai_models.dart';
import 'knowledge_screen.dart';
import '../providers/ai_provider.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  final bool isMobile;
  final String conversationId;
  const AssistantScreen({super.key, this.isMobile = false, required this.conversationId});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadConversation();
    
    // Auto-focus the input field when Assistant Screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(AssistantScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId) {
      _loadConversation();
    }
  }

  void _loadConversation() {
    // Schedule loading to next frame to avoid notifying during build
    Future.microtask(() {
      if (!mounted) return;
      final assistant = ref.read(activeAgentProvider);
      assistant.loadConversation(widget.conversationId).then((_) {
         // Restore draft if any
         if (mounted) {
           _textController.text = assistant.draftMessage;
         }
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit(AiAgent assistant) {
    if (_textController.text.isNotEmpty) {
      print("[VERIFY_FLOW] UI Submit: ${_textController.text}");
      assistant.sendMessage(_textController.text);
      _textController.clear();
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final assistant = ref.watch(activeAgentProvider);

    return ListenableBuilder(
      listenable: assistant,
      builder: (context, child) {
        return Scaffold( // Use scaffold to ensure overlay context if needed, or Container
          body: Stack(
            children: [
              // Main Chat Area
              Column(
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

              // Action Log Overlay (Top Right)
              if (assistant.pendingActions.isNotEmpty || assistant.executedActions.isNotEmpty)
                Positioned(
                  top: 60, // Below header
                  right: 16,
                  width: 350,
                  bottom: 100, // Above input
                  child: PointerInterceptor( // Only intercept clicks on cards, let clicks through gaps pass? 
                    // Actually Flutter Stack passes clicks through transparent areas by default.
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (assistant.pendingActions.isNotEmpty)
                          ...assistant.pendingActions.where((a) => !a.isExecuted).map((a) => _buildActionOverlayCard(assistant, a)),
                        
                        // Show recently executed actions (limit to last 3 for overlay cleanliness?)
                        if (assistant.executedActions.isNotEmpty)
                           ...assistant.executedActions.reversed.take(3).map((a) => _buildLogOverlayCard(a)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildConversationHeader(AiAgent assistant) {
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
                 assistant.isThinkingMode ? Icons.lightbulb : Icons.lightbulb_outline,
                 color: assistant.isThinkingMode ? Colors.amber[700] : Colors.blueGrey,
               ),
               const SizedBox(width: 8),
               if (!widget.isMobile)
                 Text(
                  assistant.isThinkingMode ? "Thinking Mode" : "Standard Mode",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 16,
                      color: assistant.isThinkingMode ? Colors.amber[700] : Colors.blueGrey,
                  ),
                ),
            ],
          ),
          Row(
            children: [
                if (!widget.isMobile) ...[
                  const Text("Standard", style: TextStyle(fontSize: 12)),
                  Switch(
                    value: assistant.isThinkingMode,
                    onChanged: (val) => assistant.toggleThinking(),
                    activeColor: Colors.amber[700],
                    activeTrackColor: Colors.amber[100],
                    inactiveThumbColor: Colors.blueGrey,
                    inactiveTrackColor: Colors.blueGrey.shade100,
                  ),
                  Text("Thinking", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber[700])),
                ] else
                  IconButton(
                    icon: Icon(
                      assistant.isThinkingMode ? Icons.lightbulb : Icons.lightbulb_outline,
                      color: assistant.isThinkingMode ? Colors.amber[700] : Colors.blueGrey,
                      size: 20,
                    ),
                    onPressed: () => assistant.toggleThinking(),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    assistant.isVoiceEnabled ? Icons.volume_up : Icons.volume_off, 
                    size: 20, 
                    color: assistant.isVoiceEnabled ? Colors.amber[700] : Colors.grey
                  ),
                  tooltip: 'Toggle Voice Response',
                  onPressed: () => assistant.toggleVoice(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.psychology, size: 20, color: Colors.grey),
                  tooltip: 'Manage Knowledge',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const KnowledgeScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                  tooltip: 'Clear History',
                  onPressed: () {
                    showDialog(
                      context: context, 
                      builder: (ctx) => AlertDialog(
                        title: const Text("Clear Conversation?"),
                        content: const Text("This will delete all messages in this conversation."),
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

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 600), // Limit width for readability
        decoration: BoxDecoration(
          color: msg.isUser ? Colors.blue.shade100 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SelectableText(msg.text),
      ),
    );
  }

  Widget _buildInputArea(AiAgent assistant) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey, width: 0.2)),
        color: Colors.white,
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

  Widget _buildLogOverlayCard(ProposedAction action) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.green.shade200),
      ),
      color: Colors.white.withOpacity(0.95),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 4),
            Text(
              action.description,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionOverlayCard(AiAgent assistant, ProposedAction action) {
    return Card(
      key: ValueKey(action.id),
      elevation: 6,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.orange, width: 1.5),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
              style: const TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
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

// Dummy widget for PointerInterceptor if not using a web package
// In Flutter Web, this handles clicks passing through overlays.
// On Mobile/Desktop, standard Stack usually works fine for this simple layout.
class PointerInterceptor extends StatelessWidget {
  final Widget child;
  const PointerInterceptor({super.key, required this.child});
  @override
  Widget build(BuildContext context) => child;
}
