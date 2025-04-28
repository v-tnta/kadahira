import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'kadaidata.dart';


class NotificationService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  static Future<int> _getNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('notification_time') ?? 10; // default: 10min to go
  }

  static Future<void> scheduleNotification(kadaidata kadai) async {
    final notificationTime = await _getNotificationTime(); // from shared preferences

    final scheduledTime = DateTime.fromMillisecondsSinceEpoch(kadai.timestamp)
        .subtract(Duration(minutes: notificationTime));

    // 過去の課題はスキップ
    if (scheduledTime.isBefore(DateTime.now())) {
      return;
    }

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      kadai.id, // 通知ID: kadaidata.id
      'カダイの〆切が近いよ！',
      '${kadai.name} の〆切まであと $notificationTime 分',
      tz.TZDateTime.from(scheduledTime, tz.local), // changed--<<
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'kadai_channel', // チャンネルID
          'Kadai Notifications', // チャンネル名
          channelDescription: '課題の締切を通知',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  static Future<void> cancelAllNotifications(int id) async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
