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

    // iOS用の初期化設定を追加
    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false, // 許可用のコードをAppDelegateに宣言済みのため、許可どりの重複を避ける
    );

    const InitializationSettings initializationSettings =
    InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS // iOS設定
    );

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

  // ★ このメソッドは直接使用されなくなりますが、他の機能で参照される可能性を考慮して残します。
  static Future<int> _getNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('notification_time') ?? 10;
  }

  // ★ 引数からedited_noti_timeを削除
  static Future<void> scheduleNotification(kadaidata kadai) async {
    // ★ kadaiオブジェクトのnotibeforeを直接使用
    final int notificationTime = kadai.notibefore;

    final scheduledTime = DateTime.fromMillisecondsSinceEpoch(kadai.timestamp)
        .subtract(Duration(minutes: notificationTime));

    debugPrint('scheduled time is: $scheduledTime for kadai ${kadai.name} using notibefore: ${kadai.notibefore} -- notification service --');

    if (scheduledTime.isBefore(DateTime.now())) {
      return;
    }

    try {
      tz.TZDateTime tzDT = tz.TZDateTime.from(scheduledTime, tz.local);

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
          'kadai_channel', 'Kadai Notifications',
          description: 'notify kadai due datetime',
          importance: Importance.max));

      await _flutterLocalNotificationsPlugin.zonedSchedule(
          (kadai.id + 1),
          '課題の〆切が近いです！',
          '${kadai.name} の〆切まで残り $notificationTime 分', // ★ 正しい分数を表示
          tzDT,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'kadai_channel',
              'Kadai Notifications',
              channelDescription: 'notify kadai due datetime',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle);

      debugPrint('set notification -- notification service --');
    } catch (e) {
      debugPrint('ERROR: cannot set notification -- notification service --');
      debugPrint('$e');
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id + 1); // ★ IDを合わせる
  }

  static Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
