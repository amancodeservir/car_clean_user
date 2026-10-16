import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/account_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../theme.dart';
import '../../widgets/service_card.dart';
import '../../widgets/ui.dart';
import '../../widgets/vehicle_sheets.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key, this.group = 'all'});

  final String group;

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  static const _groups = [('all', 'All'), ('wash', 'Wash'), ('detailing', 'Detailing'), ('eco', 'Eco')];

  late String _group = _groups.any((row) => row.$1 == widget.group) ? widget.group : 'all';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final vehicle = context.watch<AccountProvider>().vehicle;
    final query = _search.text.trim().toLowerCase();
    final services = catalog.services.where((service) {
      if (_group != 'all' && service.group != _group) return false;
      if (query.isEmpty) return true;
      return service.title.toLowerCase().contains(query) ||
          service.name.toLowerCase().contains(query) ||
          service.tagline.toLowerCase().contains(query) ||
          service.inclusions.any((item) => item.toLowerCase().contains(query));
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search, e.g. interior, foam, polish',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () => setState(_search.clear),
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final group in _groups)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(group.$2),
                      selected: _group == group.$1,
                      selectedColor: AppColors.yellow,
                      onSelected: (_) => setState(() => _group = group.$1),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            color: AppColors.yellowWash,
            onTap: () => vehicle == null ? addVehicle(context) : pickVehicle(context),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(vehicleIcon(vehicle), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    vehicle == null ? 'Add your vehicle to see exact prices' : 'Prices for ${vehicle.name}',
                    style: AppText.smallStrong,
                  ),
                ),
                Text(vehicle == null ? 'Add' : 'Change', style: AppText.smallStrong.copyWith(color: AppColors.navy)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (services.isEmpty)
            const EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No service matches',
              message: 'Try another word, or pick a different filter.',
            ),
          for (final service in services) ...[
            ServiceCard(service),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
