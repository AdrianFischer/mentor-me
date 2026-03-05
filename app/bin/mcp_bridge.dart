import 'dart:async';
import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  String? baseUrl;

  // Try auto-discovery
  try {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null) {
      final portFile = File('$home/.assisted_intelligence/mcp_port');
      if (portFile.existsSync()) {
        final port = portFile.readAsStringSync().trim();
        baseUrl = 'http://localhost:$port/mcp';
        stderr.writeln('[Bridge] Auto-discovered server at $baseUrl');
      }
    }
  } catch (e) {
    stderr.writeln('[Bridge] Auto-discovery failed: $e');
  }

  // Fallback to args or default
  baseUrl ??= args.isNotEmpty ? args[0] : 'http://localhost:8081/mcp';
  
  stderr.writeln('[Bridge] Connecting to $baseUrl...');

  final client = HttpClient();
  String? postEndpoint;
  final List<String> pendingMessages = [];

  try {
    final request = await client.getUrl(Uri.parse(baseUrl));
    request.headers.set('Accept', 'text/event-stream');
    
    final response = await request.close();
    if (response.statusCode != 200) {
      stderr.writeln('[Bridge] Failed to connect: ${response.statusCode}');
      exit(1);
    }

    String? currentEvent;

    // Handle SSE Stream (Server -> Bridge -> Cursor)
    response.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      if (line.trim().isEmpty) {
        currentEvent = null;
        return;
      }
      
      if (line.startsWith('event: ')) {
        currentEvent = line.substring(7).trim();
      } else if (line.startsWith('data: ')) {
        final data = line.substring(6);
        if (currentEvent == 'endpoint') {
           postEndpoint = data.trim();
           stderr.writeln('[Bridge] Endpoint discovered: $postEndpoint');
           
           // Process buffered messages
           if (pendingMessages.isNotEmpty) {
             stderr.writeln('[Bridge] Processing ${pendingMessages.length} buffered messages.');
             for (final msg in pendingMessages) {
               _sendToApp(client, baseUrl!, postEndpoint!, msg);
             }
             pendingMessages.clear();
           }
        } else if (currentEvent == 'message') {
           stdout.writeln(data); 
        }
      }
    }, onError: (e) {
      stderr.writeln('[Bridge] SSE Error: $e');
      exit(1);
    }, onDone: () {
      stderr.writeln('[Bridge] Connection closed by server.');
      exit(0);
    });

    // Handle Stdin (Cursor -> Bridge -> Server)
    stdin.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
       if (line.trim().isEmpty) return;

       if (postEndpoint == null) {
         stderr.writeln('[Bridge] Buffering message until connection established.');
         pendingMessages.add(line);
         return;
       }
       
       _sendToApp(client, baseUrl!, postEndpoint!, line);
    });

  } catch (e) {
    stderr.writeln('[Bridge] Fatal Error: $e');
    exit(1);
  }
}

Future<void> _sendToApp(HttpClient client, String baseUrl, String endpoint, String message) async {
  try {
    // Ensure we don't double up /mcp/mcp
    Uri uri;
    if (endpoint.startsWith('http')) {
      uri = Uri.parse(endpoint);
    } else {
      final base = Uri.parse(baseUrl);
      // If endpoint starts with /, it's relative to host.
      // If not, it's relative to the path.
      uri = base.resolve(endpoint);
    }

    final postReq = await client.postUrl(uri);
    postReq.headers.contentType = ContentType.json;
    postReq.write(message);
    
    final postRes = await postReq.close();
    if (postRes.statusCode != 202 && postRes.statusCode != 200) {
       final body = await postRes.transform(utf8.decoder).join();
       stderr.writeln('[Bridge] POST Failed: ${postRes.statusCode} - $body');
    } else {
       await postRes.drain();
    }
  } catch (e) {
    stderr.writeln('[Bridge] POST Error: $e');
  }
}