class AgentStep {
  final String step;
  final String agentName;
  final String status;
  final String output;
  final String timestamp;

  AgentStep({
    required this.step,
    required this.agentName,
    required this.status,
    required this.output,
    required this.timestamp,
  });

  factory AgentStep.fromJson(Map<String, dynamic> json) {
    String formattedOutput = '';
    final resultObj = json['output'] ?? json['result'];

    if (resultObj is Map) {
      resultObj.forEach((key, value) {
        // Skip metadata/internal fields
        if (['agent', 'timestamp', 'used_fallback', 'step'].contains(key)) return;

        final niceKey = key.toString().replaceAll('_', ' ').toUpperCase();

        if (key == 'recommended_actions' && value is List) {
          // Decision Agent — format prioritized action list
          formattedOutput += '$niceKey:\n';
          for (var item in value) {
            if (item is Map) {
              final priority = item['priority'] ?? '?';
              final action = item['action'] ?? 'UNKNOWN';
              final timeframe = item['timeframe'] ?? 'Immediate';
              formattedOutput += '  • Priority $priority: $action — $timeframe\n';
            }
          }
        } else if (key == 'actions_executed' && value is List) {
          // Execution Agent — format completed actions with result summary
          formattedOutput += '$niceKey:\n';
          for (var item in value) {
            if (item is Map) {
              final action = item['action'] ?? 'UNKNOWN';
              final status = item['status'] ?? 'COMPLETED';
              final res = item['result'];
              String detail = '';
              if (res is Map) {
                // Pick the most descriptive field from result
                detail = (res['new_status'] != null
                        ? '${res['shipment_id'] ?? ''} → ${res['new_status']}'
                        : null) ??
                    res['recipient'] ??
                    res['order_id'] ??
                    res['details'] ??
                    res['message'] ??
                    '';
              }
              final detailStr = detail.toString().trim().isNotEmpty ? ' — $detail' : '';
              formattedOutput += '  • $action: $status$detailStr\n';
            }
          }
        } else if (value is List) {
          // Generic list field
          formattedOutput += '$niceKey:\n';
          for (var item in value) {
            if (item is Map) {
              final entries = item.entries.map((e) => '${e.key}: ${e.value}').join(', ');
              formattedOutput += '  • $entries\n';
            } else {
              formattedOutput += '  • $item\n';
            }
          }
        } else {
          // Simple key: value field
          formattedOutput += '$niceKey: $value\n';
        }
      });
    } else if (resultObj != null) {
      formattedOutput = resultObj.toString();
    }

    return AgentStep(
      step: json['step']?.toString() ?? '',
      agentName: json['agent'] ?? json['agent_name'] ?? 'System',
      status: json['status'] ?? (json['event'] == 'agent_started' ? 'RUNNING' : 'DONE'),
      output: formattedOutput.trim(),
      timestamp: json['timestamp'] ?? '',
    );
  }
}
