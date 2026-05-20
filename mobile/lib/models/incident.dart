class Incident {
  final String incidentId;
  final String truckId;
  final String cargoType;
  final double breachTemp;
  final String severity;
  final String pipelineStart;
  final String pipelineEnd;
  final double totalDuration;
  final String finalOutcome;
  final String timestamp;

  Incident({
    required this.incidentId,
    required this.truckId,
    required this.cargoType,
    required this.breachTemp,
    required this.severity,
    required this.pipelineStart,
    required this.pipelineEnd,
    required this.totalDuration,
    required this.finalOutcome,
    required this.timestamp,
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      incidentId: json['incident_id'] ?? '',
      truckId: json['truck_id'] ?? '',
      cargoType: json['cargo_type'] ?? '',
      breachTemp: (json['temperature'] ?? json['breach_temp'] ?? 0.0).toDouble(),
      severity: json['severity'] ?? 'LOW',
      pipelineStart: json['detected_at'] ?? json['pipeline_start'] ?? '',
      pipelineEnd: json['resolved_at'] ?? json['pipeline_end'] ?? '',
      totalDuration: (json['total_duration'] ?? 0.0).toDouble(),
      finalOutcome: json['status'] ?? json['final_outcome'] ?? 'UNRESOLVED',
      timestamp: json['logged_at'] ?? json['timestamp'] ?? '',
    );
  }
}
