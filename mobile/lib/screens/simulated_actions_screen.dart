import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/theme.dart';
import '../models/truck.dart';
import 'outcome_screen.dart';

enum ActionState { pending, executing, completed }

class SimulatedActionsScreen extends StatefulWidget {
  final bool isManual;
  final Truck? truck;
  const SimulatedActionsScreen({super.key, this.isManual = false, this.truck});
  @override
  State<SimulatedActionsScreen> createState() => _SimulatedActionsScreenState();
}

class _SimulatedActionsScreenState extends State<SimulatedActionsScreen> {
  final ApiService _apiService = ApiService();
  bool _show1 = false, _show2 = false, _show3 = false;
  ActionState _s1 = ActionState.pending,
      _s2 = ActionState.pending,
      _s3 = ActionState.pending;
  bool _allDone = false;
  int _done = 0;

  @override
  void initState() {
    super.initState();
    _run();
  }

  void _run() async {
    // If manual, actually trigger the breach on the backend to execute actions
    if (widget.isManual && widget.truck != null) {
      try {
        await _apiService.triggerBreach(widget.truck!.truckId, widget.truck!.currentTemp);
      } catch (e) {
        debugPrint('Manual override backend call failed: $e');
      }
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() {
      _show1 = true;
      _s1 = ActionState.executing;
    });
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _show2 = true;
      _s2 = ActionState.executing;
    });
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _show3 = true;
      _s3 = ActionState.executing;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() {
      _s1 = ActionState.completed;
      _done = 1;
    });
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _s2 = ActionState.completed;
      _done = 2;
    });
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _s3 = ActionState.completed;
      _done = 3;
      _allDone = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Executing Actions')),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.isManual ? 'Manual override in progress...' : 'Autonomous response in progress...',
                  style: TextStyle(
                      color: widget.isManual ? AppTheme.warning : AppTheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(widget.isManual ? 'Executing human-validated mitigation steps.' : 'AI agents executing mitigation steps.',
                  style:
                      TextStyle(color: context.onSurfaceVariant, fontSize: 12)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                            value: _done / 3,
                            backgroundColor: context.outline.withOpacity(0.15),
                            color: AppTheme.primary,
                            minHeight: 5))),
                const SizedBox(width: 10),
                Text('$_done / 3',
                    style: TextStyle(
                        color: context.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ]),
            ])),
        Expanded(
            child: ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(scrollbars: false),
          child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _animCard(_show1, _s1, 'Shipment Quarantined', Icons.block,
                    AppTheme.danger, _det1()),
                const SizedBox(height: 6),
                _animCard(_show2, _s2, 'Client Notified',
                    Icons.notifications_active, AppTheme.warning, _det2()),
                const SizedBox(height: 6),
                _animCard(_show3, _s3, 'Replacement Order', Icons.refresh,
                    AppTheme.primary, _det3()),
              ]),
        )),
        AnimatedOpacity(
          opacity: _allDone ? 1 : 0,
          duration: const Duration(milliseconds: 500),
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: _allDone
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => OutcomeScreen(truck: widget.truck)))
                    : null,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white),
                icon: const Icon(Icons.assessment),
                label: const Text('View Outcome Report',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              )),
        ),
      ]),
    );
  }

  Widget _animCard(bool show, ActionState state, String title, IconData icon,
      Color color, Widget details) {
    return AnimatedScale(
        scale: show ? 1 : 0.85,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        child: AnimatedOpacity(
            opacity: show ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: show
                ? _Card(
                    title: title,
                    icon: icon,
                    color: color,
                    state: state,
                    details: details)
                : const SizedBox.shrink()));
  }

  Widget _row(String l, String v, {Widget? t}) => Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$l: ',
            style: TextStyle(color: context.onSurfaceVariant, fontSize: 12)),
        Expanded(
            child: Text(v,
                style: TextStyle(
                    color: context.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.bold))),
        if (t != null) t,
      ]));

  Widget _badge(String l, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
          color: c.withOpacity(0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: c)),
      child: Text(l,
          style:
              TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.bold)));

  String _getNotificationRecipient(Truck? truck) {
    if (truck == null) return 'medlife@pharma.pk';
    final dest = truck.destination.toLowerCase();
    if (dest.contains('quetta')) return 'quetta.hospital@pharma.pk';
    if (dest.contains('karachi')) return 'karachi.distributor@pharma.pk';
    if (dest.contains('lahore')) return 'lahore.clinic@pharma.pk';
    if (dest.contains('peshawar')) return 'peshawar.storage@pharma.pk';
    return 'ops.center@coldguard.pk';
  }

  Widget _det1() {
    final tId = widget.truck?.truckId ?? 'TRK-004';
    final shipId = 'SHIP-${tId.replaceAll('TRK-', '')}';
    final location = 'Locked (Depot at ${widget.truck?.destination ?? 'Quetta'})';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Divider(color: context.outline.withOpacity(0.3)),
      _row('Shipment', shipId),
      _row('Status', 'QUARANTINED',
          t: _badge('QUARANTINED', AppTheme.danger)),
      _row('Updated', 'Just now'),
      _row('Location', location)
    ]);
  }

  Widget _det2() {
    final tId = widget.truck?.truckId ?? 'TRK-004';
    final cargo = widget.truck?.cargoType ?? 'Vaccines';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Divider(color: context.outline.withOpacity(0.3)),
      _row('Recipient', _getNotificationRecipient(widget.truck)),
      _row('Type', 'EMAIL'),
      _row('Preview', '"URGENT: Cold chain breach on $tId ($cargo)..."'),
      _row('Sent', 'Just now')
    ]);
  }

  Widget _det3() {
    final tId = widget.truck?.truckId ?? 'TRK-004';
    final repOrder = 'REP-ORD-${tId.replaceAll('TRK-', '')}-EXP';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Divider(color: context.outline.withOpacity(0.3)),
      _row('Order', repOrder),
      _row('Cargo', '${widget.truck?.cargoType ?? 'Vaccines'} (Priority)'),
      _row('Priority', 'URGENT', t: _badge('URGENT', AppTheme.warning)),
      _row('Delivery', 'Tomorrow, 08:00 AM (to ${widget.truck?.destination ?? 'Quetta'})')
    ]);
  }
}

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final ActionState state;
  final Widget details;
  const _Card(
      {required this.title,
      required this.icon,
      required this.color,
      required this.state,
      required this.details});

  @override
  Widget build(BuildContext context) {
    final exec = state == ActionState.executing;
    final done = state == ActionState.completed;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          side: BorderSide(
              color: done
                  ? AppTheme.success.withOpacity(0.3)
                  : Colors.transparent)),
      child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 18)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: context.onSurface)),
                    const SizedBox(height: 3),
                    Row(children: [
                      Text(
                          exec
                              ? 'EXECUTING'
                              : done
                                  ? 'COMPLETED'
                                  : 'PENDING',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: exec
                                  ? color
                                  : done
                                      ? AppTheme.success
                                      : context.onSurfaceVariant)),
                      if (exec) ...[
                        const SizedBox(width: 5),
                        SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                                strokeWidth: 1.5, color: color))
                      ],
                      if (done) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.check_circle,
                            color: AppTheme.success, size: 12)
                      ],
                    ]),
                  ])),
            ]),
            if (exec) ...[
              const SizedBox(height: 10),
              TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1500),
                  builder: (_, v, __) => LinearProgressIndicator(
                      value: v,
                      backgroundColor: context.outline.withOpacity(0.15),
                      color: color,
                      borderRadius: BorderRadius.circular(3)))
            ],
            AnimatedSize(
                duration: const Duration(milliseconds: 300),
                alignment: Alignment.topCenter,
                child: done
                    ? Padding(
                        padding: const EdgeInsets.only(top: 6), child: details)
                    : const SizedBox.shrink()),
          ])),
    );
  }
}
