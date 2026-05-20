import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agent_step.dart';
import '../models/truck.dart';
import '../models/incident.dart';
import '../widgets/agent_step_card.dart';
import '../widgets/pulsing_dot.dart';
import '../core/api_service.dart';
import '../core/theme.dart';
import '../core/demo_data.dart';
import '../providers/demo_provider.dart';
import 'simulated_actions_screen.dart';
import '../providers/sensors_provider.dart';
import '../providers/navigation_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AgentTraceScreen extends ConsumerStatefulWidget {
  final Truck? truck;
  final String? incidentId;
  final bool isReadOnly;
  const AgentTraceScreen({super.key, this.truck, this.incidentId, this.isReadOnly = false});
  @override
  ConsumerState<AgentTraceScreen> createState() => _AgentTraceScreenState();
}

class _AgentTraceScreenState extends ConsumerState<AgentTraceScreen> {
  final ApiService _apiService = ApiService();
  final List<AgentStep> _steps = [];
  final List<String> _logLines = [];
  final ScrollController _scrollCtrl = ScrollController();
  bool _pipelineComplete = false;
  bool _isComplete = false;
  bool _isStreaming = false;
  int _activeStep = 0;
  StreamSubscription<Map<String, dynamic>>? _streamSub;
  DateTime? _startTime;
  Duration _duration = Duration.zero;
  bool _showLogs = false;
  bool _hasError = false;

  static const _labels = ['SensorMonitor', 'Analysis', 'Decision', 'Execution'];

  @override
  void initState() {
    super.initState();
    if (widget.isReadOnly && widget.incidentId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadSavedTrace());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    }
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _start() {
    if (!widget.isReadOnly) {
      final demo = ref.read(demoModeProvider);
      final activeTruck = widget.truck ?? ref.read(activeTruckProvider);
      final hasActiveBreach = activeTruck != null &&
          (activeTruck.status == 'breach' || activeTruck.currentTemp > activeTruck.thresholdTemp);

      if (!hasActiveBreach) {
        // No active breach, keep steps empty and show standby empty state
        return;
      }

      if (demo) {
        _runMock();
        return;
      }
      setState(() {
        _isStreaming = true;
        _startTime = DateTime.now();
      });
      _streamSub = _apiService
          .streamAgentTrace(activeTruck.truckId, activeTruck.currentTemp)
          .listen(
        (data) {
          if (!mounted) return;

          final event = data['event'];
          final incidentId = data['incident_id'];

          if (event == 'pipeline_started' || event == 'pipeline_completed') {
            if (event == 'pipeline_completed' && incidentId != null) {
              _fetchCompletedIncident(incidentId);
            }
            return;
          }

          final s = AgentStep.fromJson(data);
          if (s.step.isEmpty || s.agentName == 'System') return;

          setState(() {
            final existingIndex =
                _steps.indexWhere((step) => step.step == s.step);
            if (existingIndex >= 0) {
              _steps[existingIndex] = s;
            } else {
              _steps.add(s);
            }
            _activeStep = _steps.length - 1;
            _logLines.add(
                '> [${s.timestamp}] ${s.agentName}: ${s.output.replaceAll('\n', ' | ')}');
          });
          _scroll();
        },
        onDone: () {
          if (!mounted) return;
          setState(() {
            _isStreaming = false;
            if (_steps.isNotEmpty) {
              _pipelineComplete = true;
              _isComplete = true;
              _duration = DateTime.now().difference(_startTime ?? DateTime.now());
              _activeStep = _labels.length;
            }
          });
          ref.read(sensorsProvider.notifier).refresh();
        },
        onError: (e) {
          if (!mounted) return;
          setState(() {
            _isStreaming = false;
            _hasError = true;
            _logLines.add('> ERROR: $e');
          });
        },
      );
    }
  }

