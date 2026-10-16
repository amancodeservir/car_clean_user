import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/address.dart';
import '../providers/account_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/catalog_provider.dart';
import '../services/api.dart';
import '../theme.dart';
import 'ui.dart';

IconData addressIcon(String label) {
  switch (label.toLowerCase()) {
    case 'home':
      return Icons.home_rounded;
    case 'office':
    case 'work':
      return Icons.business_rounded;
    default:
      return Icons.place_rounded;
  }
}

/// Reads the phone location. Shows a message and returns null when it is off
/// or not allowed.
Future<Position?> currentPosition(BuildContext context) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (context.mounted) showMessage(context, 'Turn on location services to use your current location.');
      return null;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) showMessage(context, 'Location is blocked for this app. Allow it in Settings.');
      await Geolocator.openAppSettings();
      return null;
    }
    if (permission == LocationPermission.denied) return null;
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
    );
  } catch (error) {
    if (context.mounted) showMessage(context, 'Could not read your location. Try again.');
    return null;
  }
}

/// Where the wash happens: pick a saved address, add one, or change city.
Future<SavedAddress?> pickAddress(BuildContext context) {
  return showModalBottomSheet<SavedAddress>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _PickAddressSheet(),
  );
}

Future<SavedAddress?> addAddress(BuildContext context) {
  return showModalBottomSheet<SavedAddress>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _AddAddressSheet(),
  );
}

class _PickAddressSheet extends StatelessWidget {
  const _PickAddressSheet();

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountProvider>();
    final signedIn = context.watch<AuthProvider>().isSignedIn;
    final city = context.watch<CatalogProvider>().city;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Where should we come?', style: AppText.h2),
            const SizedBox(height: 14),
            if (signedIn)
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final address in account.addresses)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          color: address.isDefault ? AppColors.yellowWash : null,
                          onTap: () async {
                            try {
                              await account.setDefaultAddress(address);
                            } catch (_) {}
                            if (context.mounted) Navigator.pop(context, address);
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(addressIcon(address.label), size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(address.label, style: AppText.title),
                                    const SizedBox(height: 2),
                                    Text('${address.address}, ${address.city}', style: AppText.small),
                                  ],
                                ),
                              ),
                              if (address.isDefault) const Icon(Icons.check_circle_rounded, color: AppColors.green),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            if (signedIn)
              OutlinedButton.icon(
                onPressed: () async {
                  final added = await addAddress(context);
                  if (added != null && context.mounted) Navigator.pop(context, added);
                },
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('Add a new address'),
              ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.push('/cities');
              },
              icon: const Icon(Icons.location_city_rounded, size: 18),
              label: Text('City: $city · Change'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddAddressSheet extends StatefulWidget {
  const _AddAddressSheet();

  @override
  State<_AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends State<_AddAddressSheet> {
  final _address = TextEditingController();
  String _label = 'Home';
  late String _city = context.read<CatalogProvider>().city;
  double? _latitude;
  double? _longitude;
  bool _locating = false;
  bool _saving = false;

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    final position = await currentPosition(context);
    if (!mounted) return;
    setState(() => _locating = false);
    if (position == null) return;
    final city = context.read<CatalogProvider>().nearestCity(position.latitude, position.longitude);
    if (city == null) {
      showMessage(context, 'Sorry, we do not wash at this location yet.');
      return;
    }
    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
      _city = city.name;
    });
    showMessage(context, 'Pin saved in ${city.name}. Add the flat or parking details below.');
  }

  Future<void> _save() async {
    final text = _address.text.trim();
    if (text.length < 8) {
      showMessage(context, 'Add the full address: flat, building, street and landmark');
      return;
    }
    setState(() => _saving = true);
    try {
      final saved = await context.read<AccountProvider>().addAddress(
            label: _label,
            address: text,
            city: _city,
            latitude: _latitude,
            longitude: _longitude,
            makeDefault: true,
          );
      if (!mounted) return;
      await context.read<CatalogProvider>().setCity(_city);
      if (mounted) Navigator.pop(context, saved);
    } catch (error) {
      if (mounted) showMessage(context, errorText(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cities = context.watch<CatalogProvider>().cities;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add address', style: AppText.h2),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _locating ? null : _locate,
                icon: _locating
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(_latitude == null ? Icons.my_location_rounded : Icons.check_circle_rounded,
                        color: _latitude == null ? null : AppColors.green),
                label: Text(_latitude == null ? 'Use my current location' : 'Location pinned'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _address,
                minLines: 2,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Full address',
                  hintText: 'Flat / house no., building, street, landmark',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: cities.any((city) => city.name == _city) ? _city : null,
                decoration: const InputDecoration(labelText: 'City', prefixIcon: Icon(Icons.location_city_rounded, size: 20)),
                items: [for (final city in cities) DropdownMenuItem(value: city.name, child: Text(city.name))],
                onChanged: (value) => setState(() {
                  _city = value ?? _city;
                  _latitude = null;
                  _longitude = null;
                }),
              ),
              const SizedBox(height: 12),
              Text('Save as', style: AppText.title),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final label in const ['Home', 'Office', 'Other'])
                    ChoiceChip(
                      avatar: Icon(addressIcon(label), size: 16),
                      label: Text(label),
                      selected: _label == label,
                      onSelected: (_) => setState(() => _label = label),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              PrimaryButton(label: 'Save address', loading: _saving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
