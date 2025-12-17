import 'package:isar/isar.dart';

part 'isar_models.g.dart';

@collection
class IsarProject {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String originalId;

  late String title;
  
  double order = 0.0;

  final tasks = IsarLinks<IsarTask>();
}

@collection
class IsarTask {
  Id id = Isar.autoIncrement;

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
class IsarChatMessage {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String originalId;

  late String text;
  
  bool isUser = false;
  
  late DateTime timestamp;
  
  // "assistant" or "mentor"
  @Index()
  late String mode; 
}

@collection
class IsarKnowledge {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String originalId;

  late String content;
  
  late DateTime createdAt;
  late DateTime updatedAt;
}