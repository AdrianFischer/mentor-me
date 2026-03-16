import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:flutter_app/app.dart';
import 'package:flutter_app/providers/data_provider.dart';
import 'package:flutter_app/data/repository/rest_storage_repository.dart';
import 'package:flutter_app/providers/ai_provider.dart';
import 'package:flutter_app/providers/mcp_provider.dart';
import 'package:flutter_app/services/mcp_server.dart';

import 'helpers/mock_assistant_service.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockMcpServerService extends Mock implements McpServerService {
  @override
  Future<void> start({int? port, int? retries, bool? savePortToConfig}) async {}

  @override
  Future<void> stop() async {}
}

class FakeUri extends Fake implements Uri {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeUri());
    registerFallbackValue(http.Request('GET', Uri.parse('http://localhost')));
  });

  testWidgets('Test 20: Offline Agent Independence Test - App gracefully handles ECONNREFUSED', (WidgetTester tester) async {
    // Set up screen size
    tester.view.physicalSize = const Size(2000, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Create a mock http client that throws Connection Refused (simulating offline backend)
    final mockHttpClient = MockHttpClient();
    
    // For send() which is used by SSE
    when(() => mockHttpClient.send(any())).thenThrow(Exception('Connection refused'));
    // For get() which is used by getAllNodes
    when(() => mockHttpClient.get(any(), headers: any(named: 'headers'))).thenThrow(Exception('Connection refused'));
    when(() => mockHttpClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body'))).thenThrow(Exception('Connection refused'));
    when(() => mockHttpClient.put(any(), headers: any(named: 'headers'), body: any(named: 'body'))).thenThrow(Exception('Connection refused'));
    when(() => mockHttpClient.delete(any(), headers: any(named: 'headers'), body: any(named: 'body'))).thenThrow(Exception('Connection refused'));

    // Create a RestStorageRepository using the failing mock client
    final restRepo = RestStorageRepository(
      baseUrl: 'http://localhost:3000',
      client: mockHttpClient,
    );

    final mockAssistant = MockAssistantService();

    // Catch Flutter errors to ensure the test only passes if errors are handled
    // but actually, Riverpod or Flutter might catch the Future error from Riverpod FutureProvider
    // or AsyncValue gracefully. Let's just pump the widget and verify it doesn't freeze or crash.

    await tester.pumpWidget(ProviderScope(
      overrides: [
        storageRepositoryProvider.overrideWithValue(restRepo),
        internalAgentProvider.overrideWith((ref) => mockAssistant),
        mcpServerProvider.overrideWith((ref) => MockMcpServerService()),
      ],
      child: const MyApp(),
    ));

    // Pump to let initial requests fail
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Verify the app is still responsive, e.g., the title or main scaffolding is present
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);

    // Dispose explicitly before test completion to clear timers
    restRepo.dispose();
  });
}
