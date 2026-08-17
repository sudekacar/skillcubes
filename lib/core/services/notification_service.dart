import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Duolingo-style local streak reminders (daily at 20:00 local).
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _prefsEnabledKey = 'streak_reminders_enabled';
  static const _channelId = 'skillcubes_streak';
  static const _channelName = 'Streak Reminders';
  static const _notificationId = 42001;
  static const _reminderHour = 20;
  static const _reminderMinute = 0;

  static const reminderTitle = 'Serini Bozma! 🔥';
  static const reminderBody =
      'Zihnin seni bekliyor! Bugünkü 3 dakikalık egzersizini yapmadın.';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  SharedPreferences? _prefs;

  bool get isInitialized => _initialized;

  Future<bool> get remindersEnabled async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getBool(_prefsEnabledKey) ?? true;
  }

  Future<void> setRemindersEnabled(bool enabled) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(_prefsEnabledKey, enabled);
    if (enabled) {
      await ensureDailyReminderScheduled();
    } else {
      await cancelDailyReminder();
    }
  }

  Future<void> init({SharedPreferences? prefs}) async {
    if (_initialized) return;
    _prefs = prefs ?? await SharedPreferences.getInstance();

    tzdata.initializeTimeZones();
    // App is TR-first; Istanbul covers TR daylight-saving correctly.
    try {
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
    );

    _initialized = true;
  }

  /// Requests OS permission (Android 13+ / iOS). Returns whether granted.
  Future<bool> requestPermissions() async {
    if (!_initialized) await init();

    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? false;
    }

    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  /// Ensures permission + schedules the daily 20:00 streak reminder.
  Future<void> ensureDailyReminderScheduled() async {
    if (kIsWeb) return;
    if (!_initialized) await init();
    if (!await remindersEnabled) return;

    await requestPermissions();
    await scheduleDailyReminder();
  }

  Future<void> scheduleDailyReminder({
    int hour = _reminderHour,
    int minute = _reminderMinute,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await init();

    await cancelDailyReminder();

    final when = _nextInstanceOf(hour, minute);

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Daily SkillCubes streak reminders',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.reminder,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.zonedSchedule(
      id: _notificationId,
      title: reminderTitle,
      body: reminderBody,
      scheduledDate: when,
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_streak',
    );
  }

  Future<void> cancelDailyReminder() async {
    if (!_initialized) await init();
    await _plugin.cancel(id: _notificationId);
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
