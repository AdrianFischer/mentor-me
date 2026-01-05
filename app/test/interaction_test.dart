import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/app.dart';
import 'package:flutter_app/ui/widgets/editable_column.dart';
import 'package:flutter_app/ui/widgets/editable_item_widget.dart';
import 'package:flutter_app/ui/actions/selection_actions.dart';
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

    // Ensure root focus
    Focus.of(tester.element(find.byKey(const ValueKey('rootFocus')))).requestFocus();
    await tester.pumpAndSettle();
    
    // Navigate to Inbox
    await tester.tap(find.text("Inbox"));
    await tester.pumpAndSettle();
    
    expect(find.text("Inbox"), findsOneWidget);
    
    // Navigate Right to Tasks (Auto-creates task if empty)
    await tester.runAsync(() async {
      Actions.invoke(
        tester.element(find.byKey(const ValueKey('rootFocus'))),
        const ChangeColumnIntent(1)
      );
    });
    for (int i=0; i<10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    
    expect(find.text("Tasks"), findsOneWidget);
    
    // Item should already be created and in edit mode due to auto-create on nav
    // Find the TextField (title is first)
    final titleField = find.descendant(
      of: find.ancestor(of: find.text('Tasks'), matching: find.byType(EditableColumn)),
      matching: find.byType(TextField)
    ).first;
    
    await tester.enterText(titleField, "My New Task");
    await tester.pumpAndSettle();
    
    expect(find.text("My New Task"), findsOneWidget);
    
    // Toggle checkbox
    // Find the task item widget first
    final taskItemFinder = find.byWidgetPredicate(
      (widget) => widget is EditableItemWidget && widget.item.text == "My New Task"
    );
    expect(taskItemFinder, findsOneWidget);

    // Escape to exit edit mode before tapping checkbox
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
  });
}