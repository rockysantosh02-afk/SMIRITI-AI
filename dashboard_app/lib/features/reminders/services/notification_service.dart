import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Computes a deterministic positive 31-bit integer from a reminder ID string.
/// Safe for Android notification IDs (0 to 2,147,483,647).
int notificationIdFromReminderId(String reminderId) {
  var hash = 0;
  for (var i = 0; i < reminderId.length; i++) {
    hash = (31 * hash + reminderId.codeUnitAt(i)) & 0x7FFFFFFF;
  }
  return hash;
}

/// Abstract contract for local notification management.
abstract class NotificationService {
  Future<bool> initialize();
  Future<bool> requestPermission();
  Future<bool> hasPermission();
  Future<bool> scheduleReminder({
    required int notificationId,
    required String title,
    required String body,
    required DateTime scheduledDate,
    bool isDaily = false,
  });
  Future<void> cancelReminder(int notificationId);
  Future<void> cancelAll();
  Future<List<int>> getPendingNotificationIds();
}

/// Production implementation of [NotificationService] using flutter_local_notifications.
class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  bool _isInitialized = false;

  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String channelId = 'smriti_reminders';
  static const String channelName = 'Smriti AI Reminders';
  static const String channelDescription =
      'Gentle reminders for daily activities and routines';

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      tz.initializeTimeZones();
      try {
        final timeZoneName = DateTime.now().timeZoneName;
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (_) {
        try {
          final offset = DateTime.now().timeZoneOffset;
          final matchingLocation = tz.timeZoneDatabase.locations.values.firstWhere(
            (loc) => loc.currentTimeZone.offset == offset.inMilliseconds,
            orElse: () => tz.getLocation('UTC'),
          );
          tz.setLocalLocation(matchingLocation);
        } catch (_) {
          // Keep default if location resolution fails
        }
      }

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
      );

      final success = await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('[NotificationService] Notification tapped: ${details.id}');
        },
      );

      if (!kIsWeb && Platform.isAndroid) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          const channel = AndroidNotificationChannel(
            channelId,
            channelName,
            description: channelDescription,
            importance: Importance.max,
            enableVibration: true,
            playSound: true,
          );
          await androidPlugin.createNotificationChannel(channel);
        }
      }

      _isInitialized = success ?? true;
      return _isInitialized;
    } catch (e) {
      debugPrint('[NotificationService] Initialization error: $e');
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      if (kIsWeb) return false;

      if (Platform.isAndroid) {
        final androidImpl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (androidImpl != null) {
          final granted = await androidImpl.requestNotificationsPermission();
          return granted ?? false;
        }
      } else if (Platform.isIOS || Platform.isMacOS) {
        final iosImpl = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        if (iosImpl != null) {
          final granted = await iosImpl.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          return granted ?? false;
        }
      }
      return true;
    } catch (e) {
      debugPrint('[NotificationService] Request permission error: $e');
      return false;
    }
  }

  @override
  Future<bool> hasPermission() async {
    try {
      if (kIsWeb) return false;

      if (Platform.isAndroid) {
        final androidImpl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (androidImpl != null) {
          final granted = await androidImpl.areNotificationsEnabled();
          return granted ?? false;
        }
      }
      return true;
    } catch (e) {
      debugPrint('[NotificationService] hasPermission error: $e');
      return false;
    }
  }

  @override
  Future<bool> scheduleReminder({
    required int notificationId,
    required String title,
    required String body,
    required DateTime scheduledDate,
    bool isDaily = false,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      final tzLocation = tz.local;
      var targetDate = tz.TZDateTime(
        tzLocation,
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        scheduledDate.hour,
        scheduledDate.minute,
        scheduledDate.second,
      );

      if (isDaily) {
        // Ensure daily reminder starts in future
        final now = tz.TZDateTime.now(tzLocation);
        while (targetDate.isBefore(now)) {
          targetDate = targetDate.add(const Duration(days: 1));
        }

        debugPrint('[NotificationService] Scheduling daily notification id=$notificationId at $targetDate, tz=${tzLocation.name}');
        try {
          await _plugin.zonedSchedule(
            notificationId,
            title,
            body,
            targetDate,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        } catch (scheduleErr) {
          debugPrint('[NotificationService] Exact daily schedule failed ($scheduleErr), falling back to inexact');
          await _plugin.zonedSchedule(
            notificationId,
            title,
            body,
            targetDate,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        }
      } else {
        // One-time reminder: skip if already in the past
        if (targetDate.isBefore(tz.TZDateTime.now(tzLocation))) {
          debugPrint('[NotificationService] Scheduled date is in the past for id=$notificationId: $targetDate');
          return false;
        }

        debugPrint('[NotificationService] Scheduling one-time notification id=$notificationId at $targetDate, tz=${tzLocation.name}');
        try {
          await _plugin.zonedSchedule(
            notificationId,
            title,
            body,
            targetDate,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        } catch (scheduleErr) {
          debugPrint('[NotificationService] Exact one-time schedule failed ($scheduleErr), falling back to inexact');
          await _plugin.zonedSchedule(
            notificationId,
            title,
            body,
            targetDate,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }

      debugPrint('[NotificationService] Successfully scheduled notification id=$notificationId at $targetDate');
      return true;
    } catch (e) {
      debugPrint('[NotificationService] scheduleReminder failed for id=$notificationId: ${e.runtimeType}: $e');
      return false;
    }
  }

  @override
  Future<void> cancelReminder(int notificationId) async {
    try {
      await _plugin.cancel(notificationId);
    } catch (e) {
      debugPrint('[NotificationService] cancelReminder error: $e');
    }
  }

  @override
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('[NotificationService] cancelAll error: $e');
    }
  }

  @override
  Future<List<int>> getPendingNotificationIds() async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      return pending.map((r) => r.id).toList();
    } catch (e) {
      debugPrint('[NotificationService] getPendingNotificationIds error: $e');
      return [];
    }
  }
}

/// Fake in-memory implementation of [NotificationService] for unit and widget tests.
class FakeNotificationService implements NotificationService {
  bool isInitialized = false;
  bool permissionGranted = true;
  bool shouldFailScheduling = false;

  final Map<int, Map<String, dynamic>> scheduled = {};

  @override
  Future<bool> initialize() async {
    isInitialized = true;
    return true;
  }

  @override
  Future<bool> requestPermission() async {
    return permissionGranted;
  }

  @override
  Future<bool> hasPermission() async {
    return permissionGranted;
  }

  @override
  Future<bool> scheduleReminder({
    required int notificationId,
    required String title,
    required String body,
    required DateTime scheduledDate,
    bool isDaily = false,
  }) async {
    if (shouldFailScheduling) return false;
    scheduled[notificationId] = {
      'title': title,
      'body': body,
      'scheduledDate': scheduledDate,
      'isDaily': isDaily,
    };
    return true;
  }

  @override
  Future<void> cancelReminder(int notificationId) async {
    scheduled.remove(notificationId);
  }

  @override
  Future<void> cancelAll() async {
    scheduled.clear();
  }

  @override
  Future<List<int>> getPendingNotificationIds() async {
    return scheduled.keys.toList();
  }
}
