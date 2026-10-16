import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/account_provider.dart';
import '../providers/bookings_provider.dart';
import '../theme.dart';

/// Bottom navigation. Also owns the foreground refresh: bookings and alerts
/// refresh when the app comes back, and polling stops in the background.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final bookings = context.read<BookingsProvider>();
    if (state == AppLifecycleState.resumed) {
      bookings.refresh(quiet: true);
      bookings.startPolling();
      context.read<AccountProvider>().refreshUnread();
    } else if (state == AppLifecycleState.paused) {
      bookings.stopPolling();
    }
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = context.select<BookingsProvider, int>((p) => p.upcoming.length);
    return Scaffold(
      body: widget.shell,
      bottomNavigationBar: _NavBar(
        index: widget.shell.currentIndex,
        upcoming: upcoming,
        onTap: (index) {
          HapticFeedback.selectionClick();
          widget.shell.goBranch(index, initialLocation: index == widget.shell.currentIndex);
        },
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.index, required this.onTap, required this.upcoming});

  final int index;
  final int upcoming;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.event_note_outlined, Icons.event_note_rounded, 'Bookings'),
    (Icons.workspace_premium_outlined, Icons.workspace_premium_rounded, 'Plus'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == index,
                    label: _items[i].$3,
                    child: InkWell(
                      onTap: () => onTap(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: i == index ? AppColors.yellow : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Badge(
                              isLabelVisible: i == 1 && upcoming > 0,
                              backgroundColor: AppColors.ink,
                              label: Text('$upcoming'),
                              child: Icon(
                                i == index ? _items[i].$2 : _items[i].$1,
                                size: 23,
                                color: i == index ? AppColors.ink : AppColors.mute,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _items[i].$3,
                            style: (i == index ? AppText.smallStrong : AppText.small).copyWith(
                              fontSize: 11.5,
                              color: i == index ? AppColors.ink : AppColors.mute,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
