import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/truck.dart';
import '../widgets/temperature_gauge.dart';
import '../widgets/mascot_widget.dart';
import '../core/theme.dart';
import '../core/api_service.dart';
import '../providers/demo_provider.dart';
import 'agent_trace_screen.dart';
import 'simulated_actions_screen.dart';

class BreachAlertScreen extends ConsumerStatefulWidget {
  final Truck? truck;
  const BreachAlertScreen({super.key, this.truck});
  @override
  ConsumerState<BreachAlertScreen> createState() => _BreachAlertScreenState();
}

class _BreachAlertScreenState extends ConsumerState<BreachAlertScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  String _getSeverity() {
    final truck = widget.truck;
    if (truck == null) return 'LOW';
    final excess = truck.currentTemp - truck.thresholdTemp;
    if (excess > 5.0) return 'CRITICAL';
    if (excess > 2.0) return 'MEDIUM';
    return 'LOW';
  }

  Color _getSeverityColor(String s) {
    switch (s) {
      case 'CRITICAL':
        return AppTheme.danger;
      case 'MEDIUM':
        return Colors.orange;
      default:
        return AppTheme.warning;
    }
  }

  void _navigateToTrace() {
    if (widget.truck == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AgentTraceScreen(truck: widget.truck)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final truck = widget.truck;
    final severity = _getSeverity();
    final sevColor = _getSeverityColor(severity);

    return Scaffold(
      appBar: AppBar(title: const Text('Breach Alert')),
      body: truck == null
          ? Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  const Icon(Icons.warning_amber,
                      color: AppTheme.danger, size: 100),
                  const SizedBox(height: 16),
                  Text('No active breach.',
                      style: TextStyle(
                          color: context.onSurfaceVariant, fontSize: 15)),
                ]))
          : ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(scrollbars: false),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Banner
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 32, horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: AppTheme.dangerGradient,
                          borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(32),
                              bottomRight: Radius.circular(32)),
                          boxShadow: [
                            BoxShadow(
                                color: AppTheme.danger.withOpacity(0.35),
                                blurRadius: 20,
                                spreadRadius: 2)
                          ],
                        ),
                        child: Column(children: [
                          const Icon(Icons.notifications_active,
                                  color: Colors.white, size: 52)
                              .animate(onPlay: (c) => c.repeat())
                              .shake(hz: 5, duration: 1000.ms)
                              .shimmer(duration: 1500.ms),
                          const SizedBox(height: 10),
                          const Text('CRITICAL BREACH',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2))
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .fadeOut(duration: 800.ms),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(
                                '${truck.truckId} | ${truck.cargoType.toUpperCase()}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8)),
                          ),
                        ]),
                      ).animate().slideY(
                          begin: -0.5,
                          duration: 500.ms,
                          curve: Curves.easeOutBack),
                      const SizedBox(height: 12),

                      // Mascot
                      const Center(
                          child: Icon(Icons.warning_amber,
                              color: AppTheme.danger, size: 110)),
                      const SizedBox(height: 16),

                      // Gauge
                      Center(
                          child: Stack(alignment: Alignment.center, children: [
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: sevColor.withOpacity(0.04),
                              boxShadow: [
                                BoxShadow(
                                    color: sevColor.withOpacity(0.06),
                                    blurRadius: 24,
                                    spreadRadius: 4)
                              ]),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scaleXY(end: 1.06, duration: 1000.ms),
                        TemperatureGauge(
                            currentTemperature: truck.currentTemp,
                            thresholdTemperature: truck.thresholdTemp,
                            size: 160),
                      ])).animate().scaleXY(
                          begin: 0.6,
                          duration: 700.ms,
                          curve: Curves.elasticOut),
                      const SizedBox(height: 20),

                      // Info cards
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(children: [
                            Expanded(
                                child: _infoCard(
                                    'Deviation',
                                    '+${(truck.currentTemp - truck.thresholdTemp).toStringAsFixed(1)}°C',
                                    sevColor,
                                    Icons.trending_up)),
                            const SizedBox(width: 10),
                            Expanded(
                                child: _infoCard('Severity', severity, sevColor,
                                    Icons.warning_amber)),
                          ])
                              .animate()
                              .fadeIn(delay: 300.ms)
                              .slideY(begin: 0.1)),
                      const SizedBox(height: 28),

                      // Buttons
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(children: [
                            _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                        color: AppTheme.danger))
                                : Container(
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.primaryGradient,
                                      borderRadius: BorderRadius.circular(
                                          AppTheme.radiusLg),
                                      boxShadow: [
                                        BoxShadow(
                                            color: AppTheme.primary
                                                .withOpacity(0.2),
                                            blurRadius: 14,
                                            offset: const Offset(0, 5))
                                      ],
                                    ),
                                    child: ElevatedButton.icon(
                              onPressed: _navigateToTrace,
                              icon: const Icon(Icons.auto_awesome, size: 22),
                              label: const Text('AUTO-RESOLVE WITH AI', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent, foregroundColor: Colors.white, shadowColor: Colors.transparent,
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
                              ),
                            ),
                          ).animate().shimmer(delay: 800.ms, duration: 2500.ms),
                  ]).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1)),
                      const SizedBox(height: 40),
                    ]),
              ),
            ),
    );
  }

  Widget _infoCard(String title, String value, Color color, IconData icon) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: color.withOpacity(0.15))),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(title.toUpperCase(),
              style: TextStyle(
                  color: context.onSurfaceVariant,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
        ]),
      );
}
