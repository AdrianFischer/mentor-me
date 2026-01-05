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
import 'package:flutter_app/providers/selection_provider.dart';
import 'package:flutter_app/services/mcp_server.dart';
import 'package:flutter_app/providers/mcp_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_app/ui/widgets/editable_column.dart';
import 'package:flutter_app/ui/widgets/editable_item_widget.dart'; // Import EditableItemWidget
import 'helpers/fake_storage_repository.dart';

class MockMcpServerService extends Mock implements McpServerService {
  @override
  Future<void> start({int? port, int? retries}) async {}

  @override
  Future<void> stop() async {}
}

void main() {
  testWidgets('Checked state persistence test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(2000, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeRepository = FakeStorageRepository(initialProjects: [
        Project(id: 'p1', title: 'Inbox'),
        Project(id: 'p2', title: 'Today'),
    ]);
    
    await tester.pumpWidget(ProviderScope(
      overrides: [
        storageRepositoryProvider.overrideWithValue(fakeRepository),
        mcpServerProvider.overrideWith((ref) => MockMcpServerService()),
      ],
      child: const MyApp()
    ));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(tester.element(find.byType(MyApp)));

    // Ensure root focus
    Focus.of(tester.element(find.byKey(const ValueKey('rootFocus')))).requestFocus();
    await tester.pumpAndSettle();

    // 2. Select "Inbox" Project
    container.read(selectionProvider.notifier).selectProject('p1');
    await tester.pumpAndSettle();

    // Create a task "Check Me"
    container.read(dataServiceProvider).addTask('p1', '').then((id) {
       if (id != null) {
          container.read(selectionProvider.notifier).selectTask(id);
          container.read(selectionProvider.notifier).setEditingItem(id);
       }
    });
    
    // Debug: show what's on screen
    debugPrint("--- WIDGET TREE ---");
    for (var widget in find.byType(EditableColumn).evaluate().map((e) => e.widget)) {
       debugPrint("Column Found: ${(widget as EditableColumn).title}");
    }
    
    // Wait for TextField to appear
    Finder? titleField;
    for (int i=0; i<50; i++) {
      final taskColumn = find.ancestor(of: find.text('Tasks'), matching: find.byType(EditableColumn));
      titleField = find.descendant(
        of: taskColumn,
        matching: find.byType(TextField)
      );
      if (titleField.evaluate().isNotEmpty) {
        titleField = titleField.first;
        break;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    
    if (titleField == null || titleField.evaluate().isEmpty) fail("Title TextField not found after clicking add");
    
    await tester.enterText(titleField, "Check Me");
    await tester.pumpAndSettle();
    
    // Explicitly select the task
    await tester.tap(find.text("Check Me"));
    await tester.pumpAndSettle();

    // Exit Edit Mode
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    // 3. Find the checkbox
    // Find the task item widget first
    final taskItemFinder = find.byWidgetPredicate(
      (widget) => widget is EditableItemWidget && widget.item.text == "Check Me"
    );
    expect(taskItemFinder, findsOneWidget);

    // Find the checkbox by key
    final checkbox = find.descendant(
      of: taskItemFinder,
      matching: find.byKey(const Key('item_checkbox'))
    );
    
    // 4. Tap the checkbox to check it
    await tester.tap(checkbox);
    await tester.pumpAndSettle();

    // Verify checked (Icon check appears)
    expect(find.byIcon(Icons.check), findsOneWidget);

    // 5. Navigate away to "Today" project
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();

    expect(find.text('Check Me'), findsNothing);

    // 6. Navigate back to "Inbox"
    await tester.tap(find.text('Inbox'));
    await tester.pumpAndSettle();

    // 7. Verify "Check Me" is still checked
    expect(find.text('Check Me'), findsOneWidget);
    // Re-find because widget tree rebuilt
    final taskItemFinderBack = find.byWidgetPredicate(
      (widget) => widget is EditableItemWidget && widget.item.text == "Check Me"
    );
    final gestureDetectorsBack = find.descendant(
      of: taskItemFinderBack,
      matching: find.byType(GestureDetector)
    );
    final checkboxFinderBack = gestureDetectorsBack.last;
    
    // Check if Icon(Icons.check) is descendant of this item
    expect(
      find.descendant(of: taskItemFinderBack, matching: find.byIcon(Icons.check)),
      findsOneWidget
    );
  });
}
