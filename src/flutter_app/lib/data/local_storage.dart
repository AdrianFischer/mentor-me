import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

class StorageService {
  final String _fileName = 'app_data.json';
  
  // Optional: Allow injecting a directory for testing purposes
  final Directory? _fixedDirectory;

  StorageService({Directory? fixedDirectory}) : _fixedDirectory = fixedDirectory;

  Future<File> get _file async {
    final directory = _fixedDirectory ?? await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  Future<List<Project>> loadProjects() async {
    try {
      final file = await _file;
      if (!await file.exists()) {
        return [];
      }

      final content = await file.readAsString();
      if (content.isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((json) => Project.fromJson(json)).toList();
    } catch (e) {
      // In a real app, might want to log this or rethrow
      print('Error loading projects: $e');
      return [];
    }
  }

  Future<void> saveProjects(List<Project> projects) async {
    try {
      final file = await _file;
      final jsonList = projects.map((p) => p.toJson()).toList();
      // Use pretty print for easier debugging/inspection if needed, 
      // but standard jsonEncode is leaner. 
      // Let's use standard for now.
      final content = jsonEncode(jsonList);
      await file.writeAsString(content);
    } catch (e) {
      print('Error saving projects: $e');
    }
  }
}