  void _runMock() async {
    setState(() {
      _isStreaming = true;
      _startTime = DateTime.now();
    });
    final mock = DemoData.agentTrace;
    for (int i = 0; i < mock.length; i++) {
      if (!mounted) return;
      setState(() {
        _steps.add(AgentStep(
            step: mock[i].step,
            agentName: mock[i].agentName,
            status: 'RUNNING',
            output: '',
            timestamp: ''));
        _activeStep = i;
      });
      _scroll();
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      setState(() {
        _steps[i] = mock[i];
        _logLines.add(
            '> [${mock[i].timestamp}] ${mock[i].agentName}: ${mock[i].output.replaceAll('\n', ' | ')}');
      });
      _scroll();
    }
    if (!mounted) return;
    setState(() {
      _isStreaming = false;
      _pipelineComplete = true;
      _isComplete = true;
      _duration = DateTime.now().difference(_startTime ?? DateTime.now());
      _activeStep = _labels.length;
    });
    final activeTruck = widget.truck ?? ref.read(activeTruckProvider);
    if (activeTruck != null) {
      final now = DateTime.now();
      final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final newIncident = Incident(
        incidentId: 'INC-$dateStr-${(DemoData.incidentHistory.length + 1).toString().padLeft(3, '0')}',
        truckId: activeTruck.truckId,
        cargoType: activeTruck.cargoType,
        breachTemp: activeTruck.currentTemp,
        severity: (activeTruck.currentTemp - activeTruck.thresholdTemp) > 4 ? 'CRITICAL' : 'MEDIUM',
        pipelineStart: DateTime.now().subtract(_duration ?? const Duration(seconds: 6)).toLocal().toString().split(' ')[1].substring(0, 8),
        pipelineEnd: DateTime.now().toLocal().toString().split(' ')[1].substring(0, 8),
        totalDuration: (_duration?.inMilliseconds ?? 6000) / 1000,
        finalOutcome: 'CONTAINED',
        timestamp: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      );
      DemoData.incidentHistory.insert(0, newIncident);

      final sensorsAsync = ref.read(sensorsProvider);
      if (sensorsAsync.hasValue && sensorsAsync.value != null) {
        final currentList = List<Truck>.from(sensorsAsync.value!);
        final idx = currentList.indexWhere((t) => t.truckId == activeTruck.truckId);
        if (idx != -1) {
          currentList[idx] = DemoData.getInitialTrucks().firstWhere(
            (t) => t.truckId == activeTruck.truckId,
            orElse: () => activeTruck,
          );
          ref.read(sensorsProvider.notifier).setTrucks(currentList);
        }
      } else {
        ref.read(sensorsProvider.notifier).refresh();
      }
    } else {
      ref.read(sensorsProvider.notifier).refresh();
    }
  }

  void _loadSavedTrace() async {
    setState(() {
      _steps.clear();
      _isComplete = false;
      _hasError = false;
    });
    
    final demo = ref.read(demoModeProvider);
    if (demo || (widget.incidentId != null && widget.incidentId!.startsWith('INC-202'))) {
      // Load mock trace locally for demo/mock incidents to avoid 404 API calls
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() {
        _steps.clear();
        _steps.addAll(DemoData.agentTrace);
        _isComplete = true;
        _pipelineComplete = true;
        _isStreaming = false;
        _activeStep = _labels.length;
        _duration = const Duration(seconds: 6);
      });
      return;
    }

