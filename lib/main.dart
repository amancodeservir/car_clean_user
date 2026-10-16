import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'src/config.dart';
import 'src/providers/account_provider.dart';
import 'src/providers/auth_provider.dart';
import 'src/providers/bookings_provider.dart';
import 'src/providers/catalog_provider.dart';
import 'src/router.dart';
import 'src/services/local_store.dart';
import 'src/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark),
  );
  final store = await LocalStore.open();
  runApp(CarCleanApp(store: store));
}

class CarCleanApp extends StatefulWidget {
  const CarCleanApp({super.key, required this.store});

  final LocalStore store;

  @override
  State<CarCleanApp> createState() => _CarCleanAppState();
}

class _CarCleanAppState extends State<CarCleanApp> {
  late final AuthProvider _auth = AuthProvider(widget.store);
  late final CatalogProvider _catalog = CatalogProvider(widget.store);
  late final TourGate _tour = TourGate(widget.store);
  late final AccountProvider _account = AccountProvider(widget.store, _auth, _catalog);
  late final BookingsProvider _bookings = BookingsProvider(widget.store, _auth);
  late final GoRouter _router = buildRouter(_auth, _tour);

  @override
  void initState() {
    super.initState();
    _catalog.load();
    _auth.start();
  }

  @override
  void dispose() {
    _router.dispose();
    _bookings.dispose();
    _account.dispose();
    _catalog.dispose();
    _auth.dispose();
    _tour.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _catalog),
        ChangeNotifierProvider.value(value: _tour),
        ChangeNotifierProvider.value(value: _account),
        ChangeNotifierProvider.value(value: _bookings),
      ],
      child: MaterialApp.router(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
        builder: (context, child) {
          // Keep layouts readable when the phone uses very large text.
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(textScaler: media.textScaler.clamp(maxScaleFactor: 1.3)),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
