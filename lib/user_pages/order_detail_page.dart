import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/saved_booking.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/brand_theme.dart';
import '../utils/constants.dart';

class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<AppProvider>().orders;
    SavedBooking? order;
    for (final item in orders) {
      if (item.id == id) {
        order = item;
        break;
      }
    }
    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order')),
        body: const Center(child: Text('This wash is no longer in your list.')),
      );
    }
    return _Detail(order: order);
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.order});

  final SavedBooking order;

  bool get _cancelled => order.status == 'cancelled' || order.status == 'canceled';

  @override
  Widget build(BuildContext context) {
    final canCancel = order.status == 'pending';
    final canMove = order.status == 'pending' || order.status == 'confirmed';
    final canPay = order.paymentStatus != 'paid' &&
        order.status != 'cancelled' &&
        order.status != 'canceled' &&
        order.status != 'blocked' &&
        order.status != 'lead';
    final vehicleIcon = order.category == 'Bike' ? Icons.two_wheeler_outlined : Icons.directions_car_outlined;
    return Scaffold(
      backgroundColor: AppConstants.cream,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppConstants.cream,
            foregroundColor: AppConstants.ink,
            title: const Text('Order'),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(AppConstants.photoForService(order.service), fit: BoxFit.cover),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x44000000), Color(0xCC111827)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _label(order.status),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.service,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            height: 1.05,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_cancelled) _Progress(status: order.status),
                  if (_cancelled)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'This wash was cancelled.',
                        style: TextStyle(color: Color(0xFFBE123C), fontWeight: FontWeight.w700),
                      ),
                    ),
                  const SizedBox(height: 18),
                  Text('Order path', style: AppType.title),
                  const SizedBox(height: 10),
                  if (order.timeline.isEmpty)
                    Text('No status changes yet.', style: AppType.body.copyWith(color: AppConstants.mute))
                  else
                    for (final event in order.timeline)
                      _PathStep(
                        title: _label(event.status),
                        when: _stamp(event.at),
                        who: [event.byName, _role(event.byRole)].where((part) => part.isNotEmpty).join(' · '),
                        note: event.note,
                        last: event == order.timeline.last,
                      ),
                  const SizedBox(height: 16),
                  Text('Washer', style: AppType.title),
                  const SizedBox(height: 8),
                  _Row(
                    icon: Icons.person_outline,
                    text: order.washerName.isEmpty
                        ? 'Not assigned yet'
                        : '${order.washerName}${order.washerPhone.isEmpty ? '' : '  ·  ${order.washerPhone}'}',
                  ),
                  const SizedBox(height: 8),
                  Text('Details', style: AppType.title),
                  const SizedBox(height: 10),
                  _Row(icon: vehicleIcon, text: '${order.vehicleName}  ·  ${order.category}'),
                  _Row(icon: Icons.calendar_today_outlined, text: _when(order.date, order.timeSlot)),
                  _Row(icon: Icons.location_on_outlined, text: _place(order.address, order.city)),
                  _Row(
                    icon: Icons.payments_outlined,
                    text: '₹${order.price}  ${order.paymentMethod}',
                    strong: true,
                  ),
                  if (order.rating != null)
                    _Row(icon: Icons.star_outline, text: 'Rated ${order.rating} of 5'),
                  _WashPhoto(label: 'Before', image: order.beforePhoto),
                  _WashPhoto(label: 'After', image: order.afterPhoto),
                  if (order.reports.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Reports', style: AppType.title),
                    const SizedBox(height: 8),
                    for (final report in order.reports) _ReportTile(report: report),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    children: [
                      if ((order.washerPhone.isNotEmpty ? order.washerPhone : order.staffPhone).isNotEmpty)
                        _Button(
                          icon: Icons.call_outlined,
                          label: 'Call washer',
                          onPressed: () => launchUrl(Uri.parse(
                            'tel:${order.washerPhone.isNotEmpty ? order.washerPhone : order.staffPhone}',
                          )),
                        ),
                      if (canPay)
                        _Button(
                          icon: Icons.payments_outlined,
                          label: 'Pay now',
                          onPressed: () => _pay(context),
                        ),
                      if (canCancel)
                        _Button(
                          icon: Icons.cancel_outlined,
                          label: 'Cancel',
                          onPressed: () => _run(context, (token) => ApiService.cancelBooking(token, order.id)),
                        ),
                      if (canMove)
                        _Button(
                          icon: Icons.event_outlined,
                          label: 'Move',
                          onPressed: () => _reschedule(context),
                        ),
                      if (order.status == 'completed' && order.rating == null)
                        _Button(
                          icon: Icons.star_outline,
                          label: 'Rate',
                          onPressed: () => _rate(context),
                        ),
                      _Button(
                        icon: Icons.receipt_long_outlined,
                        label: 'Receipt',
                        onPressed: () => _receipt(context),
                      ),
                      _Button(
                        icon: Icons.chat_bubble_outline,
                        label: 'Message desk',
                        onPressed: () => _support(context),
                      ),
                      _Button(
                        icon: Icons.report_outlined,
                        label: 'Report with photo',
                        onPressed: () => _report(context),
                      ),
                      _Button(
                        icon: Icons.replay_outlined,
                        label: 'Book again',
                        onPressed: () => context.push(Uri(
                          path: '/book',
                          queryParameters: {
                            'service': order.service,
                            'vehicle': order.category == 'Bike' ? 'BIKE' : 'CAR',
                          },
                        ).toString()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _run(BuildContext context, Future<void> Function(String token) action) async {
    final token = context.read<AuthProvider>().user?.token;
    if (token == null || token.isEmpty) return;
    try {
      await action(token);
      if (!context.mounted) return;
      await context.read<AppProvider>().syncOrders(token);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _pay(BuildContext context) async {
    await _run(context, (token) async {
      final data = await ApiService.sendJson('POST', '/booking/${order.id}/pay', token, {});
      if (!context.mounted) return;
      final nested = data['data'];
      final direct = '${data['paymentUrl'] ?? ''}'.trim();
      final nestedUrl = nested is Map ? '${nested['paymentUrl'] ?? ''}'.trim() : '';
      final uri = Uri.tryParse(direct.isNotEmpty ? direct : nestedUrl);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    });
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
            TextField(controller: date, decoration: const InputDecoration(labelText: 'Date YYYY-MM-DD')),
            const SizedBox(height: 8),
            TextField(controller: slot, decoration: const InputDecoration(labelText: 'Slot')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Close')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved != true || !context.mounted) return;
    await _run(context, (token) => ApiService.sendJson('PUT', AppConstants.rescheduleBooking(order.id), token, {
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
                  icon: Icon(Icons.star, color: star <= score ? AppConstants.signal : AppConstants.line),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, score), child: const Text('Send')),
        ],
      ),
    );
    if (saved == null || !context.mounted) return;
    await _run(context, (token) => ApiService.sendJson('PUT', AppConstants.rateBooking(order.id), token, {
          'rating': saved,
        }));
  }

  void _receipt(BuildContext context) {
    context.push(Uri(path: '/receipt', queryParameters: {'id': order.id}).toString());
  }

  Future<void> _report(BuildContext context) async {
    final note = TextEditingController();
    String? photo;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setLocal) => AlertDialog(
          title: const Text('Report this wash'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: note,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'What should the desk check?'),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    final shot = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1200,
                      imageQuality: 55,
                    );
                    if (shot == null) return;
                    final bytes = await shot.readAsBytes();
                    photo = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                    setLocal(() {});
                  },
                  icon: const Icon(Icons.photo_outlined),
                  label: Text(photo == null ? 'Add photo proof' : 'Photo added'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Close')),
            TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Send')),
          ],
        ),
      ),
    );
    if (saved != true || !context.mounted) return;
    if ((note.text.trim().isEmpty) && (photo == null || photo!.isEmpty)) return;
    await _run(context, (token) => ApiService.sendJson('POST', AppConstants.reportBooking(order.id), token, {
          'note': note.text.trim(),
          'image': photo ?? '',
        }));
  }

  Future<void> _support(BuildContext context) async {
    final controller = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Message the desk'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'About this wash'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Send')),
        ],
      ),
    );
    if (saved != true || controller.text.trim().isEmpty || !context.mounted) return;
    await _run(context, (token) => ApiService.sendJson('POST', AppConstants.bookingMessages(order.id), token, {
          'body': controller.text.trim(),
        }));
  }
}

