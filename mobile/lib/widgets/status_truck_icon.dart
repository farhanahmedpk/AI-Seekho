import 'package:flutter/material.dart';

class StatusTruckIcon extends StatelessWidget {
  final String status;
  final double size;
  const StatusTruckIcon({super.key, required this.status, this.size = 48});

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    bool hasWarning = false;
    
    switch (status.toLowerCase()) {
      case 'breach':
        iconColor = const Color(0xFFFF3D57); // Red
        hasWarning = true;
        break;
      case 'elevated':
        iconColor = const Color(0xFFFFB300); // Amber
        break;
      default:
        iconColor = const Color(0xFF00C853); // Green
    }

    return SizedBox(
      width: size + 6,
      height: size + 6,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.local_shipping,
            color: iconColor,
            size: size,
          ),
          if (hasWarning)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(3),
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
                  size: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
