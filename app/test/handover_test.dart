import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/markdown_persistence_service.dart';
import 'package:flutter_app/models/models.dart';

void main() {
  test('Handover creates file in to_dos', () async {
    final tempDir = await Directory.systemTemp.createTemp('handover_test');
    final service = MarkdownPersistenceService(baseDir: tempDir.path);
    
    // Setup Task
    final task = Task(id: 't1', title: 'New Task', isCompleted: false);
    final project = Project(id: 'p1', title: 'Test Project', tasks: [task]);
    
    await service.saveProject(project);
    
    final file = File('${tempDir.path}/todos/unsorted/test_project.md');
    
    // Verify file creation
    expect(await file.exists(), isTrue);
    
    // Cleanup
    await tempDir.delete(recursive: true);
  });
}








