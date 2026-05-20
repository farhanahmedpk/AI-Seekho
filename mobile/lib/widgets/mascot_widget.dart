import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme.dart';

enum MascotMood { happy, worried, working, celebrating, sad }

class ColdGuardMascot extends StatefulWidget {
  final MascotMood mood;
  final double size;
  const ColdGuardMascot(
      {super.key, this.mood = MascotMood.happy, this.size = 140});

  @override
  State<ColdGuardMascot> createState() => _ColdGuardMascotState();
}

class _ColdGuardMascotState extends State<ColdGuardMascot>
    with TickerProviderStateMixin {
  late AnimationController _bounceCtrl;
  late AnimationController _shakeCtrl;
  late AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400))
      ..repeat(reverse: true);
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _shakeCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  Color _moodColor() {
    switch (widget.mood) {
      case MascotMood.happy:
        return AppTheme.primary;
      case MascotMood.worried:
        return AppTheme.danger;
      case MascotMood.working:
        return AppTheme.info;
      case MascotMood.celebrating:
        return AppTheme.warning;
      case MascotMood.sad:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final color = _moodColor();

    return AnimatedBuilder(
      animation: Listenable.merge([_bounceCtrl, _shakeCtrl, _glowCtrl]),
      builder: (context, child) {
        double dy = 0;
        double dx = 0;
        double scale = 1.0;

        switch (widget.mood) {
          case MascotMood.happy:
            dy = sin(_bounceCtrl.value * pi) * 4;
            scale = 1.0 + sin(_bounceCtrl.value * pi) * 0.02;
            break;
          case MascotMood.worried:
            dx = sin(_shakeCtrl.value * pi * 4) * 3;
            scale = 1.0;
            break;
          case MascotMood.working:
            dy = sin(_bounceCtrl.value * pi * 2) * 2;
            scale = 1.0 + sin(_glowCtrl.value * pi) * 0.03;
            break;
          case MascotMood.celebrating:
            dy = -sin(_bounceCtrl.value * pi) * 6;
            scale = 1.0 + sin(_bounceCtrl.value * pi) * 0.05;
            break;
          case MascotMood.sad:
            dy = sin(_bounceCtrl.value * pi) * 1.5;
            scale = 0.95 + sin(_bounceCtrl.value * pi) * 0.02;
            break;
        }

        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.scale(
            scale: scale,
            child: SizedBox(
              width: s,
              height: s * 1.2,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glow
                  Positioned.fill(
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        width: s * 0.8,
                        height: s * 0.8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color
                                  .withOpacity(0.15 + _glowCtrl.value * 0.15),
                              blurRadius: 30 + _glowCtrl.value * 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Body
                  CustomPaint(
                    size: Size(s, s * 1.2),
                    painter: _PenguinPainter(mood: widget.mood, color: color),
                  ),
                  // Sweat drops for worried
                  if (widget.mood == MascotMood.worried)
                    Positioned(
                      top: s * 0.18,
                      right: s * 0.15,
                      child: Opacity(
                        opacity: _shakeCtrl.value,
                        child: Icon(Icons.water_drop,
                            size: s * 0.1,
                            color: AppTheme.info.withOpacity(0.7)),
                      ),
                    ),
                  // Sparkles for celebrating
                  if (widget.mood == MascotMood.celebrating) ...[
                    Positioned(
                      top: s * 0.05,
                      left: s * 0.1,
                      child: Opacity(
                        opacity: _bounceCtrl.value,
                        child: Icon(Icons.auto_awesome,
                            size: s * 0.12, color: AppTheme.warning),
                      ),
                    ),
                    Positioned(
                      top: s * 0.1,
                      right: s * 0.08,
                      child: Opacity(
                        opacity: 1 - _bounceCtrl.value,
                        child: Icon(Icons.star,
                            size: s * 0.1, color: AppTheme.warning),
                      ),
                    ),
                  ],
                  // Gear for working
                  if (widget.mood == MascotMood.working)
                    Positioned(
                      top: s * 0.02,
                      right: s * 0.12,
                      child: Transform.rotate(
                        angle: _bounceCtrl.value * pi * 2,
                        child: Icon(Icons.settings,
                            size: s * 0.14,
                            color: AppTheme.info.withOpacity(0.6)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PenguinPainter extends CustomPainter {
  final MascotMood mood;
  final Color color;

  _PenguinPainter({required this.mood, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.48;
    final bodyW = size.width * 0.42;
    final bodyH = size.height * 0.38;

    // Body
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
      ).createShader(Rect.fromCenter(
          center: Offset(cx, cy), width: bodyW * 2, height: bodyH * 2));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, cy), width: bodyW * 2, height: bodyH * 2),
        Radius.circular(bodyW * 0.7),
      ),
      bodyPaint,
    );

    // Belly
    final bellyPaint = Paint()..color = const Color(0xFFE2E8F0);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + bodyH * 0.25),
          width: bodyW * 1.2,
          height: bodyH * 1.2),
      bellyPaint,
    );

    // Snowflake badge
    final badgePaint = Paint()..color = color;
    canvas.drawCircle(
        Offset(cx, cy - bodyH * 0.3), size.width * 0.06, badgePaint);

    // Eyes
    final eyeW = bodyW * 0.28;
    final eyeY = cy - bodyH * 0.05;
    final eyeSpacing = bodyW * 0.4;

    _drawEye(canvas, Offset(cx - eyeSpacing, eyeY), eyeW);
    _drawEye(canvas, Offset(cx + eyeSpacing, eyeY), eyeW);

    // Beak
    final beakPaint = Paint()..color = const Color(0xFFF97316);
    final beakPath = Path();
    final beakY = cy + bodyH * 0.15;
    beakPath.moveTo(cx - size.width * 0.04, beakY);
    beakPath.lineTo(cx, beakY + size.width * 0.05);
    beakPath.lineTo(cx + size.width * 0.04, beakY);
    beakPath.close();
    canvas.drawPath(beakPath, beakPaint);

    // Mouth
    _drawMouth(canvas, Offset(cx, beakY + size.width * 0.07), size.width * 0.1);

    // Feet
    final feetPaint = Paint()..color = const Color(0xFFF97316);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx - bodyW * 0.45, cy + bodyH + size.height * 0.04),
          width: bodyW * 0.5,
          height: bodyH * 0.2),
      feetPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx + bodyW * 0.45, cy + bodyH + size.height * 0.04),
          width: bodyW * 0.5,
          height: bodyH * 0.2),
      feetPaint,
    );
  }

  void _drawEye(Canvas canvas, Offset center, double radius) {
    // White
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);

    double pupilDx = 0, pupilDy = 0;
    double pupilScale = 1.0;

    switch (mood) {
      case MascotMood.happy:
        pupilDy = -radius * 0.1;
        break;
      case MascotMood.worried:
        pupilScale = 1.3;
        pupilDy = -radius * 0.15;
        break;
      case MascotMood.working:
        pupilDy = radius * 0.1;
        break;
      case MascotMood.celebrating:
        pupilScale = 0.8;
        pupilDy = -radius * 0.2;
        break;
      case MascotMood.sad:
        pupilDy = radius * 0.2;
        pupilScale = 0.9;
        break;
    }

    // Pupil
    canvas.drawCircle(
      Offset(center.dx + pupilDx, center.dy + pupilDy),
      radius * 0.5 * pupilScale,
      Paint()..color = const Color(0xFF0F172A),
    );

    // Highlight
    canvas.drawCircle(
      Offset(center.dx + pupilDx + radius * 0.15,
          center.dy + pupilDy - radius * 0.15),
      radius * 0.18,
      Paint()..color = Colors.white,
    );

    // Sad: half-lid
    if (mood == MascotMood.sad) {
      final lidPaint = Paint()..color = const Color(0xFF1E293B);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius + 1),
        pi,
        pi,
        true,
        lidPaint,
      );
    }
  }

  void _drawMouth(Canvas canvas, Offset center, double width) {
    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final path = Path();

    switch (mood) {
      case MascotMood.happy:
      case MascotMood.celebrating:
        path.moveTo(center.dx - width * 0.4, center.dy);
        path.quadraticBezierTo(center.dx, center.dy + width * 0.4,
            center.dx + width * 0.4, center.dy);
        break;
      case MascotMood.worried:
        path.moveTo(center.dx - width * 0.35, center.dy + width * 0.15);
        path.quadraticBezierTo(center.dx, center.dy - width * 0.15,
            center.dx + width * 0.35, center.dy + width * 0.15);
        break;
      case MascotMood.sad:
        path.moveTo(center.dx - width * 0.3, center.dy + width * 0.1);
        path.quadraticBezierTo(center.dx, center.dy - width * 0.2,
            center.dx + width * 0.3, center.dy + width * 0.1);
        break;
      case MascotMood.working:
        path.moveTo(center.dx - width * 0.25, center.dy);
        path.lineTo(center.dx + width * 0.25, center.dy);
        break;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PenguinPainter old) =>
      old.mood != mood || old.color != color;
}
