import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../authentication/singin_singup.dart';
import '../authentication/splash_page.dart';
import '../authentication/walkthrough_page.dart';
import '../location/user_city_location.dart';
import '../providers/auth_provider.dart';
import '../user_footer/footer.dart';
import '../user_pages/alerts_page.dart';
import '../user_pages/booking_page.dart';
import '../authentication/otp_verificaion.dart';
import '../user_pages/order_detail_page.dart';
import '../user_pages/orders_page.dart';
import '../user_pages/plus_page.dart';
import '../user_pages/profile_page.dart';
import '../user_pages/receipt_page.dart';
import '../user_pages/service_detail_page.dart';
import '../user_pages/user_home_page.dart';
import '../theme/brand_theme.dart';
import '../user_pages/water_page.dart';
import '../utils/constants.dart';

GoRouter createRouter(AuthProvider auth, WalkthroughGate gate) {
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: Listenable.merge([auth, gate]),
    redirect: (context, state) {
      final path = state.matchedLocation;
      if (auth.isLoading) {
        return path == '/boot' ? null : '/boot';
      }
      if (path == '/boot') {
        return '/home';
      }

      final signedIn = auth.isAuthenticated;

      // Staff/Desk redirect
      if (signedIn && auth.user?.role != 'customer') {
        return path == '/desk' ? null : '/desk';
      }

      // Show walkthrough ONLY for new registered customer who has NOT seen onboarding
      final needsOnboarding = signedIn &&
          auth.user?.role == 'customer' &&
          auth.user?.seenOnboarding == false &&
          !gate.seen &&
          path != '/book';

      if (needsOnboarding) {
        return path == '/walkthrough' ? null : '/walkthrough';
      }

      // If user is on login/desk or on walkthrough when already seen, redirect to /home
      if (signedIn) {
        if (path == '/login' ||
            path == '/boot' ||
            path == '/desk' ||
            (path == '/walkthrough' && (gate.seen || auth.user?.seenOnboarding == true))) {
          return '/home';
        }
      }

      // Guest trying to access desk
      if (!signedIn && path == '/desk') {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/boot', builder: (context, state) => const _BootScreen()),
      GoRoute(path: '/walkthrough', builder: (context, state) => const WalkthroughPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginSignupScreen()),
      GoRoute(path: '/otp', builder: (context, state) => const OtpVerificationPage()),
      GoRoute(path: '/desk', builder: (context, state) => const _DeskScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (context, state) => const HomePage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/orders', builder: (context, state) => const OrdersPage()),
              GoRoute(
                path: '/order/:id',
                builder: (context, state) => OrderDetailPage(id: state.pathParameters['id'] ?? ''),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/plus', builder: (context, state) => const PlusPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/book',
        builder: (context, state) => BookingPage(
          initialService: state.uri.queryParameters['service'],
          vehicleType: state.uri.queryParameters['vehicle'] ?? 'CAR',
        ),
      ),
      GoRoute(path: '/cities', builder: (context, state) => const SelectCityPage()),
      GoRoute(path: '/alerts', builder: (context, state) => const AlertsPage()),
      GoRoute(path: '/water', builder: (context, state) => const WaterPage()),
      GoRoute(
        path: '/receipt',
        builder: (context, state) => ReceiptPage(bookingId: state.uri.queryParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/service',
        builder: (context, state) {
          final query = state.uri.queryParameters;
          return ServiceDetailPage(
            title: query['title'] ?? 'Car Wash',
            service: query['service'] ?? 'Basic Wash',
            vehicle: query['vehicle'] ?? 'CAR',
          );
        },
      ),
    ],
  );
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const SplashView();
  }
}

class _DeskScreen extends StatelessWidget {
  const _DeskScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Car Clean Plus')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BrandIconWell(icon: Icons.info_outline),
            const SizedBox(height: 16),
            Text(
              'This phone is the customer book.',
              style: AppType.display.copyWith(fontWeight: FontWeight.w800, height: 1.05),
            ),
            const SizedBox(height: 12),
            Text(
              'Admin and staff sign in on the wash desk app.',
              style: AppType.body.copyWith(color: AppConstants.mute),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.read<AuthProvider>().logout(),
              icon: const Icon(Icons.logout_outlined, size: 20),
              label: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }
}
