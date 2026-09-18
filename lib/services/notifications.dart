import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/repository.dart' show stableHash;
import 'analytics.dart';

/// On-device reminders: "your show starts in 1 hour" and "bookings are open"
/// for movies the user asked to be reminded about. These work without any
/// server. Marketing pushes to all users (new releases, offers) need
/// Firebase Cloud Messaging, which plugs in once the Firebase project exists.
class Notifications {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'parda_reminders',
      'Show reminders',
      channelDescription: 'Reminders before your show and when bookings open',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static Future<void> init() async {
    if (kIsWeb || _ready) return;
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Karachi'));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _ready = true;
    } catch (e, s) {
      Analytics.recordError(e, s);
    }
  }

  /// Asks for permission (Android 13+ and iOS). Safe to call repeatedly.
  static Future<void> requestPermission() async {
    if (!_ready) return;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e, s) {
      Analytics.recordError(e, s);
    }
  }

  static int _id(String key) => stableHash(key);

  static Future<void> schedule({
    required String key,
    required DateTime when,
    required String title,
    required String body,
  }) async {
    if (!_ready || !when.isAfter(DateTime.now())) return;
    try {
      await _plugin.zonedSchedule(
        id: _id(key),
        scheduledDate: tz.TZDateTime.from(when, tz.local),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
      );
    } catch (e, s) {
      Analytics.recordError(e, s);
    }
  }

  static Future<void> showNow({
    required String key,
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id: _id(key),
        title: title,
        body: body,
        notificationDetails: _details,
      );
    } catch (e, s) {
      Analytics.recordError(e, s);
    }
  }

  static Future<void> cancel(String key) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _id(key));
    } catch (_) {}
  }

  static Future<void> cancelAll() async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
