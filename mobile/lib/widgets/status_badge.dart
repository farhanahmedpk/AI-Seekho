import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Color _getColor() {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'breach':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
