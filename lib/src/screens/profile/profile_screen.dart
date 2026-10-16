import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bookings_provider.dart';
import '../../services/api.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final account = context.watch<AccountProvider>();
    final user = auth.user;
    final completed = context.watch<BookingsProvider>().completed.length;

    return Scaffold(
      appBar: statusBarBackdrop(const Color(0xFFFFE680)),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: const BoxDecoration(gradient: AppColors.headerGradient),
            child: user == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hello there', style: AppText.h1),
                      const SizedBox(height: 4),
                      Text('Sign in to book, track and pay for your washes.', style: AppText.body),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: PrimaryButton(label: 'Sign in', dark: true, onPressed: () => context.push('/login?from=/profile'))),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => context.push('/signup?from=/profile'),
                              child: const Text('Create account'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.ink,
                        child: Text(user.initial, style: AppText.h1.copyWith(color: AppColors.yellow)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.name, style: AppText.h2, maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(user.email, style: AppText.small, maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (user.phone.isNotEmpty) Text('+91 ${user.phone}', style: AppText.small),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit profile',
                        onPressed: () => context.push('/profile/edit'),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ],
                  ),
          ),
          if (user != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  _Stat(label: 'Washes done', value: '$completed'),
                  const SizedBox(width: 10),
                  _Stat(label: 'Plan washes', value: account.plan.isActive ? '${account.plan.washesLeft}' : '0'),
                  const SizedBox(width: 10),
                  _Stat(label: 'Credit', value: rupees(account.plan.credit)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _Group(children: [
              _Tile(Icons.directions_car_outlined, 'My vehicles', account.vehicles.isEmpty ? 'Add a car or bike' : '${account.vehicles.length} saved',
                  () => context.push('/vehicles')),
              if (user != null)
                _Tile(Icons.location_on_outlined, 'Saved addresses',
                    account.addresses.isEmpty ? 'Add where your vehicle is parked' : '${account.addresses.length} saved', () => context.push('/addresses')),
              _Tile(Icons.workspace_premium_outlined, 'Wash plans', account.plan.isActive ? account.plan.planName : 'Save on every wash',
                  () => context.go('/plus')),
              if (user != null) _Tile(Icons.card_giftcard_rounded, 'Refer and earn', 'You both get ₹50', () => context.push('/refer')),
              if (user != null)
                _Tile(Icons.notifications_none_rounded, 'Notifications', account.unread > 0 ? '${account.unread} new' : 'Wash updates and offers',
                    () => context.push('/alerts')),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: _Group(children: [
              _Tile(Icons.support_agent_rounded, 'Help and support', 'Call, WhatsApp or email us', () => context.push('/help')),
              if (AppConfig.siteBase.isNotEmpty) ...[
                _Tile(Icons.privacy_tip_outlined, 'Privacy policy', null, () => openLink(context, '${AppConfig.siteBase}/privacy-policy')),
                _Tile(Icons.description_outlined, 'Terms of service', null, () => openLink(context, '${AppConfig.siteBase}/termsofservice')),
              ],
            ]),
          ),
          if (user != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: _Group(children: [
                _Tile(Icons.logout_rounded, 'Log out', null, () async {
                  if (await confirm(context, title: 'Log out?', message: 'You can sign in again any time.', confirmLabel: 'Log out')) {
                    await auth.logout();
                  }
                }),
                _Tile(Icons.delete_outline_rounded, 'Delete account', 'Removes your login, vehicles and alerts', () => _delete(context),
                    danger: true),
              ]),
            ),
          const SizedBox(height: 18),
          Center(child: Text('${AppConfig.appName} · Your car. Our care.', style: AppText.tiny)),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await confirm(
      context,
      title: 'Delete your account?',
      message: 'This removes your login, saved vehicles and notifications. It cannot be undone. Past bookings stay on record for billing.',
      confirmLabel: 'Delete',
      cancelLabel: 'Keep account',
      danger: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await context.read<AuthProvider>().deleteAccount();
      if (context.mounted) showMessage(context, 'Your account was deleted.');
    } catch (error) {
      if (context.mounted) showMessage(context, errorText(error));
    }
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppText.h2),
            Text(label, style: AppText.tiny),
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(indent: 56),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.icon, this.title, this.subtitle, this.onTap, {this.danger = false});

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.red : AppColors.ink;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(title, style: AppText.title.copyWith(color: color)),
      subtitle: subtitle == null ? null : Text(subtitle!, style: AppText.small),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
    );
  }
}
