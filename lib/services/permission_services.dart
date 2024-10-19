import 'package:whereisthetoilet/main.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> notificationPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      logger.d('User granted full permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      logger.d('User granted provisional permission');
    } else {
      logger.d('User declined or has not accepted permission');
    }
  }

  Future<LocationPermission> locationPermission() async {
    // Check and request location permission using Geolocator
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      logger.d('User permanently denied location permission');
      // You can open app settings to let the user manually enable the permission
      openAppSettings();
    } else if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      logger.d('User granted location permission');
      // You can now get the location if needed
    } else {
      logger.d('User denied location permission');
    }

    return permission; // Return the permission status
  }
}
