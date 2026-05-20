import 'package:flutter/material.dart';
import '../models/agent_step.dart';
import '../core/theme.dart';
import '../widgets/pulsing_dot.dart';

import 'package:flutter_animate/flutter_animate.dart';

class AgentStepCard extends StatefulWidget {
  final AgentStep step;
  final int index;
  const AgentStepCard({super.key, required this.step, required this.index});
  @override
  State<AgentStepCard> createState() => _AgentStepCardState();
}

class _AgentStepCardState extends State<AgentStepCard> with SingleTickerProviderStateMixin {
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _slideAnim = Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _slideCtrl.forward();
  }

  @override
  void dispose() { _slideCtrl.dispose(); super.dispose(); }

  Color _getStatusColor(String s) {
    switch (s.toUpperCase()) {
      case 'RUNNING': case 'IN_PROGRESS': return AppTheme.primary;
      case 'DONE': case 'COMPLETED': return AppTheme.success;
      default: return const Color(0xFF94A3B8);
    }
  }

  Color _getCircleColor(int i) {
    const colors = [AppTheme.primary, Colors.purple, AppTheme.warning, AppTheme.success];
    return colors[i % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.step;
    final statusColor = _getStatusColor(step.status);
    final circleColor = _getCircleColor(widget.index);
    final isRunning = step.status.toUpperCase() == 'RUNNING' || step.status.toUpperCase() == 'IN_PROGRESS';
    final isDone = step.status.toUpperCase() == 'DONE' || step.status.toUpperCase() == 'COMPLETED';

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: circleColor.withOpacity(0.15), shape: BoxShape.circle, border: Border.all(color: circleColor, width: 2)),
                child: Center(child: Text('${widget.index + 1}', style: TextStyle(color: circleColor, fontWeight: FontWeight.bold, fontSize: 14))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Flexible(child: Text(step.agentName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.onSurface))),
                  _buildStatusPill(step.status, statusColor, isRunning),
                ]),
                const SizedBox(height: 6),
                AnimatedSize(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOutCubic,
                  alignment: Alignment.topCenter,
                  child: isRunning
                      ? const _TypingDotsWidget()
                      : (isDone && step.output.isNotEmpty)
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Divider(height: 14, color: context.outline.withOpacity(0.3)),
                                _buildOutputSection(step.output)
                                    .animate()
                                    .fadeIn(duration: 400.ms, curve: Curves.easeIn)
                                    .slideY(begin: 0.1, end: 0, duration: 450.ms, curve: Curves.easeOutQuad),
                                const SizedBox(height: 6),
                                Text(step.timestamp, style: TextStyle(color: context.onSurfaceVariant, fontSize: 10))
                                    .animate()
                                    .fadeIn(duration: 300.ms, delay: 100.ms),
                              ],
                            )
                          : const SizedBox.shrink(),
                ),
              ])),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status, Color color, bool isRunning) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(AppTheme.radiusMd), border: Border.all(color: color.withOpacity(0.3))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (isRunning) ...[const PulsingDot(color: AppTheme.primary, size: 6), const SizedBox(width: 4)],
      Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _buildOutputSection(String output) {
    final lines = output.split('\n').where((l) => l.trim().isNotEmpty).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: lines.map((line) {
      if (line.contains(':')) {
        final idx = line.indexOf(':');
        return Padding(
          padding: const EdgeInsets.only(bottom: 3), 
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${line.substring(0, idx)}: ', 
                  style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)
                ),
                TextSpan(
                  text: line.substring(idx + 1).trim(), 
                  style: TextStyle(color: context.onSurface, fontSize: 12, fontStyle: FontStyle.italic)
                ),
              ],
            ),
          ),
        );
      }
      return Padding(padding: const EdgeInsets.only(bottom: 3), child: Text(line, style: TextStyle(color: context.onSurface, fontSize: 12, fontStyle: FontStyle.italic)));
    }).toList());
  }
}

class _TypingDotsWidget extends StatefulWidget {
  const _TypingDotsWidget();
  @override
  State<_TypingDotsWidget> createState() => _TypingDotsWidgetState();
}

class _TypingDotsWidgetState extends State<_TypingDotsWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(); }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(children: [
        Text('Analyzing', style: TextStyle(color: AppTheme.primary.withOpacity(0.7), fontSize: 12, fontStyle: FontStyle.italic)),
        ...List.generate(3, (i) {
          final offset = i * 0.25;
          final opacity = (_controller.value > offset && _controller.value < offset + 0.5) ? 1.0 : 0.3;
          return Text('.', style: TextStyle(color: AppTheme.primary.withOpacity(opacity), fontSize: 16, fontWeight: FontWeight.bold));
        }),
      ]),
    );
  }
}
