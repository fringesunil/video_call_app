import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:vcapp/screens/incomming_call_screen.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          try {
            final data = jsonDecode(response.payload!) as Map<String, dynamic>;
            final navigator = navigatorKey.currentState;
            if (navigator == null) {
              debugPrint('Navigator is null, cannot navigate');
              return;
            }
            if (data['type'] == 'call') {
              if (response.notificationResponseType ==
                      NotificationResponseType.selectedNotificationAction &&
                  response.actionId == 'accept') {
                navigator.push(
                  MaterialPageRoute(
                    builder:
                        (context) => IncomingCallScreen(
                          channelName: data['channelName'],
                          callerId: data['callerId'],
                          userId: int.parse(data['targetUserId']),
                        ),
                  ),
                );
              } else if (response.notificationResponseType ==
                      NotificationResponseType.selectedNotificationAction &&
                  response.actionId == 'reject') {
                navigator.popUntil((route) => route.isFirst);
              } else if (response.notificationResponseType ==
                  NotificationResponseType.selectedNotification) {
                // Handle notification tap (not action button)
                navigator.push(
                  MaterialPageRoute(
                    builder:
                        (context) => IncomingCallScreen(
                          channelName: data['channelName'],
                          callerId: data['callerId'],
                          userId: int.parse(data['targetUserId']),
                        ),
                  ),
                );
              }
            }
          } catch (e) {
            debugPrint('Error handling notification tap: $e');
          }
        }
      },
    );

    final androidPlugin =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'call_channel',
        'Call Notifications',
        description: 'Notifications for incoming video calls',
        importance: Importance.max,
        playSound: true,
      ),
    );
  }

  static Future<void> showCallNotification(
    Map<String, dynamic> data, {
    BuildContext? context,
    int? currentUserId,
  }) async {
    debugPrint('Showing call notification with data: $data');
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'call_channel',
          'Call Notifications',
          channelDescription: 'Notifications for incoming video calls',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          playSound: true,
          category: AndroidNotificationCategory.call,
          actions: [
            AndroidNotificationAction(
              'accept',
              'Accept',
              showsUserInterface: true,
              // Remove icon if ic_call_accept.png is not in res/drawable
              // icon: DrawableResourceAndroidBitmap('ic_call_accept'),
            ),
            AndroidNotificationAction(
              'reject',
              'Reject',
              showsUserInterface: true,
              // Remove icon if ic_call_reject.png is not in res/drawable
              // icon: DrawableResourceAndroidBitmap('ic_call_reject'),
            ),
          ],
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      0,
      'Incoming Video Call',
      'From User ${data['callerId']}',
      platformChannelSpecifics,
      payload: jsonEncode(data),
    );

    // Navigate to IncomingCallScreen for foreground notifications
    if (context != null && currentUserId != null && data['type'] == 'call') {
      debugPrint('Navigating to IncomingCallScreen in foreground');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => IncomingCallScreen(
                channelName: data['channelName'],
                callerId: data['callerId'],
                userId: currentUserId,
              ),
        ),
      );
    }
  }
}
