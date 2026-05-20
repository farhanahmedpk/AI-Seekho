import 'package:flutter/material.dart';
import 'dart:async';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (context, animation, _) => FadeTransition(
              opacity: animation, child: const DashboardScreen()),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF0A0E1A);
    const accentColor = Color(0xFF00E5FF);
    const subtitleColor = Color(0xFF8892A4);

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.shield, color: accentColor.withOpacity(0.15), size: 120),
                const Icon(Icons.shield_outlined, color: accentColor, size: 120),
                const Icon(Icons.ac_unit, color: accentColor, size: 55),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'ColdGuard',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'AI-Powered Cold Chain Protection',
              style: TextStyle(
                color: subtitleColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
