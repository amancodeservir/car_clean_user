import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/brand_theme.dart';
import '../utils/constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _chip = 'Foam Wash';

  static const _chips = ['Foam Wash', 'Stream Wash', 'Polishing'];

  static const _offers = [
    _Offer('Foam Wash', 'Basic Wash', Icons.bubble_chart_outlined, 'Foam, rinse and dry at your door.'),
    _Offer('Stream Wash', 'Premium Wash', Icons.water_drop_outlined, 'Pressure wash with interior vacuum.'),
    _Offer('Polishing', 'Complete Clean', Icons.auto_awesome_outlined, 'Deep clean and a lasting shine.'),
    _Offer('Deep Clean', 'Complete Clean', Icons.cleaning_services_outlined, 'Interior and exterior foam wash.'),
    _Offer('Shine and Coat', 'Premium Wash', Icons.shield_outlined, 'Coat that keeps the paint brighter.'),
    _Offer('Luxury Care', 'Festive Offer', Icons.diamond_outlined, 'Festive detail for a new-car look.'),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final app = context.watch<AppProvider>();
    final name = (user?.name ?? '').trim();
    final first = name.isEmpty ? 'there' : name.split(' ').first;
    final visible = _offers.where((offer) {
      if (_chip == 'Foam Wash') return offer.service == 'Basic Wash' || offer.title == 'Foam Wash';
      if (_chip == 'Stream Wash') return offer.service == 'Premium Wash';
      return offer.service == 'Complete Clean' || offer.title == 'Polishing';
    }).toList();

    return Scaffold(
      backgroundColor: AppConstants.cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: Color(0xFFFFE8D6),
                  child: Icon(Icons.person, color: AppConstants.orange),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome', style: AppType.label),
                      Text(
                        first,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.title,
                      ),
                    ],
                  ),
                ),
                _RoundIcon(icon: Icons.search, onTap: () => _search(context, app.vehicle)),
                const SizedBox(width: 8),
                _RoundIcon(
                  icon: Icons.notifications_none,
                  badge: app.unread,
                  onTap: () => context.push('/alerts'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final city = await context.push<String>('/cities');
                      if (city != null && city.isNotEmpty && context.mounted) {
                        context.read<AppProvider>().setCity(city);
                      }
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 18, color: AppConstants.orange),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            app.address.trim().isEmpty ? app.city : app.address.trim(),
                            overflow: TextOverflow.ellipsis,
                            style: AppType.label,
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down, size: 18),
                      ],
                    ),
                  ),
                ),
                _VehiclePill(vehicle: app.vehicle),
              ],
            ),
            const SizedBox(height: 16),
            _PromoCard(
              onExplore: () => _openDetail(
                context,
                title: 'Luxury Care',
                service: 'Festive Offer',
                vehicle: app.vehicle,
              ),
            ),
            const SizedBox(height: 18),
            Text('Services', style: AppType.title),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final chip in _chips)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(chip),
                        selected: _chip == chip,
                        onSelected: (_) => setState(() => _chip = chip),
                        selectedColor: AppConstants.orange,
                        labelStyle: AppType.label.copyWith(
                          color: _chip == chip ? Colors.white : Colors.black,
                        ),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                        side: BorderSide(color: _chip == chip ? AppConstants.orange : const Color(0xFFE7E4DF)),
                        backgroundColor: Colors.white,
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text('Popular washes', style: AppType.title),
            const SizedBox(height: 10),
            for (final offer in visible.take(3))
              _StudioRow(
                offer: offer,
                price: _price(app, offer),
                onTap: () => _openDetail(context, title: offer.title, service: offer.service, vehicle: app.vehicle),
              ),
            const SizedBox(height: 8),
            Text('Doorstep services', style: AppType.title),
            const SizedBox(height: 10),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisExtent: 114,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              children: [
                for (final offer in [
                  ..._offers.where((offer) => offer.title != 'Stream Wash'),
                  const _Offer('Bike', 'Basic Wash', Icons.two_wheeler, 'A wash for bikes and mopeds.'),
                ])
                  _CategoryTile(
                    offer: offer,
                    onTap: () {
                      final isBike = offer.title == 'Bike';
                      if (isBike) context.read<AppProvider>().setVehicle('BIKE');
                      _openDetail(
                        context,
                        title: isBike ? 'Bike Wash' : offer.title,
                        service: offer.service,
                        vehicle: isBike ? 'BIKE' : app.vehicle,
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Posters', style: AppType.title),
            const SizedBox(height: 10),
            _PosterCard(
              image: AppConstants.photoHero,
              kicker: 'Festive',
              title: 'A new-car shine\nat your door',
              onTap: () => _openDetail(context, title: 'Luxury Care', service: 'Festive Offer', vehicle: app.vehicle),
            ),
            const SizedBox(height: 10),
            _PosterCard(
              image: AppConstants.photoInterior,
              kicker: 'Interior',
              title: 'Seats, mats and\na deep clean',
              onTap: () => _openDetail(context, title: 'Deep Clean', service: 'Complete Clean', vehicle: app.vehicle),
            ),
            const SizedBox(height: 10),
            _PosterCard(
              image: AppConstants.photoBeforeAfter,
              kicker: 'Before and after',
              title: 'See the wash\nup close',
              onTap: () => _openDetail(context, title: 'Complete Clean', service: 'Complete Clean', vehicle: app.vehicle),
            ),
          ],
        ),
      ),
    );
  }

  int _price(AppProvider app, _Offer offer) {
    final category = app.vehicle == 'BIKE' ? 'Bike' : 'Compact';
    return app.priceFor(category: category, service: offer.service);
  }

  void _openDetail(
    BuildContext context, {
    required String title,
    required String service,
    required String vehicle,
  }) {
    context.push(Uri(path: '/service', queryParameters: {
      'title': title,
      'service': service,
      'vehicle': vehicle,
    }).toString());
  }

  Future<void> _search(BuildContext context, String vehicle) async {
    final picked = await showModalBottomSheet<_Offer>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (context) {
        final bottom = MediaQuery.paddingOf(context).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Text('Search a wash', style: AppType.title),
              ),
              for (final offer in _offers)
                ListTile(
                  visualDensity: VisualDensity.compact,
                  leading: Icon(offer.icon, color: AppConstants.orange, size: 22),
                  title: Text(offer.title, style: AppType.item),
                  subtitle: Text(offer.blurb, style: AppType.label),
                  onTap: () => Navigator.pop(context, offer),
                ),
            ],
          ),
        );
      },
    );
    if (picked != null && context.mounted) {
      _openDetail(context, title: picked.title, service: picked.service, vehicle: vehicle);
    }
  }
}

