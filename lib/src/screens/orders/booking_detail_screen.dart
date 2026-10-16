import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../data/defaults.dart';
import '../../models/booking.dart';
import '../../providers/bookings_provider.dart';
import '../../router.dart';
import '../../services/api.dart';
import '../../theme.dart';
import '../../widgets/slot_picker.dart';
import '../../widgets/ui.dart';

class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  bool _loading = true;
  String? _error;
  bool _working = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _load(quiet: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool quiet = false}) async {
    if (!quiet) setState(() => _error = null);
    try {
      await context.read<BookingsProvider>().fetch(widget.id);
    } catch (error) {
      if (mounted && !quiet) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _run(Future<void> Function() action, {String? done}) async {
    setState(() => _working = true);
    try {
      await action();
      if (mounted && done != null) showMessage(context, done);
    } catch (error) {
      if (mounted) showMessage(context, errorText(error));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingsProvider>().byId(widget.id);
    if (booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking')),
        body: Center(
          child: _loading
              ? const CircularProgressIndicator()
              : EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Booking not found',
                  message: _error ?? 'This booking is not on your account.',
                  action: 'Try again',
                  onAction: _load,
                ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Booking #${booking.shortId}'),
        actions: [
          IconButton(
            tooltip: 'Chat with us',
            onPressed: () => context.push('/booking/${booking.id}/chat'),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.ink,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
          children: [
            _StatusCard(booking),
            const SizedBox(height: 12),
            if (booking.washerName.isNotEmpty) ...[
              _WasherCard(booking),
              const SizedBox(height: 12),
            ],
            _DetailsCard(booking),
            const SizedBox(height: 12),
            _PaymentCard(
              booking,
              working: _working,
              onPay: () => _pay(booking),
            ),
            if (RemotePhoto.canShow(booking.beforePhoto) || RemotePhoto.canShow(booking.afterPhoto)) ...[
              const SizedBox(height: 12),
              _PhotosCard(booking),
            ],
            if (booking.isCompleted) ...[
              const SizedBox(height: 12),
              _RateCard(booking, onRate: (rating, review) {
                return _run(
                  () => context.read<BookingsProvider>().rate(booking.id, rating, review),
                  done: 'Thanks for rating the wash',
                );
              }),
            ],
            if (booking.reports.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ReportsCard(booking),
            ],
            const SizedBox(height: 16),
            _Actions(
              booking,
              working: _working,
              onCancel: () => _cancel(booking),
              onReschedule: () => _reschedule(booking),
              onReport: () => _report(booking),
            ),
            const SizedBox(height: 18),
            _Activity(booking),
          ],
        ),
      ),
    );
  }

  Future<void> _pay(Booking booking) async {
    final bookings = context.read<BookingsProvider>();
    await _run(() async {
      final url = await bookings.payLink(booking.id);
      if (mounted) await openLink(context, url);
    });
  }

  Future<void> _cancel(Booking booking) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CancelSheet(),
    );
    if (reason == null || !mounted) return;
    await _run(
      () => context.read<BookingsProvider>().cancel(booking.id, reason: reason),
      done: 'Booking cancelled',
    );
  }

  Future<void> _reschedule(Booking booking) async {
    final picked = await showModalBottomSheet<(String, Slot)>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RescheduleSheet(booking),
    );
    if (picked == null || !mounted) return;
    await _run(
      () => context.read<BookingsProvider>().reschedule(booking.id, picked.$1, picked.$2.id),
      done: 'Moved to ${dayLabel(picked.$1)}, ${picked.$2.label}',
    );
  }

  Future<void> _report(Booking booking) async {
    final sent = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ReportSheet(),
    );
    if (sent == null || !mounted) return;
    await _run(
      () => context.read<BookingsProvider>().report(booking.id, sent.$1, sent.$2),
      done: 'Thanks. The desk will look into it.',
    );
  }
}

// Progress

const _steps = [
  ('pending', 'Booked', Icons.receipt_long_rounded),
  ('confirmed', 'Confirmed', Icons.verified_rounded),
  ('accepted', 'Washer assigned', Icons.person_pin_rounded),
  ('on_the_way', 'On the way', Icons.directions_bike_rounded),
  ('in_progress', 'Washing', Icons.local_car_wash_rounded),
  ('completed', 'Done', Icons.check_circle_rounded),
];

