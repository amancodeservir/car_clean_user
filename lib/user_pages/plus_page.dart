import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/brand_theme.dart';
import '../utils/constants.dart';

class PlusPage extends StatefulWidget {
  const PlusPage({super.key});

  @override
  State<PlusPage> createState() => _PlusPageState();
}

class _PlusPageState extends State<PlusPage> {
  String _plan = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().user?.token ?? '';
    if (token.isEmpty) return;
    try {
      final plan = await ApiService.getJson(AppConstants.plan, token);
      final data = plan['data'];
      if (!mounted || data is! Map) return;
      final name = '${data['planName'] ?? ''}'.trim();
      final left = data['washesLeft'] ?? 0;
      setState(() {
        _plan = name.isEmpty ? '' : '$name · $left washes left';
      });
    } catch (_) {}
  }

  Future<void> _upgrade() async {
    final token = context.read<AuthProvider>().user?.token ?? '';
    setState(() => _busy = true);
    try {
      await ApiService.sendJson('POST', AppConstants.plan, token, {'name': 'City 4'});
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('City 4 plan is on this account')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text(
              'Plus',
              style: AppType.display,
            ),
            const SizedBox(height: 18),
            const _PlusArt(),
            const SizedBox(height: 18),
            Text(
              'Unlock Plus',
              textAlign: TextAlign.center,
              style: AppType.title,
            ),
            const SizedBox(height: 8),
            Text(
              'A wash plan with priority booking, saved vehicles, and referral credit.',
              textAlign: TextAlign.center,
              style: AppType.body,
            ),
            const SizedBox(height: 18),
            const _Perk(icon: Icons.star_outline, text: 'Priority support and booking'),
            const _Perk(icon: Icons.lock_open_outlined, text: 'City 4 plan: 4 doorstep washes'),
            const _Perk(icon: Icons.card_giftcard_outlined, text: 'Referral credit on a new signup'),
            const _Perk(icon: Icons.bolt_outlined, text: 'Early access to festive offers'),
            if (_plan.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _plan,
                textAlign: TextAlign.center,
                style: AppType.item.copyWith(color: AppConstants.orange),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              height: 54,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppConstants.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _busy ? null : _upgrade,
                child: Text(_busy ? 'Adding plan…' : 'Upgrade to Plus'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlusArt extends StatelessWidget {
  const _PlusArt();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppConstants.well,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Icon(Icons.directions_car_filled, size: 96, color: AppConstants.orange),
    );
  }
}

class _Perk extends StatelessWidget {
  const _Perk({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppConstants.orange),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppType.body)),
        ],
      ),
    );
  }
}
