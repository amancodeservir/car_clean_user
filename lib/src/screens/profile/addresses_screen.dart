import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/account_provider.dart';
import '../../services/api.dart';
import '../../theme.dart';
import '../../widgets/address_sheets.dart';
import '../../widgets/ui.dart';

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Saved addresses')),
      body: account.addresses.isEmpty
          ? Center(
              child: EmptyState(
                icon: Icons.location_on_rounded,
                title: 'No addresses yet',
                message: 'Save where your vehicle is parked so booking takes seconds.',
                action: 'Add address',
                onAction: () => addAddress(context),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final address in account.addresses)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      color: address.isDefault ? AppColors.yellowWash : null,
                      onTap: address.isDefault
                          ? null
                          : () async {
                              try {
                                await account.setDefaultAddress(address);
                              } catch (error) {
                                if (context.mounted) showMessage(context, errorText(error));
                              }
                            },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(addressIcon(address.label), size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(address.label, style: AppText.title),
                                    if (address.isDefault) ...[
                                      const SizedBox(width: 8),
                                      Text('DEFAULT', style: AppText.tiny.copyWith(color: AppColors.green)),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text('${address.address}, ${address.city}', style: AppText.small),
                                if (address.hasPin)
                                  Text('Location pinned', style: AppText.tiny.copyWith(color: AppColors.green)),
                                if (!address.isDefault)
                                  Text('Tap to use for bookings', style: AppText.tiny),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remove',
                            onPressed: () async {
                              final ok = await confirm(
                                context,
                                title: 'Remove this address?',
                                message: '${address.address}, ${address.city}',
                                confirmLabel: 'Remove',
                                danger: true,
                              );
                              if (!ok) return;
                              try {
                                await account.removeAddress(address);
                              } catch (error) {
                                if (context.mounted) showMessage(context, errorText(error));
                              }
                            },
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.mute),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  onPressed: () => addAddress(context),
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('Add a new address'),
                ),
              ],
            ),
    );
  }
}
