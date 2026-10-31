import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/catalog.dart';
import '../providers/account_provider.dart';
import '../providers/catalog_provider.dart';
import '../router.dart';
import '../theme.dart';
import 'ui.dart';

/// Price of [service] for the chosen vehicle, or the lowest price when no
/// vehicle is chosen yet.
({PriceTag price, bool exact}) priceForSelection(BuildContext context, String service) {
  final catalog = context.watch<CatalogProvider>();
  final vehicle = context.watch<AccountProvider>().vehicle;
  if (vehicle != null) return (price: catalog.price(service, vehicle.category), exact: true);
  return (price: catalog.startingPrice(service), exact: false);
}

class ServiceCard extends StatelessWidget {
  const ServiceCard(this.service, {super.key});

  final ServiceInfo service;

  @override
  Widget build(BuildContext context) {
    final selection = priceForSelection(context, service.name);
    final stats = context.watch<CatalogProvider>().stats(service.name);
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push(servicePath(service.name)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Photo(Photos.forService(service.name), width: 78, height: 78),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(service.title, style: AppText.h3),
                      const SizedBox(height: 3),
                      PriceLine(selection.price, prefix: selection.exact ? '' : 'from'),
                      const SizedBox(height: 5),
                      ServiceProof(stats),
                      if (service.durationLabel.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded, size: 13, color: AppColors.mute),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Takes about ${service.durationLabel}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.tiny,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 2),
            child: Column(
              children: [
                for (final item in service.inclusions.take(3)) Bullet(item),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => context.push(servicePath(service.name)),
                    child: const Text('View details'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: selection.price.isKnown ? () => context.push(bookPath(service.name)) : null,
                    child: const Text('Book'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