class _Offer {
  const _Offer(this.title, this.service, this.icon, this.blurb);
  final String title;
  final String service;
  final IconData icon;
  final String blurb;
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.onExplore});
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 148,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppConstants.orange,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'Protect your car\nwith a festive detail',
                    style: AppType.title.copyWith(color: Colors.white, height: 1.15),
                  ),
                  const SizedBox(height: 4),
                  Text('Doorstep wash, at your time', style: AppType.label.copyWith(color: Colors.white)),
                  const Spacer(),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppConstants.orange,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      textStyle: AppType.item.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    onPressed: onExplore,
                    child: Text(
                      'Explore',
                      style: AppType.item.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Image.asset(
              AppConstants.photoPromo,
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudioRow extends StatelessWidget {
  const _StudioRow({required this.offer, required this.price, required this.onTap});
  final _Offer offer;
  final int price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(AppConstants.photoForOffer(offer.title), width: 72, height: 72, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(offer.title, style: AppType.item),
                      const SizedBox(height: 2),
                      Text('4.8  ★ ★ ★ ★ ★', style: AppType.label),
                      Text(
                        price == 0 ? 'Open · 8:30 AM to 4:30 PM' : '₹$price  ·  Open · 8:30 AM to 4:30 PM',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.label.copyWith(color: const Color(0xFF16A34A)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppConstants.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('ADD', style: AppType.label.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.offer, required this.onTap});
  final _Offer offer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE7E4DF)),
            ),
            child: Icon(offer.icon, color: AppConstants.orange, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            offer.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppType.label.copyWith(height: 1.2),
          ),
        ],
      ),
    );
  }
}

class _PosterCard extends StatelessWidget {
  const _PosterCard({
    required this.image,
    required this.kicker,
    required this.title,
    required this.onTap,
  });

  final String image;
  final String kicker;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 168,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(image, fit: BoxFit.cover),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xCC111827), Color(0x22111827)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kicker.toUpperCase(),
                        style: AppType.label.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        title,
                        style: AppType.display.copyWith(
                          color: Colors.white,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                        ),
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

class _VehiclePill extends StatelessWidget {
  const _VehiclePill({required this.vehicle});
  final String vehicle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7E4DF)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: vehicle,
          isDense: true,
          style: AppType.label,
          iconSize: 18,
          items: [
            DropdownMenuItem(value: 'CAR', child: Text('4 wheeler', style: AppType.label)),
            DropdownMenuItem(value: 'BIKE', child: Text('2 wheeler', style: AppType.label)),
          ],
          onChanged: (value) {
            if (value != null) context.read<AppProvider>().setVehicle(value);
          },
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.onTap, this.badge = 0});
  final IconData icon;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE7E4DF)),
        ),
        child: Badge(
          isLabelVisible: badge > 0,
          label: Text('$badge'),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}
