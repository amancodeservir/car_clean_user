import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';
import '../../widgets/vehicle_sheets.dart';

class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountProvider>();
    final signedIn = context.watch<AuthProvider>().isSignedIn;
    final current = account.vehicle;
    return Scaffold(
      appBar: AppBar(title: const Text('My vehicles')),
      body: account.vehicles.isEmpty
          ? Center(
              child: EmptyState(
                icon: Icons.directions_car_filled_rounded,
                title: 'No vehicles yet',
                message: 'Add your car or bike so prices match its size.',
                action: 'Add a vehicle',
                onAction: () => addVehicle(context),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
              children: [
                if (!signedIn)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('Saved on this phone. Sign in to keep it on your account.', style: AppText.small),
                  ),
                for (final vehicle in account.vehicles)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      color: vehicle == current ? AppColors.brandWash : null,
                      padding: const EdgeInsets.all(10),
                      onTap: () => account.selectVehicle(vehicle),
                      child: Row(
                        children: [
                          Icon(vehicleIcon(vehicle), size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(vehicle.name, style: AppText.bodyStrong),
                                Text([vehicle.sizeLabel, if (vehicle.plate.isNotEmpty) vehicle.plate].join(' · '), style: AppText.small),
                                if (vehicle == current)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text('Used for prices and bookings', style: AppText.tiny.copyWith(color: AppColors.green)),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Remove',
                            onPressed: () async {
                              final ok = await confirm(
                                context,
                                title: 'Remove ${vehicle.name}?',
                                message: 'Past bookings are not affected.',
                                confirmLabel: 'Remove',
                                danger: true,
                              );
                              if (!ok) return;
                              try {
                                await account.removeVehicle(vehicle);
                              } catch (error) {
                                if (context.mounted) showMessage(context, errorText(error));
                              }
                            },
                            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.mute),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: () => addVehicle(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add a vehicle'),
                ),
              ],
            ),
    );
  }
}
