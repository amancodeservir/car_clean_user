import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../theme/brand_theme.dart';
import '../utils/constants.dart';

class ServiceDetailPage extends StatelessWidget {
  const ServiceDetailPage({
    super.key,
    required this.title,
    required this.service,
    required this.vehicle,
  });

  final String title;
  final String service;
  final String vehicle;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final category = vehicle == 'BIKE' ? 'Bike' : 'Compact';
    final price = app.priceFor(category: category, service: service);
    final ride = vehicle == 'BIKE' ? 'bike' : 'car';

    return Scaffold(
      backgroundColor: AppConstants.paper,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _Hero(service: service)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppType.display),
                        const SizedBox(height: 12),
                        const Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const _MetaChip(
                              icon: Icons.star_rounded,
                              iconColor: Color(0xFFF5A524),
                              label: '4.8',
                              detail: '(2,589)',
                            ),
                            const _MetaChip(
                              icon: Icons.schedule_rounded,
                              iconColor: Color(0xFF16A34A),
                              label: 'Open',
                              detail: '8:30 AM – 4:30 PM',
                              tint: Color(0xFFECFDF3),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Text('Description', style: AppType.title),
                        const SizedBox(height: 8),
                        Text(
                          'Foam, dust and road film come off at your door. $title is a doorstep wash for your $ride in ${app.city}.',
                          style: AppType.body.copyWith(
                            color: AppConstants.mute,
                            fontWeight: FontWeight.w400,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text('Services', style: AppType.title),
                        const SizedBox(height: 12),
                        const Row(
                          children: [
                            _MiniService(icon: Icons.bubble_chart_outlined, label: 'Foam Wash'),
                            SizedBox(width: 10),
                            _MiniService(icon: Icons.shield_outlined, label: 'Coating'),
                            SizedBox(width: 10),
                            _MiniService(icon: Icons.auto_awesome_outlined, label: 'Polishing'),
                          ],
                        ),
                        const SizedBox(height: 22),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            AppConstants.galleryForService(service),
                            height: 168,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _BookBar(price: price, onBook: () => _sheet(context, price)),
        ],
      ),
    );
  }

  void _sheet(BuildContext context, int price) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppConstants.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  AppConstants.sheetForService(service),
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 14),
              Text(title, style: AppType.title),
              const SizedBox(height: 4),
              Text(
                price == 0 ? 'Price on request' : '₹$price   ·   about 1 hr',
                style: AppType.body.copyWith(color: AppConstants.mute, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    context.push(Uri(path: '/book', queryParameters: {
                      'vehicle': vehicle,
                      'service': service,
                    }).toString());
                  },
                  child: const Text('Add to Cart'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.service});

  final String service;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 292,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(AppConstants.photoForService(service), fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x59000000), Color(0x00000000), Color(0x33000000)],
                stops: [0, 0.45, 1],
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: MediaQuery.paddingOf(context).top + 8,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 2,
              shadowColor: const Color(0x33000000),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  if (context.canPop()) context.pop();
                },
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.arrow_back_rounded, size: 20, color: AppConstants.ink),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.detail,
    this.tint = Colors.white,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String detail;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppConstants.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
            Text(label, style: AppType.item.copyWith(fontSize: 13)),
            const SizedBox(width: 4),
            Text(detail, style: AppType.label.copyWith(color: AppConstants.mute)),
          ],
        ),
      ),
    );
  }
}

class _MiniService extends StatelessWidget {
  const _MiniService({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppConstants.line),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppConstants.signal,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Color(0x332563EB), blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: AppType.item.copyWith(fontSize: 12, height: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookBar extends StatelessWidget {
  const _BookBar({required this.price, required this.onBook});

  final int price;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppConstants.line)),
        boxShadow: [
          BoxShadow(color: Color(0x14111827), blurRadius: 16, offset: Offset(0, -6)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Price', style: AppType.label.copyWith(color: AppConstants.mute)),
                    const SizedBox(height: 2),
                    Text(
                      price == 0 ? 'Ask' : '₹$price',
                      style: AppType.display.copyWith(fontSize: 24),
                    ),
                  ],
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(148, 52),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                ),
                onPressed: onBook,
                child: const Text('Book Now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

