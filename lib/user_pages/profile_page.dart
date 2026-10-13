import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/brand_theme.dart';

import '../utils/constants.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final appProvider = Provider.of<AppProvider>(context);
    final user = authProvider.user;
    final phone = (user?.phone ?? '').trim();
    final address = appProvider.address.trim();
    final city = appProvider.city.trim();

    final name = (user?.name ?? '').trim();
    final email = (user?.email ?? '').trim();
    final isBike = appProvider.vehicle == 'BIKE';

    return Scaffold(
      backgroundColor: AppConstants.paper,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _ProfileHero(
            name: name.isEmpty ? 'Your profile' : name,
            email: email.isEmpty ? 'Add email' : email,
            city: city.isEmpty ? 'Select city' : city,
            initial: name.isEmpty ? 'C' : name.substring(0, 1).toUpperCase(),
            onCity: () async {
              final selected = await context.push<String>('/cities');
              if (selected != null && selected.isNotEmpty) {
                appProvider.setCity(selected);
                if (user != null) {
                  final error = await authProvider.updateProfile(
                    name: user.name,
                    phone: user.phone,
                    city: selected,
                    address: appProvider.address,
                  );
                  if (error != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error)),
                    );
                  }
                }
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        label: 'Mobile',
                        value: phone.isEmpty ? 'Add phone' : phone,
                        icon: Icons.phone_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatTile(
                        label: 'Vehicle',
                        value: isBike ? 'Bike' : 'Car',
                        icon: isBike ? Icons.two_wheeler_outlined : Icons.directions_car_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _AddressBand(
                  city: city.isEmpty ? 'Select city' : city,
                  address: address.isEmpty ? 'Add address' : address,
                  empty: address.isEmpty,
                  onTap: () => _editAddress(context, appProvider),
                ),
                const SizedBox(height: 12),
                const _Garage(),
                if (user != null) ...[
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      context.read<AuthProvider>().logout();
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFB91C1C)),
                    label: Text(
                      'Log out',
                      style: AppType.title.copyWith(color: const Color(0xFFB91C1C)),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) {
                          return AlertDialog(
                            content: const Text(
                              'Delete this account? Washes and the login are removed.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          );
                        },
                      );
                      if (confirmed != true || !context.mounted) return;
                      final auth = context.read<AuthProvider>();
                      final message = await auth.deleteAccount();
                      if (message != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message)),
                        );
                      }
                    },
                    child: Text(
                      'Delete account',
                      style: AppType.title.copyWith(color: const Color(0xFFB91C1C)),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppConstants.signal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => context.push('/login'),
                      icon: const Icon(Icons.login_rounded, size: 20),
                      label: const Text('Sign in / Register', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editAddress(
      BuildContext context, AppProvider appProvider) async {
    final controller = TextEditingController(text: appProvider.address);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              BrandIconWell(icon: Icons.location_on_outlined, box: 36, iconSize: 20),
              SizedBox(width: 10),
              Text('Address'),
            ],
          ),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter your address',
              prefixIcon: Icon(Icons.edit_outlined, size: 22),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (saved == true) {
      final nextAddress = controller.text.trim();
      appProvider.setAddress(nextAddress);
      final user = context.mounted ? context.read<AuthProvider>().user : null;
      if (user != null) {
        final error = await context.read<AuthProvider>().updateProfile(
          name: user.name,
          phone: user.phone,
          city: appProvider.city,
          address: nextAddress,
        );
        if (error != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      }
    }
    controller.dispose();
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.email,
    required this.city,
    required this.initial,
    required this.onCity,
  });

  final String name;
  final String email;
  final String city;
  final String initial;
  final VoidCallback onCity;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
      child: SizedBox(
        height: top + 188,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(AppConstants.photoCrew, fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x99111827), Color(0xE6111827)],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, top + 8, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile',
                    style: AppType.label.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          initial,
                          style: AppType.title.copyWith(
                            color: AppConstants.signal,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.title.copyWith(
                                color: Colors.white,
                                fontSize: 22,
                                height: 1.05,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email.replaceAll('@', '@\u200b'),
                              maxLines: 2,
                              style: AppType.label.copyWith(
                                color: Colors.white70,
                                height: 1.25,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: onCity,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            city,
                            style: AppType.label.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BrandTheme.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrandIconWell(icon: icon, box: 30, iconSize: 16),
          const SizedBox(height: 8),
          Text(label, style: AppType.label.copyWith(color: AppConstants.mute)),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppType.title.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _AddressBand extends StatelessWidget {
  const _AddressBand({
    required this.city,
    required this.address,
    required this.empty,
    required this.onTap,
  });

  final String city;
  final String address;
  final bool empty;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Ink(
          decoration: BrandTheme.card,
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              const BrandIconWell(icon: Icons.near_me_outlined, box: 32, iconSize: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Doorstep · $city', style: AppType.label.copyWith(color: AppConstants.mute)),
                    const SizedBox(height: 2),
                    Text(
                      address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.title.copyWith(
                        color: empty ? AppConstants.mute : AppConstants.ink,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppConstants.mute),
            ],
          ),
        ),
      ),
    );
  }
}

