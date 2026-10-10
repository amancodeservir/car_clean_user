import 'package:flutter/material.dart';

import '../utils/constants.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SplashView(
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(scale: _scale, child: const _SplashMark()),
      ),
    );
  }
}

class SplashView extends StatelessWidget {
  const SplashView({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE7EFFF), Colors.white, Colors.white, Color(0xFFF3F7FF)],
          stops: [0, 0.34, 0.7, 1],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),
            child ?? const _SplashMark(),
            const Spacer(flex: 2),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: AppConstants.signal),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

class _SplashMark extends StatelessWidget {
  const _SplashMark();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image(
            image: AssetImage(AppConstants.logo),
            width: 240,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}
