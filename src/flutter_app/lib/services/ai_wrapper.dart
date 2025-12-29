import 'package:firebase_ai/firebase_ai.dart';

// Simple data wrapper for response to allow mocking/instantiation
class AIResponse {
  final String? text;
  final List<FunctionCall> functionCalls;
  final Content? rawModelContent;

  AIResponse({this.text, this.functionCalls = const [], this.rawModelContent});
}

// Wrapper interface for Chat Session
abstract class ChatSessionWrapper {
  Future<AIResponse> sendMessage(Content content);
  List<Content> get history;
}

// Wrapper interface for Generative Model
abstract class AIModelWrapper {
  ChatSessionWrapper startChat({List<Content>? history});
}

// --- Firebase Implementation ---

class FirebaseAIModelWrapper implements AIModelWrapper {
  final GenerativeModel _model;

  FirebaseAIModelWrapper(this._model);

  @override
  ChatSessionWrapper startChat({List<Content>? history}) {
    return FirebaseChatSessionWrapper(_model.startChat(history: history));
  }
}

class FirebaseChatSessionWrapper implements ChatSessionWrapper {
  final ChatSession _chat;

  FirebaseChatSessionWrapper(this._chat);

  @override
  List<Content> get history => _chat.history.toList();

  @override
  Future<AIResponse> sendMessage(Content content) async {
    final response = await _chat.sendMessage(content);
    return AIResponse(
      text: response.text,
      functionCalls: response.functionCalls.toList(),
      rawModelContent: response.candidates.isNotEmpty ? response.candidates.first.content : null,
    );
  }
}