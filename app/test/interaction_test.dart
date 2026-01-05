import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/app.dart';
import 'package:flutter_app/ui/widgets/editable_item_widget.dart';
import 'package:flutter_app/data/repository/storage_repository.dart';
import 'package:flutter_app/models/models.dart';
import 'package:flutter_app/models/ai_models.dart';
import 'package:flutter_app/providers/data_provider.dart';
import 'package:flutter_app/ui/assistant_screen.dart'; // assistantServiceProvider
import 'package:flutter_app/services/assistant_service.dart';
import 'package:flutter_app/services/mcp_server.dart';
import 'package:flutter_app/providers/mcp_provider.dart';
import 'package:flutter_app/providers/ai_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'helpers/fake_storage_repository.dart';
import 'helpers/mock_assistant_service.dart';

class MockMcpServerService extends Mock implements McpServerService {
  @override
  Future<void> start({int? port, int? retries}) async {}

  @override
  Future<void> stop() async {}
}

void main() {
  testWidgets('Navigation, Typing, and Checkbox Toggle Test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(2000, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeRepository = FakeStorageRepository(initialProjects: [
        Project(id: 'p1', title: 'Inbox'),
    ]);
    final mockAssistant = MockAssistantService();
    
    // 1. Build App
    await tester.pumpWidget(ProviderScope(
      overrides: [
        storageRepositoryProvider.overrideWithValue(fakeRepository),
        internalAgentProvider.overrideWith((ref) => mockAssistant),
        mcpServerProvider.overrideWith((ref) => MockMcpServerService()),
      ],
      child: const MyApp()
    ));
    await tester.pumpAndSettle();
    
    // Navigate to Inbox
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // Assistant
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // Inbox
    await tester.pumpAndSettle();
    
    expect(find.text("Inbox"), findsOneWidget);
    
    // Navigate Right to Tasks
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    
    expect(find.text("Tasks"), findsOneWidget);
    
    // Create a task
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    
    await tester.enterText(find.byType(TextField).last, "My New Task");
    await tester.pumpAndSettle();
    
    expect(find.text("My New Task"), findsOneWidget);
    
    // Toggle checkbox
    // Find the task item widget first
    final taskItemFinder = find.byWidgetPredicate(
      (widget) => widget is EditableItemWidget && widget.item.text == "My New Task"
    );
    expect(taskItemFinder, findsOneWidget);

    // Find the checkbox gesture detector within it. 
    // The main widget has a GestureDetector, and the checkbox has one.
    // The checkbox is inside the Row.
    final gestureDetectors = find.descendant(
      of: taskItemFinder,
      matching: find.byType(GestureDetector)
    );
    
    // We expect at least 2: 1 for item tap, 1 for checkbox.
    // The structure is EditableItemWidget -> Container -> GestureDetector(main) -> ... -> GestureDetector(checkbox)
    // So both are descendants.
    // We want the inner one (checkbox).
    final checkbox = gestureDetectors.last; 
    
    await tester.tap(checkbox);
    await tester.pumpAndSettle();
    
    // Verify checked (Icon check appears)
    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}