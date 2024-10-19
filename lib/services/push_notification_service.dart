import 'dart:convert';

import 'package:whereisthetoilet/main.dart';
import 'package:whereisthetoilet/services/permission_services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:realm/realm.dart';

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static final PermissionService _permissionService = PermissionService();

  // Variables to store realm, deviceToken, and deviceType
  static late Realm realm;
  static late String deviceToken;
  static late String deviceType;

  // Method to set the device details
  static void setDeviceDetails({
    required Realm realm,
    required String deviceToken,
    required String deviceType,
  }) {
    PushNotificationService.realm = realm;
    PushNotificationService.deviceToken = deviceToken;
    PushNotificationService.deviceType = deviceType;
  }

  static Future<void> initialize() async {
    await _permissionService.notificationPermission();
  }

  static Future<String?> getDeviceToken({int retries = 3}) async {
    int attempt = 0;
    while (attempt < retries) {
      try {
        String? token = await _firebaseMessaging.getToken();
        return token;
      } catch (e) {
        attempt++;
        if (attempt >= retries) {
          throw Exception(
              'Failed to get device token after $retries attempts: $e');
        }
        await Future.delayed(Duration(seconds: 2)); // Wait before retrying
      }
    }
    return null;
  }

  static Future localNotificationInit() async {
    // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      onDidReceiveLocalNotification: (userId, title, body, payload) {},
    );
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    // Check if _flutterLocalNotificationsPlugin is not null
    if (_flutterLocalNotificationsPlugin != null) {
      // request notification permissions for android 13 or above
      _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: onNotificationTap,
        onDidReceiveBackgroundNotificationResponse: onNotificationTap,
      );
    } else {
      // Handle the case where _flutterLocalNotificationsPlugin is null
      logger.d('Error: _flutterLocalNotificationsPlugin is null');
    }
  }

  // on tap local notification in foreground
  static void onNotificationTap(NotificationResponse notificationResponse) {
    Future.delayed(const Duration(seconds: 1), () {
      navigatorKey.currentState!.pushNamedAndRemoveUntil(
        '/peakflow_record_screen', // Named route
        (Route<dynamic> route) => false, // This removes all previous routes
        arguments: {
          'realm': realm,
          'deviceToken': deviceToken,
          'deviceType': deviceType,
        },
      );
    });
  }

  static void onNotificationTapBackground() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.notification != null) {
        logger.d('Message received in the background!');
        navigatorKey.currentState!.pushNamedAndRemoveUntil(
          '/peakflow_record_screen', // Named route
          (Route<dynamic> route) => false, // This removes all previous routes
          arguments: {
            'realm': realm,
            'deviceToken': deviceToken,
            'deviceType': deviceType,
          },
        );
      }
    });
  }

  static void onNotificationTapForeground() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      String payloadData = jsonEncode(message.data);
      logger.d('Message received in the foreground!');
      if (message.notification != null) {
        PushNotificationService.showSimpleNotification(
          title: message.notification!.title,
          body: message.notification!.body,
          payload: payloadData,
        );
      }
    });
  }

  static void onNotificationTerminatedState() async {
    final RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      logger.d('Message received in terminated state!');

      // Wait until app is initialized or a bit longer if needed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(seconds: 2), () {
          if (navigatorKey.currentState != null) {
            navigatorKey.currentState!.pushNamedAndRemoveUntil(
              '/peakflow_record_screen', // Named route
              (Route<dynamic> route) =>
                  false, // This removes all previous routes
              arguments: {
                'realm': realm,
                'deviceToken': deviceToken,
                'deviceType': deviceType,
              },
            );
          } else {
            logger.d('Navigator key state is null, cannot navigate.');
          }
        });
      });
    }
  }

  // show a simple notification
  static Future showSimpleNotification({
    required String? title,
    required String? body,
    required String? payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'your channel id',
      'your channel name',
      channelDescription: 'your channel description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );
    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}
