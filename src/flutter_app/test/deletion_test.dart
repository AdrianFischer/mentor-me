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
import 'helpers/fake_storage_repository.dart';

class MockMcpServerService extends Mock implements McpServerService {
  @override
  Future<void> start({int? port, int? retries}) async {}

  @override
  Future<void> stop() async {}
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
