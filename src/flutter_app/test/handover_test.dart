import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/markdown_persistence_service.dart';
import 'package:flutter_app/models/models.dart';

void main() {
  test('Handover creates file in to_dos', () async {
    final tempDir = await Directory.systemTemp.createTemp('handover_test');
    final service = MarkdownPersistenceService(baseDir: tempDir.path);
    
    // Setup Task
    final project = Project(id: 'p_handover', title: 'Handover Project');
    final task = Task(id: 't_handover', title: "Handover Test Task");
    
    // Simulate handover
    await service.saveTask(task, project);
    
    // Verify file creation
    final todoDir = Directory('${tempDir.path}/to_dos');
    expect(await todoDir.exists(), isTrue);
    final files = await todoDir.list().toList();
    expect(files, isNotEmpty);
    
    // Cleanup
    await tempDir.delete(recursive: true);
  });
}