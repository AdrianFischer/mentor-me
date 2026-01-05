import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/app.dart';
import 'helpers/fake_storage_repository.dart';
import 'package:flutter_app/models/models.dart';
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
    expect(find.text("Inbox"), findsOneWidget);
    
    // Tap Inbox
    await tester.tap(find.text("Inbox"));
    await tester.pumpAndSettle();
    
    // Verify Tasks column appears
    expect(find.text('Tasks'), findsOneWidget);
    
    // Tap the Add button for Tasks column
    await tester.tap(find.byKey(const ValueKey('tasks_add_btn')));
    await tester.pumpAndSettle();

    // Add a task to verify interaction
    final textFieldFinder = find.byType(TextField).last;
    expect(textFieldFinder, findsOneWidget);
    await tester.enterText(textFieldFinder, "New Smoke Task");
    await tester.pumpAndSettle();
    expect(find.text("New Smoke Task"), findsOneWidget);
  });
}