String _stamp(String raw) {
  final parsed = DateTime.tryParse(raw)?.toLocal();
  if (parsed == null) return raw;
  final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
  final minute = parsed.minute.toString().padLeft(2, '0');
  final suffix = parsed.hour >= 12 ? 'PM' : 'AM';
  return '${parsed.day} ${_months[parsed.month - 1]}, $hour:$minute $suffix';
}

String _role(String role) {
  switch (role) {
    case 'customer':
      return 'Customer';
    case 'admin':
    case 'superadmin':
      return 'Desk';
    case 'washer':
    case 'staff':
      return 'Washer';
    default:
      return role;
  }
}

String _label(String status) {
  final cleaned = status.replaceAll('_', ' ').trim();
  if (cleaned.isEmpty) return 'Update';
  return cleaned[0].toUpperCase() + cleaned.substring(1);
}

class _Progress extends StatelessWidget {
  const _Progress({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    const steps = ['pending', 'confirmed', 'on_the_way', 'completed'];
    final aliases = {'accepted': 'confirmed', 'in_progress': 'on_the_way'};
    final current = aliases[status] ?? status;
    final index = steps.indexOf(current);
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) Expanded(child: Container(height: 2, color: i <= index ? AppConstants.signal : AppConstants.line)),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: i <= index ? AppConstants.signal : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: i <= index ? AppConstants.signal : AppConstants.line, width: 2),
            ),
          ),
        ],
      ],
    );
  }
}

