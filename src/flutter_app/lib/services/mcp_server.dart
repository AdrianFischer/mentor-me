import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';
import 'data_service.dart';
import '../models/models.dart';
import '../models/ai_models.dart';

class McpServerService {
  final DataService _dataService;
  HttpServer? _server;

  McpServerService(this._dataService);

  Future<void> start({int port = 8081, int retries = 5}) async {
    if (_server != null) return;

    final router = Router();

    // --- Projects ---
    router.get('/projects', (Request request) async {
      try {
        final projects = _dataService.projects;
        // Manually map to ensure deep conversion, avoiding implicit serialization issues
        final jsonList = projects.map((p) {
                       final pJson = p.toJson();
                       pJson['order'] = p.order.isNaN ? 0.0 : p.order; // Handle NaN
                       // Explicitly convert nested tasks to ensure they are Maps, not Objects
                       if (pJson['tasks'] is List) {
                          pJson['tasks'] = (pJson['tasks'] as List).map((t) {
                            final tJson = (t as dynamic).toJson();
                            tJson['order'] = t.order.isNaN ? 0.0 : t.order; // Handle NaN
                            if (tJson['subtasks'] is List) {
                              tJson['subtasks'] = (tJson['subtasks'] as List).map((s) {
                                final sJson = (s as dynamic).toJson();
                                sJson['order'] = s.order.isNaN ? 0.0 : s.order; // Handle NaN
                                return sJson;
                              }).toList();
                            }
                            return tJson; 
                          }).toList();
                       }          return pJson;
        }).toList();
        return Response.ok(jsonEncode(jsonList), headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response.internalServerError(body: 'Error fetching projects: $e');
      }
    });

    router.post('/projects', (Request request) async {
      try {
        final content = await request.readAsString();
        final json = jsonDecode(content);
        final project = Project.fromJson(json);
        _dataService.upsertProject(project);
        return Response.ok(jsonEncode({'status': 'success', 'id': project.id}), headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response.internalServerError(body: 'Error saving project: $e');
      }
    });

    // --- Tasks ---
    router.get('/tasks', (Request request) async {
       try {
         final projects = _dataService.projects;
         final allTasks = projects.expand((p) => p.tasks).toList();
         return Response.ok(jsonEncode(allTasks.map((t) => t.toJson()).toList()), headers: {'content-type': 'application/json'});
       } catch (e) {
         return Response.internalServerError(body: 'Error fetching tasks: $e');
       }
    });

    router.post('/tasks', (Request request) async {
      try {
        final content = await request.readAsString();
        final json = jsonDecode(content);
        
        // Handle simplified input (create ID if missing)
        String id = json['id'] ?? const Uuid().v4();
        String title = json['title'] ?? '';
        String? projectId = json['projectId'];
        bool isCompleted = json['isCompleted'] ?? false;
        
        // Check if we need to create a full Task object manually
        // or if we can use Task.fromJson if the structure matches.
        // For robustness, we construct it manually if simplified keys are present.
        final task = Task(
          id: id, 
          title: title, 
          projectId: projectId, 
          isCompleted: isCompleted,
          subtasks: [] // default empty for new task
        );

        _dataService.upsertTask(task);
        return Response.ok(jsonEncode({'status': 'success', 'id': task.id}), headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response.internalServerError(body: 'Error saving task: $e');
      }
    });
    
    router.post('/tasks/<taskId>/subtasks', (Request request, String taskId) async {
      try {
        final content = await request.readAsString();
        final json = jsonDecode(content);
        final title = json['title'];
        
        if (title == null || title.isEmpty) {
           return Response.badRequest(body: 'Title is required');
        }

        final subtaskId = _dataService.addSubtask(taskId, title);
        
        if (subtaskId == null) {
           return Response.notFound('Task with ID $taskId not found');
        }
        
        return Response.ok(jsonEncode({'status': 'success', 'id': subtaskId}), headers: {'content-type': 'application/json'});

      } catch (e) {
        return Response.internalServerError(body: 'Error adding subtask: $e');
      }
    });

    router.delete('/tasks/<id>', (Request request, String id) async {
      try {
        _dataService.deleteItem(id);
        return Response.ok(jsonEncode({'status': 'deleted', 'id': id}), headers: {'content-type': 'application/json'});
      } catch (e) {
         return Response.internalServerError(body: 'Error deleting task: $e');
      }
    });

    router.post('/items/<itemId>/status', (Request request, String itemId) async {
      try {
        final content = await request.readAsString();
        final json = jsonDecode(content);
        final isCompleted = json['isCompleted'];

        if (isCompleted == null || !(isCompleted is bool)) {
           return Response.badRequest(body: '"isCompleted" boolean field is required');
        }

        _dataService.setItemStatus(itemId, isCompleted);
        return Response.ok(jsonEncode({'status': 'success', 'id': itemId, 'isCompleted': isCompleted}), headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response.internalServerError(body: 'Error updating item status: $e');
      }
    });

    // --- Knowledge ---
    router.get('/knowledge', (Request request) async {
      try {
        final knowledge = await _dataService.getAllKnowledge();
        final list = knowledge.map((k) => {
          'id': k.id,
          'content': k.content,
          'createdAt': k.createdAt.toIso8601String(),
          'updatedAt': k.updatedAt.toIso8601String(),
        }).toList();
        return Response.ok(jsonEncode(list), headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response.internalServerError(body: 'Error fetching knowledge: $e');
      }
    });

    // --- MCP Discovery ---
    router.get('/mcp/tools', (Request request) {
      final tools = [
        {
          'name': 'get_projects',
          'description': 'Get all projects and their tasks',
          'parameters': {'type': 'object', 'properties': {}}
        },
        {
          'name': 'add_task',
          'description': 'Add a new task',
          'parameters': {
            'type': 'object',
            'properties': {
              'title': {'type': 'string'},
              'projectId': {'type': 'string', 'description': 'Optional Project ID'}
            },
            'required': ['title']
          }
        },
        {
          'name': 'add_subtask',
          'description': 'Add a new subtask to a specific task',
          'parameters': {
            'type': 'object',
            'properties': {
              'taskId': {'type': 'string', 'description': 'ID of the parent task'},
              'title': {'type': 'string', 'description': 'Title of the subtask'}
            },
            'required': ['taskId', 'title']
          }
        },
        {
          'name': 'update_item_status',
          'description': 'Update the completion status of a project, task, or subtask.',
          'parameters': {
            'type': 'object',
            'properties': {
              'itemId': {'type': 'string', 'description': 'The ID of the item (project, task, or subtask) to update.'},
              'isCompleted': {'type': 'boolean', 'description': 'The new completion status.'}
            },
            'required': ['itemId', 'isCompleted']
          }
        },
        {
           'name': 'get_knowledge',
           'description': 'Get all knowledge items',
           'parameters': {'type': 'object', 'properties': {}}
        }
      ];
      return Response.ok(jsonEncode(tools), headers: {'content-type': 'application/json'});
    });

    final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router.call);

    for (var i = 0; i < retries; i++) {
      try {
        _server = await HttpServer.bind(InternetAddress.anyIPv4, port + i, shared: true);
        shelf_io.serveRequests(_server!, handler);
        print('MCP Server listening on http://${_server!.address.host}:${_server!.port}');
        return; // Success, exit
      } on SocketException catch (e) {
        if (i < retries - 1) {
          print('Failed to start MCP Server on port ${port + i}: $e. Retrying on next port...');
        } else {
          print('Failed to start MCP Server after $retries attempts: $e');
          rethrow; // Re-throw if all retries fail
        }
      } catch (e) {
        print('Failed to start MCP Server: $e');
        rethrow;
      }
    }
  }

  Future<void> restart({int port = 8081, int retries = 5}) async {
    await stop();
    await start(port: port, retries: retries);
  }

  Future<void> stop() async {
    await _server?.close();
    _server = null;
  }
}
