import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/app.dart';
import 'package:flutter_app/data/repository/storage_repository.dart';
import 'package:flutter_app/models/models.dart';
import 'package:flutter_app/providers/selection_provider.dart';
import 'package:flutter_app/services/mcp_server.dart';
import 'package:flutter_app/providers/mcp_provider.dart';
import 'package:flutter_app/providers/data_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'helpers/fake_storage_repository.dart';

class MockMcpServerService extends Mock implements McpServerService {
  @override
  Future<void> start({int? port, int? retries}) async {}

  @override
  Future<void> stop() async {}
}

void main() {
  testWidgets('Backspace Deletion: Delete middle item, focus moves up', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Setup: Projects [A, B, C]
    final fakeRepository = FakeStorageRepository(initialProjects: [
        Project(id: 'p1', title: 'A'),
        Project(id: 'p2', title: 'B'),
        Project(id: 'p3', title: 'C'),
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
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);

    final container = ProviderScope.containerOf(tester.element(find.byType(MyApp)));

    // Select 'B'
    await tester.tap(find.text('B'));
    await tester.pumpAndSettle();

    // Ensure 'B' is selected
    expect(container.read(selectionProvider).selectedProjectId, 'p2');

    // Enter Edit Mode by pressing Enter
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    // The spec says: "If an entry is currently selected and its content is empty, pressing Backspace MUST delete the entry."
    // First, let's clear the text of B to make it empty.
    
    final bTextField = find.widgetWithText(TextField, 'B');
    await tester.enterText(bTextField, '');
    await tester.pumpAndSettle();

    // Verify text is empty
    expect(find.text('B'), findsNothing); // Title is empty now

    // Press Backspace
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();

    // Verify 'B' is removed (p2 is gone)
    expect(fakeRepository.getProjects().any((p) => p.id == 'p2'), isFalse);
    
    // Verify 'A' (p1) is now selected (Focus moves up)
    expect(container.read(selectionProvider).selectedProjectId, 'p1');
  });

  testWidgets('Backspace Deletion: Delete first item, selection cleared', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Setup: Projects [A, B]
    final fakeRepository = FakeStorageRepository(initialProjects: [
        Project(id: 'p1', title: 'A'),
        Project(id: 'p2', title: 'B'),
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

    // Select 'A' (First item)
    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();
    
    expect(container.read(selectionProvider).selectedProjectId, 'p1');

    // Enter Edit Mode by pressing Enter
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    // Clear text of 'A'
    final aTextField = find.widgetWithText(TextField, 'A');
    await tester.enterText(aTextField, '');
    await tester.pumpAndSettle();

    // Press Backspace
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();

    // Verify 'A' is removed
    expect(fakeRepository.getProjects().any((p) => p.id == 'p1'), isFalse);

    // Verify Selection is CLEARED (Spec: "If the deleted entry was the first in the list, no item should be selected")
    expect(container.read(selectionProvider).selectedProjectId, isNull);
  });
}
