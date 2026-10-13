import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/saved_booking.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/brand_theme.dart';
import '../utils/constants.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _sync(quiet: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _sync({bool quiet = false}) async {
    final token = context.read<AuthProvider>().user?.token;
    await context.read<AppProvider>().syncOrders(token);
    await context.read<AppProvider>().refreshUnread(token);
  }

  Future<void> _run(Future<void> Function(String token) action) async {
    final token = context.read<AuthProvider>().user?.token;
    if (token == null || token.isEmpty) return;
    try {
      await action(token);
      await _sync();
    } catch (error) {
      if (!mounted) return;
      final text = error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<AppProvider>().orders;
    final signedIn = context.watch<AuthProvider>().isAuthenticated;
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: RefreshIndicator(
        onRefresh: _sync,
        child: orders.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 80),
                  const Center(child: BrandIconWell(icon: Icons.receipt_long_outlined)),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      signedIn ? 'No washes booked yet.' : 'Sign in to see your booked washes.',
                      style: AppType.body.copyWith(color: AppConstants.mute, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (!signedIn) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppConstants.signal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => context.push('/login'),
                        icon: const Icon(Icons.login_rounded, size: 18),
                        label: const Text('Sign in'),
                      ),
                    ),
                  ],
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                itemCount: orders.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _Ticket(order: orders[index], run: _run),
              ),
      ),
    );
  }
}

class _Ticket extends StatelessWidget {
  const _Ticket({required this.order, required this.run});

  final SavedBooking order;
  final Future<void> Function(Future<void> Function(String token) action) run;

  _Tone get _tone {
    switch (order.status) {
      case 'confirmed':
        return const _Tone(Color(0xFFECFDF3), Color(0xFF15803D), Icons.check_rounded);
      case 'on_the_way':
      case 'accepted':
      case 'in_progress':
        return const _Tone(AppConstants.signal, Colors.white, Icons.near_me_rounded);
      case 'completed':
        return const _Tone(Color(0xFFF3F4F6), AppConstants.ink, Icons.check_rounded);
      case 'cancelled':
      case 'canceled':
        return const _Tone(Color(0xFFFEF2F2), Color(0xFFB91C1C), Icons.close_rounded);
      default:
        return const _Tone(AppConstants.well, AppConstants.signal, Icons.schedule_rounded);
    }
  }