class _StatusCard extends StatelessWidget {
  const _StatusCard(this.booking);

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    if (booking.isCancelled) {
      return AppCard(
        color: AppColors.redSoft,
        child: Row(
          children: [
            const Icon(Icons.cancel_rounded, color: AppColors.red, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Booking cancelled', style: AppText.h3.copyWith(color: AppColors.red)),
                  Text('${booking.service} · ${dayLabel(booking.date)}', style: AppText.small),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final current = _steps.indexWhere((step) => step.$1 == booking.status);
    final at = {for (final event in booking.timeline) event.status: event.at};
    return AppCard(
      color: AppColors.yellowWash,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(booking.statusLabel, style: AppText.h2),
          const SizedBox(height: 2),
          Text(
            booking.isCompleted ? 'Your vehicle is sparkling clean.' : '${dayLabel(booking.date)} · ${booking.slotTime}',
            style: AppText.body,
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < _steps.length; i++)
            _StepRow(
              icon: _steps[i].$3,
              label: _steps[i].$2,
              when: at[_steps[i].$1] == null ? '' : stamp(at[_steps[i].$1]!),
              done: i <= current,
              active: i == current,
              last: i == _steps.length - 1,
            ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.icon,
    required this.label,
    required this.when,
    required this.done,
    required this.active,
    required this.last,
  });

  final IconData icon;
  final String label;
  final String when;
  final bool done;
  final bool active;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: done ? AppColors.ink : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: done ? AppColors.ink : AppColors.line, width: 1.5),
                  ),
                  child: Icon(icon, size: 15, color: done ? AppColors.yellow : AppColors.faint),
                ),
                if (!last)
                  Expanded(
                    child: Container(width: 2, color: done ? AppColors.ink : AppColors.line),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 4, bottom: last ? 0 : 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: (active ? AppText.title : AppText.body).copyWith(color: done ? AppColors.ink : AppColors.faint),
                    ),
                  ),
                  if (when.isNotEmpty) Text(when, style: AppText.tiny),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WasherCard extends StatelessWidget {
  const _WasherCard(this.booking);

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.yellowSoft,
            child: Text(booking.washerName[0].toUpperCase(), style: AppText.h3),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.washerName, style: AppText.title),
                Text('Your service partner', style: AppText.small),
              ],
            ),
          ),
          if (booking.washerPhone.isNotEmpty && !booking.isCompleted)
            IconButton.filled(
              style: IconButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: Colors.white),
              tooltip: 'Call washer',
              onPressed: () => openLink(context, 'tel:${booking.washerPhone}'),
              icon: const Icon(Icons.call_rounded),
            ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard(this.booking);

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Service details', style: AppText.h3),
          const SizedBox(height: 10),
          _InfoRow(Icons.local_car_wash_outlined, booking.service),
          _InfoRow(booking.isBike ? Icons.two_wheeler_rounded : Icons.directions_car_outlined, booking.vehicleName),
          _InfoRow(Icons.event_outlined, '${dayLabel(booking.date)} · ${booking.slotTime}'),
          _InfoRow(Icons.location_on_outlined, '${booking.address}, ${booking.city}'),
          if (booking.instructions.isNotEmpty) _InfoRow(Icons.notes_rounded, booking.instructions),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.mute),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppText.body)),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard(this.booking, {required this.onPay, required this.working});

  final Booking booking;
  final VoidCallback onPay;
  final bool working;

  // The total is stored after discounts; work back to the service price.
  int get _servicePrice {
    final addons = booking.addons.fold<int>(0, (sum, row) => sum + row.price);
    return booking.price + booking.discount + booking.creditUsed - booking.travelFee - addons;
  }

  @override
  Widget build(BuildContext context) {
    final paid = booking.isPaid;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Payment', style: AppText.h3),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: paid ? AppColors.greenSoft : AppColors.orangeSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  paid ? 'PAID' : (booking.paymentStatus == 'refunded' ? 'REFUNDED' : 'UNPAID'),
                  style: AppText.tiny.copyWith(color: paid ? AppColors.green : AppColors.orange, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _amount(booking.service, rupees(_servicePrice)),
          for (final addon in booking.addons) _amount(addon.name, rupees(addon.price)),
          if (booking.discount > 0) _amount('Discount', '-${rupees(booking.discount)}', green: true),
          if (booking.travelFee > 0) _amount('Travel fee', rupees(booking.travelFee)),
          if (booking.creditUsed > 0) _amount('Referral credit', '-${rupees(booking.creditUsed)}', green: true),
          _amount('Total', rupees(booking.price), strong: true),
          Text(
            paid
                ? (booking.paymentMethod == 'Online' ? 'Paid online' : 'Paid to the washer')
                : (booking.paymentMethod == 'Online' ? 'Online payment pending' : 'Pay the washer by cash or UPI'),
            style: AppText.small,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/booking/${booking.id}/receipt'),
                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                  label: const Text('Receipt'),
                ),
              ),
              if (booking.canPay) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(label: 'Pay online', loading: working, onPressed: onPay),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _amount(String label, String value, {bool strong = false, bool green = false}) {
    final style = strong ? AppText.h3 : AppText.body;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style.copyWith(color: green ? AppColors.green : null, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _PhotosCard extends StatelessWidget {
  const _PhotosCard(this.booking);

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Before and after', style: AppText.h3),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final (label, source) in [('Before', booking.beforePhoto), ('After', booking.afterPhoto)])
                if (RemotePhoto.canShow(source))
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RemotePhoto(source, height: 130),
                          const SizedBox(height: 4),
                          Text(label, style: AppText.smallStrong),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RateCard extends StatefulWidget {
  const _RateCard(this.booking, {required this.onRate});

  final Booking booking;
  final Future<void> Function(int rating, String review) onRate;

  @override
  State<_RateCard> createState() => _RateCardState();
}

class _RateCardState extends State<_RateCard> {
  int _stars = 0;
  final _review = TextEditingController();

  @override
  void dispose() {
    _review.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rated = widget.booking.rating;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(rated == null ? 'How was your wash?' : 'Your rating', style: AppText.h3),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var star = 1; star <= 5; star++)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: rated == null ? () => setState(() => _stars = star) : null,
                  icon: Icon(
                    star <= (rated ?? _stars) ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 32,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
            ],
          ),
          if (rated != null && widget.booking.review.isNotEmpty) Text('"${widget.booking.review}"', style: AppText.body),
          if (rated == null && _stars > 0) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _review,
              maxLines: 3,
              maxLength: 400,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Tell us what went well or what we can do better'),
            ),
            PrimaryButton(label: 'Submit rating', onPressed: () => widget.onRate(_stars, _review.text.trim())),
          ],
        ],
      ),
    );
  }
}

