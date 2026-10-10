import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/brand_theme.dart';
import '../utils/constants.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _sync());
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _sync();
  }

  Future<void> _sync() async {
    if (!mounted) return;
    final token = context.read<AuthProvider>().user?.token;
    await context.read<AppProvider>().syncOrders(token);
    await context.read<AppProvider>().refreshUnread(token);
  }

  @override
  Widget build(BuildContext context) {
    final shell = widget.shell;
    return Scaffold(
      backgroundColor: AppConstants.paper,
      body: shell,
      bottomNavigationBar: _Dock(
        index: shell.currentIndex,
        onTap: (index) => shell.goBranch(
          index,
          initialLocation: index == shell.currentIndex,
        ),
      ),
    );
  }
}

class _Dock extends StatefulWidget {
  const _Dock({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  @override
  State<_Dock> createState() => _DockState();
}

class _DockState extends State<_Dock> with SingleTickerProviderStateMixin {
  static const _labels = ['Home', 'My Orders', 'Plus', 'Profile'];
  static const _icons = [
    (Icons.home_outlined, Icons.home_rounded),
    (Icons.calendar_month_outlined, Icons.calendar_month_rounded),
    (Icons.diamond_outlined, Icons.diamond_rounded),
    (Icons.person_outline_rounded, Icons.person_rounded),
  ];

  late final AnimationController _motion;
  double _from = 0;
  double _to = 0;

  @override
  void initState() {
    super.initState();
    _from = widget.index.toDouble();
    _to = _from;
    _motion = AnimationController(vsync: this, duration: const Duration(milliseconds: 460))
      ..value = 1;
  }

  @override
  void didUpdateWidget(covariant _Dock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index.toDouble() == _to) return;
    _from = _travel;
    _to = widget.index.toDouble();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _motion.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  double get _travel {
    final curved = Curves.easeOutCubic.transform(_motion.value.clamp(0, 1));
    return _from + (_to - _from) * curved;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _motion,
      builder: (context, _) {
        final travel = _travel;
        final bottom = MediaQuery.viewPaddingOf(context).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, bottom + 8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(color: Color(0x1A111827), blurRadius: 24, offset: Offset(0, 8)),
                BoxShadow(color: Color(0x0F111827), blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final slot = constraints.maxWidth / _labels.length;
                const pillWidth = 52.0;
                final pillLeft = (travel * slot) + (slot - pillWidth) / 2;
                return SizedBox(
                  height: 64,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: pillLeft,
                        top: 8,
                        width: pillWidth,
                        height: 32,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppConstants.signal,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x472563EB),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (var index = 0; index < _labels.length; index++)
                            Expanded(
                              child: _DockItem(
                                label: _labels[index],
                                outlined: _icons[index].$1,
                                filled: _icons[index].$2,
                                cover: (1 - (travel - index).abs()).clamp(0, 1),
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  widget.onTap(index);
                                },
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.label,
    required this.outlined,
    required this.filled,
    required this.cover,
    required this.onTap,
  });

  final String label;
  final IconData outlined;
  final IconData filled;
  final double cover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = cover > 0.62;
    final labelColor = Color.lerp(Colors.black, AppConstants.signal, cover)!;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            children: [
              SizedBox(
                height: 32,
                child: Center(
                  child: Transform.scale(
                    scale: 1 + (0.08 * cover),
                    child: Icon(
                      selected ? filled : outlined,
                      size: AppConstants.iconSize,
                      color: Color.lerp(AppConstants.mute, Colors.white, cover),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: AppType.label.copyWith(
                  color: labelColor,
                  fontWeight: cover > 0.5 ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
