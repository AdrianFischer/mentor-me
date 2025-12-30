import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_ai/firebase_ai.dart';
import '../ai_tools/tool_registry.dart';
import '../ai_tools/tool_definitions.dart';
import '../services/assistant_service.dart';
import '../services/mcp_agent_service.dart';
import '../services/ai_wrapper.dart';
import '../services/ai_agent.dart';
import 'data_provider.dart';
import 'mcp_provider.dart';

final toolRegistryProvider = Provider<ToolRegistry>((ref) {
  final dataService = ref.read(dataServiceProvider);
  return ToolRegistry(dataService);
});

// Helper to create model with tools
GenerativeModel _createGenerativeModel() {
  final List<FunctionDeclaration> validTools = ToolDefinitions.tools.map((t) {
      final properties = <String, Schema>{};
      final propsMap = t['parameters']['properties'] as Map;
      
      for (var entry in propsMap.entries) {
        final type = entry.value['type'];
        final description = entry.value['description'];
        
        if (type == 'integer') {
          properties[entry.key] = Schema.integer(description: description, nullable: false);
        } else if (type == 'boolean') {
          properties[entry.key] = Schema.boolean(description: description, nullable: false);
        } else {
          properties[entry.key] = Schema.string(description: description, nullable: false);
        }
      }

      return FunctionDeclaration(
        t['name'],
        t['description'],
        parameters: properties, 
      );
  }).toList();

  return FirebaseAI.vertexAI(location: 'us-central1').generativeModel(
    model: 'gemini-2.5-pro',
    tools: [Tool.functionDeclarations(validTools)],
  );
}

final internalAgentProvider = ChangeNotifierProvider<AssistantService>((ref) {
  final dataService = ref.read(dataServiceProvider);
  final registry = ref.watch(toolRegistryProvider);
  
  // Ensure MCP Client is active/connected
  ref.watch(mcpClientServiceProvider);

  // Create wrapper with real model
  final model = _createGenerativeModel();
  final wrapper = FirebaseAIModelWrapper(model);
  
  return AssistantService(dataService, registry, wrapper);
});

final mcpAgentProvider = ChangeNotifierProvider<McpAgentService>((ref) {
  final mcpClient = ref.watch(mcpClientServiceProvider);
  return McpAgentService(mcpClient);
});

// This provider controls which agent is currently active in the UI
// Defaults to internal agent. Can be overridden or changed via state.
final activeAgentProvider = Provider<AiAgent>((ref) {
  // Logic to switch agents could be added here (e.g. watch a state provider)
  // For now, return internal
  return ref.watch(internalAgentProvider);
});