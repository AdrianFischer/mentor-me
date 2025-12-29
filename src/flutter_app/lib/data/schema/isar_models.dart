import 'package:isar/isar.dart';

part 'isar_models.g.dart';

@collection
class IsarProject {
  Id? id;

  @Index(unique: true, replace: true)
  late String originalId;

  late String title;
  
  double order = 0.0;

  final tasks = IsarLinks<IsarTask>();
}

@collection
class IsarTask {
  Id? id;

  @Index(unique: true, replace: true)
  late String originalId;

  late String title;

  bool isCompleted = false;
  
  double order = 0.0;

  String? projectId;

  List<IsarSubtask> subtasks = [];
}

@embedded
class IsarSubtask {
  late String originalId;
  late String title;
  bool isCompleted = false;
  double order = 0.0;
}

@collection
class IsarConversation {
  Id? id;

  @Index(unique: true, replace: true)
  late String originalId;

  late String title;

  late DateTime lastModified;
}

@collection
class IsarChatMessage {
  Id? id;

  @Index(unique: true, replace: true)
  late String originalId;

  late String text;
  
  bool isUser = false;
  
  late DateTime timestamp;
  
  // "assistant" or "mentor" (Legacy support, though arguably redundant with conversationId)
  @Index()
  late String mode; 

  @Index()
  String? conversationId;
}

@collection
class IsarKnowledge {
  Id? id;

  @Index(unique: true, replace: true)
  late String originalId;

  late String content;
  
  late DateTime createdAt;
  late DateTime updatedAt;
}