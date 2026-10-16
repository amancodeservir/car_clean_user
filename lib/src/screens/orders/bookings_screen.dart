import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../models/booking.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bookings_provider.dart';
import '../../router.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final signedIn = context.watch<AuthProvider>().isSignedIn;
    if (!signedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Bookings')),
        body: Center(
          child: EmptyState(
            icon: Icons.event_note_rounded,
            title: 'Sign in to see your bookings',
            message: 'Track the washer, pay, reschedule and rate every wash in one place.',
            action: 'Sign in',
            onAction: () => context.push('/login?from=/bookings'),
          ),
        ),
      );
    }
    final bookings = context.watch<BookingsProvider>();
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Bookings'),
          actions: [
            IconButton(
              tooltip: 'Help',
              onPressed: () => context.push('/help'),
              icon: const Icon(Icons.support_agent_rounded),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: TabBar(
                tabs: [
                  const Tab(height: 36, text: 'Upcoming'),
                  const Tab(height: 36, text: 'Completed'),
                  const Tab(height: 36, text: 'Cancelled'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _BookingList(
              rows: bookings.upcoming,
              empty: const EmptyState(
                icon: Icons.local_car_wash_rounded,
                title: 'No upcoming washes',
                message: 'Book a doorstep wash and it will show up here.',
              ),
              showBook: true,
            ),
            _BookingList(
              rows: bookings.completed,
              empty: const EmptyState(
                icon: Icons.check_circle_outline_rounded,
                title: 'No finished washes yet',
                message: 'Completed washes, receipts and ratings appear here.',
              ),
            ),
            _BookingList(
              rows: bookings.cancelled,
              empty: const EmptyState(
                icon: Icons.event_busy_rounded,
                title: 'Nothing cancelled',
                message: 'Good. Cancelled bookings would be listed here.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  const _BookingList({required this.rows, required this.empty, this.showBook = false});

  final List<Booking> rows;
  final Widget empty;
  final bool showBook;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingsProvider>();
    return RefreshIndicator(
      color: AppColors.ink,
      onRefresh: () => provider.refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (provider.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                color: AppColors.redSoft,
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off_rounded, color: AppColors.red),
                    const SizedBox(width: 10),
                    Expanded(child: Text(provider.error!, style: AppText.small.copyWith(color: AppColors.red))),
                    TextButton(onPressed: provider.refresh, child: const Text('Retry')),
                  ],
                ),
              ),
            ),
          if (rows.isEmpty && provider.loading && !provider.loaded)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
          else if (rows.isEmpty) ...[
            empty,
            if (showBook)
              Center(child: PrimaryButton(label: 'Book a wash', expand: false, onPressed: () => context.push('/services'))),
          ],
          for (final booking in rows) ...[
            BookingCard(booking),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class BookingCard extends StatelessWidget {
  const BookingCard(this.booking, {super.key});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push('/booking/${booking.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Photo(Photos.forService(booking.service), width: 64, height: 64),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusPill(booking),
                          const Spacer(),
                          Text(rupees(booking.price), style: AppText.title),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(booking.service, style: AppText.title),
                      Text(booking.vehicleName, style: AppText.small, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.event_rounded, size: 14, color: AppColors.mute),
                          const SizedBox(width: 4),
                          Text('${dayLabel(booking.date)} · ${booking.slotTime}', style: AppText.smallStrong),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 6, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _hint(booking),
                    style: AppText.tiny.copyWith(color: AppColors.inkSoft),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (booking.isCompleted || booking.isCancelled)
                  TextButton(onPressed: () => context.push(bookPath(booking.service)), child: const Text('Book again'))
                else
                  TextButton(onPressed: () => context.push('/booking/${booking.id}'), child: const Text('Track')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _hint(Booking booking) {
    if (booking.isCancelled) return 'Cancelled';
    if (booking.isCompleted) {
      if (booking.rating == null) return 'Rate this wash';
      return 'You rated it ${booking.rating}/5';
    }
    if (booking.washerName.isNotEmpty) return 'Washer: ${booking.washerName}';
    if (!booking.isPaid && booking.paymentMethod == 'Online') return 'Payment pending';
    return 'Booking #${booking.shortId}';
  }
}
