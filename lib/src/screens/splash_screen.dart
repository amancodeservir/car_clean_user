import 'package:flutter/material.dart';

import '../config.dart';
import '../theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE066), Color(0xFFFFF5CC), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.92, end: 1),
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 30, offset: Offset(0, 12))],
                  ),
                  child: Image.asset(Photos.logo, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 22),
              Text('Your car deserves better', style: AppText.h3),
              const SizedBox(height: 4),
              Text('Doorstep car & bike care', style: AppText.small),
              const Spacer(flex: 3),
              const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4)),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
