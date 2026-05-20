import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../core/theme.dart';
import '../models/truck.dart';
import '../core/demo_data.dart';
import '../providers/demo_provider.dart';
import '../providers/sensors_provider.dart';
import '../providers/navigation_provider.dart';

class OutcomeScreen extends ConsumerWidget {
  final Truck? truck;
  const OutcomeScreen({super.key, this.truck});

  double _getCargoValueUsd(Truck? truck) {
    if (truck == null) return 450000.0;
    final cargo = truck.cargoType.toLowerCase();
    if (cargo.contains('vaccine') || cargo.contains('pharma') || cargo.contains('medical')) {
      return 450000.0;
    }
    if (cargo.contains('meat') || cargo.contains('beef') || cargo.contains('seafood')) {
      return 35000.0;
    }
    if (cargo.contains('dairy') || cargo.contains('milk') || cargo.contains('cheese')) {
      return 15000.0;
    }
    return 25000.0;
  }

  String _getFormattedLoss(Truck? truck) {
    final value = _getCargoValueUsd(truck);
    if (value >= 100000) {
      return '\$${(value / 1000).toStringAsFixed(0)}k USD';
    } else {
      return '\$${value.toStringAsFixed(0)} USD';
    }
  }

  void _shareReport(BuildContext context, Truck? truck) {
    final tId = truck?.truckId ?? 'TRK-004';
    final cargo = truck?.cargoType ?? 'Vaccines';
    final temp = truck?.currentTemp != null ? '${truck!.currentTemp.toStringAsFixed(1)}°C' : '12.5°C';
    final origin = truck?.origin ?? 'Peshawar';
    final destination = truck?.destination ?? 'Quetta';
    final lossVal = _getFormattedLoss(truck);

    final String reportText = '''
====================================
COLDGUARD AI INCIDENT OUTCOME REPORT
====================================
Incident ID: INC-${tId.split('-')[1]}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}
Truck ID: $tId
Driver Name: ${truck?.driverName ?? 'Tariq Mahmood'}
Route: $origin to $destination

CONTAINMENT METRICS:
------------------------------------
Current Temp (Before): $temp
Target Threshold: ${truck?.thresholdTemp ?? 8.0}°C
Status: CONTAINED & QUARANTINED
Cargo at Risk: $cargo
Financial Value at Risk: $lossVal
Estimated Loss Prevented: $lossVal
Total Agent Response Time: 1.8 seconds

MITIGATION ACTIONS TAKEN:
------------------------------------
1. [0.3s] Sensor Monitor: Temperature anomaly detected. Initiated emergency pipeline.
2. [1.0s] Analysis Agent: Confirmed cold chain breach. Flagged cargo risk level as CRITICAL.
3. [1.4s] Decision Agent: Determined quarantine protocol. Dispatched priority replacement order.
4. [1.8s] Execution Agent:
   - Shipment Quarantined (Locked Depot at $destination)
   - Client Notified via Email
   - Replacement Order Created

====================================
ColdGuard AI-Powered Cold Chain Protection
====================================
''';

    Share.share(
      reportText,
      subject: 'ColdGuard Incident Containment Report - $tId',
    );
  }

