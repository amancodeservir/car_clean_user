import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../theme/brand_theme.dart';
import '../utils/constants.dart';

class LocationPermission extends StatelessWidget {
  const LocationPermission({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
          child: Column(
            children: [
              const BrandIconWell(icon: Icons.location_city_outlined),
              const SizedBox(height: 16),
              Text(
                'Select your city to get',
                textAlign: TextAlign.center,
                style: AppType.display.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                'Professional Auto Care at your Door-Step!',
                textAlign: TextAlign.center,
                style: AppType.title,
              ),
              const SizedBox(height: 12),
              Text(
                'Turn on location so we can confirm the doorstep wash area.',
                textAlign: TextAlign.center,
                style: AppType.body.copyWith(color: AppConstants.mute, height: 1.4),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    if (await Permission.location.request().isGranted) {
                      // Location permission granted.
                    } else {
                      openAppSettings();
                    }
                  },
                  icon: const Icon(Icons.my_location_outlined, size: 20),
                  label: const Text('Open Location Settings'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.push('/cities');
                  },
                  icon: const Icon(Icons.location_city_outlined, size: 20),
                  label: const Text('Browse Cities'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
