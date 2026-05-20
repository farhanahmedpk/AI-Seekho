import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../models/truck.dart';
import '../models/incident.dart';
import '../widgets/pulsing_dot.dart';
import '../widgets/mascot_widget.dart';
import '../widgets/status_truck_icon.dart';
import '../core/api_service.dart';
import '../core/auth_service.dart';
import '../core/theme.dart';
import '../core/demo_data.dart';
import '../providers/demo_provider.dart';
import '../providers/navigation_provider.dart';
import 'breach_alert_screen.dart';
import 'agent_trace_screen.dart';
import 'outcome_screen.dart';
import 'incident_history_screen.dart';
import 'settings_screen.dart';
import '../providers/sensors_provider.dart';
import 'truck_detail_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  ApiService get _apiService => ApiService();
  List<Truck> _trucks = [];
  bool _isLoading = true;
  bool _isOffline = false;
  Timer? _timer;
  Timer? _demoBreachTimer;
  String? _userName;
  bool _showGreeting = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _loadUser();
    _timer = Timer.periodic(
        const Duration(seconds: 10), (_) => _fetchData(showLoading: false));
    // Fade out greeting after 3s
    Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showGreeting = false);
    });
  }

  Future<void> _loadUser() async {
    final name = await AuthService.getCurrentUserName();
    if (mounted) setState(() => _userName = name);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _demoBreachTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);

    final isDemoMode = ref.read(demoModeProvider);
    if (isDemoMode) {
      if (mounted) {
        setState(() {
          if (_trucks.isEmpty || _isOffline) {
            _trucks = DemoData.getInitialTrucks();
          }
          _isLoading = false;
          _isOffline = false;
        });
        ref.read(sensorsProvider.notifier).setTrucks(_trucks);
      }
      _demoBreachTimer?.cancel();
      _demoBreachTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        if (ref.read(demoModeProvider)) {
          // Synchronize _trucks with the current sensorsProvider value before doing checks
          final sensorsAsync = ref.read(sensorsProvider);
          if (sensorsAsync.hasValue && sensorsAsync.value != null && sensorsAsync.value!.isNotEmpty) {
            _trucks = List<Truck>.from(sensorsAsync.value!);
          }

          // Check the current status of TRK-004 and TRK-007
          final t4 = _trucks.firstWhere((t) => t.truckId == 'TRK-004', orElse: () => DemoData.getBreachedTruck004());
          final t7 = _trucks.firstWhere((t) => t.truckId == 'TRK-007', orElse: () => DemoData.getBreachedTruck007());
          
          final trk4IsHealthy = t4.status.toLowerCase() != 'breach' && t4.currentTemp <= t4.thresholdTemp;
          final trk7IsHealthy = t7.status.toLowerCase() != 'breach' && t7.currentTemp <= t7.thresholdTemp;

          // Only trigger breaches if both are healthy (initial state or both resolved/reset cycle).
          // If only one is resolved, leave it healthy and don't re-trigger it.
          if (trk4IsHealthy && trk7IsHealthy) {
            setState(() {
              final idx4 = _trucks.indexWhere((t) => t.truckId == 'TRK-004');
              if (idx4 != -1) {
                _trucks[idx4] = DemoData.getBreachedTruck004();
              }
              final idx7 = _trucks.indexWhere((t) => t.truckId == 'TRK-007');
              if (idx7 != -1) {
                _trucks[idx7] = DemoData.getBreachedTruck007();
              }
            });
            ref.read(sensorsProvider.notifier).setTrucks(List<Truck>.from(_trucks));
          }
        }
      });
      return;
    }

    try {
      final trucks = await _apiService.getSensors();
      if (mounted) {
        setState(() {
          _trucks = trucks;
          _isLoading = false;
          _isOffline = false;
        });
        ref.read(sensorsProvider.notifier).setTrucks(_trucks);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOffline = true;
          _isLoading = false;
          if (_trucks.isEmpty) {
            _trucks = DemoData.getInitialTrucks();
          }
        });
        ref.read(sensorsProvider.notifier).setTrucks(_trucks);
      }
    }
  }

  // Priority sort: breaches first, then elevated, then normal
  List<Truck> get _sortedTrucks {
    final list = List<Truck>.from(_trucks);
    list.sort((a, b) {
      final aExcess = a.currentTemp - a.thresholdTemp;
      final bExcess = b.currentTemp - b.thresholdTemp;
      if (aExcess > 0 && bExcess <= 0) return -1;
      if (bExcess > 0 && aExcess <= 0) return 1;
      return bExcess.compareTo(aExcess);
    });
    return list;
  }

  List<Truck> get _breachedTrucks => _trucks
      .where((t) => t.status == 'breach' && t.currentTemp > t.thresholdTemp)
      .toList();
  List<Truck> get _safeTrucks => _trucks
      .where((t) => t.status != 'breach' || t.currentTemp <= t.thresholdTemp)
      .toList();

  @override
  Widget build(BuildContext context) {
    ref.listen(demoModeProvider, (prev, next) {
      if (next == true) {
        setState(() {
          _trucks = DemoData.getInitialTrucks();
        });
        ref.read(sensorsProvider.notifier).setTrucks(_trucks);
      }
      _fetchData();
    });
    final isDemoMode = ref.watch(demoModeProvider);

    // Watch sensorsProvider reactively to ensure instantaneous, correct updates
    final sensorsAsync = ref.watch(sensorsProvider);
    final currentList = sensorsAsync.maybeWhen(
      data: (list) => list,
      orElse: () => _trucks,
    );

    final breaches = currentList.where((t) => t.status == 'breach' && t.currentTemp > t.thresholdTemp).toList();
    final safe = currentList.where((t) => t.status != 'breach' || t.currentTemp <= t.thresholdTemp).toList();
    int totalTrucks = currentList.length;
    int activeBreaches = breaches.length;
    int allClear = safe.length;

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.shield, color: const Color(0xFF00E5FF).withOpacity(0.15), size: 28),
              const Icon(Icons.shield_outlined, color: const Color(0xFF00E5FF), size: 28),
              const Icon(Icons.ac_unit, color: const Color(0xFF00E5FF), size: 14),
            ],
          )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 2000.ms, color: Colors.white),
          const SizedBox(width: 8),
          const Text('ColdGuard'),
          if (isDemoMode) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                  border:
                      Border.all(color: AppTheme.secondary.withOpacity(0.3))),
              child: const Text('DEMO',
                  style: TextStyle(
                      fontSize: 9,
                      color: AppTheme.secondary,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ]),
        actions: [
          if (activeBreaches > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: AppTheme.danger.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const PulsingDot(color: AppTheme.danger, size: 7),
                  const SizedBox(width: 5),
                  Text('$activeBreaches',
                      style: const TextStyle(
                          color: AppTheme.danger,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          IconButton(
            icon: Icon(Icons.settings_outlined,
                color: context.onSurfaceVariant, size: 22),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchData(showLoading: false),
        color: AppTheme.primary,
        child: _isLoading && _trucks.isEmpty
            ? _buildShimmerLoading()
            : ScrollConfiguration(
                behavior: _HideScrollbarBehavior(),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  slivers: [
                    SliverToBoxAdapter(
                        child: Column(children: [
                      if (_isOffline && !isDemoMode) _buildOfflineBanner(),

                      if (activeBreaches > 1) _buildAutoResolveBanner(activeBreaches),

                      // ─── Greeting ───
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(children: [
                          AnimatedOpacity(
                            opacity: _showGreeting ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 600),
                            child: Text(
                              _userName != null
                                  ? 'Welcome back, $_userName!'
                                  : 'Hello!',
                              style: TextStyle(
                                  color: context.onSurfaceVariant,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ]),
                      ),

                      // ─── Summary Counters (aligned row) ───
                      _buildSummaryRow(totalTrucks, activeBreaches, allClear),

                      // ─── Quick Actions Grid ───
                      _buildActionGrid(currentList),
                    ])),

                    // ─── Active Breaches (pinned to top) ───
                    if (breaches.isNotEmpty) ...[
                      const SliverToBoxAdapter(
                          child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 8, 20, 6),
                        child: Row(children: [
                          PulsingDot(color: AppTheme.danger, size: 6),
                          SizedBox(width: 8),
                          Text('ACTIVE BREACHES',
                              style: TextStyle(
                                  color: AppTheme.danger,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1)),
                        ]),
                      )),
                      SliverList(
                          delegate: SliverChildBuilderDelegate(
                        (_, i) => _CompactTruckCard(
                            truck: breaches[i],
                            isBreach: true,
                            onTap: () => _openTruckDetails(breaches[i])),
                        childCount: breaches.length,
                      )),
                    ],

                    // ─── Fleet Status ───
                    if (safe.isNotEmpty) ...[
                      SliverToBoxAdapter(
                          child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                        child: Text('FLEET STATUS',
                            style: TextStyle(
                                color: context.onSurfaceVariant,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1)),
                      )),
                      SliverList(
                          delegate: SliverChildBuilderDelegate(
                        (_, i) => _CompactTruckCard(
                            truck: safe[i],
                            isBreach: false,
                            onTap: () => _openTruckDetails(safe[i])),
                        childCount: safe.length,
                      )),
                    ],

                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _openTruckDetails(Truck truck) async {
    ref.read(activeTruckProvider.notifier).state = truck;
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => TruckDetailScreen(truck: truck)));
    
    final updatedList = ref.read(sensorsProvider).value;
    if (updatedList != null && updatedList.isNotEmpty) {
      if (mounted) {
        setState(() {
          _trucks = List<Truck>.from(updatedList);
        });
      }
    } else {
      ref.read(sensorsProvider.notifier).refresh();
    }
  }

  Future<void> _openBreach(Truck truck) async {
    ref.read(activeTruckProvider.notifier).state = truck;
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => BreachAlertScreen(truck: truck)));
    
    final updatedList = ref.read(sensorsProvider).value;
    if (updatedList != null && updatedList.isNotEmpty) {
      if (mounted) {
        setState(() {
          _trucks = List<Truck>.from(updatedList);
        });
      }
    } else {
      ref.read(sensorsProvider.notifier).refresh();
    }
  }

  void resetOfflineFlag() {
    if (mounted) {
      setState(() => _isOffline = false);
    }
  }

  Future<void> _handleAutoResolveAll(int count) async {
    final startTime = DateTime.now();
    double savedValue = 0;
    final activeBreaches = _trucks.where((t) => t.status == 'breach' && t.currentTemp > t.thresholdTemp).toList();
    for (var t in activeBreaches) {
      savedValue += _getCargoValueUsd(t);
    }
    if (savedValue == 0) {
      savedValue = count * 450000.0; // Perfect fallback
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22).withOpacity(0.95),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: Colors.cyan.withOpacity(0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.cyan.withOpacity(0.18),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.cyan.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.cyan,
                  size: 48,
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 800.ms, curve: Curves.easeInOut)
                  .shimmer(duration: 1600.ms, color: Colors.cyan.withOpacity(0.4)),
              const SizedBox(height: 24),
              const Text(
                'COLDGUARD AI ACTIVE',
                style: TextStyle(
                  color: Colors.cyan,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Resolving $count active breaches...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(
                width: 140,
                child: LinearProgressIndicator(
                  color: Colors.cyan,
                  backgroundColor: Color(0xFF30363D),
                  minHeight: 3,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Spawning SensorMonitorAgent...\nRunning containment telemetry pipelines...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 11,
                  height: 1.5,
                  fontFamily: 'monospace',
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.3)),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
    );

    // --- DEMO MODE SUPPORT ---
    final isDemoMode = ref.read(demoModeProvider);
    if (isDemoMode) {
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        setState(() {
          final idx4 = _trucks.indexWhere((t) => t.truckId == 'TRK-004');
          if (idx4 != -1) {
            _trucks[idx4] = DemoData.getInitialTrucks().firstWhere((t) => t.truckId == 'TRK-004');
          }
          final idx7 = _trucks.indexWhere((t) => t.truckId == 'TRK-007');
          if (idx7 != -1) {
            _trucks[idx7] = DemoData.getInitialTrucks().firstWhere((t) => t.truckId == 'TRK-007');
          }
        });
        ref.read(sensorsProvider.notifier).setTrucks(List<Truck>.from(_trucks));
        
        final now = DateTime.now();
        final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
        
        final inc4 = Incident(
          incidentId: 'INC-$dateStr-${(DemoData.incidentHistory.length + 1).toString().padLeft(3, '0')}',
          truckId: 'TRK-004',
          cargoType: 'Vaccines',
          breachTemp: 12.5,
          severity: 'CRITICAL',
          pipelineStart: DateTime.now().subtract(const Duration(seconds: 12)).toLocal().toString().split(' ')[1].substring(0, 8),
          pipelineEnd: DateTime.now().toLocal().toString().split(' ')[1].substring(0, 8),
          totalDuration: 1.8,
          finalOutcome: 'CONTAINED',
          timestamp: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        );
        DemoData.incidentHistory.insert(0, inc4);
        
        final inc7 = Incident(
          incidentId: 'INC-$dateStr-${(DemoData.incidentHistory.length + 1).toString().padLeft(3, '0')}',
          truckId: 'TRK-007',
          cargoType: 'Vaccines',
          breachTemp: 11.0,
          severity: 'MEDIUM',
          pipelineStart: DateTime.now().subtract(const Duration(seconds: 15)).toLocal().toString().split(' ')[1].substring(0, 8),
          pipelineEnd: DateTime.now().toLocal().toString().split(' ')[1].substring(0, 8),
          totalDuration: 2.1,
          finalOutcome: 'CONTAINED',
          timestamp: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        );
        DemoData.incidentHistory.insert(0, inc7);
        
        Navigator.of(context).pop(); // Dismiss dialog
        
        _showSuccessDialog(
          context: context,
          count: count,
          savedValue: savedValue,
          duration: 1.8,
        );
      }
      return;
    }
    // --- END DEMO MODE SUPPORT ---

    try {
      try {
        await _apiService.resolveAllBreaches();
      } catch (_) {
        // Ignore all exceptions before starting the polling loop
      }
      
      bool allResolved = false;
      int elapsedSeconds = 0;
      
      while (DateTime.now().difference(startTime).inSeconds < 120) {
        await Future.delayed(const Duration(seconds: 3));
        elapsedSeconds = DateTime.now().difference(startTime).inSeconds;
        
        try {
          final trucks = await _apiService.getSensors();
          final currentBreaches = trucks.where((t) => t.status == 'breach' && t.currentTemp > t.thresholdTemp).length;
          
          if (currentBreaches == 0) {
            allResolved = true;
            break;
          }
        } catch (_) {
          // Ignore transient timeout/network errors during polling and keep retrying
        }
      }
      
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss dialog
      }
      
      if (mounted) {
        if (allResolved) {
          _showSuccessDialog(
            context: context,
            count: count,
            savedValue: savedValue,
            duration: elapsedSeconds.toDouble(),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Monitoring timed out. Some breaches may still be active.'),
              backgroundColor: AppTheme.warning,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      
      if (mounted) {
        // 1. Force the API service to use the real backend URL first
        final realUrl = await ApiService.getBaseUrl();
        await ApiService.setBaseUrl(realUrl);
        
        // 2. Explicitly reset offline flag in state
        setState(() {
          _isOffline = false;
        });
        
        // 3. Check if demo mode is active — if so, switch it off
        if (ref.read(demoModeProvider)) {
          ref.read(demoModeProvider.notifier).state = false;
        }
      }
      
      // 4. Then call _fetchData()
      await _fetchData(showLoading: false);
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to auto-resolve breaches.'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildAutoResolveBanner(int count) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1414).withOpacity(0.85),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.danger.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.danger.withOpacity(0.12),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppTheme.danger,
                  size: 18,
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 1000.ms),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count ACTIVE BREACHES DETECTED',
                      style: const TextStyle(
                        color: AppTheme.danger,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'AI containment pipelines ready to dispatch.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Colors.cyan,
                  Color(0xFF00E5FF),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyan.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextButton.icon(
              onPressed: () => _handleAutoResolveAll(count),
              icon: const Icon(Icons.bolt, color: Colors.white, size: 18),
              label: const Text(
                'AI AUTO-RESOLVE ALL BREACHES',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.8,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildOfflineBanner() => Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(color: Colors.orange.withOpacity(0.3))),
        child:
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.offline_bolt, color: Colors.orange, size: 16),
          SizedBox(width: 6),
          Text('Backend offline — demo data',
              style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
        ]),
      ).animate().slideY().fadeIn();

  Widget _buildSummaryRow(int total, int breaches, int clear) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(children: [
        _buildCounter('Total', total, AppTheme.primary),
        const SizedBox(width: 10),
        _buildCounter('Breaches', breaches,
            breaches > 0 ? AppTheme.danger : context.onSurfaceVariant),
        const SizedBox(width: 10),
        _buildCounter('Safe', clear, AppTheme.success),
      ]).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05),
    );
  }

  Widget _buildCounter(String label, int value, Color color) {
    return Expanded(
        child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(children: [
        Text('$value',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label.toUpperCase(),
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: color.withOpacity(0.7))),
      ]),
    ));
  }

  // ─── 2x2 Grid of Navigation Actions ───
  Widget _buildActionGrid(List<Truck> currentList) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.6,
        children: [
          _buildGridBtn(
              Icons.notifications_active_rounded, 'Alerts', AppTheme.danger,
              () async {
            final b = _breachedTrucks;
            if (b.isNotEmpty) {
              await _openBreach(b.first);
            } else {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const BreachAlertScreen()));
              _fetchData();
            }
          }),
          _buildGridBtn(Icons.memory_rounded, 'AI Trace', AppTheme.info,
              () async {
            // Target first active breached truck in list, fallback to active provider, then first truck
            final breached = currentList.where((t) => t.status == 'breach' && t.currentTemp > t.thresholdTemp).toList();
            final targetTruck = breached.isNotEmpty 
                ? breached.first 
                : (ref.read(activeTruckProvider) ?? (currentList.isNotEmpty ? currentList.first : null));
            
            if (targetTruck != null) {
              ref.read(activeTruckProvider.notifier).state = targetTruck;
            }
            
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AgentTraceScreen(
                        truck: targetTruck)));
            ref.read(sensorsProvider.notifier).refresh();
          }),
          _buildGridBtn(Icons.assessment_rounded, 'Reports', AppTheme.success,
              () async {
            await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const OutcomeScreen()));
            ref.read(sensorsProvider.notifier).refresh();
          }),
          _buildGridBtn(Icons.history_rounded, 'History', AppTheme.warning,
              () async {
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const IncidentHistoryScreen()));
            _fetchData();
          }),
        ],
      ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.05),
    );
  }

  Widget _buildGridBtn(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    final base =
        context.isDark ? const Color(0xFF1A1A2E) : const Color(0xFFE2E8F0);
    final high =
        context.isDark ? const Color(0xFF2D2D3F) : const Color(0xFFF1F5F9);
    return ListView(children: [
      const SizedBox(height: 120),
      ...List.generate(
          5,
          (_) => Shimmer.fromColors(
                baseColor: base,
                highlightColor: high,
                child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    height: 56,
                    decoration: BoxDecoration(
                        color: base,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd))),
              )),
    ]);
  }
}

