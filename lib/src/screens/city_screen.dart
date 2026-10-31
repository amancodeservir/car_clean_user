import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../providers/catalog_provider.dart';
import '../theme.dart';
import '../widgets/address_sheets.dart';
import '../widgets/ui.dart';

/// Pick one of the cities we wash in. The list comes from the backend, so a
/// city here is always one a booking will accept.
class CityScreen extends StatefulWidget {
  const CityScreen({super.key});

  @override
  State<CityScreen> createState() => _CityScreenState();
}

class _CityScreenState extends State<CityScreen> {
  final _search = TextEditingController();
  bool _locating = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _pick(String city) async {
    await context.read<CatalogProvider>().setCity(city);
    if (mounted) context.pop(city);
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    final position = await currentPosition(context);
    if (!mounted) return;
    setState(() => _locating = false);
    if (position == null) return;
    final city = context.read<CatalogProvider>().nearestCity(position.latitude, position.longitude);
    if (city == null) {
      showMessage(context, 'We do not wash in your area yet. Pick the nearest city below.');
      return;
    }
    await _pick(city.name);
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final query = _search.text.trim().toLowerCase();
    final cities = catalog.cities.where((city) => city.name.toLowerCase().contains(query)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Select your city')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
        children: [
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration:
                const InputDecoration(hintText: 'Search city', prefixIcon: Icon(Icons.search_rounded, size: 20)),
          ),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            onTap: _locating ? null : _locate,
            child: Row(
              children: [
                _locating
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location_rounded, size: 20, color: AppColors.navy),
                const SizedBox(width: 10),
                Expanded(child: Text('Use my current location', style: AppText.bodyStrong.copyWith(color: AppColors.navy))),
                const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.faint),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('We wash in', style: AppText.bodyStrong),
          const SizedBox(height: 8),
          GridView.count(
            padding: EdgeInsets.zero,
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.0,
            children: [
              for (final city in cities)
                AppCard(
                  padding: const EdgeInsets.all(6),
                  color: city.name == catalog.city ? AppColors.brandWash : null,
                  onTap: () => _pick(city.name),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 42,
                        child: Photos.cityImages[city.name] == null
                            ? const Icon(Icons.location_city_rounded, size: 34, color: AppColors.brandDeep)
                            : Image.asset(Photos.cityImages[city.name]!, fit: BoxFit.contain),
                      ),
                      const SizedBox(height: 6),
                      Text(city.name,
                          style: AppText.smallStrong,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
            ],
          ),
          if (cities.isEmpty)
            const EmptyState(
              icon: Icons.location_off_rounded,
              title: 'Not there yet',
              message: 'We are not in that city yet. Tell us on WhatsApp from Help and support.',
            ),
        ],
      ),
    );
  }
}
