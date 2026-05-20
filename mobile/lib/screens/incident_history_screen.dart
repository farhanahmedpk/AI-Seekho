import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/incident.dart';
import '../models/agent_step.dart';
import '../widgets/agent_step_card.dart';
import '../widgets/mascot_widget.dart';
import '../core/api_service.dart';
import '../core/theme.dart';
import '../core/demo_data.dart';
import '../providers/demo_provider.dart';
import 'agent_trace_screen.dart';

class IncidentHistoryScreen extends ConsumerStatefulWidget {
  const IncidentHistoryScreen({super.key});
  @override
  ConsumerState<IncidentHistoryScreen> createState() =>
      _IncidentHistoryScreenState();
}

class _IncidentHistoryScreenState extends ConsumerState<IncidentHistoryScreen> {
  final ApiService _apiService = ApiService();
  List<Incident> _incidents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchIncidents();
  }

  Future<void> _fetchIncidents() async {
    setState(() => _isLoading = true);
    final isDemoMode = ref.read(demoModeProvider);
    if (isDemoMode) {
      if (mounted) {
        setState(() {
          _incidents = List<Incident>.from(DemoData.incidentHistory);
          _isLoading = false;
        });
      }
      return;
    }
    try {
      final incidents = await _apiService.getIncidents();
      if (mounted) {
        setState(() {
          _incidents = incidents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _incidents = [];
          _isLoading = false;
        });
      }
    }
  }

  Color _getSeverityColor(String s) {
    switch (s.toUpperCase()) {
      case 'CRITICAL':
        return AppTheme.danger;
      case 'MEDIUM':
        return Colors.orange;
      default:
        return AppTheme.warning;
    }
  }

  Color _getOutcomeColor(String o) =>
      o.toUpperCase() == 'CONTAINED' ? AppTheme.success : AppTheme.danger;

  void _openIncidentTrace(Incident i) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => AgentTraceScreen(
                  incidentId: i.incidentId,
                  isReadOnly: true,
                )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Incident History')),
      body: RefreshIndicator(
        onRefresh: _fetchIncidents,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primary))
            : _incidents.isEmpty
                ? Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        Icon(Icons.history,
                            color: context.onSurfaceVariant.withOpacity(0.3),
                            size: 100),
                        const SizedBox(height: 16),
                        Text('No incidents recorded yet',
                            style: TextStyle(
                                color: context.onSurface,
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('Trigger a breach to begin',
                            style: TextStyle(
                                color: context.onSurfaceVariant, fontSize: 13)),
                      ]))
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _incidents.length,
                    itemBuilder: (_, i) => _buildIncidentCard(_incidents[i]),
                  ),
      ),
    );
  }

  Widget _buildIncidentCard(Incident inc) {
    final sevColor = _getSeverityColor(inc.severity);
    final outColor = _getOutcomeColor(inc.finalOutcome);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () => _openIncidentTrace(inc),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                const Icon(Icons.receipt_long,
                    color: AppTheme.primary, size: 18),
                const SizedBox(width: 8),
                Text(inc.incidentId,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: context.onSurface)),
              ]),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: outColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: outColor.withOpacity(0.4))),
                child: Text(inc.finalOutcome.toUpperCase(),
                    style: TextStyle(
                        color: outColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 10),
            _infoRow(Icons.local_shipping, '${inc.truckId} • ${inc.cargoType}'),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                  child: _infoRow(Icons.thermostat,
                      '${inc.breachTemp.toStringAsFixed(1)}°C')),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: sevColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(inc.severity,
                    style: TextStyle(
                        color: sevColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                  child: _infoRow(
                      Icons.timer, '${inc.totalDuration.toStringAsFixed(1)}s')),
              const SizedBox(width: 12),
              Expanded(child: _infoRow(Icons.schedule, inc.timestamp)),
            ]),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Text('Tap to view trace',
                  style:
                      TextStyle(color: context.onSurfaceVariant, fontSize: 10)),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right,
                  color: context.onSurfaceVariant, size: 14),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(children: [
        Icon(icon, size: 13, color: context.onSurfaceVariant),
        const SizedBox(width: 4),
        Flexible(
            child: Text(text,
                style: TextStyle(color: context.onSurfaceVariant, fontSize: 12),
                overflow: TextOverflow.ellipsis)),
      ]);
}
