import 'dart:convert';
import 'dart:typed_data';
import '../../services/data_service.dart';
import '../ai_tool.dart';

class UploadImageTool implements AiTool {
  @override
  String get name => 'upload_image';

  @override
  String get description => 'Saves an image received as base64 to local storage and returns the absolute path.';

  @override
  String describeAction(Map<String, dynamic> args) {
    return "Saving image ${args['filename']}";
  }

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'base64': { 'type': 'string', 'description': 'The base64 encoded image data.' },
      'filename': { 'type': 'string', 'description': 'Preferred filename (e.g. receipt.jpg).' }
    },
    'required': ['base64', 'filename']
  };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args, DataService dataService) async {
    try {
      final String base64Data = args['base64'];
      final String filename = args['filename'];
      
      final bytes = base64Decode(base64Data);
      final path = await dataService.saveImageArtifact(Uint8List.fromList(bytes), filename);
      
      return {
        'result': 'success',
        'path': path,
        'message': 'Image saved successfully at $path'
      };
    } catch (e) {
      return {
        'result': 'error',
        'message': 'Failed to save image: $e'
      };
    }
  }
}
