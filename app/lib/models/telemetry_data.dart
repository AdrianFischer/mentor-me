class TelemetryData {
  final String routine;
  final DateTime timestamp;
  final int totalTokens;
  final String? logFile;

  TelemetryData({
    required this.routine,
    required this.timestamp,
    required this.totalTokens,
    this.logFile,
  });

  factory TelemetryData.fromJson(Map<String, dynamic> json) {
    return TelemetryData(
      routine: json['routine'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      totalTokens: (json['total_tokens'] as num).toInt(),
      logFile: json['log_file'] as String?,
    );
  }
}
