import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/telemetry_data.dart';
import 'package:flutter_app/ui/widgets/telemetry_dashboard.dart';

void main() {
  group('Test 19: Routine Integration Telemetry Test', () {
    late File tempFile;
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('telemetry_test');
      tempFile = File('${tempDir.path}/telemetry.json');

      final mockData = [
        {
          "routine": "Mock Routine 1",
          "timestamp": "2026-03-12T08:21:02.596Z",
          "total_tokens": 1000
        },
        {
          "routine": "Mock Routine 2",
          "timestamp": "2026-03-12T08:26:21.251Z",
          "total_tokens": 2000,
          "log_file": "/tmp/mock.log"
        }
      ];

      tempFile.writeAsStringSync(jsonEncode(mockData));
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('TelemetryData parses correctly', () {
      final content = tempFile.readAsStringSync();
      final List<dynamic> jsonList = jsonDecode(content);
      final List<TelemetryData> telemetryList = jsonList.map((j) => TelemetryData.fromJson(j)).toList();

      expect(telemetryList.length, 2);
      expect(telemetryList[0].routine, 'Mock Routine 1');
      expect(telemetryList[0].totalTokens, 1000);
      expect(telemetryList[0].logFile, isNull);

      expect(telemetryList[1].routine, 'Mock Routine 2');
      expect(telemetryList[1].totalTokens, 2000);
      expect(telemetryList[1].logFile, '/tmp/mock.log');
    });

    testWidgets('Dashboard correctly displays token usage metrics', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TelemetryDashboard(telemetryFilePath: tempFile.path),
        ),
      ));

      // Wait for future to complete
      while (tester.any(find.byType(CircularProgressIndicator))) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pump();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Total Tokens: 3000'), findsOneWidget);
      expect(find.text('Mock Routine 1'), findsOneWidget);
      expect(find.text('Mock Routine 2'), findsOneWidget);
      expect(find.text('1000 tokens'), findsOneWidget);
      expect(find.text('2000 tokens'), findsOneWidget);
    });
  });
}
