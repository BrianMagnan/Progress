import 'dart:developer' as developer;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'web_notification_interop.dart' if (dart.library.io) 'web_notification_interop_stub.dart';
import '../router/app_router.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  NotificationService._init();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      developer.log('NotificationService: Already initialized');
      return;
    }

    try {
      if (kIsWeb) {
        // Web notifications using browser API
        await _initializeWebNotifications();
      } else {
        // Mobile notifications
        // Initialize timezone
        tz.initializeTimeZones();
        
        // Initialize local notifications
        const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
        const iosSettings = DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
        const initSettings = InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        );

        final initialized = await _localNotifications.initialize(
          initSettings,
          onDidReceiveNotificationResponse: _onNotificationTapped,
        );

        if (initialized == true) {
          // Request permissions (iOS)
          await _requestPermissions();
          
          _initialized = true;
          developer.log('NotificationService: Initialized successfully');
        } else {
          developer.log('NotificationService: Initialization failed', name: 'ERROR');
        }
      }
    } catch (e) {
      developer.log('NotificationService: Initialization failed: $e', name: 'ERROR');
    }
  }

  Future<void> _initializeWebNotifications() async {
    try {
      // Check if browser supports notifications
      if (!_isWebNotificationSupported()) {
        developer.log('NotificationService: Web notifications not supported', name: 'ERROR');
        return;
      }

      // Request permission (JS will handle it automatically)
      await _requestWebPermission();
      
      // Permission is requested asynchronously by JS, so we initialize anyway
      // The JS service will handle permission checking when showing notifications
      _initialized = true;
      developer.log('NotificationService: Web notifications initialized');
    } catch (e) {
      developer.log('NotificationService: Web notification initialization failed: $e', name: 'ERROR');
    }
  }

  bool _isWebNotificationSupported() {
    // Check if running on web and if Notification API is available
    if (!kIsWeb) return false;
    try {
      // Use JS interop to check if Notification is available
      return true; // Assume supported if on web
    } catch (e) {
      return false;
    }
  }

  Future<String> _requestWebPermission() async {
    if (!kIsWeb) return 'denied';
    
    try {
      return await requestWebNotificationPermission();
    } catch (e) {
      developer.log('Error requesting web notification permission: $e', name: 'ERROR');
      return 'denied';
    }
  }

  Future<void> _requestPermissions() async {
    // Request permissions for iOS
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  void _onNotificationTapped(NotificationResponse response) {
    developer.log('NotificationService: Notification tapped: ${response.payload}');
    _navigateFromPayload(response.payload);
  }

  void _navigateFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      // No payload, navigate to home
      AppRouter.router.go('/');
      return;
    }

    try {
      // Parse payload format: "short-term-goal:${goal.id}:task:${task.id}"
      // or potentially other formats in the future
      final parts = payload.split(':');
      
      if (parts.length >= 2 && parts[0] == 'short-term-goal') {
        final goalId = parts[1];
        // Navigate to the short-term goal detail screen
        AppRouter.router.go('/short-term-goals/$goalId');
        developer.log('NotificationService: Navigated to short-term goal: $goalId');
      } else if (parts.length >= 2 && parts[0] == 'goal') {
        // For long-term goals: "goal:${goal.id}"
        final goalId = parts[1];
        AppRouter.router.go('/goals/$goalId');
        developer.log('NotificationService: Navigated to goal: $goalId');
      } else {
        // Unknown payload format, navigate to home
        developer.log('NotificationService: Unknown payload format: $payload');
        AppRouter.router.go('/');
      }
    } catch (e) {
      developer.log('NotificationService: Error parsing payload "$payload": $e', name: 'ERROR');
      // On error, navigate to home
      AppRouter.router.go('/');
    }
  }

  // Schedule a local notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    if (kIsWeb) {
      try {
        final options = payload != null ? {'tag': payload} : null;
        callScheduleNotification(
          id,
          title,
          body,
          scheduledDate.toIso8601String(),
          options,
        );
        developer.log('NotificationService: Scheduled web notification: $title at $scheduledDate');
      } catch (e) {
        developer.log('NotificationService: Failed to schedule web notification: $e', name: 'ERROR');
      }
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'progress_channel',
      'Progress Notifications',
      channelDescription: 'Notifications for your progress tracking',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      developer.log('NotificationService: Scheduled notification: $title at $scheduledDate');
    } catch (e) {
      developer.log('NotificationService: Failed to schedule notification: $e', name: 'ERROR');
    }
  }

  // Schedule a daily recurring notification
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    if (kIsWeb) {
      try {
        final options = payload != null ? {'tag': payload} : null;
        callScheduleDailyNotification(id, title, body, hour, minute, options);
        developer.log('NotificationService: Scheduled daily web notification: $title at $hour:$minute');
      } catch (e) {
        developer.log('NotificationService: Failed to schedule daily web notification: $e', name: 'ERROR');
      }
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'progress_channel',
      'Progress Notifications',
      channelDescription: 'Notifications for your progress tracking',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOfTime(hour, minute),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      developer.log('NotificationService: Scheduled daily notification: $title at $hour:$minute');
    } catch (e) {
      developer.log('NotificationService: Failed to schedule daily notification: $e', name: 'ERROR');
    }
  }

  // Schedule a weekly recurring notification
  Future<void> scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int dayOfWeek, // 1 = Monday, 7 = Sunday
    required int hour,
    required int minute,
    String? payload,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    if (kIsWeb) {
      try {
        final options = payload != null ? {'tag': payload} : null;
        callScheduleWeeklyNotification(id, title, body, dayOfWeek, hour, minute, options);
        developer.log('NotificationService: Scheduled weekly web notification: $title on day $dayOfWeek at $hour:$minute');
      } catch (e) {
        developer.log('NotificationService: Failed to schedule weekly web notification: $e', name: 'ERROR');
      }
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'progress_channel',
      'Progress Notifications',
      channelDescription: 'Notifications for your progress tracking',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOfDayAndTime(dayOfWeek, hour, minute),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      developer.log('NotificationService: Scheduled weekly notification: $title on day $dayOfWeek at $hour:$minute');
    } catch (e) {
      developer.log('NotificationService: Failed to schedule weekly notification: $e', name: 'ERROR');
    }
  }

  // Show an immediate notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    const androidDetails = AndroidNotificationDetails(
      'progress_channel',
      'Progress Notifications',
      channelDescription: 'Notifications for your progress tracking',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Cancel a scheduled notification
  Future<void> cancelNotification(int id) async {
    if (kIsWeb) {
      try {
        callCancelNotification(id);
        developer.log('NotificationService: Cancelled web notification: $id');
      } catch (e) {
        developer.log('NotificationService: Failed to cancel web notification: $e', name: 'ERROR');
      }
      return;
    }
    await _localNotifications.cancel(id);
    developer.log('NotificationService: Cancelled notification: $id');
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
    developer.log('NotificationService: Cancelled all notifications');
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }

  // Helper methods for scheduling
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
      0,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfDayAndTime(int dayOfWeek, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
      0,
    );
    
    // Adjust to the correct day of week (1 = Monday, 7 = Sunday)
    final currentWeekday = now.weekday;
    int daysUntil = (dayOfWeek - currentWeekday) % 7;
    if (daysUntil == 0 && scheduledDate.isBefore(now)) {
      daysUntil = 7; // If it's today but time has passed, schedule for next week
    } else if (daysUntil == 0) {
      // It's today and time hasn't passed yet
      return scheduledDate;
    }
    
    scheduledDate = scheduledDate.add(Duration(days: daysUntil));
    return scheduledDate;
  }
}
