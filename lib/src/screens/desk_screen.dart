import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// Shown when a staff or admin account signs in to the customer app.
class DeskScreen extends StatelessWidget {
  const DeskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: EmptyState(
            icon: Icons.badge_outlined,
            title: 'This is the customer app',
            message:
                '${auth.user?.email ?? 'This account'} is a staff account. Washers and the desk sign in on the Car Clean Plus staff app.',
            action: 'Log out',
            onAction: () => auth.logout(),
          ),
        ),
      ),
      backgroundColor: AppColors.paper,
    );
  }
}
