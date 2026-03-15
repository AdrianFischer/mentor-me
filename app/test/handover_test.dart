import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/file_system_service.dart';
import 'package:flutter_app/models/node.dart';

void main() {
  test('Handover creates file in to_dos', () async {
    final tempDir = await Directory.systemTemp.createTemp('handover_test');
    final service = FileSystemService(baseDir: tempDir.path);

    // Setup Node
    final node = Node(
      id: 'p1',
      title: 'Test Project',
      children: [
        Node(id: 't1', title: 'New Task', isCompleted: false, parentId: 'p1'),
      ],
    );

    await service.saveNode(node);

    final file = File('${tempDir.path}/todos/unsorted/test_project.md');

    // Verify file creation
    expect(await file.exists(), isTrue);

    // Cleanup
    await tempDir.delete(recursive: true);
  });
}
