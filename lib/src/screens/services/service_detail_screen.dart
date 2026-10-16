import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../data/defaults.dart';
import '../../models/vehicle.dart';
import '../../providers/account_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../router.dart';
import '../../theme.dart';
import '../../widgets/service_card.dart';
import '../../widgets/ui.dart';
import '../../widgets/vehicle_sheets.dart';

class ServiceDetailScreen extends StatefulWidget {
  const ServiceDetailScreen({super.key, required this.service});

  final String service;

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  int _photo = 0;

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final info = catalog.service(widget.service);
    if (info == null || !catalog.offers(widget.service)) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.local_car_wash_outlined,
          title: 'Not available right now',
          message: 'This service is turned off for now. Have a look at the others.',
          action: 'See services',
          onAction: () => context.pushReplacement('/services'),
        ),
      );
    }
    final vehicle = context.watch<AccountProvider>().vehicle;
    final selection = priceForSelection(context, info.name);
    final stats = catalog.stats(info.name);
    final gallery = Photos.galleryFor(info.name);
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 300 + top,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView(
                    onPageChanged: (index) => setState(() => _photo = index),
                    children: [for (final asset in gallery) Image.asset(asset, fit: BoxFit.cover)],
                  ),
                  const IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x66000000), Color(0x00000000), Color(0x55000000)],
                          stops: [0, 0.4, 1],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: top + 8,
                    left: 12,
                    child: _RoundButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => context.canPop() ? context.pop() : context.go('/home'),
                    ),
                  ),
                  Positioned(
                    bottom: 14,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < gallery.length; i++)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _photo ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == _photo ? Colors.white : Colors.white54,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            sliver: SliverList.list(
              children: [
                Text(info.title, style: AppText.h1),
                const SizedBox(height: 4),
                Text(info.tagline, style: AppText.body),
                const SizedBox(height: 10),
                ServiceProof(stats),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (info.durationLabel.isNotEmpty) _Meta(Icons.schedule_rounded, 'Takes ${info.durationLabel}'),
                    const _Meta(Icons.home_work_outlined, 'At your doorstep'),
                    const _Meta(Icons.payments_outlined, 'Pay after service'),
                  ],
                ),
                const SizedBox(height: 18),
                _VehiclePrice(vehicle: vehicle, service: info.name),
                const SizedBox(height: 22),
                Text("What's included", style: AppText.h3),
                const SizedBox(height: 10),
                for (final item in info.inclusions) Bullet(item),
                const SizedBox(height: 18),
                Text('About this service', style: AppText.h3),
                const SizedBox(height: 8),
                Text(info.description, style: AppText.body),
                const SizedBox(height: 22),
                Text('How it works', style: AppText.h3),
                const SizedBox(height: 10),
                const _Step(1, 'Pick a slot', 'Choose a day and time that suits you.'),
                const _Step(2, 'We come to you', 'A trained washer reaches your parking spot with all equipment.'),
                const _Step(3, 'Pay and rate', 'Check the before and after photos, pay, and rate the wash.'),
                const SizedBox(height: 10),
                _AllSizes(service: info.name),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BookBar(
        price: selection.price.amount,
        exact: selection.exact,
        onBook: () => context.push(bookPath(info.name)),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 42, height: 42, child: Icon(icon, size: 22)),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.inkSoft),
          const SizedBox(width: 5),
          Text(label, style: AppText.tiny.copyWith(color: AppColors.inkSoft)),
        ],
      ),
    );
  }
}

class _VehiclePrice extends StatelessWidget {
  const _VehiclePrice({required this.vehicle, required this.service});

  final Vehicle? vehicle;
  final String service;

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final current = vehicle;
    return AppCard(
      color: AppColors.yellowWash,
      onTap: () => current == null ? addVehicle(context) : pickVehicle(context),
      child: Row(
        children: [
          Icon(vehicleIcon(current), size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(current?.name ?? 'Which vehicle?', style: AppText.title),
                const SizedBox(height: 2),
                if (current == null)
                  Text('Add it to see the exact price', style: AppText.small)
                else
                  PriceLine(catalog.price(service, current.category)),
              ],
            ),
          ),
          Text(current == null ? 'Add' : 'Change', style: AppText.smallStrong.copyWith(color: AppColors.navy)),
        ],
      ),
    );
  }
}

class _AllSizes extends StatelessWidget {
  const _AllSizes({required this.service});

  final String service;

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final rows = [
      for (final category in [...Defaults.carCategories, 'Bike'])
        if (catalog.price(service, category).isKnown) category,
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text('Prices by vehicle size', style: AppText.h3),
        children: [
          for (final category in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(category == 'Bike' ? Icons.two_wheeler_rounded : Icons.directions_car_rounded, size: 18, color: AppColors.mute),
                  const SizedBox(width: 10),
                  Expanded(child: Text(Vehicle(name: '', category: category).sizeLabel, style: AppText.body)),
                  Text(rupees(catalog.price(service, category).amount), style: AppText.bodyStrong),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.number, this.title, this.body);

  final int number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.yellow, shape: BoxShape.circle),
            child: Text('$number', style: AppText.smallStrong),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.title),
                Text(body, style: AppText.small),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookBar extends StatelessWidget {
  const _BookBar({required this.price, required this.exact, required this.onBook});

  final int price;
  final bool exact;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exact ? 'Price' : 'Starting at', style: AppText.small),
                    Text(price > 0 ? rupees(price) : '—', style: AppText.h2),
                  ],
                ),
              ),
              SizedBox(
                width: 170,
                child: PrimaryButton(label: 'Book now', onPressed: price > 0 ? onBook : null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