class _Garage extends StatefulWidget {
  const _Garage();

  @override
  State<_Garage> createState() => _GarageState();
}

class _GarageState extends State<_Garage> {
  List<Map<String, dynamic>> _vehicles = [];
  String _planName = '';
  int _washesLeft = 0;
  String _code = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().user?.token ?? '';
    if (token.isEmpty) return;
    try {
      final vehicles = await ApiService.getJson(AppConstants.vehicles, token);
      final plan = await ApiService.getJson(AppConstants.plan, token);
      final rows = vehicles['data'];
      final planData = plan['data'];
      if (!mounted) return;
      setState(() {
        if (rows is List) {
          _vehicles = rows.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
        }
        if (planData is Map) {
          _planName = '${planData['planName'] ?? ''}'.trim();
          _washesLeft = int.tryParse('${planData['washesLeft'] ?? 0}') ?? 0;
          _code = '${planData['referralCode'] ?? ''}'.trim();
        }
      });
    } catch (_) {}
  }

  Future<void> _add() async {
    final name = TextEditingController();
    final category = TextEditingController(text: 'Compact');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save a vehicle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.directions_car_outlined, size: 22),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: category,
              decoration: const InputDecoration(
                labelText: 'Size',
                prefixIcon: Icon(Icons.category_outlined, size: 22),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved != true || !mounted) return;
    final token = context.read<AuthProvider>().user?.token ?? '';
    await ApiService.sendJson('POST', AppConstants.vehicles, token, {
      'name': name.text.trim(),
      'category': category.text.trim(),
      'isDefault': true,
    });
    await _load();
  }

  Future<void> _buyPlan() async {
    final token = context.read<AuthProvider>().user?.token ?? '';
    await ApiService.sendJson('POST', AppConstants.plan, token, {'name': 'City 4'});
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final hasPlan = _planName.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Care plan', style: AppType.title),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: AppConstants.ink,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasPlan ? _planName : 'No plan yet',
                      style: AppType.title.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasPlan
                          ? (_code.isEmpty ? 'Doorstep washes on this plan' : 'Code $_code')
                          : 'Four washes, one city.',
                      style: AppType.label.copyWith(color: Colors.white70, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    hasPlan ? '$_washesLeft' : '—',
                    style: AppType.title.copyWith(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  Text(
                    'left',
                    style: AppType.label.copyWith(color: Colors.white70, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(vertical: 6),
            ),
            onPressed: _buyPlan,
            child: const Text('Add City 4 plan'),
          ),
        ),
        Text('Garage', style: AppType.title),
        const SizedBox(height: 8),
        if (_vehicles.isEmpty)
          Text(
            'Save the cars we should know by name.',
            style: AppType.label.copyWith(color: AppConstants.mute),
          ),
        for (final vehicle in _vehicles)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BrandTheme.card,
              child: Row(
                children: [
                  BrandIconWell(
                    icon: '${vehicle['category']}' == 'Bike'
                        ? Icons.two_wheeler_outlined
                        : Icons.directions_car_outlined,
                    box: 32,
                    iconSize: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${vehicle['name']}',
                      style: AppType.item,
                    ),
                  ),
                  Text(
                    '${vehicle['category']}',
                    style: AppType.label.copyWith(color: AppConstants.mute),
                  ),
                ],
              ),
            ),
          ),
        TextButton.icon(
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(vertical: 4),
          ),
          onPressed: _add,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Save a vehicle'),
        ),
      ],
    );
  }
}
