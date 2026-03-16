import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import '../../models/telemetry_data.dart';

class TelemetryDashboard extends StatefulWidget {
  final String telemetryFilePath;

  const TelemetryDashboard({super.key, required this.telemetryFilePath});

  @override
  State<TelemetryDashboard> createState() => _TelemetryDashboardState();
}

class _TelemetryDashboardState extends State<TelemetryDashboard> {
  List<TelemetryData> _telemetryData = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTelemetry();
  }

  Future<void> _loadTelemetry() async {
    try {
      final file = File(widget.telemetryFilePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        setState(() {
          _telemetryData = jsonList.map((j) => TelemetryData.fromJson(j)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Telemetry file not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error parsing telemetry: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!, key: const Key('telemetry_error')));
    }

    final totalTokens = _telemetryData.fold<int>(0, (sum, data) => sum + data.totalTokens);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('Total Tokens: $totalTokens', key: const Key('total_tokens_text'), style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _telemetryData.length,
                itemBuilder: (context, index) {
                  final data = _telemetryData[index];
                  return ListTile(
                    title: Text(data.routine),
                    subtitle: Text('${data.timestamp.toLocal()}'),
                    trailing: Text('${data.totalTokens} tokens'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
