import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:whereisthetoilet/models/user_models.dart';
import 'package:whereisthetoilet/routes/router_provider.dart';
import 'package:whereisthetoilet/routes/routes.dart';
import 'package:whereisthetoilet/screens/home_screen/home_screen.dart';
import 'package:whereisthetoilet/screens/splash_screen/splash_screen.dart';
import 'package:whereisthetoilet/services/analytics_service.dart';
import 'package:whereisthetoilet/services/push_notification_service.dart';
import 'package:whereisthetoilet/utils/custom_snackbar_util.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:realm/realm.dart';

final Logger logger = Logger();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future _firebaseBackgroundMessageHandler(RemoteMessage message) async {
  if (message.notification != null) {
    logger.d('Message received in the background!');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(MobileAds.instance.initialize());
  await Firebase.initializeApp();

  final router = FluroRouter();
  final config = Configuration.local(
    [
      UserModel.schema,
    ],
  );
  final realm = Realm(config);
  UserModel? userModel;
  final results = realm.all<UserModel>();
  if (results.isNotEmpty) {
    userModel = results.first;
  }

  // Initialize various services
  await PushNotificationService.initialize();
  await AnalyticsService.initialize();
  await PushNotificationService.localNotificationInit();

  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessageHandler);
  PushNotificationService.onNotificationTapBackground();
  PushNotificationService.onNotificationTapForeground();
  PushNotificationService.onNotificationTerminatedState();

  defineRoutes(router);

  runApp(
    RouterProvider(
      router: router,
      child: Main(
        realm: realm,
        userModel: userModel,
        router: router,
      ),
    ),
  );
}

class Main extends StatefulWidget {
  final Realm realm;
  final UserModel? userModel;
  final FluroRouter router;
  const Main({
    super.key,
    required this.realm,
    required this.userModel,
    required this.router,
  });

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
  bool _isDeviceTokenInitialized = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2)).then((value) async {
      await PushNotificationService.getDeviceToken();
      setState(() {
        _isDeviceTokenInitialized = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: CustomSnackBarUtil.rootScaffoldMessengerKey,
      navigatorKey: navigatorKey,
      onGenerateRoute: widget.router.generator,
      home: _initialNavigation(),
    );
  }

  Widget _initialNavigation() {
    UserModel? userModel = getUserData(widget.realm);
    // return userModel?.userId != null && _isDeviceTokenInitialized
    return _isDeviceTokenInitialized
        ? RouterProvider(
            router: widget.router,
            child: HomeScreen(
              realm: widget.realm,
              deviceToken: '',
              deviceType: '',
            ),
          )
        : RouterProvider(
            router: widget.router,
            child: const SplashScreen(),
          );
  }

  UserModel? getUserData(Realm realm) {
    final results = realm.all<UserModel>();
    return results.isNotEmpty ? results.first : null;
  }
}
