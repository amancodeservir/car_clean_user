import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../models/booking.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bookings_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../router.dart';
import '../../theme.dart';
import '../../widgets/address_sheets.dart';
import '../../widgets/service_card.dart';
import '../../widgets/ui.dart';
import '../../widgets/vehicle_sheets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _refresh(BuildContext context) async {
    await Future.wait([
      context.read<CatalogProvider>().load(),
      context.read<BookingsProvider>().refresh(quiet: true),
      context.read<AccountProvider>().refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final bookings = context.watch<BookingsProvider>();
    final popular = catalog.services.where((service) => service.popular).toList();
    final next = bookings.upcoming.isEmpty ? null : bookings.upcoming.first;
    return Scaffold(
      appBar: statusBarBackdrop(const Color(0xFFFFE680)),
      body: RefreshIndicator(
        color: AppColors.ink,
        onRefresh: () => _refresh(context),
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _Header()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              sliver: SliverList.list(
                children: [
                  if (next != null) ...[
                    _UpcomingCard(next),
                    const SizedBox(height: 18),
                  ],
                  const _Categories(),
                  const SizedBox(height: 22),
                  SectionTitle(
                    'Popular services',
                    subtitle: 'Doorstep care, priced for your vehicle',
                    action: 'See all',
                    onAction: () => context.push('/services'),
                  ),
                  for (final service in popular) ...[
                    ServiceCard(service),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 8),
                  const _PlanBanner(),
                  const SizedBox(height: 22),
                  const _Promises(),
                  const SizedBox(height: 18),
                  const _ReferBanner(),
                  const SizedBox(height: 26),
                  Center(child: Text('Your car. Our care.', style: AppText.h3.copyWith(color: AppColors.faint))),
                  const SizedBox(height: 2),
                  Center(child: Text('Made in India', style: AppText.small)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final account = context.watch<AccountProvider>();
    final auth = context.watch<AuthProvider>();
    final address = auth.isSignedIn ? account.defaultAddress : null;
    final vehicle = account.vehicle;
    final basic = vehicle != null ? catalog.price('Basic Wash', vehicle.category) : catalog.startingPrice('Basic Wash');
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => auth.isSignedIn ? pickAddress(context) : context.push('/cities'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 22),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      address?.label ?? catalog.city,
                                      style: AppText.h3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                                ],
                              ),
                              Text(
                                address == null
                                    ? (auth.isSignedIn ? 'Add your address' : 'Change city')
                                    : '${address.address}, ${address.city}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.small.copyWith(color: AppColors.inkSoft),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _VehicleChip(name: vehicle?.name, icon: vehicleIcon(vehicle)),
              const SizedBox(width: 8),
              _BellButton(unread: account.unread, signedIn: auth.isSignedIn),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push('/services'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF1E3A3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppColors.mute, size: 21),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Search washes and detailing',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body.copyWith(color: AppColors.faint),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _HeroBanner(price: basic.amount, festival: catalog.festival),
        ],
      ),
    );
  }
}

class _VehicleChip extends StatelessWidget {
  const _VehicleChip({required this.name, required this.icon});

  final String? name;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.read<AccountProvider>().vehicles.isEmpty ? addVehicle(context) : pickVehicle(context),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 130),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name == null ? 'Add vehicle' : _short(name!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.smallStrong,
                    ),
                    if (name != null)
                      Text(_brand(name!), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.tiny),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // "Hyundai Creta" → "Creta" over "Hyundai", as the store screenshots show.
  static String _short(String name) {
    final parts = name.trim().split(' ');
    if (parts.length < 2) return name;
    final skip = parts.length > 2 && parts[1] == 'Suzuki' ? 2 : 1;
    return parts.skip(skip).join(' ');
  }

  static String _brand(String name) {
    final parts = name.trim().split(' ');
    if (parts.length < 2) return '';
    return parts.length > 2 && parts[1] == 'Suzuki' ? '${parts[0]} ${parts[1]}' : parts.first;
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.unread, required this.signedIn});

  final int unread;
  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: 'Alerts',
        onPressed: () => context.push('/alerts'),
        icon: Badge(
          isLabelVisible: signedIn && unread > 0,
          label: Text('$unread'),
          child: const Icon(Icons.notifications_none_rounded),
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.price, required this.festival});

  final int price;
  final String festival;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => context.push(servicePath('Basic Wash')),
      child: Container(
        height: 156,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(18)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(left: 120, child: Image(image: AssetImage(Photos.hero), fit: BoxFit.cover)),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.ink, Color(0xE6111827), Color(0x00111827)],
                  stops: [0, 0.45, 0.85],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      festival.isEmpty ? 'DOORSTEP CAR WASH' : '${festival.toUpperCase()} OFFER',
                      style: AppText.tiny.copyWith(color: AppColors.ink, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('Sparkling clean,\nright where you park', style: AppText.h2.copyWith(color: Colors.white)),
                  const Spacer(),
                  if (price > 0)
                    Text.rich(
                      TextSpan(
                        text: 'Starting at ',
                        style: AppText.small.copyWith(color: Colors.white70),
                        children: [
                          TextSpan(text: rupees(price), style: AppText.h3.copyWith(color: AppColors.yellow)),
                        ],
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

class _Categories extends StatelessWidget {
  const _Categories();

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final tiles = <Widget>[
      _CategoryTile(
        title: 'Car & Bike\nWash',
        note: 'Foam and pressure wash',
        image: Photos.basic,
        onTap: () => context.push('/services?group=wash'),
      ),
      _CategoryTile(
        title: 'Deep\nDetailing',
        note: 'Interior and polish',
        image: Photos.interior,
        onTap: () => context.push('/services?group=detailing'),
      ),
      if (catalog.offers('Waterless Wash'))
        _CategoryTile(
          title: 'Waterless\nWash',
          note: 'Eco, no hose needed',
          image: Photos.waterless,
          onTap: () => context.push(servicePath('Waterless Wash')),
        ),
      _CategoryTile(
        title: 'Wash\nPlans',
        note: 'Save on every wash',
        image: Photos.premium,
        onTap: () => context.go('/plus'),
      ),
    ];
    return GridView.count(
      padding: EdgeInsets.zero,
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.45,
      children: tiles,
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.title, required this.note, required this.image, required this.onTap});

  final String title;
  final String note;
  final String image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -6,
                bottom: -6,
                child: Photo(image, width: 84, height: 70, radius: 14),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title.toUpperCase(), style: AppText.smallStrong.copyWith(height: 1.2)),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 90,
                      child: Text(note, style: AppText.tiny.copyWith(color: AppColors.green)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard(this.booking);

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.yellowWash,
      onTap: () => context.push('/booking/${booking.id}'),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(12)),
            child: Icon(booking.isActive ? Icons.directions_run_rounded : Icons.event_available_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(booking.service, style: AppText.title, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    StatusPill(booking),
                  ],
                ),
                const SizedBox(height: 3),
                Text('${dayLabel(booking.date)} · ${booking.slotTime}', style: AppText.small),
              ],
            ),
          ),
          Text('Track', style: AppText.smallStrong),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _PlanBanner extends StatelessWidget {
  const _PlanBanner();

  @override
  Widget build(BuildContext context) {
    final plans = context.watch<CatalogProvider>().plans;
    final plan = context.watch<AccountProvider>().plan;
    if (plans.isEmpty) return const SizedBox.shrink();
    final best = plans.reduce((a, b) => a.perWash <= b.perWash ? a : b);
    final active = plan.isActive;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => context.go('/plus'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.ink, Color(0xFF1F2937)]),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.workspace_premium_rounded, color: AppColors.yellow, size: 20),
                      const SizedBox(width: 6),
                      Text('CAR CLEAN PLUS', style: AppText.tiny.copyWith(color: AppColors.yellow, letterSpacing: 1)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    active ? '${plan.washesLeft} plan washes left' : '${best.washes} washes for ${rupees(best.amount)}',
                    style: AppText.h3.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    active
                        ? 'Use one on your next ${best.service}'
                        : 'That is ${rupees(best.perWash)} a wash. Valid 30 days.',
                    style: AppText.small.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(10)),
              child: Text(active ? 'View' : 'Get plan', style: AppText.smallStrong),
            ),
          ],
        ),
      ),
    );
  }
}

class _Promises extends StatelessWidget {
  const _Promises();

  static const _items = [
    (Icons.home_work_rounded, 'At your doorstep', 'Home, office or society parking'),
    (Icons.verified_user_rounded, 'Trained washers', 'Safe products for your paint'),
    (Icons.payments_rounded, 'Pay after the wash', 'Cash, UPI or online'),
    (Icons.photo_camera_back_rounded, 'Before & after', 'Photos on every booking'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Why Car Clean Plus'),
        GridView.count(
          padding: EdgeInsets.zero,
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.1,
          children: [
            for (final item in _items)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    Icon(item.$1, size: 22, color: AppColors.yellowDeep),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(item.$2, style: AppText.smallStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(item.$3, style: AppText.tiny, maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ReferBanner extends StatelessWidget {
  const _ReferBanner();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.greenSoft,
      onTap: () => context.push('/refer'),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard_rounded, color: AppColors.green, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Invite friends, you both get ₹50', style: AppText.title),
                Text('Credit is used on your next wash', style: AppText.small),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
