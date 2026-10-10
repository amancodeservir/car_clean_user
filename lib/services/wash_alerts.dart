import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class WashAlerts {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> show(String title, String body) async {
    try {
      if (!_ready) {
        const android = AndroidInitializationSettings('@mipmap/ic_launcher');
        const ios = DarwinInitializationSettings();
        await _plugin.initialize(
          const InitializationSettings(android: android, iOS: ios),
        );
        await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
        await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        _ready = true;
      }
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'wash_status',
            'Wash updates',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (_) {}
  }
}