  String get _statusLabel {
    final cleaned = order.status.replaceAll('_', ' ').trim();
    if (cleaned.isEmpty) return 'Update';
    return cleaned.split(' ').where((word) => word.isNotEmpty).map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  String get _when {
    final clock = _clock(order.timeSlot);
    final day = _day(order.date);
    if (day.isEmpty) return clock;
    if (clock.isEmpty) return day;
    return '$day · $clock';
  }

  String get _place {
    final address = order.address.trim();
    final city = order.city.trim();
    if (address.isEmpty) return city;
    if (city.isEmpty || address.toLowerCase().contains(city.toLowerCase())) return address;
    return '$address, $city';
  }

  String get _vehicle {
    final name = order.vehicleName.trim();
    final category = order.category.trim();
    if (name.isEmpty) return category;
    if (category.isEmpty) return name;
    return '$name · $category';
  }

  @override
  Widget build(BuildContext context) {
    final actions = _actions(context);
    final shown = actions.take(2).toList();
    final extra = actions.skip(2).toList();
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BrandTheme.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => context.push('/order/${order.id}'),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _StatusPill(label: _statusLabel, tone: _tone),
                        const Spacer(),
                        Text('₹${order.price}', style: AppType.title),
                        if (order.paymentMethod.trim().isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            order.paymentMethod,
                            style: AppType.label.copyWith(color: AppConstants.mute),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(order.service, style: AppType.title.copyWith(fontSize: 18)),
                    if (_vehicle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _vehicle,
                        style: AppType.body.copyWith(color: AppConstants.mute, fontWeight: FontWeight.w500),
                      ),
                    ],
                    if (_when.isNotEmpty)
                      Text(_when, style: AppType.item.copyWith(fontSize: 13)),
                    if (_place.isNotEmpty)
                      Text(
                        _place,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.body.copyWith(color: AppConstants.mute, fontWeight: FontWeight.w400),
                      ),
                    if (order.staffName.trim().isNotEmpty)
                      Text(
                        'Washer ${order.staffName.trim()}',
                        style: AppType.label.copyWith(color: AppConstants.mute),
                      ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
              child: Row(
                children: [
                  for (var index = 0; index < shown.length; index++) ...[
                    if (index > 0) const SizedBox(width: 8),
                    Expanded(child: _ActionButton(action: shown[index])),
                  ],
                  if (extra.isNotEmpty)
                    PopupMenuButton<_Act>(
                      tooltip: 'More',
                      icon: const Icon(Icons.more_horiz_rounded, color: AppConstants.ink),
                      onSelected: (action) => action.onTap(),
                      itemBuilder: (context) => [
                        for (final action in extra)
                          PopupMenuItem(
                            value: action,
                            child: Row(
                              children: [
                                Icon(action.icon, size: 18, color: AppConstants.signal),
                                const SizedBox(width: 10),
                                Text(action.label, style: AppType.item),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_Act> _actions(BuildContext context) {
    final canCancel = order.status == 'pending';
    final canMove = order.status == 'pending' || order.status == 'confirmed';
    final active = order.status == 'on_the_way' || order.status == 'accepted' || order.status == 'in_progress';
    return [
      if (canCancel)
        _Act('Cancel', Icons.close_rounded, () => run((token) => ApiService.cancelBooking(token, order.id)), danger: true),
      if (canMove) _Act('Move', Icons.event_rounded, () => _reschedule(context)),
      if (order.status == 'completed' && order.rating == null) _Act('Rate', Icons.star_rounded, () => _rate(context)),
      if (order.staffPhone.trim().isNotEmpty && active)
        _Act('Call', Icons.call_rounded, () => launchUrl(Uri.parse('tel:${order.staffPhone}'))),
      if (order.status == 'completed') _Act('Book again', Icons.replay_rounded, () => _bookAgain(context)),
      _Act('Receipt', Icons.receipt_long_rounded, () => _receipt(context)),
      _Act('Message', Icons.chat_bubble_outline_rounded, () => _support(context)),
      if (order.status != 'completed') _Act('Book again', Icons.replay_rounded, () => _bookAgain(context)),
    ];
  }

  void _bookAgain(BuildContext context) {
    context.push(Uri(
      path: '/book',
      queryParameters: {
        'service': order.service,
        'vehicle': order.category == 'Bike' ? 'BIKE' : 'CAR',
      },
    ).toString());
  }

  Future<void> _reschedule(BuildContext context) async {
    final date = TextEditingController(text: order.date);
    final slot = TextEditingController(text: order.timeSlot);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move this wash'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: date,
              decoration: const InputDecoration(
                labelText: 'Date YYYY-MM-DD',
                prefixIcon: Icon(Icons.calendar_today_outlined, size: 22),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: slot,
              decoration: const InputDecoration(
                labelText: 'Slot',
                prefixIcon: Icon(Icons.schedule_outlined, size: 22),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Close')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved != true) return;
    await run((token) => ApiService.sendJson('PUT', AppConstants.rescheduleBooking(order.id), token, {
          'date': date.text.trim(),
          'timeSlot': slot.text.trim(),
        }));
  }

  Future<void> _rate(BuildContext context) async {
    var score = 5;
    final saved = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate the wash'),
        content: StatefulBuilder(
          builder: (context, setLocal) => Wrap(
            children: [
              for (var star = 1; star <= 5; star++)
                IconButton(
                  onPressed: () => setLocal(() => score = star),
                  icon: Icon(
                    Icons.star_outline,
                    size: 22,
                    color: star <= score ? AppConstants.signal : AppConstants.mute,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, score), child: const Text('Send')),
        ],
      ),
    );
    if (saved == null) return;
    await run((token) => ApiService.sendJson('PUT', AppConstants.rateBooking(order.id), token, {
          'rating': saved,
        }));
  }

  void _receipt(BuildContext context) {
    context.push(Uri(path: '/receipt', queryParameters: {'id': order.id}).toString());
  }

  Future<void> _support(BuildContext context) async {
    final controller = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Message the desk'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'About this wash',
            prefixIcon: Icon(Icons.chat_bubble_outline, size: 22),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Send')),
        ],
      ),
    );
    if (saved != true || controller.text.trim().isEmpty) return;
    await run((token) => ApiService.sendJson('POST', AppConstants.bookingMessages(order.id), token, {
          'body': controller.text.trim(),
        }));
  }
}

class _Tone {
  const _Tone(this.background, this.foreground, this.icon);

  final Color background;
  final Color foreground;
  final IconData icon;
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.tone});

  final String label;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tone.icon, size: 14, color: tone.foreground),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppType.label.copyWith(color: tone.foreground, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _Act {
  const _Act(this.label, this.icon, this.onTap, {this.danger = false});

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action});

  final _Act action;

  @override
  Widget build(BuildContext context) {
    final color = action.danger ? const Color(0xFFB91C1C) : AppConstants.signal;
    return OutlinedButton.icon(
      onPressed: action.onTap,
      icon: Icon(action.icon, size: 16, color: color),
      label: Text(action.label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        visualDensity: VisualDensity.compact,
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        side: BorderSide(color: color.withValues(alpha: 0.45)),
        textStyle: AppType.label.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String _day(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw.trim();
  final now = DateTime.now();
  final day = DateTime(parsed.year, parsed.month, parsed.day);
  final today = DateTime(now.year, now.month, now.day);
  if (day == today) return 'Today';
  if (day == today.add(const Duration(days: 1))) return 'Tomorrow';
  return '${parsed.day} ${_months[parsed.month - 1]}';
}

String _clock(String slot) {
  final parts = slot.split(RegExp(r'\s[–-]\s'));
  return (parts.length > 1 ? parts.last : slot).trim();
}
