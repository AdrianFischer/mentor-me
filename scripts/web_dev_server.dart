import 'dart:io';
import 'dart:convert';
import 'dart:async';

void main() async {
  print('Starting Flutter Web Server on port 3000...');
  print('Working directory: ${Directory.current.path}');

  // 1. Launch flutter run -d web-server --web-port=3000
  var process = await Process.start(
    'flutter',
    ['run', '-d', 'web-server', '--web-port=3000'],
    runInShell: true,
    workingDirectory: 'app',
  );

  // Stream stdout and stderr
  process.stdout.transform(utf8.decoder).listen((data) {
    stdout.write(data);
  });
  process.stderr.transform(utf8.decoder).listen((data) {
    stderr.write(data);
  });

  // 2. Watch app/lib/ for changes to trigger Hot Restart
  var libDir = Directory('app/lib');
  if (await libDir.exists()) {
    print('Watching lib/ directory for changes...');
    
    // Simple debounce to avoid multiple restarts for a single save
    Timer? debounceTimer;
    
    libDir.watch(recursive: true).listen((event) {
      if (event.path.endsWith('.dart')) {
        if (debounceTimer?.isActive ?? false) debounceTimer!.cancel();
        
        debounceTimer = Timer(Duration(milliseconds: 500), () {
          print('\nChange detected in ${event.path}. Triggering Hot Restart (R)...');
          process.stdin.write('R');
        });
      }
    });
  } else {
    print('Warning: lib/ directory not found. Hot Restart watch disabled.');
  }

  // Handle exit
  var exitCode = await process.exitCode;
  print('Flutter process exited with code $exitCode');
  exit(exitCode);
}