class _ReportsCard extends StatelessWidget {
  const _ReportsCard(this.booking);

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your reports', style: AppText.h3),
          const SizedBox(height: 8),
          for (final report in booking.reports)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(report.note.isEmpty ? 'Photo report' : report.note, style: AppText.body),
                  Text(stamp(report.at), style: AppText.tiny),
                  if (RemotePhoto.canShow(report.image)) ...[
                    const SizedBox(height: 6),
                    RemotePhoto(report.image, height: 120),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions(
    this.booking, {
    required this.working,
    required this.onCancel,
    required this.onReschedule,
    required this.onReport,
  });

  final Booking booking;
  final bool working;
  final VoidCallback onCancel;
  final VoidCallback onReschedule;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      if (booking.canReschedule)
        OutlinedButton.icon(
          onPressed: working ? null : onReschedule,
          icon: const Icon(Icons.edit_calendar_rounded, size: 18),
          label: const Text('Reschedule'),
        ),
      if (booking.isCompleted || booking.isCancelled)
        FilledButton.icon(
          onPressed: () => context.push(bookPath(booking.service)),
          icon: const Icon(Icons.replay_rounded, size: 18),
          label: const Text('Book again'),
        ),
      OutlinedButton.icon(
        onPressed: () => context.push('/booking/${booking.id}/chat'),
        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
        label: const Text('Chat with us'),
      ),
      if (!booking.isCancelled)
        OutlinedButton.icon(
          onPressed: working ? null : onReport,
          icon: const Icon(Icons.report_gmailerrorred_rounded, size: 18),
          label: const Text('Report an issue'),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final button in buttons) ...[button, const SizedBox(height: 8)],
        if (booking.canCancel)
          TextButton(
            onPressed: working ? null : onCancel,
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Cancel booking'),
          )
        else if (booking.isActive)
          Text(
            'A washer has this job, so it can no longer be cancelled in the app. Chat with us if plans changed.',
            style: AppText.small,
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}

class _Activity extends StatelessWidget {
  const _Activity(this.booking);

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    if (booking.timeline.isEmpty) return const SizedBox.shrink();
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text('Activity', style: AppText.h3),
        children: [
          for (final event in booking.timeline.reversed)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.circle, size: 10, color: AppColors.yellowDeep),
              minLeadingWidth: 14,
              title: Text(
                Booking.labelFor(event.status),
                style: AppText.title,
              ),
              subtitle: Text(
                [stamp(event.at), if (event.byName.isNotEmpty) event.byName, if (event.note.isNotEmpty) event.note].join(' · '),
                style: AppText.small,
              ),
            ),
        ],
      ),
    );
  }
}

