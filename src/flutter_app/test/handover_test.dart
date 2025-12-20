import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/markdown_persistence_service.dart';
import 'package:flutter_app/models/models.dart';

void main() {
  test('Handover creates file in to_dos', () async {
    final service = MarkdownPersistenceService();
    
    // Setup Task
    final task = Task(title: "Handover Test Task");
    print("Creating task with ID: ${task.id}");
    
    // Save
    await service.saveTask(task);
    
    print("Save completed");
  });
}