  void _returnHome(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If no specific truck is passed, treat this screen as the premium Reports Portal
    if (truck == null) {
      return _buildReportsPortal(context, ref);
    }

    final activeTruck = truck;

    return Scaffold(
      appBar: AppBar(title: const Text('Outcome Report')),
      body: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(scrollbars: false),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Center(
                child: Icon(Icons.verified_user,
                    color: AppTheme.success, size: 100)),
            const SizedBox(height: 14),
            _successBanner(context),
            const SizedBox(height: 20),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _beforeCard(context, activeTruck)),
              const SizedBox(width: 10),
              Expanded(child: _afterCard(context)),
            ]),
            const SizedBox(height: 24),
            Text('Impact Summary',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.onSurface)),
            const SizedBox(height: 10),
            _impactGrid(context, activeTruck),
            const SizedBox(height: 24),
            Text('Agent Timeline',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.onSurface)),
            const SizedBox(height: 12),
            _timeline(context),
            const SizedBox(height: 28),
            ElevatedButton.icon(
                onPressed: () => _shareReport(context, activeTruck),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share Containment Report')),
            const SizedBox(height: 10),
            OutlinedButton.icon(
                onPressed: () => _returnHome(context),
                icon: const Icon(Icons.home, size: 18),
                label: const Text('Return to Dashboard')),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  Widget _buildReportsPortal(BuildContext context, WidgetRef ref) {
    final incidents = DemoData.incidentHistory;
    
    // Calculate total prevented loss
    double totalPrevented = 0;
    for (var inc in incidents) {
      final cargo = inc.cargoType.toLowerCase();
      if (cargo.contains('vaccine')) {
        totalPrevented += 450000;
      } else if (cargo.contains('meat')) {
        totalPrevented += 35000;
      } else if (cargo.contains('dairy')) {
        totalPrevented += 15000;
      } else {
        totalPrevented += 25000;
      }
    }
    
    final formattedTotalPrevented = '\$${(totalPrevented / 1000000).toStringAsFixed(2)}M';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports Portal'),
      ),
      body: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(scrollbars: false),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Premium Glassmorphic Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary.withOpacity(0.12), Colors.purple.withOpacity(0.12)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.02),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.assessment_rounded, color: AppTheme.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Incident Reports Portal',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: context.onSurface,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Audit records of autonomous mitigation actions & financial loss prevention.',
                            style: TextStyle(
                              fontSize: 10,
                              color: context.onSurfaceVariant,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Summary Metrics Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.3,
                children: [
                  _metric(context, 'Total Audited', '${incidents.length}', ' Incidents', Icons.receipt_long_rounded, AppTheme.primary),
                  _metric(context, 'Loss Prevented', formattedTotalPrevented, '', Icons.shield_outlined, AppTheme.success),
                  _metric(context, 'Avg Containment', '1.8', 's', Icons.flash_on_rounded, AppTheme.warning),
                  _metric(context, 'Success Rate', '100', '%', Icons.verified_user_outlined, AppTheme.success),
                ],
              ),
              const SizedBox(height: 24),

              // Section Header
              Text(
                'Archived Incident Audits',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: context.onSurface,
                ),
              ),
              const SizedBox(height: 10),

              // Incident Reports List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: incidents.length,
                itemBuilder: (context, index) {
                  final inc = incidents[index];
                  final isCritical = inc.severity.toUpperCase() == 'CRITICAL';
                  final sevColor = isCritical ? AppTheme.danger : Colors.orange;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      onTap: () {
                        // Look up matching base truck details to pass into OutcomeScreen
                        final matchTruck = DemoData.getInitialTrucks().firstWhere(
                          (t) => t.truckId == inc.truckId,
                          orElse: () => Truck(
                            truckId: inc.truckId,
                            driverName: 'Driver',
                            cargoType: inc.cargoType,
                            currentTemp: inc.breachTemp,
                            thresholdTemp: 8.0,
                            status: 'breach',
                            origin: 'Origin',
                            destination: 'Destination',
                          ),
                        );
                        
                        // Reconstruct specific truck state at breach
                        final reportTruck = Truck(
                          truckId: inc.truckId,
                          driverName: matchTruck.driverName,
                          cargoType: inc.cargoType,
                          currentTemp: inc.breachTemp,
                          thresholdTemp: matchTruck.thresholdTemp,
                          status: 'breach',
                          origin: matchTruck.origin,
                          destination: matchTruck.destination,
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OutcomeScreen(truck: reportTruck),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: sevColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              ),
                              child: Icon(
                                isCritical ? Icons.error_outline : Icons.warning_amber_rounded,
                                color: sevColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        inc.incidentId,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: context.onSurface,
                                        ),
                                      ),
                                      Text(
                                        inc.timestamp,
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: context.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${inc.truckId} • ${inc.cargoType} • ${inc.breachTemp.toStringAsFixed(1)}°C (Max Temp)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: context.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: context.onSurfaceVariant.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _successBanner(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
            color: AppTheme.success.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.success.withOpacity(0.3))),
        child: const Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.check_circle, color: AppTheme.success, size: 20),
            SizedBox(width: 8),
            Text('Breach Contained',
                style: TextStyle(
                    color: AppTheme.success,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
          ]),
          SizedBox(height: 4),
          Text('Total response: 1.8 seconds',
              style: TextStyle(color: AppTheme.success, fontSize: 12)),
        ]),
      );

  Widget _beforeCard(BuildContext ctx, Truck? truck) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: AppTheme.danger.withOpacity(0.04),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(color: AppTheme.danger.withOpacity(0.2))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Center(
              child: Text('BEFORE',
                  style: TextStyle(
                      color: AppTheme.danger,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 1))),
          Divider(color: AppTheme.danger.withOpacity(0.2), height: 16),
          _attr(ctx, 'Status', 'IN TRANSIT'),
          _attr(ctx, 'Temp', truck?.currentTemp != null ? '${truck!.currentTemp.toStringAsFixed(1)}°C' : '12.5°C', c: AppTheme.danger),
          _attr(ctx, 'Notified', 'No'),
          _attr(ctx, 'Replace', 'None'),
          _attr(ctx, 'Risk', 'CRITICAL', c: AppTheme.danger),
        ]),
      );

  Widget _afterCard(BuildContext ctx) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: AppTheme.success.withOpacity(0.04),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(color: AppTheme.success.withOpacity(0.2))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Center(
              child: Text('AFTER',
                  style: TextStyle(
                      color: AppTheme.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 1))),
          Divider(color: AppTheme.success.withOpacity(0.2), height: 16),
          _attr(ctx, 'Status', 'QUARANTINED', c: AppTheme.success),
          _attr(ctx, 'Temp', 'Monitored'),
          _attr(ctx, 'Notified', 'Yes', c: AppTheme.success),
          _attr(ctx, 'Replace', 'CREATED', c: AppTheme.success),
          _attr(ctx, 'Risk', 'CONTAINED', c: AppTheme.success),
        ]),
      );

  Widget _attr(BuildContext ctx, String l, String v, {Color? c}) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l, style: TextStyle(fontSize: 9, color: ctx.onSurfaceVariant)),
        const SizedBox(height: 1),
        Text(v,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: c ?? ctx.onSurface)),
      ]));

  Widget _impactGrid(BuildContext ctx, Truck? truck) {
    final lossVal = _getFormattedLoss(truck).replaceAll('\$', '').replaceAll(' USD', '');
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: [
        _metric(ctx, 'Response', '1.8', 's', Icons.timer, AppTheme.primary),
        _metric(ctx, 'Actions', '3', '', Icons.bolt, AppTheme.warning),
        _metric(
            ctx, 'Cargo', truck?.cargoType ?? 'Vaccines', '', Icons.inventory, AppTheme.success),
        _metric(ctx, 'Loss Prevented', lossVal, '', Icons.attach_money,
            AppTheme.success),
      ],
    );
  }

  Widget _metric(BuildContext ctx, String title, String num, String suf,
          IconData icon, Color c) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
            color: ctx.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(color: ctx.outline.withOpacity(0.2))),
        child: Row(children: [
          Icon(icon, color: c, size: 20),
          const SizedBox(width: 8),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Text('$num$suf',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: c, fontSize: 13, fontWeight: FontWeight.bold)),
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: ctx.onSurfaceVariant, fontSize: 9)),
              ])),
        ]),
      );

  Widget _timeline(BuildContext ctx) => Column(children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(children: [
              Expanded(
                  flex: 20,
                  child: Container(height: 8, color: AppTheme.primary)),
              Expanded(
                  flex: 40, child: Container(height: 8, color: Colors.purple)),
              Expanded(
                  flex: 20,
                  child: Container(height: 8, color: AppTheme.warning)),
              Expanded(
                  flex: 20,
                  child: Container(height: 8, color: AppTheme.success)),
            ])),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _leg(ctx, 'Monitor\n0.3s', AppTheme.primary),
          _leg(ctx, 'Analyze\n0.7s', Colors.purple),
          _leg(ctx, 'Decide\n0.4s', AppTheme.warning),
          _leg(ctx, 'Execute\n0.4s', AppTheme.success),
        ]),
      ]);

  Widget _leg(BuildContext ctx, String l, Color c) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            margin: const EdgeInsets.only(top: 2),
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(l,
            style: TextStyle(
                color: ctx.onSurfaceVariant, fontSize: 9, height: 1.2)),
      ]);
}
