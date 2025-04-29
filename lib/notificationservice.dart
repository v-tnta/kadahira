import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:kadahira/kadaidata.dart';

// for back ground service (it must be declared out side of the class)
// top level function
@pragma('vm:entry-point')
Future<void> onDidRBN(NotificationResponse response) async {
  debugPrint('tapped! -- notification service (bg) --');
}

class NotificationService {

  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse res){
          debugPrint('tapped! -- notification service --');
      },
      onDidReceiveBackgroundNotificationResponse: onDidRBN
    );
  }

  static Future<int> _getNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('notification_time') ?? 10; // default: 10min to go
  }

  static Future<void> scheduleNotification(kadaidata kadai) async {
    final notificationTime = await _getNotificationTime(); // from shared preferences

    final scheduledTime = DateTime.fromMillisecondsSinceEpoch(kadai.timestamp)
        .subtract(Duration(minutes: notificationTime));

    debugPrint('scheduled time is: $scheduledTime -- notification service --');

    // 過去の課題はスキップ
    if (scheduledTime.isBefore(DateTime.now())) {
      return;
    }

    try{
      tz.TZDateTime tzDT = tz.TZDateTime.from(scheduledTime, tz.local); // teinei coding
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        kadai.id, // 通知ID: kadaidata.id
        'カダイの〆切が近いよ！',
        '${kadai.name} の〆切まであと $notificationTime 分',
        tzDT, // changed--<<
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
      debugPrint('set notification -- notification service --');
    }catch(e){
      debugPrint('ERROR: cannot set notification -- notification service --');
    }

  }

  static Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
