import 'dart:io';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'app.dart';

void main() {
  runApp(const PipelineWrapper());
}

class PipelineWrapper extends StatefulWidget {
  const PipelineWrapper({super.key});

  @override
  State<PipelineWrapper> createState() => _PipelineWrapperState();
}

class _PipelineWrapperState extends State<PipelineWrapper> {
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void reassemble() {
    super.reassemble();
    // Trigger screenshot after a short delay to allow re-render
    Future.delayed(const Duration(milliseconds: 800), () {
      _captureScreenshot();
    });
  }

  Future<void> _captureScreenshot() async {
    try {
      const screenshotDir = String.fromEnvironment('SCREENSHOT_DIR');
      if (screenshotDir.isEmpty) {
        print('⚠️ PIPELINE: SCREENSHOT_DIR environment variable not set');
        return;
      }

      final fileName = 'current_state.png';
      final path = '$screenshotDir/$fileName';

      // screenshot package captures as Uint8List
      // We explicitly capture the pixel ratio to ensure high quality
      final image = await _screenshotController.capture(
        pixelRatio: 2.0, 
        delay: const Duration(milliseconds: 100)
      );

      if (image != null) {
        final file = File(path);
        await file.writeAsBytes(image);
        print('📸 PIPELINE: Screenshot saved to $path');
      } else {
        print('⚠️ PIPELINE: Screenshot capture returned null');
      }
    } catch (e) {
      print('❌ PIPELINE: Error capturing screenshot: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: _screenshotController,
      child: const MyApp(),
    );
  }
}

