import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../models/booking.dart';
import '../../models/catalog.dart';
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
      appBar: statusBarBackdrop(AppColors.headerTop),
      body: RefreshIndicator(
        color: AppColors.brand,
        onRefresh: () => _refresh(context),
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _Header()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
              sliver: SliverList.list(
                children: [
                  if (next != null) ...[
                    _UpcomingCard(next),
                    const SizedBox(height: 14),
                  ],
                  const _Categories(),
                  const SizedBox(height: 18),
                  SectionTitle(
                    'Popular services',
                    subtitle: 'Top-rated doorstep care for your vehicle',
                    action: 'See all',
                    onAction: () => context.push('/services'),
                  ),
                  for (final service in popular) ...[
                    _CompactServiceCard(service),
                  ],
                  const SizedBox(height: 12),
                  const _PlanBanner(),
                  const SizedBox(height: 18),
                  const _Promises(),
                  const SizedBox(height: 14),
                  const _ReferBanner(),
                  const SizedBox(height: 20),
                  Center(child: Text('Your car. Our care.', style: AppText.h3.copyWith(color: AppColors.faint, fontSize: 13))),
                  const SizedBox(height: 2),
                  Center(child: Text('Made in India', style: AppText.tiny)),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Address selector (compact, sleek)
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => auth.isSignedIn ? pickAddress(context) : context.push('/cities'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: const [
                              BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
                            ],
                          ),
                          child: const Icon(Icons.location_on_rounded, size: 18, color: AppColors.brand),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      address?.label ?? catalog.city,
                                      style: AppText.smallStrong.copyWith(fontSize: 13.5),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down_rounded, size: 17, color: AppColors.inkSoft),
                                ],
                              ),
                              Text(
                                address == null
                                    ? (auth.isSignedIn ? 'Add your address' : 'Tap to change city')
                                    : '${address.address}, ${address.city}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.tiny.copyWith(color: AppColors.mute, fontSize: 11),
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
              const SizedBox(width: 6),
              _BellButton(unread: account.unread, signedIn: auth.isSignedIn),
            ],
          ),
          const SizedBox(height: 11),
          // Compact modern search bar
          InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: () => context.push('/services'),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 1.5)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppColors.mute, size: 19),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Search wash, polish, interior clean...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.small.copyWith(color: AppColors.faint, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 11),
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
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.read<AccountProvider>().vehicles.isEmpty ? addVehicle(context) : pickVehicle(context),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 115),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: AppColors.brand),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  name == null ? 'Add Vehicle' : _short(name!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.smallStrong.copyWith(fontSize: 11.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _short(String name) {
    final parts = name.trim().split(' ');
    if (parts.length < 2) return name;
    final skip = parts.length > 2 && parts[1] == 'Suzuki' ? 2 : 1;
    return parts.skip(skip).join(' ');
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.unread, required this.signedIn});

  final int unread;
  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        tooltip: 'Alerts',
        onPressed: () => context.push('/alerts'),
        icon: Badge(
          isLabelVisible: signedIn && unread > 0,
          label: Text('$unread', style: const TextStyle(fontSize: 9)),
          child: const Icon(Icons.notifications_none_rounded, size: 19, color: AppColors.inkSoft),
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
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push(servicePath('Basic Wash')),
      child: Container(
        height: 124,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF1E3A8A)],
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x18000000), blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(
              left: 140,
              child: Image(
                image: AssetImage(Photos.hero),
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xF50F172A), Color(0x000F172A)],
                  stops: [0, 0.48, 0.85],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: AppColors.brand,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, size: 10, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          festival.isEmpty ? 'DOORSTEP CARE' : '${festival.toUpperCase()} OFFER',
                          style: AppText.tiny.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Sparkling Clean,\nRight Where You Park',
                    style: AppText.title.copyWith(color: Colors.white, fontSize: 15.5, height: 1.2),
                  ),
                  Row(
                    children: [
                      if (price > 0)
                        Text.rich(
                          TextSpan(
                            text: 'From ',
                            style: AppText.tiny.copyWith(color: Colors.white70, fontSize: 11),
                            children: [
                              TextSpan(
                                text: rupees(price),
                                style: AppText.smallStrong.copyWith(color: AppColors.brandOnDark, fontSize: 13.5),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Book',
                              style: AppText.smallStrong.copyWith(color: AppColors.ink, fontSize: 11),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.arrow_forward_rounded, size: 11, color: AppColors.ink),
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
}

class _Categories extends StatelessWidget {
  const _Categories();

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final hasWaterless = catalog.offers('Waterless Wash');

    final items = [
      (
        title: 'Car Wash',
        subtitle: 'Foam wash',
        image: Photos.basic,
        onTap: () => context.push('/services?group=wash'),
      ),
      (
        title: 'Detailing',
        subtitle: 'Deep clean',
        image: Photos.interior,
        onTap: () => context.push('/services?group=detailing'),
      ),
      (
        title: hasWaterless ? 'Waterless' : 'Bike Wash',
        subtitle: hasWaterless ? 'Eco wash' : 'Quick shine',
        image: hasWaterless ? Photos.waterless : Photos.complete,
        onTap: () => hasWaterless
            ? context.push(servicePath('Waterless Wash'))
            : context.push('/services?group=wash'),
      ),
      (
        title: 'Wash Plans',
        subtitle: 'Save 40%',
        image: Photos.premium,
        onTap: () => context.go('/plus'),
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _QuickCategoryItem(
              title: items[i].title,
              subtitle: items[i].subtitle,
              image: items[i].image,
              onTap: items[i].onTap,
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickCategoryItem extends StatelessWidget {
  const _QuickCategoryItem({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEEF2F6)),
            boxShadow: const [
              BoxShadow(color: Color(0x06000000), blurRadius: 5, offset: Offset(0, 1.5)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0C000000), blurRadius: 4, offset: Offset(0, 1.5)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    image,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppText.smallStrong.copyWith(fontSize: 11.5, color: AppColors.ink),
              ),
              const SizedBox(height: 1.5),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppText.tiny.copyWith(fontSize: 9.5, color: AppColors.mute),
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.brandWash,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.brandSoft),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () => context.push('/booking/${booking.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    booking.isActive ? Icons.directions_run_rounded : Icons.event_available_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              booking.service,
                              style: AppText.title.copyWith(fontSize: 13.5),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          StatusPill(booking),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${dayLabel(booking.date)} · ${booking.slotTime}',
                        style: AppText.tiny.copyWith(color: AppColors.mute, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.brandSoft),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Track', style: AppText.smallStrong.copyWith(color: AppColors.brand, fontSize: 11)),
                      const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.brand),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactServiceCard extends StatelessWidget {
  const _CompactServiceCard(this.service);

  final ServiceInfo service;

  @override
  Widget build(BuildContext context) {
    final selection = priceForSelection(context, service.name);
    final stats = context.watch<CatalogProvider>().stats(service.name);
    final rating = stats.rating;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE9EEF4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 7,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () => context.push(servicePath(service.name)),
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Row(
              children: [
                Stack(
                  children: [
                    Photo(Photos.forService(service.name), width: 74, height: 74, radius: 10),
                    if (rating != null && rating > 0)
                      Positioned(
                        left: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xDD000000),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 11, color: Color(0xFFFBBF24)),
                              const SizedBox(width: 2),
                              Text(
                                rating.toStringAsFixed(1),
                                style: AppText.tiny.copyWith(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        service.title,
                        style: AppText.title.copyWith(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      if (service.durationLabel.isNotEmpty || service.inclusions.isNotEmpty)
                        Row(
                          children: [
                            if (service.durationLabel.isNotEmpty) ...[
                              const Icon(Icons.schedule_rounded, size: 11, color: AppColors.mute),
                              const SizedBox(width: 3),
                              Text(
                                service.durationLabel,
                                style: AppText.tiny.copyWith(color: AppColors.mute, fontSize: 11),
                              ),
                            ],
                            if (service.durationLabel.isNotEmpty && service.inclusions.isNotEmpty)
                              Text(' • ', style: AppText.tiny.copyWith(color: AppColors.faint)),
                            if (service.inclusions.isNotEmpty)
                              Expanded(
                                child: Text(
                                  service.inclusions.first,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.tiny.copyWith(color: AppColors.inkSoft, fontSize: 11),
                                ),
                              ),
                          ],
                        ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: PriceLine(selection.price, prefix: selection.exact ? '' : 'from'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.brand,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                              minimumSize: const Size(0, 32),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              textStyle: AppText.button.copyWith(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            onPressed: selection.price.isKnown ? () => context.push(bookPath(service.name)) : null,
                            child: const Text('Book'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.go('/plus'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Color(0x12000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF334155),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFBBF24), size: 20),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'CAR CLEAN PLUS',
                        style: AppText.tiny.copyWith(
                          color: const Color(0xFFFBBF24),
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    active ? '${plan.washesLeft} plan washes left' : '${best.washes} washes for ${rupees(best.amount)}',
                    style: AppText.title.copyWith(color: Colors.white, fontSize: 13.5),
                  ),
                  Text(
                    active
                        ? 'Use on your next ${best.service}'
                        : 'Only ${rupees(best.perWash)} per wash',
                    style: AppText.tiny.copyWith(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                active ? 'View' : 'Get Plan',
                style: AppText.smallStrong.copyWith(color: Colors.white, fontSize: 11.5),
              ),
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
    (Icons.home_work_rounded, 'At Doorstep', 'Home or office'),
    (Icons.verified_user_rounded, 'Safe Products', 'Paint-safe wash'),
    (Icons.payments_rounded, 'Pay After Wash', 'Cash or UPI'),
    (Icons.photo_camera_rounded, 'Before & After', 'Photos shared'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Why Car Clean Plus', subtitle: 'Hassle-free doorstep car care'),
        Row(
          children: [
            Expanded(child: _tile(_items[0])),
            const SizedBox(width: 8),
            Expanded(child: _tile(_items[1])),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _tile(_items[2])),
            const SizedBox(width: 8),
            Expanded(child: _tile(_items[3])),
          ],
        ),
      ],
    );
  }

  Widget _tile((IconData, String, String) item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFEEF2F6)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.brandWash,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.$1, size: 16, color: AppColors.brand),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.$2, style: AppText.smallStrong.copyWith(fontSize: 11.5), maxLines: 1),
                Text(item.$3, style: AppText.tiny.copyWith(fontSize: 9.5), maxLines: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferBanner extends StatelessWidget {
  const _ReferBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.greenSoft,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFC6F6D5)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () => context.push('/refer'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.card_giftcard_rounded, color: AppColors.green, size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Invite friends, get ₹50 credit', style: AppText.title.copyWith(fontSize: 13)),
                      Text('Applied automatically on next wash', style: AppText.tiny.copyWith(fontSize: 10.5)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.green),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
