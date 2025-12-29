import 'package:uuid/uuid.dart';

class ProposedAction {
  final String id;
  final String description;
  final String toolName;
  final Map<String, dynamic> toolArgs;
  bool isExecuted;

  ProposedAction({
    required this.description,
    required this.toolName,
    required this.toolArgs,
    this.isExecuted = false,
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
    String? id,
    DateTime? timestamp,
  }) : id = id ?? const Uuid().v4(), timestamp = timestamp ?? DateTime.now();
}

class Knowledge {
  final String id;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Knowledge({
    required this.content,
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(), 
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Knowledge copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Knowledge(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}




