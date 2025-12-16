import 'dart:io';
import 'dart:convert';
import 'dart:async';

Process? flutterProcess;
bool isRestarting = false;

void main(List<String> args) async {
  // Define paths
  final projectRoot = Directory.current.path;
  final appDirPath = args.isNotEmpty 
      ? args[0] 
      : 'src/flutter_app';
  final appDir = Directory('$projectRoot/$appDirPath');
  final libDir = Directory('${appDir.path}/lib');
  final testDir = Directory('${appDir.path}/test');
  final outputDir = Directory('$projectRoot/knowledge_base/design_specs_2025_12_13');

  if (!await appDir.exists()) {
    print('Error: App directory not found at ${appDir.path}');
    exit(1);
  }

  print('Starting Autonomous Flutter Pipeline...');
  print('App Directory: ${appDir.path}');

  // Start the process loop
  unawaited(_startFlutterLoop(appDir, projectRoot, outputDir));

  // Watchers setup (only once)
  print('Watching ${libDir.path} and ${testDir.path} for changes...');
  
  bool libChanged = false;
  bool testChanged = false;
  Timer? debounceTimer;

  void handleFileSystemEvent(FileSystemEvent event) {
    if (!event.path.endsWith('.dart')) return;
    
    // Determine source of change
    if (event.path.contains('/lib/')) {
      libChanged = true;
    } else if (event.path.contains('/test/')) {
      testChanged = true;
    }

    if (debounceTimer?.isActive ?? false) debounceTimer!.cancel();
    debounceTimer = Timer(const Duration(seconds: 2), () {
      if (libChanged) {
        print('🔄 Lib change detected. Reloading & Testing...');
        if (flutterProcess != null) {
          flutterProcess!.stdin.write('r');
          // Give reload a moment before testing
          Future.delayed(const Duration(seconds: 1), () => _runTests(appDir.path, projectRoot));
        } else {
           print('⚠️ Flutter process is down. Waiting for restart...');
        }
      } else if (testChanged) {
        print('🧪 Test change detected. Running tests only...');
        _runTests(appDir.path, projectRoot);
      }
      
      libChanged = false;
      testChanged = false;
    });
  }
  
  libDir.watch(recursive: true).listen(handleFileSystemEvent);
  
  if (await testDir.exists()) {
    testDir.watch(recursive: true).listen(handleFileSystemEvent);
  }
}

Future<void> _startFlutterLoop(Directory appDir, String projectRoot, Directory outputDir) async {
  while (true) {
    try {
      print('🚀 Launching flutter run -d macos...');
      
      flutterProcess = await Process.start(
        'flutter', 
        [
          'run', 
          '-d', 'macos',
          '-t', 'lib/main_dev.dart',
          '--dart-define=SCREENSHOT_DIR=${outputDir.path}',
          '--dart-define=DATA_DIR=$projectRoot'
        ],
        workingDirectory: appDir.path,
      );

      // Stream stdout
      flutterProcess!.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        if (line.contains('Reloaded') || 
            line.contains('Restarted') || 
            line.contains('📸 PIPELINE') ||
            line.contains('Error') ||
            line.contains('Exception')) {
          print('FLUTTER: $line');
        }
        if (line.contains('📸 PIPELINE: Screenshot saved')) {
          print('✅ Verification Successful: Screenshot updated.');
        }
      });

      // Stream stderr
      flutterProcess!.stderr.transform(utf8.decoder).listen((data) {
        stdout.write('FLUTTER ERROR: $data');
      });

      // Wait for exit
      int code = await flutterProcess!.exitCode;
      print('⚠️ Flutter process exited with code $code.');
      
      // Reset
      flutterProcess = null;
      
      print('♻️ Restarting in 3 seconds...');
      await Future.delayed(const Duration(seconds: 3));
      
    } catch (e) {
      print('❌ Critical Error in Flutter Process Loop: $e');
      print('♻️ Retrying in 5 seconds...');
      await Future.delayed(const Duration(seconds: 5));
    }
  }
}

Future<void> _runTests(String appDirPath, String projectRoot) async {
  print('🧪 Running tests...');
  final testReportPath = '$projectRoot/knowledge_base/design_specs_2025_12_13/test_report.md';
  final statusPath = '$projectRoot/knowledge_base/design_specs_2025_12_13/pipeline_status.json';
  
  try {
    final result = await Process.run(
      'flutter', 
      ['test', '--no-pub'], 
      workingDirectory: appDirPath,
    );

    final timestamp = DateTime.now().toIso8601String();
    final passed = result.exitCode == 0;
    final status = passed ? 'PASS ✅' : 'FAIL ❌';
    
    // Detailed Report
    final report = '''
# Test Report
**Status**: $status
**Time**: $timestamp

## Output
```
${result.stdout}
```

## Errors
```
${result.stderr}
```
''';

    await File(testReportPath).writeAsString(report);
    
    // Status Indicator
    await File(statusPath).writeAsString(jsonEncode({
      'status': passed ? 'PASS' : 'FAIL',
      'timestamp': timestamp,
    }));

    print('📄 Test report generated: $status');
  } catch (e) {
    print('❌ Error running tests: $e');
  }
}
