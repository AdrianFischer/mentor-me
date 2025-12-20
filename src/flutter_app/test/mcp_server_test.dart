import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_app/data/repository/storage_repository.dart';
import 'package:flutter_app/models/models.dart';
import 'package:flutter_app/models/ai_models.dart';
import 'package:flutter_app/services/mcp_server.dart';
import 'package:flutter_app/services/data_service.dart';

class MockDataService extends Mock implements DataService {}

void main() {
  late MockDataService mockDataService;
  late McpServerService serverService;
  final int port = 8099; 

  setUp(() {
    mockDataService = MockDataService();
    serverService = McpServerService(mockDataService);
    registerFallbackValue(const Task(id: 'fallback', title: 'fallback'));
    registerFallbackValue(const Project(id: 'fallback', title: 'fallback'));
  });

  tearDown(() async {
    await serverService.stop();
  });

  test('GET /projects returns projects list', () async {
    // Arrange
    final project = Project(id: 'p1', title: 'Project 1', tasks: []);
    when(() => mockDataService.projects).thenReturn([project]);

    // Act
    await serverService.start(port: port);
    
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://localhost:$port/projects'));
    final response = await request.close();
    final content = await response.transform(utf8.decoder).join();

    // Assert
    expect(response.statusCode, 200);
    final json = jsonDecode(content);
    expect(json, isA<List>());
    expect(json[0]['id'], 'p1');
    expect(json[0]['title'], 'Project 1');
  });

  test('POST /tasks saves a task', () async {
    // Arrange
    // upsertTask returns void
    
    // Act
    await serverService.start(port: port);
    
    final client = HttpClient();
    final request = await client.postUrl(Uri.parse('http://localhost:$port/tasks'));
    request.write(jsonEncode({
      'id': 't1',
      'title': 'Task 1',
      'isCompleted': false,
      'projectId': 'p1'
    }));
    final response = await request.close();

    // Assert
    expect(response.statusCode, 200);
    verify(() => mockDataService.upsertTask(any())).called(1);
  });
  
  test('POST /tasks saves a task with simplified input (no ID)', () async {
    // Arrange
    
    // Act
    await serverService.start(port: port);
    
    final client = HttpClient();
    final request = await client.postUrl(Uri.parse('http://localhost:$port/tasks'));
    request.write(jsonEncode({
      'title': 'Task 2',
      'projectId': 'p1'
    }));
    final response = await request.close();
    final content = await response.transform(utf8.decoder).join();

    // Assert
    expect(response.statusCode, 200);
    final json = jsonDecode(content);
    expect(json['status'], 'success');
    expect(json['id'], isNotNull);
    
    verify(() => mockDataService.upsertTask(any(that: predicate<Task>((t) => t.title == 'Task 2' && t.projectId == 'p1')))).called(1);
  });

  test('POST /tasks/<taskId>/subtasks adds a subtask', () async {
    // Arrange
    when(() => mockDataService.addSubtask('t1', 'Subtask 1')).thenReturn('s1');

    // Act
    await serverService.start(port: port);
    
    final client = HttpClient();
    final request = await client.postUrl(Uri.parse('http://localhost:$port/tasks/t1/subtasks'));
    request.write(jsonEncode({
      'title': 'Subtask 1'
    }));
    final response = await request.close();
    final content = await response.transform(utf8.decoder).join();

    // Assert
    expect(response.statusCode, 200);
    final json = jsonDecode(content);
    expect(json['status'], 'success');
    expect(json['id'], 's1');

    verify(() => mockDataService.addSubtask('t1', 'Subtask 1')).called(1);
  });
  
  test('GET /mcp/tools returns tools list', () async {
    // Act
    await serverService.start(port: port);
    
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://localhost:$port/mcp/tools'));
    final response = await request.close();
    final content = await response.transform(utf8.decoder).join();

    // Assert
    expect(response.statusCode, 200);
    final json = jsonDecode(content);
    expect(json, isA<List>());
    expect(json.any((t) => t['name'] == 'add_task'), isTrue);
  });
}
