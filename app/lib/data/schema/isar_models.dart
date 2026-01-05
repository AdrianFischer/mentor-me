import 'package:isar/isar.dart';

part 'isar_models.g.dart';

@collection
class IsarProject {
  Id? id;

  @Index(unique: true, replace: true)
  late String originalId;

  late String title;
  
  double order = 0.0;
  
  List<String> tags = [];

  String? notes;

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

  List<String> tags = [];

  String? notes;

  String aiStatus = 'notReady';

  List<IsarSubtask> subtasks = [];

  IsarTaskGoal? goal;
}

@embedded
class IsarSubtask {
  late String originalId;
  late String title;
  bool isCompleted = false;
  double order = 0.0;
  List<String> tags = [];
  String? notes;
  String aiStatus = 'notReady';
}

@embedded
class IsarTaskGoal {
  late String type; // "numeric" or "habit"
  
  // Numeric
  double? numericTarget;
  double? numericCurrent;
  String? numericUnit;
  List<IsarGoalTransaction> transactions = [];

  // Habit
  double? habitTargetFrequency;
  List<IsarHabitRecord> habitHistory = [];
}

@embedded
class IsarGoalTransaction {
  late String id;
  late double amount;
  late DateTime date;
  String? note;
}

@embedded
class IsarHabitRecord {
  late DateTime date;
  late bool isSuccess;
  String? note;
}


@collection
class IsarConversation {
  Id? id;

  @Index(unique: true, replace: true)
  late String originalId;

  late String title;

  late DateTime lastModified;

  String? notes;
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