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
      appBar: statusBarBackdrop(AppColors.headerTop),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: const BoxDecoration(gradient: AppColors.headerGradient),
            child: user == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hello there', style: AppText.title.copyWith(fontSize: 17)),
                      const SizedBox(height: 2),
                      Text('Sign in to book, track and pay for your washes.', style: AppText.small),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              label: 'Sign in',
                              dark: true,
                              onPressed: () => context.push('/login?from=/profile'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 42),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
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
                        radius: 23,
                        backgroundColor: AppColors.brand,
                        child: Text(user.initial, style: AppText.h3.copyWith(color: Colors.white)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(user.name, style: AppText.title.copyWith(fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(user.email, style: AppText.tiny.copyWith(color: AppColors.mute, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (user.phone.isNotEmpty)
                              Text('+91 ${user.phone}', style: AppText.tiny.copyWith(color: AppColors.mute, fontSize: 11)),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit profile',
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                        onPressed: () => context.push('/profile/edit'),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                      ),
                    ],
                  ),
          ),
          if (user != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  _Stat(label: 'Washes done', value: '$completed'),
                  const SizedBox(width: 8),
                  _Stat(label: 'Plan washes', value: account.plan.isActive ? '${account.plan.washesLeft}' : '0'),
                  const SizedBox(width: 8),
                  _Stat(label: 'Credit', value: rupees(account.plan.credit)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: _Group(children: [
              _Tile(Icons.directions_car_outlined, 'My vehicles', account.vehicles.isEmpty ? 'Add a car or bike' : '${account.vehicles.length} saved',
                  () => context.push('/vehicles')),
              if (user != null)
                _Tile(Icons.location_on_outlined, 'Saved addresses',
                    account.addresses.isEmpty ? 'Add parking location' : '${account.addresses.length} saved', () => context.push('/addresses')),
              _Tile(Icons.workspace_premium_outlined, 'Wash plans', account.plan.isActive ? account.plan.planName : 'Save on every wash',
                  () => context.go('/plus')),
              if (user != null) _Tile(Icons.card_giftcard_rounded, 'Refer and earn', 'You both get ₹50', () => context.push('/refer')),
              if (user != null)
                _Tile(Icons.notifications_none_rounded, 'Notifications', account.unread > 0 ? '${account.unread} new' : 'Wash updates and offers',
                    () => context.push('/alerts')),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
          const SizedBox(height: 14),
          Center(
            child: Text(
              '${AppConfig.appName} · Your car. Our care.',
              style: AppText.tiny.copyWith(color: AppColors.faint, fontSize: 10.5),
            ),
          ),
          const SizedBox(height: 18),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEF2F6)),
          boxShadow: const [
            BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: AppText.title.copyWith(fontSize: 15)),
            const SizedBox(height: 1),
            Text(label, style: AppText.tiny.copyWith(color: AppColors.mute, fontSize: 10.5), maxLines: 1, overflow: TextOverflow.ellipsis),
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
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFEEF2F6)),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(indent: 48, height: 1),
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
      dense: true,
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      onTap: onTap,
      leading: Icon(icon, color: color, size: 20),
      title: Text(title, style: AppText.bodyStrong.copyWith(color: color, fontSize: 13)),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: AppText.tiny.copyWith(color: AppColors.mute, fontSize: 10.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.faint, size: 18),
    );
  }
}
