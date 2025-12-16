import 'package:uuid/uuid.dart';

const uuid = Uuid();

class Subtask {
  final String id;
  String title;
  bool isCompleted;

  Subtask({
    String? id,
    required this.title,
    this.isCompleted = false,
  }) : id = id ?? uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
      };

  factory Subtask.fromJson(Map<String, dynamic> json) {
    return Subtask(
      id: json['id'],
      title: json['title'],
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}

class Task {
  final String id;
  String title;
  bool isCompleted;
  List<Subtask> subtasks;

  Task({
    String? id,
    required this.title,
    this.isCompleted = false,
    List<Subtask>? subtasks,
  })  : id = id ?? uuid.v4(),
        subtasks = subtasks ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
      };

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      isCompleted: json['isCompleted'] ?? false,
      subtasks: (json['subtasks'] as List<dynamic>?)
              ?.map((e) => Subtask.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class Project {
  final String id;
  String title;
  List<Task> tasks;

  Project({
    String? id,
    required this.title,
    List<Task>? tasks,
  })  : id = id ?? uuid.v4(),
        tasks = tasks ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'tasks': tasks.map((t) => t.toJson()).toList(),
      };

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      title: json['title'],
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((e) => Task.fromJson(e))
              .toList() ??
          [],
    );
  }
}
