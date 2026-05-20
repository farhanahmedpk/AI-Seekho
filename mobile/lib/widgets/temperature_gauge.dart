import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme.dart';

class TemperatureGauge extends StatefulWidget {
  final double currentTemperature;
  final double thresholdTemperature;
  final double size;
  const TemperatureGauge({super.key, required this.currentTemperature, required this.thresholdTemperature, this.size = 180.0});
  @override
  State<TemperatureGauge> createState() => _TemperatureGaugeState();
}

class _TemperatureGaugeState extends State<TemperatureGauge> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _tempCtrl;
  late Animation<double> _tempAnim;
  double _oldTemp = 0.0;

  @override
  void initState() {
    super.initState();
    _oldTemp = widget.currentTemperature;
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _tempCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _tempAnim = Tween<double>(begin: _oldTemp, end: widget.currentTemperature).animate(CurvedAnimation(parent: _tempCtrl, curve: Curves.easeOutCubic));
    _tempCtrl.value = 1.0;
    _updatePulse();
  }

  @override
  void didUpdateWidget(TemperatureGauge old) {
    super.didUpdateWidget(old);
    if (widget.currentTemperature != old.currentTemperature) {
      _oldTemp = _tempAnim.value;
      _tempAnim = Tween<double>(begin: _oldTemp, end: widget.currentTemperature).animate(CurvedAnimation(parent: _tempCtrl, curve: Curves.easeOutCubic));
      _tempCtrl.forward(from: 0.0);
      _updatePulse();
    }
  }

  void _updatePulse() {
    if (widget.currentTemperature > 8.0) { if (!_pulseCtrl.isAnimating) _pulseCtrl.repeat(reverse: true); }
    else { _pulseCtrl.stop(); _pulseCtrl.value = 0.0; }
  }

  @override
  void dispose() { _pulseCtrl.dispose(); _tempCtrl.dispose(); super.dispose(); }

  Color _getColorForTemp(double t) {
    if (t < 4.0) return AppTheme.info;
    if (t <= 7.0) return AppTheme.success;
    if (t <= 8.0) return AppTheme.warning;
    return AppTheme.danger;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_tempCtrl, _pulseCtrl]),
      builder: (context, _) {
        final val = _tempAnim.value;
        final color = _getColorForTemp(val);
        return Transform.scale(
          scale: _pulseAnim.value,
          child: SizedBox(
            width: widget.size, height: widget.size,
            child: CustomPaint(
              painter: _GaugePainter(temperature: val, color: color),
              child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${val.toStringAsFixed(1)}°C', style: TextStyle(fontSize: widget.size * 0.18, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 3),
                Text('Threshold: ${widget.thresholdTemperature.toStringAsFixed(1)}°C',
                    style: TextStyle(fontSize: widget.size * 0.07, color: context.onSurfaceVariant)),
              ])),
            ),
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double temperature;
  final Color color;
  _GaugePainter({required this.temperature, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 10;
    final bgPaint = Paint()..color = Colors.grey.withOpacity(0.15)..style = PaintingStyle.stroke..strokeWidth = 10..strokeCap = StrokeCap.round;
    final fgPaint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 10..strokeCap = StrokeCap.round;

    const startAngle = 135 * (pi / 180);
    const sweepAngle = 270 * (pi / 180);

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, bgPaint);

    const minTemp = -10.0;
    const maxTemp = 20.0;
    var pct = ((temperature - minTemp) / (maxTemp - minTemp)).clamp(0.0, 1.0);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle * pct, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.temperature != temperature || old.color != color;
}
