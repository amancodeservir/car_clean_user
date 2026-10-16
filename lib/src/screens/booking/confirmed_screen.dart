import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../providers/bookings_provider.dart';
import '../../services/api.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

class ConfirmedScreen extends StatefulWidget {
  const ConfirmedScreen({super.key, required this.id, this.openPayment = false});

  final String id;
  final bool openPayment;

  @override
  State<ConfirmedScreen> createState() => _ConfirmedScreenState();
}

class _ConfirmedScreenState extends State<ConfirmedScreen> {
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    if (widget.openPayment) WidgetsBinding.instance.addPostFrameCallback((_) => _pay());
  }

  Future<void> _pay() async {
    final bookings = context.read<BookingsProvider>();
    final booking = bookings.byId(widget.id);
    if (booking == null || booking.isPaid) return;
    setState(() => _paying = true);
    try {
      final url = booking.paymentUrl.startsWith('http') ? booking.paymentUrl : await bookings.payLink(widget.id);
      if (mounted) await openLink(context, url);
    } catch (error) {
      if (mounted) showMessage(context, errorText(error));
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingsProvider>().byId(widget.id);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/bookings');
      },
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE7F6EC), AppColors.paper],
              stops: [0, 0.45],
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 36, 20, 20),
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.5, end: 1),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                  child: const Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.green,
                      child: Icon(Icons.check_rounded, color: Colors.white, size: 48),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Booking Confirmed', style: AppText.h1, textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text(
                  'Your service partner will arrive at the scheduled time.',
                  style: AppText.body,
                  textAlign: TextAlign.center,
                ),
                if (booking != null) ...[
                  const SizedBox(height: 6),
                  Text('Booking ID: #${booking.shortId}', style: AppText.smallStrong, textAlign: TextAlign.center),
                  const SizedBox(height: 22),
                  _Summary(booking),
                  if (booking.paymentMethod == 'Online' && !booking.isPaid) ...[
                    const SizedBox(height: 12),
                    AppCard(
                      color: AppColors.yellowWash,
                      child: Row(
                        children: [
                          const Icon(Icons.credit_card_rounded),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Payment pending. You can pay now, or pay the washer after the service.',
                              style: AppText.small.copyWith(color: AppColors.inkSoft),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                            onPressed: _paying ? null : _pay,
                            child: Text(_paying ? '…' : 'Pay ${rupees(booking.price)}'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 26),
                PrimaryButton(
                  label: 'Track order',
                  icon: Icons.near_me_rounded,
                  onPressed: () => context.pushReplacement('/booking/${widget.id}'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(onPressed: () => context.go('/home'), child: const Text('Back to home')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary(this.booking);

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(booking.isBike ? Icons.two_wheeler_rounded : Icons.directions_car_filled_rounded, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.vehicleName, style: AppText.title),
                    Text(booking.service, style: AppText.small),
                  ],
                ),
              ),
              Text(rupees(booking.price), style: AppText.h3),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
          Row(
            children: [
              const Icon(Icons.event_rounded, size: 18, color: AppColors.mute),
              const SizedBox(width: 8),
              Expanded(child: Text('${dayLabel(booking.date)} · ${booking.slotTime}', style: AppText.bodyStrong)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 18, color: AppColors.mute),
              const SizedBox(width: 8),
              Expanded(child: Text('${booking.address}, ${booking.city}', style: AppText.body)),
            ],
          ),
        ],
      ),
    );
  }
}
