import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import '../data/repository/storage_repository.dart';
import '../models/models.dart';
import '../models/ai_models.dart';

class McpServerService {
  final StorageRepository _repository;
  HttpServer? _server;

  McpServerService(this._repository);

  Future<void> start({int port = 8081}) async {
    if (_server != null) return;

    final router = Router();

    // --- Projects ---
    router.get('/projects', (Request request) async {
      try {
        final projects = await _repository.getAllProjects();
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
        await _repository.saveProject(project);
        return Response.ok(jsonEncode({'status': 'success', 'id': project.id}), headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response.internalServerError(body: 'Error saving project: $e');
      }
    });

    // --- Tasks ---
    router.get('/tasks', (Request request) async {
       try {
         final projects = await _repository.getAllProjects();
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
        final task = Task.fromJson(json);
        await _repository.saveTask(task);
        return Response.ok(jsonEncode({'status': 'success', 'id': task.id}), headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response.internalServerError(body: 'Error saving task: $e');
      }
    });

    router.delete('/tasks/<id>', (Request request, String id) async {
      try {
        await _repository.deleteTask(id);
        return Response.ok(jsonEncode({'status': 'deleted', 'id': id}), headers: {'content-type': 'application/json'});
      } catch (e) {
         return Response.internalServerError(body: 'Error deleting task: $e');
      }
    });

    // --- Knowledge ---
    router.get('/knowledge', (Request request) async {
      try {
        final knowledge = await _repository.getAllKnowledge();
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

    try {
        _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
        print('MCP Server listening on http://${_server!.address.host}:${_server!.port}');
    } catch (e) {
        print('Failed to start MCP Server: $e');
    }
  }

  Future<void> stop() async {
    await _server?.close();
  }
}
