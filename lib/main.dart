import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'authentication/splash_page.dart';
import 'authentication/walkthrough_page.dart';
import 'providers/app_provider.dart';
import 'providers/auth_provider.dart';
import 'router/app_router.dart';
import 'theme/brand_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final gate = await WalkthroughGate.load();
  runApp(MyApp(gate: gate));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.gate});

  final WalkthroughGate gate;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthProvider _auth;
  late final AppProvider _app;
  late final GoRouter _router;
  bool _showSplash = true;
  bool _splashExitScheduled = false;
  late final DateTime _splashStarted;

  @override
  void initState() {
    super.initState();
    _splashStarted = DateTime.now();
    _auth = AuthProvider();
    _app = AppProvider();
    _router = createRouter(_auth, widget.gate);
    _auth.addListener(_maybeLeaveSplash);
    _app.addListener(_maybeLeaveSplash);
    _maybeLeaveSplash();
  }

  void _maybeLeaveSplash() {
    if (!_showSplash || _splashExitScheduled || _auth.isLoading || !_app.isReady) return;
    _splashExitScheduled = true;
    final elapsed = DateTime.now().difference(_splashStarted);
    const minimum = Duration(milliseconds: 1700);
    final remaining = minimum - elapsed;
    Future.delayed(remaining.isNegative ? Duration.zero : remaining, () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  void dispose() {
    _auth.removeListener(_maybeLeaveSplash);
    _app.removeListener(_maybeLeaveSplash);
    _router.dispose();
    _auth.dispose();
    _app.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashPage(),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _auth),
        ChangeNotifierProvider<AppProvider>.value(value: _app),
        ChangeNotifierProvider<WalkthroughGate>.value(value: widget.gate),
      ],
      child: MaterialApp.router(
        title: 'Car Clean Plus',
        debugShowCheckedModeBanner: false,
        theme: BrandTheme.data,
        routerConfig: _router,
      ),
    );
  }
}
