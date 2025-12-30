import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/app.dart';
import 'package:flutter_app/services/data_service.dart';
import 'package:flutter_app/providers/data_provider.dart';
import 'package:mocktail/mocktail.dart'; import 'dart:async';

import 'package:flutter_app/data/repository/storage_repository.dart';
import 'package:flutter_app/models/models.dart';
import 'package:flutter_app/models/ai_models.dart';
import 'package:flutter_app/services/markdown_persistence_service.dart';
import 'package:flutter_app/ui/widgets/editable_column.dart';
import 'package:flutter_app/ui/widgets/editable_item_widget.dart';
import 'package:flutter_app/services/mcp_server.dart';
import 'package:flutter_app/providers/mcp_provider.dart';
import 'helpers/fake_storage_repository.dart';

class MockMcpServerService extends Mock implements McpServerService {
  @override
  Future<void> start({int? port, int? retries}) async {}

  @override
  Future<void> stop() async {}
}

class MockMarkdownPersistence extends Mock implements MarkdownPersistenceService {
    @override
    bool get isEnabled => false;
    
    @override
    Future<void> saveTask(Task t, Project p) async {}
}

void main() {
  testWidgets('Right Arrow navigation focuses new task', (WidgetTester tester) async {
    // Setup
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockStorage = FakeStorageRepository(initialProjects: [
      Project(id: 'p_test_A', title: 'Project A'),
    ]);

    final mockMarkdown = MockMarkdownPersistence();
    final dataService = DataService(mockStorage, mockMarkdown);
    await dataService.initData();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Provide the pre-seeded DataService
          dataServiceProvider.overrideWith((ref) => dataService),
          mcpServerProvider.overrideWith((ref) => MockMcpServerService()),
        ],
        child: MyApp(initialSelectedProjectId: 'p_test_A', initialIsAssistantActive: false),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Select the project "Project A"
    final projectItemFinder = find.byElementPredicate(
      (element) => element.widget is EditableItemWidget && element.widget.key == const ValueKey('p_test_A'),
    );
    expect(projectItemFinder, findsOneWidget);

    await tester.tap(projectItemFinder);
    await tester.pumpAndSettle();

    // Verify Project TextField has focus
    final projectTextFieldFinder = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.controller?.text == 'Project A',
    );
    expect(projectTextFieldFinder, findsOneWidget);
    
    // Ensure cursor is at the end for Right Arrow navigation
    final textField = tester.widget<TextField>(projectTextFieldFinder);
    textField.controller!.selection = TextSelection.fromPosition(
      TextPosition(offset: textField.controller!.text.length)
    );
    await tester.pump();

    final projectField = tester.widget<TextField>(projectTextFieldFinder);
    expect(projectField.focusNode!.hasFocus, isTrue, reason: "Project A should be focused");

    // 2. Press Right Arrow
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump(); 
    await tester.pump(const Duration(milliseconds: 60)); 
    await tester.pumpAndSettle();

    // 3. Verify New Task Created
    expect(dataService.projects.first.tasks, isNotEmpty);
    final newTask = dataService.projects.first.tasks.first;
    expect(newTask.title, isEmpty); 

    // 4. Verify Focus Moved to New Task
    final taskFinder = find.descendant(
        of: find.byType(EditableColumn).at(1), 
        matching: find.byType(TextField)
    );
    expect(taskFinder, findsOneWidget);
    
    final taskField = tester.widget<TextField>(taskFinder);
    expect(taskField.focusNode!.hasFocus, isTrue, reason: "New Task should be focused");
    
    // 5. Verify Project lost focus
    expect(projectField.focusNode!.hasFocus, isFalse, reason: "Project A should lose focus");
  });
}