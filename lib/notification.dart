
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:kadahira/main.dart';
import 'package:kadahira/kadaidata.dart';

class notification {
  // must need for Android13 or later
  Future<void> requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  // initialize for notification
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
    InitializationSettings(android: androidSettings);

    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  //}

  Future<void> scheduleNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final int notifyBeforeMinutes = prefs.getInt('notification_time:') ?? 10; // 取得できなければ10分前

    List<kadaidata> kadaiAll = [];
    loadLocalData(kadaiAll);

    final bool donotifyornot = prefs.getBool('notification_tf') ?? false; // 取得できなければfalse
    if (donotifyornot){
      for (kadaidata kadai in kadaiAll) { //全てのカダイに対して設定
        final DateTime deadline = kadai.datetime as DateTime;
        final DateTime notifyTime = deadline.subtract(Duration(minutes: notifyBeforeMinutes)); // 何分前の値だけ抜き出す

        if (notifyTime.isAfter(DateTime.now())) {
          await flutterLocalNotificationsPlugin.zonedSchedule(
            kadai.id, // 通知ID
            'カダイの締切が近づいています',
            '${kadai.name} の〆切は $notifyBeforeMinutes 分後!!',
            tz.TZDateTime.from(notifyTime, tz.local),
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'kadai_channel_id',
                'カダイの通知',
                channelDescription: '〆切時刻通知',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, // correct answer
          );
        }
      }
    }else{
      debugPrint('its not gonna notify!');
    }
  }

  // timezone settings
  Future<void> configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone(); // タイムゾーンの取得→setLLにて使用
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }
}