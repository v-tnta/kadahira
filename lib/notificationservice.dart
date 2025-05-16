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

    try {
      await _flutterLocalNotificationsPlugin.initialize(
          initializationSettings,
          onDidReceiveNotificationResponse: (NotificationResponse res) {
            debugPrint('tapped! -- notification service --');
          },
          onDidReceiveBackgroundNotificationResponse: onDidRBN
      );
      debugPrint('init -- notification service --');
    }catch(e){
      debugPrint('ERROR: cannot init -- notification service --');
    }
  }

  static Future<int> _getNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('notification_time') ?? 10; // default: 10min to go
  }

  static Future<void> scheduleNotification(kadaidata kadai, int edited_noti_time) async {
    int notificationTime = 10; // default setting

    if (edited_noti_time == -1){
      notificationTime = await _getNotificationTime(); // from shared preferences
    }else{
      notificationTime = edited_noti_time; // in case user has edited the notification time
    }

    final scheduledTime = DateTime.fromMillisecondsSinceEpoch(kadai.timestamp)
        .subtract(Duration(minutes: notificationTime));

    debugPrint('scheduled time is: $scheduledTime -- notification service --');

    // 過去の課題はスキップ
    if (scheduledTime.isBefore(DateTime.now())) {
      return;
    }

    try{
      debugPrint('phase1 -- notificS try--');
      tz.TZDateTime tzDT = tz.TZDateTime.from(scheduledTime, tz.local); // teinei coding

      debugPrint('phase2 -- notificS try--');
      // Check if Android notification channel exists
      await _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(
        const AndroidNotificationChannel(
          'kadai_channel', // チャンネルID
          'Kadai Notifications', // チャンネル名
          description: 'notify kadai due datetime',
          importance: Importance.max
        )
      );

      debugPrint('phase3 -- notificS try--');
      debugPrint('Original time: $scheduledTime, TZ time: $tzDT');

      await _flutterLocalNotificationsPlugin.zonedSchedule(
          (kadai.id + 1), // notification ID: kadai id + 1 (avoid zero)
        '課題の〆切が近いです！',
        '${kadai.name} の〆切まで残り $notificationTime 分',
        tzDT, // changed--<<
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'kadai_channel',
            'Kadai Notifications',
            channelDescription: 'notify kadai due datetime',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle
      );

      debugPrint('set notification -- notification service --');
    }catch(e){
      debugPrint('ERROR: cannot set notification -- notification service --');
      debugPrint('$e');
    }

  }

  static Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
