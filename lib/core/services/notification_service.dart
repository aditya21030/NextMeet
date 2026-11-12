import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/relationship_model.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Top-level entry point required by Flutter release builds
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Request permission for iOS/Android 13+
      // ignore: unused_local_variable
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Create Android Notification Channel
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important interaction notifications.',
      importance: Importance.max,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/launcher_icon'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(initializationSettings);

    // Initialize Timezone
    tz_data.initializeTimeZones();

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final title = notification?.title ?? message.data['title']?.toString();
      final body = notification?.body ?? message.data['body']?.toString() ?? message.data['message']?.toString();

      if (title != null && title.isNotEmpty) {
        _localNotifications.show(
          message.hashCode,
          title,
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/launcher_icon',
              importance: Importance.max,
              priority: Priority.high,
              vibrationPattern: channel.vibrationPattern,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
        );
      }
    });
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  // --- Anniversary Scheduling ---

  Future<void> syncRelationshipReminders(RelationshipModel rel) async {
    // 1. Clear old scheduled notifications to avoid duplicates/ghosts
    await _localNotifications.cancelAll();

    final DateTime start = rel.anniversaryDate;
    final now = DateTime.now();

    // Schedule next 12 monthly anniversaries
    for (int i = 1; i <= 12; i++) {
        final nextMonthDate = _getNextMonthlyAnniversary(start, now, i);
        if (nextMonthDate != null) {
            final months = _calculateMonthsApart(start, nextMonthDate);
            await _scheduleLocalNotification(
                id: 100 + i,
                title: "Monthiversary! 💖",
                body: "Happy $months months together! Every moment is a treasure.",
                scheduledDate: nextMonthDate,
            );
        }
    }

    // Schedule next 5 yearly anniversaries
    for (int i = 1; i <= 5; i++) {
        final nextYearDate = _getNextYearlyAnniversary(start, now, i);
        if (nextYearDate != null) {
            final years = nextYearDate.year - start.year;
            await _scheduleLocalNotification(
                id: 200 + i,
                title: "Yearly Anniversary! ✨",
                body: "Cheers to $years years of magic! Happiest Anniversary to us ❤️",
                scheduledDate: nextYearDate,
            );
        }
    }
  }

  Future<void> _scheduleLocalNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'anniversary_reminders',
            'Anniversary Reminders',
            channelDescription: 'Comforting reminders of your journey together',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
    } catch (e) {
      debugPrint('Failed to schedule local reminder $id: $e');
    }
  }

  DateTime? _getNextMonthlyAnniversary(DateTime start, DateTime now, int offset) {
    // Current months since start
    int totalMonths = (now.year - start.year) * 12 + (now.month - start.month);
    
    // We want to schedule the (totalMonths + offset)-th monthiversary
    int targetMonths = totalMonths + offset;
    
    DateTime targetDate = DateTime(
      start.year,
      start.month + targetMonths,
      start.day,
      9, 0, // 9 AM
    );

    // Ensure it's in the future
    if (targetDate.isBefore(now)) {
       targetDate = DateTime(start.year, start.month + targetMonths + 1, start.day, 9, 0);
    }
    
    return targetDate;
  }

  DateTime? _getNextYearlyAnniversary(DateTime start, DateTime now, int offset) {
    int targetYears = (now.year - start.year) + offset;
    
    DateTime targetDate = DateTime(
      start.year + targetYears,
      start.month,
      start.day,
      9, 0, // 9 AM
    );

    if (targetDate.isBefore(now)) {
        targetDate = DateTime(start.year + targetYears + 1, start.month, start.day, 9, 0);
    }
    
    return targetDate;
  }

  int _calculateMonthsApart(DateTime start, DateTime end) {
    return (end.year - start.year) * 12 + (end.month - start.month);
  }
}
