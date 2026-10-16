import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'api.dart';

/// Push registration and on-phone alerts for wash updates.
class Notifications {
  static final _local = FlutterLocalNotificationsPlugin();
  static bool _localReady = false;
  static bool? _firebaseReady;

  static Future<bool> _firebase() async {
    if (_firebaseReady != null) return _firebaseReady!;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      _firebaseReady = true;
    } catch (error) {
      // Android has no google-services.json yet; push stays off there.
      debugPrint('Firebase is not set up: $error');
      _firebaseReady = false;
    }
    return _firebaseReady!;
  }

  /// Sends this phone's push token to the account. Safe to call often.
  static Future<void> registerPush() async {
    if (kIsWeb || !await _firebase()) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;
      await Api.instance.post('/account/push-token', {'token': token});
    } catch (error) {
      debugPrint('Push token was not saved: $error');
    }
  }

  static Future<void> unregisterPush() async {
    if (kIsWeb || _firebaseReady != true) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await Api.instance.delete('/account/push-token', {'token': token});
      }
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }

  static Future<void> _initLocal() async {
    if (_localReady || kIsWeb) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _local.initialize(settings);
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _localReady = true;
  }

  static Future<void> show(String title, String body) async {
    try {
      await _initLocal();
      if (!_localReady) return;
      await _local.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'wash_status',
            'Wash updates',
            channelDescription: 'Status changes for your bookings',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (error) {
      debugPrint('Alert was not shown: $error');
    }
  }
}
