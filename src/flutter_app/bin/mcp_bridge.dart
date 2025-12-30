import 'dart:async';
import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  // Default URL or from args
  final baseUrl = args.isNotEmpty ? args[0] : 'http://localhost:8081/mcp';
  
  stderr.writeln('[Bridge] Connecting to $baseUrl...');

  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(baseUrl));
    request.headers.set('Accept', 'text/event-stream');
    
    final response = await request.close();
    if (response.statusCode != 200) {
      stderr.writeln('[Bridge] Failed to connect: ${response.statusCode}');
      exit(1);
    }

    String? postEndpoint;
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
        } else if (currentEvent == 'message') {
           // Write to Stdout for Cursor to read
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
    stdin.transform(utf8.decoder).transform(const LineSplitter()).listen((line) async {
       if (postEndpoint == null) {
         // Buffer or warn? Warn for now.
         stderr.writeln('[Bridge] Warning: Received input before endpoint discovery.');
         return;
       }
       
       if (line.trim().isEmpty) return;

       // POST to App
       try {
         // Resolve endpoint against base
         final uri = Uri.parse(baseUrl).resolve(postEndpoint!);
         final postReq = await client.postUrl(uri);
         postReq.headers.contentType = ContentType.json;
         postReq.write(line);
         
         final postRes = await postReq.close();
         if (postRes.statusCode != 202) {
             // 202 Accepted is expected for JSON-RPC
             // Read error body if any
            final body = await postRes.transform(utf8.decoder).join();
            stderr.writeln('[Bridge] POST Failed: ${postRes.statusCode} - $body');
         } else {
             // Success, drain response to avoid leak
             await postRes.drain();
         }
       } catch (e) {
         stderr.writeln('[Bridge] POST Error: $e');
       }
    });

  } catch (e) {
    stderr.writeln('[Bridge] Fatal Error: $e');
    exit(1);
  }
}
