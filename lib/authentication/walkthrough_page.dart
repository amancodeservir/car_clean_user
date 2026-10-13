import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/brand_theme.dart';
import '../utils/constants.dart';

class WalkthroughGate extends ChangeNotifier {
  WalkthroughGate(this.seen);

  bool seen;

  static Future<WalkthroughGate> load() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('ccp_walkthrough_seen') ?? false;
    return WalkthroughGate(seen);
  }

  Future<void> complete({AuthProvider? auth}) async {
    seen = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ccp_walkthrough_seen', true);
    if (auth != null && auth.isAuthenticated) {
      await auth.markOnboardingSeen();
    }
    notifyListeners();
  }
}

class WalkthroughPage extends StatefulWidget {
  const WalkthroughPage({super.key});

  @override
  State<WalkthroughPage> createState() => _WalkthroughPageState();
}

class _WalkthroughPageState extends State<WalkthroughPage> {
  final _page = PageController();
  int _index = 0;
  String _vehicle = 'CAR';

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_index < 2) {
      await _page.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
      return;
    }
    final app = context.read<AppProvider>();
    final gate = context.read<WalkthroughGate>();
    final auth = context.read<AuthProvider>();
    await app.setVehicle(_vehicle);
    await gate.complete(auth: auth);
  }

  Future<void> _skip() async {
    final gate = context.read<WalkthroughGate>();
    final auth = context.read<AuthProvider>();
    await gate.complete(auth: auth);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.cream,
      body: Stack(
        children: [
          PageView(
            controller: _page,
            onPageChanged: (value) => setState(() => _index = value),
            children: [
              _LookSlide(onNext: _next),
              _StartSlide(onNext: _next),
              _VehicleSlide(
                vehicle: _vehicle,
                onPick: (value) => setState(() => _vehicle = value),
                onNext: _next,
              ),
            ],
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 14),
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: _index == 0 ? Colors.white : AppConstants.ink,
                    backgroundColor: _index == 0 ? const Color(0x33000000) : const Color(0x11000000),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  ),
                  onPressed: _skip,
                  child: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LookSlide extends StatelessWidget {
  const _LookSlide({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 6,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  AppConstants.photoHero,
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x22000000), Color(0x66000000)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: AppType.display,
                    children: [
                      const TextSpan(text: 'A Cleaner Car,\n'),
                      TextSpan(
                        text: 'A Better You.',
                        style: AppType.display.copyWith(color: AppConstants.signal),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your car. Our care. A doorstep wash that makes it look new.',
                  style: AppType.body,
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.centerRight,
                  child: _ArrowButton(onPressed: onNext),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StartSlide extends StatelessWidget {
  const _StartSlide({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28), bottom: Radius.circular(80)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Book Your\nCar Wash',
                      textAlign: TextAlign.center,
                      style: AppType.display.copyWith(color: AppConstants.signal),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'The Car Wash app is your mobile ticket to a sparkling clean car.',
                      textAlign: TextAlign.center,
                      style: AppType.body,
                    ),
                    const SizedBox(height: 14),
                    Container(width: 42, height: 3, color: const Color(0xFFD8D4F5)),
                    const SizedBox(height: 18),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset(
                          AppConstants.bookWashPhoto,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppConstants.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: onNext,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Get Start'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleSlide extends StatelessWidget {
  const _VehicleSlide({
    required this.vehicle,
    required this.onPick,
    required this.onNext,
  });

  final String vehicle;
  final ValueChanged<String> onPick;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE7EFFF), Color(0xFFF5F8FD), Colors.white],
          stops: [0, 0.38, 0.72],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choose your\nvehicle', style: AppType.display),
              const SizedBox(height: 8),
              Text(
                'Packages and prices follow this choice. You can change it later from home.',
                style: AppType.body,
              ),
              const SizedBox(height: 28),
              _VehicleCard(
                title: 'Car',
                subtitle: 'Hatchbacks, sedans, and SUVs',
                icon: Icons.directions_car_filled_outlined,
                selected: vehicle == 'CAR',
                onTap: () => onPick('CAR'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    const Expanded(child: Divider(color: AppConstants.line, thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or', style: AppType.caption),
                    ),
                    const Expanded(child: Divider(color: AppConstants.line, thickness: 1)),
                  ],
                ),
              ),
              _VehicleCard(
                title: 'Bike',
                subtitle: 'Motorcycles and scooters',
                icon: Icons.two_wheeler,
                selected: vehicle == 'BIKE',
                onTap: () => onPick('BIKE'),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppConstants.signal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    textStyle: AppType.body.copyWith(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  onPressed: onNext,
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppConstants.well : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppConstants.signal : AppConstants.line,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppConstants.signal : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: selected ? null : Border.all(color: AppConstants.line),
                ),
                child: Icon(
                  icon,
                  size: 26,
                  color: selected ? Colors.white : AppConstants.signal,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppType.label),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppType.caption),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? AppConstants.signal : AppConstants.line,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppConstants.orange,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: const SizedBox(
          width: 58,
          height: 58,
          child: Icon(Icons.arrow_forward, color: Colors.white),
        ),
      ),
    );
  }
}