class _PathStep extends StatelessWidget {
  const _PathStep({
    required this.title,
    required this.when,
    required this.who,
    required this.last,
    this.note = '',
  });

  final String title;
  final String when;
  final String who;
  final bool last;
  final String note;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(color: AppConstants.signal, shape: BoxShape.circle),
                ),
                if (!last) Expanded(child: Container(width: 2, color: AppConstants.line)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppType.item),
                  Text(when, style: AppType.label.copyWith(color: AppConstants.mute)),
                  if (who.isNotEmpty) Text(who, style: AppType.label.copyWith(color: AppConstants.ink)),
                  if (note.isNotEmpty) Text(note, style: AppType.body.copyWith(color: AppConstants.mute)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WashPhoto extends StatelessWidget {
  const _WashPhoto({required this.label, required this.image});

  final String label;
  final String image;

  @override
  Widget build(BuildContext context) {
    if (!image.startsWith('data:image')) return const SizedBox.shrink();
    final comma = image.indexOf(',');
    if (comma < 0) return const SizedBox.shrink();
    Uint8List bytes;
    try {
      bytes = base64Decode(image.substring(comma + 1));
    } catch (_) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppType.item),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(bytes, height: 160, width: double.infinity, fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.report});

  final OrderReport report;

  @override
  Widget build(BuildContext context) {
    final bytes = _photoBytes(report.image);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(report.note.isEmpty ? 'Photo report' : report.note, style: AppType.body),
          Text('${report.byName} · ${_stamp(report.at)}', style: AppType.label.copyWith(color: AppConstants.mute)),
          if (bytes != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(bytes, height: 140, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
        ],
      ),
    );
  }
}

Uint8List? _photoBytes(String image) {
  if (image.isEmpty) return null;
  final raw = image.contains(',') ? image.split(',').last : image;
  try {
    return base64Decode(raw);
  } catch (_) {
    return null;
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.text, this.strong = false});

  final IconData icon;
  final String text;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppConstants.signal),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: (strong ? AppType.item : AppType.body).copyWith(
                color: strong ? AppConstants.ink : AppConstants.mute,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String _when(String raw, String slot) {
  final parsed = DateTime.tryParse(raw);
  final parts = slot.split(RegExp(r'\s[–-]\s'));
  final clock = (parts.length > 1 ? parts.last : slot).trim();
  if (parsed == null) return [raw.trim(), clock].where((part) => part.isNotEmpty).join(' · ');
  final now = DateTime.now();
  final day = DateTime(parsed.year, parsed.month, parsed.day);
  final today = DateTime(now.year, now.month, now.day);
  final label = day == today
      ? 'Today'
      : day == today.add(const Duration(days: 1))
          ? 'Tomorrow'
          : '${parsed.day} ${_months[parsed.month - 1]}';
  if (clock.isEmpty) return label;
  return '$label · $clock';
}

String _place(String address, String city) {
  final street = address.trim();
  final town = city.trim();
  if (street.isEmpty) return town;
  if (town.isEmpty || street.toLowerCase().contains(town.toLowerCase())) return street;
  return '$street, $town';
}
