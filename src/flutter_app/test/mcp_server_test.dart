import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_app/data/repository/storage_repository.dart';
import 'package:flutter_app/models/models.dart';
import 'package:flutter_app/models/ai_models.dart';
import 'package:flutter_app/services/mcp_server.dart';

class MockStorageRepository extends Mock implements StorageRepository {}

void main() {
  late MockStorageRepository mockRepository;
  late McpServerService serverService;
  final int port = 8099; 

  setUp(() {
    mockRepository = MockStorageRepository();
    serverService = McpServerService(mockRepository);
    registerFallbackValue(const Task(id: 'fallback', title: 'fallback'));
  });

  tearDown(() async {
    await serverService.stop();
  });

  test('GET /projects returns projects list', () async {
    // Arrange
    final project = Project(id: 'p1', title: 'Project 1', tasks: []);
    when(() => mockRepository.getAllProjects()).thenAnswer((_) async => [project]);

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
    when(() => mockRepository.saveTask(any())).thenAnswer((_) async => {});

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
    verify(() => mockRepository.saveTask(any())).called(1);
  });
  
  test('POST /tasks saves a task with simplified input (no ID)', () async {
    // Arrange
    when(() => mockRepository.saveTask(any())).thenAnswer((_) async => {});

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
    
    verify(() => mockRepository.saveTask(any(that: predicate<Task>((t) => t.title == 'Task 2' && t.projectId == 'p1')))).called(1);
  });

  test('POST /tasks/<taskId>/subtasks adds a subtask', () async {
    // Arrange
    final existingTask = Task(id: 't1', title: 'Task 1', projectId: 'p1');
    final project = Project(id: 'p1', title: 'Project 1', tasks: [existingTask]);
    
    when(() => mockRepository.getAllProjects()).thenAnswer((_) async => [project]);
    when(() => mockRepository.saveTask(any())).thenAnswer((_) async => {});

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
    expect(json['id'], isNotNull);

    verify(() => mockRepository.saveTask(any(that: predicate<Task>((t) {
      return t.id == 't1' && t.subtasks.length == 1 && t.subtasks.first.title == 'Subtask 1';
    })))).called(1);
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
