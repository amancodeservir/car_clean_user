// Dev only: runs the app against a backend on this machine and turns on the
// Flutter Driver extension so screens can be driven from tooling.
//
//   flutter run -t test_driver/local_app.dart
//
// Android emulators reach the host at 10.0.2.2 instead of localhost.
import 'dart:io';

import 'package:car_clean_user/main.dart' as app;
import 'package:car_clean_user/src/config.dart';
import 'package:flutter_driver/driver_extension.dart';

Future<void> main() async {
  enableFlutterDriverExtension();
  AppConfig.apiBase = Platform.isAndroid ? 'http://10.0.2.2:5001/api' : 'http://localhost:5001/api';
  await app.main();
}
