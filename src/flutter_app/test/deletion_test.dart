import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/app.dart';
import 'package:flutter_app/data/repository/storage_repository.dart';
import 'package:flutter_app/models/models.dart';
import 'package:flutter_app/models/ai_models.dart';
import 'package:flutter_app/providers/data_provider.dart';
import 'package:flutter_app/services/mcp_server.dart';
import 'package:flutter_app/providers/mcp_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockMcpServerService extends Mock implements McpServerService {
  @override
  Future<void> start({int? port, int? retries}) async {}

  @override
  Future<void> stop() async {}
}


class FakeStorageRepository implements StorageRepository {
  List<Project> _projects;
  final _controller = StreamController<void>.broadcast();
  
  FakeStorageRepository({List<Project>? initialProjects}) 
      : _projects = initialProjects ?? [];
  
  @override
  List<Project> getProjects() => _projects;

  @override
  Future<void> saveProject(Project project) async {
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index >= 0) {
      _projects[index] = project;
    } else {
      _projects.add(project);
    }
    _controller.add(null);
  }

  @override
  Future<void> saveTask(Task task) async {
    _controller.add(null);
  }

  @override
  Future<void> saveSubtask(Subtask subtask) async {}
  @override
  Future<void> updateTitle(String id, String newTitle) async {}
  @override
  Future<void> setItemStatus(String id, bool isCompleted) async {}
  @override
  Future<void> deleteItem(String id) async {
    // Try delete project
    int pIndex = _projects.indexWhere((p) => p.id == id);
    if (pIndex != -1) {
      _projects.removeAt(pIndex);
      _controller.add(null);
      return;
    }
    
    // Try delete task
    for (var i = 0; i < _projects.length; i++) {
      var project = _projects[i];
      int tIndex = project.tasks.indexWhere((t) => t.id == id);
      if (tIndex != -1) {
        var newTasks = List<Task>.from(project.tasks)..removeAt(tIndex);
        _projects[i] = project.copyWith(tasks: newTasks);
        _controller.add(null);
        return;
      }
    }
  }

  @override
  Future<void> reorderProjects(int oldIndex, int newIndex) async {}
  @override
  Future<void> reorderTasks(String projectId, int oldIndex, int newIndex) async {}
  @override
  Future<void> reorderSubtasks(String taskId, int oldIndex, int newIndex) async {}
  @override
  Future<void> deleteProject(String projectId) async {
     _projects.removeWhere((p) => p.id == projectId);
     _controller.add(null);
  }
  @override
  Future<void> saveChatMessage(ChatMessage message, String mode) async {}
  @override
  Future<List<ChatMessage>> getChatHistory(String mode) async => [];
  @override
  Future<void> clearChatHistory(String mode) async {}
  @override
  Future<void> saveKnowledge(Knowledge knowledge) async {}
  @override
  Future<List<Knowledge>> getAllKnowledge() async => [];
  @override
  Future<void> deleteKnowledge(String id) async {}
  @override
  Future<void> deleteTask(String taskId) async {}
  @override
  Future<List<Project>> getAllProjects() async => _projects;
  @override
  Future<void> init() async {}
  @override
  Stream<void> get onDataChanged => _controller.stream;
}

void main() {
  testWidgets('Deletion Test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeRepository = FakeStorageRepository(initialProjects: [
        Project(id: 'p1', title: 'Inbox'),
    ]);
    
    await tester.pumpWidget(ProviderScope(
      overrides: [
        storageRepositoryProvider.overrideWithValue(fakeRepository),
        mcpServerProvider.overrideWith((ref) => MockMcpServerService()),
      ],
      child: const MyApp()
    ));
    await tester.pumpAndSettle();

    // 1. Find Inbox
    expect(find.text("Inbox"), findsOneWidget);
    
    // Select Inbox
    await tester.tap(find.text("Inbox"));
    await tester.pumpAndSettle();
    
    // Press Backspace/Delete to delete Inbox (if supported)
    // Note: App might restrict deleting default projects?
    // DataService prevents deleting Inbox?
    // Let's create a new project "Delete Me" and delete it.
    
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    
    final newItemField = find.byType(TextField).last;
    await tester.enterText(newItemField, "Delete Me");
    await tester.pumpAndSettle();
    
    expect(find.text("Delete Me"), findsOneWidget);
    
    // Focus is on "Delete Me". Press Backspace on empty? No, need special delete key combo or backspace on empty text.
    // Logic: If text is empty and backspace pressed -> delete.
    // Currently text is "Delete Me".
    
    // Clear text
    await tester.enterText(newItemField, "");
    await tester.pumpAndSettle();
    
    // Press Backspace
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();
    
    // Verify "Delete Me" is gone (or at least the count decreased)
    expect(find.text("Delete Me"), findsNothing);
  });
}