// ─── Compact Truck Card ───
class _CompactTruckCard extends StatelessWidget {
  final Truck truck;
  final bool isBreach;
  final VoidCallback? onTap;
  const _CompactTruckCard(
      {required this.truck, required this.isBreach, this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = isBreach ? AppTheme.danger : AppTheme.success;

    Widget content = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isBreach
              ? AppTheme.danger.withOpacity(0.5)
              : context.outline.withOpacity(0.2),
          width: isBreach ? 1.5 : 1,
        ),
        boxShadow: isBreach
            ? [
                BoxShadow(
                    color: AppTheme.danger.withOpacity(0.1), blurRadius: 8)
              ]
            : null,
      ),
      child: Row(children: [
        // Icon
        StatusTruckIcon(
          status: isBreach ? 'breach' : (truck.thresholdTemp - truck.currentTemp <= 2.0 ? 'elevated' : 'normal'),
          size: 36,
        ),
        const SizedBox(width: 12),
        // Info
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(truck.truckId,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: context.onSurface)),
              const SizedBox(width: 6),
              Text('${truck.driverName} • ${truck.cargoType}',
                  style: TextStyle(
                      color: context.onSurfaceVariant, fontSize: 11)),
            ]),
            const SizedBox(height: 3),
            Row(children: [
              Text('${truck.currentTemp.toStringAsFixed(1)}°C',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: statusColor)),
              Text(' / ${truck.thresholdTemp.toStringAsFixed(1)}°C',
                  style: TextStyle(
                      fontSize: 11, color: context.onSurfaceVariant)),
              const Spacer(),
              Text('${truck.origin} → ${truck.destination}',
                  style: TextStyle(
                      fontSize: 11, color: context.onSurfaceVariant)),
            ]),
          ],
        )),
        // Status dot
        const SizedBox(width: 8),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: statusColor.withOpacity(0.4), blurRadius: 4)
              ]),
        ),
        if (isBreach) ...[
          const SizedBox(width: 4),
          Icon(Icons.chevron_right,
              size: 16, color: context.onSurfaceVariant),
        ],
      ]),
    );

    // Shake animation for breach cards
    if (isBreach) {
      content = content
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 2500.ms, color: AppTheme.danger.withOpacity(0.08))
          .shakeX(hz: 1.5, amount: 1);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

  void _showSuccessDialog({
    required BuildContext context,
    required int count,
    required double savedValue,
    required double duration,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A), // Premium Deep Midnight Slate
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.success.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.success.withOpacity(0.12),
                  blurRadius: 24,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Pulse Check/Shield Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.success.withOpacity(0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.success.withOpacity(0.2),
                        blurRadius: 12,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: AppTheme.success,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Title
                const Text(
                  'AI CONTAINMENT SUCCESS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(height: 6),
                
                // Subtitle
                Text(
                  'ColdGuard autonomous pipeline has successfully mitigated all cold-chain breaches.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: ctx.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Metrics grid
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: ctx.outline.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      _dialogMetricRow(ctx, 'Incidents Contained', '$count', AppTheme.primary),
                      const Divider(color: Colors.white10, height: 16),
                      _dialogMetricRow(ctx, 'Cargo Value Saved', '\$${(savedValue / 1000).toStringAsFixed(0)}k USD', AppTheme.success),
                      const Divider(color: Colors.white10, height: 16),
                      _dialogMetricRow(ctx, 'AI Resolution Time', '${duration.toStringAsFixed(1)}s', AppTheme.warning),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: ctx.outline.withOpacity(0.3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx); // Close dialog
                        },
                        child: const Text('Dashboard'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () {
                          Navigator.pop(ctx); // Close dialog
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const OutcomeScreen()),
                          );
                        },
                        child: const Text('View Reports'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
        );
      },
    );
  }

  Widget _dialogMetricRow(BuildContext ctx, String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: ctx.onSurfaceVariant),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

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

// ─── Hide scrollbar (WhatsApp-style) ───
class _HideScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child; // No visible scrollbar
  }
}