class _CancelSheet extends StatefulWidget {
  const _CancelSheet();

  @override
  State<_CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends State<_CancelSheet> {
  static const _reasons = [
    'Plans changed',
    'Booked by mistake',
    'Want a different time',
    'Vehicle not available',
    'Other',
  ];
  String _reason = _reasons.first;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Cancel this booking?', style: AppText.h2),
            const SizedBox(height: 4),
            Text('Tell us why. It helps us improve.', style: AppText.small),
            const SizedBox(height: 12),
            for (final reason in _reasons)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                onTap: () => setState(() => _reason = reason),
                leading: Icon(
                  _reason == reason ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: _reason == reason ? AppColors.ink : AppColors.faint,
                ),
                title: Text(reason, style: AppText.title),
              ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context, _reason),
              child: const Text('Cancel booking'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Keep booking')),
          ],
        ),
      ),
    );
  }
}

class _RescheduleSheet extends StatefulWidget {
  const _RescheduleSheet(this.booking);

  final Booking booking;

  @override
  State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<_RescheduleSheet> {
  String _date = '';
  Slot? _slot;

  @override
  Widget build(BuildContext context) {
    final unchanged = _date == widget.booking.date && _slot?.id == widget.booking.timeSlot;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Pick a new time', style: AppText.h2),
            const SizedBox(height: 4),
            Text('Now: ${dayLabel(widget.booking.date)} · ${widget.booking.slotTime}', style: AppText.small),
            const SizedBox(height: 14),
            SlotPicker(
              city: widget.booking.city,
              initialDate: widget.booking.date,
              onChanged: (date, slot) => setState(() {
                _date = date;
                _slot = slot;
              }),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Move booking',
              onPressed: _slot == null || unchanged ? null : () => Navigator.pop(context, (_date, _slot!)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet();

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final _note = TextEditingController();
  String _photo = '';
  bool _picking = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    setState(() => _picking = true);
    try {
      final shot = await ImagePicker().pickImage(source: source, maxWidth: 1100, imageQuality: 55);
      if (shot == null) return;
      final bytes = await shot.readAsBytes();
      if (bytes.length > 1200000) {
        if (mounted) showMessage(context, 'That photo is too large. Try another one.');
        return;
      }
      setState(() => _photo = 'data:image/jpeg;base64,${base64Encode(bytes)}');
    } catch (_) {
      if (mounted) showMessage(context, 'Could not open the photo. Check the camera and photo permissions.');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = _note.text.trim().isNotEmpty || _photo.isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Report an issue', style: AppText.h2),
              const SizedBox(height: 4),
              Text('A spot missed, a scratch, or something else? Add a note and a photo.', style: AppText.small),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                maxLines: 4,
                maxLength: 500,
                onChanged: (_) => setState(() {}),
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'What should we check?'),
              ),
              if (_photo.isNotEmpty) ...[
                RemotePhoto(_photo, height: 140),
                TextButton(onPressed: () => setState(() => _photo = ''), child: const Text('Remove photo')),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _picking ? null : () => _pick(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_outlined, size: 18),
                        label: const Text('Camera'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _picking ? null : () => _pick(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined, size: 18),
                        label: const Text('Gallery'),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 14),
              PrimaryButton(
                label: 'Send report',
                onPressed: ready ? () => Navigator.pop(context, (_note.text.trim(), _photo)) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
