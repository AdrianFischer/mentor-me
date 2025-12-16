import 'package:uuid/uuid.dart';

class ProposedAction {
  final String id;
  final String description;
  final String toolName;
  final Map<String, dynamic> toolArgs;

  ProposedAction({
    required this.description,
    required this.toolName,
    required this.toolArgs,
  }) : id = const Uuid().v4();
}

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
  }) : id = const Uuid().v4(), timestamp = DateTime.now();
}