    try {
      final data = await _apiService.getAgentTrace(widget.incidentId!);
      print('📥 [AgentTraceScreen] Raw Trace Response: $data');

      final List rawSteps = data['steps'] ?? [];
      final parsedSteps = rawSteps.map((s) => AgentStep.fromJson(s)).toList();

      if (!mounted) return;
      setState(() {
        _steps.clear();
        _steps.addAll(parsedSteps);
        _isComplete = true;
        _pipelineComplete = true;
        _isStreaming = false;
        _activeStep = _labels.length;

        // Try to calculate duration from data if available
        if (data.containsKey('pipeline_start') &&
            data.containsKey('pipeline_end')) {
          final start = DateTime.tryParse(data['pipeline_start']);
          final end = DateTime.tryParse(data['pipeline_end']);
          if (start != null && end != null) {
            _duration = end.difference(start);
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isStreaming = false;
        _hasError = true;
        _logLines.add('> ERROR loading trace: $e');
      });
    }
  }

  void _fetchCompletedIncident(String incidentId) async {
    try {
      final data = await _apiService.getAgentTrace(incidentId);
      final List rawSteps = data['steps'] ?? [];
      final parsedSteps = rawSteps.map((s) => AgentStep.fromJson(s)).toList();

      if (!mounted) return;
      setState(() {
        _steps.clear();
        _steps.addAll(parsedSteps);
        _isComplete = true;
        _pipelineComplete = true;
        _isStreaming = false;
        _activeStep = _labels.length;
        
        // Calculate duration from data if available
        if (data.containsKey('pipeline_start') &&
            data.containsKey('pipeline_end')) {
          final start = DateTime.tryParse(data['pipeline_start']);
          final end = DateTime.tryParse(data['pipeline_end']);
          if (start != null && end != null) {
            _duration = end.difference(start);
          }
        }
      });
      ref.read(sensorsProvider.notifier).refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _logLines.add('> ERROR fetching completed trace: $e');
      });
    }
  }

  void _scroll() {
    // Slights delay to allow the card's AnimatedSize to start expanding,
    // then animate the scroll down concurrently to create a unified fluid flow.
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Text('Agent Pipeline'),
          const SizedBox(width: 8),
          if (_isStreaming)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                PulsingDot(color: AppTheme.primary, size: 5),
                SizedBox(width: 4),
                Text('LIVE',
                    style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold))
              ]),
            ),
        ]),
        actions: [
          IconButton(
            icon: Icon(_showLogs ? Icons.terminal : Icons.terminal_outlined,
                color: _showLogs ? AppTheme.primary : context.onSurfaceVariant,
                size: 20),
            tooltip: 'Toggle Logs',
            onPressed: () => setState(() => _showLogs = !_showLogs),
          ),
        ],
      ),
      body: Column(children: [
        if (_steps.isNotEmpty || _isStreaming) _buildAgentNodes(),
        Expanded(
          child: _steps.isNotEmpty
              ? ScrollConfiguration(
                  behavior: const ScrollBehavior().copyWith(scrollbars: false),
                  child: ListView.builder(
                      controller: _scrollCtrl,
                      itemCount: _steps.length,
                      itemBuilder: (_, i) =>
                          AgentStepCard(step: _steps[i], index: i)),
                )
              : _isStreaming
                  ? Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.auto_awesome, color: Colors.cyan, size: 72)
                                .animate(onPlay: (c) => c.repeat())
                                .scaleXY(begin: 0.9, end: 1.1, duration: 1000.ms, curve: Curves.easeInOut)
                                .shimmer(duration: 1500.ms),
                            const SizedBox(height: 20),
                            const Text(
                              'AI Initializing Response...',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'Connecting to real-time response stream. Dispatching orchestrator and analyzing breach telemetry...',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: context.onSurfaceVariant, fontSize: 13),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.cyan,
                              ),
                            ),
                          ]),
                    )
                  : _hasError
                      ? Center(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.danger.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
                                  ),
                                  child: const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 48),
                                ).animate().shake(duration: 500.ms),
                                const SizedBox(height: 20),
                                const Text(
                                  'Trace Not Found',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32),
                                  child: Text(
                                    'The requested agent trace could not be loaded. Demo incidents require running in Demo Mode to view their mock logs.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: context.onSurfaceVariant, fontSize: 13),
                                  ),
                                ),
                              ]),
                        )
                      : widget.isReadOnly
                          ? const Center(
                              child: CircularProgressIndicator(color: AppTheme.primary))
                          : Center(
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.radar, color: AppTheme.info, size: 72),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No Active Breach',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 32),
                                      child: Text(
                                        'AI agents are on standby. Trigger a breach to see the pipeline in action.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: context.onSurfaceVariant, fontSize: 13),
                                      ),
                                    ),
                                  ]),
                            ),
        ),
        if (_pipelineComplete) _buildDoneBanner(),
        if (_showLogs) _buildConsole(),
      ]),
    );
  }

  Widget _buildStepper() => Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        color: context.surfaceColor,
        child: Row(
            children: List.generate(_labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            final si = i ~/ 2;
            return Expanded(
                child: Container(
                    height: 2,
                    color: si < _activeStep
                        ? AppTheme.success
                        : context.outline.withOpacity(0.2)));
          }
          return _dot(i ~/ 2);
        })),
      );

  Widget _buildAgentNodes() {
    final activeColor = Colors.cyan;
    final inactiveColor = context.onSurfaceVariant.withOpacity(0.3);

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8, left: 16, right: 16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.outline.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(4, (i) {
          final isNodeActive = i == _activeStep && _isStreaming;
          final isNodeDone = i < _activeStep || _activeStep >= _labels.length;
          
          Widget nodeCircle = Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isNodeActive || isNodeDone
                  ? Colors.cyan.withOpacity(0.15)
                  : context.surfaceColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isNodeActive || isNodeDone ? Colors.cyan : inactiveColor,
                width: isNodeActive ? 3.0 : 2.0,
              ),
              boxShadow: isNodeActive
                  ? [
                      BoxShadow(
                        color: Colors.cyan.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: Icon(
              _agentIcon(i),
              color: isNodeActive || isNodeDone ? Colors.cyan : inactiveColor,
              size: 24,
            ),
          );

          if (isNodeActive) {
            nodeCircle = nodeCircle
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.1, 1.1), duration: 600.ms, curve: Curves.easeInOut)
                .shimmer(duration: 1200.ms, color: Colors.cyan.withOpacity(0.3));
          }

          if (i < 3) {
            final isLineActive = i < _activeStep && _isStreaming;
            return Expanded(
              child: Row(
                children: [
                  nodeCircle,
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          height: 2,
                          color: isLineActive ? Colors.cyan : inactiveColor,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: Icon(
                              Icons.arrow_right,
                              size: 16,
                              color: isLineActive ? Colors.cyan : inactiveColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return nodeCircle;
        }),
      ),
    );
  }

  IconData _agentIcon(int idx) {
    switch (idx) {
      case 0: return Icons.sensors;
      case 1: return Icons.analytics;
      case 2: return Icons.auto_awesome;
      case 3: return Icons.rocket_launch;
      default: return Icons.help_outline;
    }
  }

  Widget _dot(int idx) {
    final active = idx == _activeStep;
    final done = idx < _activeStep || _activeStep >= _labels.length;
    final c = done
        ? AppTheme.success
        : active
            ? AppTheme.primary
            : context.onSurfaceVariant.withOpacity(0.3);
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: active ? 26 : 20,
              height: active ? 26 : 20,
              decoration: BoxDecoration(
                  color: c.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: c, width: 2),
                  boxShadow: active
                      ? [
                          BoxShadow(
                              color: AppTheme.primary.withOpacity(0.2),
                              blurRadius: 6)
                        ]
                      : null),
              child: Icon(
                _agentIcon(idx),
                size: active ? 14 : 10,
                color: done
                    ? AppTheme.success
                    : active
                        ? AppTheme.primary
                        : context.onSurfaceVariant.withOpacity(0.4),
              )),
          const SizedBox(height: 3),
          Text(_labels[idx],
              style: TextStyle(
                  color: active || done
                      ? c
                      : context.onSurfaceVariant.withOpacity(0.4),
                  fontSize: 8,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal)),
        ]));
  }

  Widget _buildDoneBanner() => Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppTheme.success.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.success.withOpacity(0.25))),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.check_circle, color: AppTheme.success, size: 18),
            const SizedBox(width: 6),
            Text('Pipeline Complete • ${_duration.inSeconds}s',
                style: const TextStyle(
                    color: AppTheme.success,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 10),
          SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => SimulatedActionsScreen(truck: widget.truck))),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                icon: const Icon(Icons.play_circle, size: 18),
                label: const Text('View Actions',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              )),
        ]),
      );

  Widget _buildConsole() => Container(
        height: 100,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: context.outline.withOpacity(0.15))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                    color: _isStreaming
                        ? AppTheme.success
                        : context.onSurfaceVariant,
                    shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text('console',
                style: TextStyle(
                    color: context.onSurfaceVariant.withOpacity(0.4),
                    fontSize: 9,
                    fontFamily: 'monospace'))
          ]),
          const SizedBox(height: 3),
          Expanded(
              child: _logLines.isEmpty
                  ? Text('> Awaiting...',
                      style: TextStyle(
                          color: context.onSurfaceVariant.withOpacity(0.3),
                          fontSize: 10,
                          fontFamily: 'monospace'))
                  : ListView.builder(
                      itemCount: _logLines.length,
                      itemBuilder: (_, i) => Text(_logLines[i],
                          style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 9,
                              fontFamily: 'monospace',
                              height: 1.3)))),
        ]),
      );
}
