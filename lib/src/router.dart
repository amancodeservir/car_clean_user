import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'screens/alerts_screen.dart';
import 'screens/auth/auth_screens.dart';
import 'screens/booking/booking_screen.dart';
import 'screens/booking/confirmed_screen.dart';
import 'screens/city_screen.dart';
import 'screens/desk_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/orders/booking_detail_screen.dart';
import 'screens/orders/bookings_screen.dart';
import 'screens/orders/chat_screen.dart';
import 'screens/orders/receipt_screen.dart';
import 'screens/plus/plus_screen.dart';
import 'screens/profile/addresses_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/help_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/refer_screen.dart';
import 'screens/profile/vehicles_screen.dart';
import 'screens/services/service_detail_screen.dart';
import 'screens/services/services_screen.dart';
import 'screens/shell.dart';
import 'screens/splash_screen.dart';
import 'screens/tour_screen.dart';
import 'services/local_store.dart';

/// First-run tour flag, kept on the phone.
class TourGate extends ChangeNotifier {
  TourGate(this._store) : _seen = _store.tourSeen;

  final LocalStore _store;
  bool _seen;

  bool get seen => _seen;

  Future<void> finish() async {
    _seen = true;
    await _store.setTourSeen();
    notifyListeners();
  }
}

const _authPages = {'/login', '/signup', '/forgot'};

/// Pages that need an account. A guest is sent to sign in and brought back.
bool _needsAccount(String path) =>
    path == '/book' ||
    path.startsWith('/booking/') ||
    path == '/alerts' ||
    path == '/addresses' ||
    path == '/profile/edit' ||
    path == '/refer';

GoRouter buildRouter(AuthProvider auth, TourGate tour) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: kDebugMode,
    refreshListenable: Listenable.merge([auth, tour]),
    redirect: (context, state) {
      final path = state.matchedLocation;
      if (auth.status == AuthStatus.unknown) return path == '/splash' ? null : '/splash';
      if (!tour.seen) return path == '/tour' ? null : '/tour';
      if (path == '/tour') return '/home';

      final signedIn = auth.isSignedIn;
      if (signedIn && !auth.user!.isCustomer) return path == '/desk' ? null : '/desk';
      if (path == '/desk') return '/home';
      if (path == '/splash') return '/home';

      if (signedIn && _authPages.contains(path)) {
        final from = state.uri.queryParameters['from'];
        return from != null && from.startsWith('/') && !_authPages.contains(Uri.parse(from).path) ? from : '/home';
      }
      if (!signedIn && _needsAccount(path)) {
        return Uri(path: '/login', queryParameters: {'from': state.uri.toString()}).toString();
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/tour', builder: (_, __) => const TourScreen()),
      GoRoute(path: '/login', builder: (_, state) => SignInScreen(from: state.uri.queryParameters['from'])),
      GoRoute(path: '/signup', builder: (_, state) => SignUpScreen(from: state.uri.queryParameters['from'])),
      GoRoute(path: '/forgot', builder: (_, state) => ForgotPasswordScreen(
          email: state.uri.queryParameters['email'],
          from: state.uri.queryParameters['from'],
        )),
      GoRoute(path: '/desk', builder: (_, __) => const DeskScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, __) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/bookings', builder: (_, __) => const BookingsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/plus', builder: (_, __) => const PlusScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen())]),
        ],
      ),
      GoRoute(
        path: '/services',
        builder: (_, state) => ServicesScreen(group: state.uri.queryParameters['group'] ?? 'all'),
      ),
      GoRoute(
        path: '/service/:name',
        builder: (_, state) => ServiceDetailScreen(service: state.pathParameters['name'] ?? ''),
      ),
      GoRoute(
        path: '/book',
        builder: (_, state) => BookingScreen(service: state.uri.queryParameters['service'] ?? 'Basic Wash'),
      ),
      GoRoute(
        path: '/booking/:id',
        builder: (_, state) => BookingDetailScreen(id: state.pathParameters['id']!),
        routes: [
          GoRoute(path: 'confirmed', builder: (_, state) => ConfirmedScreen(
                id: state.pathParameters['id']!,
                openPayment: state.uri.queryParameters['pay'] == '1',
              )),
          GoRoute(path: 'chat', builder: (_, state) => ChatScreen(id: state.pathParameters['id']!)),
          GoRoute(path: 'receipt', builder: (_, state) => ReceiptScreen(id: state.pathParameters['id']!)),
        ],
      ),
      GoRoute(path: '/alerts', builder: (_, __) => const AlertsScreen()),
      GoRoute(path: '/cities', builder: (_, __) => const CityScreen()),
      GoRoute(path: '/vehicles', builder: (_, __) => const VehiclesScreen()),
      GoRoute(path: '/addresses', builder: (_, __) => const AddressesScreen()),
      GoRoute(path: '/profile/edit', builder: (_, __) => const EditProfileScreen()),
      GoRoute(path: '/refer', builder: (_, __) => const ReferScreen()),
      GoRoute(path: '/help', builder: (_, __) => const HelpScreen()),
    ],
  );
}

/// Path for a service page.
String servicePath(String service) => '/service/${Uri.encodeComponent(service)}';

String bookPath(String service) => Uri(path: '/book', queryParameters: {'service': service}).toString();
