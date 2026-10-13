import 'package:car_clean_user/providers/app_provider.dart';
import 'package:car_clean_user/theme/brand_theme.dart';
import 'package:car_clean_user/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class WaterPage extends StatelessWidget {
  const WaterPage({super.key});

  @override
  Widget build(BuildContext context) {
    const service = 'Waterless Wash';
    final app = context.watch<AppProvider>();
    if (!app.offers(service)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Waterless wash'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Waterless wash is not available right now.'),
          ),
        ),
      );
    }
    final compact = app.priceFor(category: 'Compact', service: service);
    final standard = app.priceFor(category: 'Standard', service: service);
    final large = app.priceFor(category: 'Large', service: service);
    final bike = app.priceFor(category: 'Bike', service: service);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Waterless wash'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const BrandPhoto(asset: AppConstants.photoWaterless, height: 180),
                const SizedBox(height: 16),
                Text(
                  'Doorstep waterless wash',
                  style: AppType.display.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'A waterless wash comes to your home or office. It is an eco-friendly clean that uses very little water and leaves the vehicle spotless where it is parked.',
                  style: AppType.body.copyWith(color: AppConstants.mute, height: 1.4),
                ),
                const SizedBox(height: 16),
                const _Benefit(
                  icon: Icons.eco_outlined,
                  text: 'Eco-friendly formula',
                ),
                const _Benefit(
                  icon: Icons.water_drop_outlined,
                  text: 'Low water use',
                ),
                const _Benefit(
                  icon: Icons.home_work_outlined,
                  text: 'At your home or office',
                ),
                const SizedBox(height: 8),
                Text(
                  'Waterless Wash',
                  style: AppType.title,
                ),
                const SizedBox(height: 12),
                _PriceRow(
                  icon: Icons.directions_car_outlined,
                  label: 'Compact',
                  price: 'From ₹$compact',
                ),
                _PriceRow(
                  icon: Icons.directions_car_outlined,
                  label: 'Standard',
                  price: '₹$standard',
                ),
                _PriceRow(
                  icon: Icons.airport_shuttle_outlined,
                  label: 'Large',
                  price: '₹$large',
                ),
                _PriceRow(
                  icon: Icons.two_wheeler_outlined,
                  label: 'Bike',
                  price: '₹$bike',
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final vehicle = context.read<AppProvider>().vehicle;
                    context.push(
                      Uri(
                        path: '/book',
                        queryParameters: {
                          'service': 'Waterless Wash',
                          'vehicle': vehicle,
                        },
                      ).toString(),
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Book waterless wash'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_outlined, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BrandTheme.card,
      child: Row(
        children: [
          BrandIconWell(icon: icon, box: 40, iconSize: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppType.item,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.icon,
    required this.label,
    required this.price,
  });

  final IconData icon;
  final String label;
  final String price;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BrandTheme.card,
      child: Row(
        children: [
          BrandIconWell(icon: icon, box: 36, iconSize: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppType.item,
            ),
          ),
          if (price.startsWith('From'))
            Text(
              'From ',
              style: AppType.label.copyWith(color: AppConstants.mute, fontWeight: FontWeight.w600),
            ),
          const Icon(
            Icons.currency_rupee_outlined,
            size: 20,
            color: AppConstants.signal,
          ),
          Text(
            price.replaceAll(RegExp(r'[^0-9]'), ''),
            style: AppType.title.copyWith(
              color: AppConstants.signal,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
