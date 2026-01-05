import 'dart:async';
import 'package:flutter/material.dart';
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
  Future<void> deleteItem(String id) async {}
  @override
  Future<void> reorderProjects(int oldIndex, int newIndex) async {}
  @override
  Future<void> reorderTasks(String projectId, int oldIndex, int newIndex) async {}
  @override
  Future<void> reorderSubtasks(String taskId, int oldIndex, int newIndex) async {}
  @override
  Future<void> deleteProject(String projectId) async {}
    @override
    Future<void> saveConversation(Conversation conversation) async {}
  
    @override
    Future<List<Conversation>> getAllConversations() async => [];
  
    @override
    Future<void> deleteConversation(String conversationId) async {}
  
    @override
    Future<void> saveChatMessage(ChatMessage message, String mode) async {}
  
    @override
    Future<List<ChatMessage>> getChatHistory(String mode, {String? conversationId}) async => [];
  
    @override
    Future<void> clearChatHistory(String mode, {String? conversationId}) async {}
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
  testWidgets('App smoke test', (WidgetTester tester) async {
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

    // Verify initial state
    expect(find.text('Projects'), findsOneWidget);
    
    // Check for "Select a Project" - this text might be conditional on selection
    // If we have projects (DataService creates defaults), first one might be auto-selected?
    // Actually MyApp logic usually auto-selects first project if available?
    // Let's check finding "Inbox".
    expect(find.text("Inbox"), findsOneWidget);
    
    // Tap Inbox
    await tester.tap(find.text("Inbox"));
    await tester.pumpAndSettle();
    
    // Verify Tasks column appears (it should be visible if project selected)
    expect(find.text('Tasks'), findsOneWidget);
    
    // Add a task to verify interaction
    await tester.enterText(find.byType(TextField).last, "New Smoke Task");
    await tester.pumpAndSettle();
    expect(find.text("New Smoke Task"), findsOneWidget);
  });
}