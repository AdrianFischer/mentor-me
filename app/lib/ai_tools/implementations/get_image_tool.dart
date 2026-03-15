import 'dart:convert';
import 'dart:io';
import '../ai_tool.dart';

class GetImageTool implements AiTool {
  @override
  String get name => 'get_image_data';

  @override
  String get description => 'Reads a local image file and returns its base64 encoded data.';

  @override
  String describeAction(Map<String, dynamic> args) {
    return "Reading image ${args['path']}";
  }

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'path': { 'type': 'string', 'description': 'The absolute local path to the image file.' }
    },
    'required': ['path']
  };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args, ToolContext context) async {
    try {
      final String path = args['path'];
      final file = File(path);

      if (!await file.exists()) {
        return {
          'result': 'error',
          'message': 'File not found at $path'
        };
      }

      final bytes = await file.readAsBytes();
      final base64Data = base64Encode(bytes);

      return {
        'result': 'success',
        'media': {
          'imageBase64': base64Data,
          'mimeType': 'image/jpeg'
        }
      };
    } catch (e) {
      return {
        'result': 'error',
        'message': 'Failed to read image: $e'
      };
    }
  }
}
