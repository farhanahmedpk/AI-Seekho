import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/truck.dart';
import '../widgets/pulsing_dot.dart';
import '../core/theme.dart';
import '../providers/navigation_provider.dart';
import '../widgets/status_truck_icon.dart';

class TruckCard extends ConsumerStatefulWidget {
  final Truck truck;
  final int index;
  const TruckCard({super.key, required this.truck, this.index = 0});
  @override
  ConsumerState<TruckCard> createState() => _TruckCardState();
}

class _TruckCardState extends ConsumerState<TruckCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool get _isBreached => _getStatus() == 'BREACH';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _pulseAnimation = Tween<double>(begin: 0.25, end: 0.85).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (_isBreached) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant TruckCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isBreached) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  IconData _getCargoIcon(String c) {
    switch (c.toLowerCase()) {
      case 'vaccines':
      case 'vaccine':
      case 'insulin':
        return Icons.medical_services;
      case 'dairy':
      case 'dairy products':
        return Icons.water_drop;
      case 'meat':
      case 'seafood':
        return Icons.set_meal;
      case 'blood samples':
        return Icons.bloodtype;
      case 'frozen food':
        return Icons.kitchen;
      default:
        return Icons.local_shipping;
    }
  }

  String _getStatus() {
    if (widget.truck.currentTemp > widget.truck.thresholdTemp) return 'BREACH';
    if (widget.truck.thresholdTemp - widget.truck.currentTemp <= 2.0)
      return 'ELEVATED';
    return 'NORMAL';
  }

  Color _getStatusColor(String s) {
    switch (s) {
      case 'BREACH':
        return AppTheme.danger;
      case 'ELEVATED':
        return AppTheme.warning;
      default:
        return AppTheme.success;
    }
  }

  Widget _buildStatusIndicator(String status, bool isBreached) {
    final cargoLetter = widget.truck.cargoType.isNotEmpty
        ? widget.truck.cargoType[0].toUpperCase()
        : 'T';

    Color bgColor;
    switch (status) {
      case 'BREACH':
        bgColor = const Color(0xFFFF3D57); // Red
        break;
      case 'ELEVATED':
        bgColor = const Color(0xFFFFB300); // Amber
        break;
      default:
        bgColor = const Color(0xFF00C853); // Green
    }

    Widget circleIndicator = Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Text(
        cargoLetter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    if (isBreached) {
      circleIndicator = AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF3D57).withOpacity(_pulseAnimation.value * 0.4),
                  blurRadius: 12,
                  spreadRadius: _pulseAnimation.value * 6,
                )
              ],
            ),
            child: child,
          );
        },
        child: circleIndicator,
      );
    }

    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          circleIndicator,
          if (isBreached)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF3D57),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                child: const Icon(
                  Icons.warning,
                  color: Colors.white,
                  size: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _getStatus();
    final statusColor = _getStatusColor(status);
    final isBreached = _isBreached;
    final truck = widget.truck;

    Widget cardContent = AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            if (isBreached) {
              ref.read(activeTruckProvider.notifier).state = truck;
              ref.read(activeTabIndexProvider.notifier).state = 1;
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              border: Border.all(
                color: isBreached
                    ? AppTheme.danger.withOpacity(_pulseAnimation.value)
                    : context.outline.withOpacity(0.3),
                width: isBreached ? 2.0 : 1,
              ),
              boxShadow: isBreached
                  ? [
                      BoxShadow(
                          color: AppTheme.danger.withOpacity(_pulseAnimation.value * 0.25),
                          blurRadius: 12,
                          spreadRadius: 1)
                    ]
                  : null,
            ),
            child: child,
          ),
        );
      },
      child: Column(children: [
        Row(children: [
          _buildStatusIndicator(status, isBreached)
              .animate(target: isBreached ? 1 : 0)
              .shake(hz: 6, duration: 1000.ms)
              .shimmer(delay: 400.ms, duration: 1800.ms),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(truck.truckId,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: context.onSurface)),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isBreached)
                            const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 18)
                                .animate(onPlay: (c) => c.repeat())
                                .fadeIn(duration: 500.ms)
                                .fadeOut(delay: 500.ms),
                          if (isBreached) const SizedBox(width: 6),
                          _buildBadge(status, statusColor, isBreached),
                        ],
                      ),
                    ]),
                const SizedBox(height: 3),
                Text('${truck.driverName} • ${truck.cargoType}',
                    style: TextStyle(
                        color: context.onSurfaceVariant, fontSize: 13)),
              ])),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: context.isDark
                ? Colors.black.withOpacity(0.3)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric(
                    'Temp',
                    '${truck.currentTemp.toStringAsFixed(1)}°C',
                    statusColor,
                    isBreached),
                _buildMetric(
                    'Threshold',
                    '${truck.thresholdTemp.toStringAsFixed(1)}°C',
                    context.onSurfaceVariant,
                    false),
                _buildMetric(
                    'Route',
                    '${truck.origin} → ${truck.destination}',
                    context.onSurface,
                    false),
              ]),
        ),
      ]),
    );

    cardContent = cardContent
        .animate(delay: (50 * widget.index).ms)
        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        .slideY(
            begin: 0.15, end: 0, duration: 400.ms, curve: Curves.easeOutBack);

    if (isBreached) {
      cardContent = cardContent
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 2000.ms, color: AppTheme.danger.withOpacity(0.12))
          .shakeX(hz: 2, amount: 1.5);
    }

    return cardContent;
  }

  Widget _buildBadge(String status, Color color, bool isBreached) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: color.withOpacity(0.3))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (isBreached) ...[
            const PulsingDot(color: AppTheme.danger, size: 7),
            const SizedBox(width: 5)
          ],
          Text(status,
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5)),
        ]),
      );

  Widget _buildMetric(String label, String value, Color color, bool pulse) {
    Widget valueText = Text(value,
        style:
            TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color));
    if (pulse)
      valueText = valueText
          .animate(onPlay: (c) => c.repeat())
          .fadeIn(duration: 500.ms)
          .fadeOut(delay: 500.ms);
    return Column(children: [
      valueText,
      const SizedBox(height: 2),
      Text(label.toUpperCase(),
          style: TextStyle(
              color: context.onSurfaceVariant,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5)),
    ]);
  }
}
