import 'package:whereisthetoilet/screens/home_screen/home_screen.dart';
import 'package:fluro/fluro.dart';
import 'package:realm/realm.dart';
import 'package:whereisthetoilet/screens/splash_screen/splash_screen.dart';

void defineRoutes(FluroRouter router) {
  router.define(
    '/splash',
    handler: Handler(
      handlerFunc: (context, parameters) {
        return const SplashScreen();
      },
    ),
  );
  router.define(
    '/home',
    handler: Handler(
      handlerFunc: (context, parameters) {
        final arguments = context?.settings?.arguments as Map<String, dynamic>;
        Realm realm = arguments['realm'];
        String deviceToken = arguments['deviceToken'];
        String deviceType = arguments['deviceType'];
        return HomeScreen(
          realm: realm,
          deviceToken: deviceToken,
          deviceType: deviceType,
        );
      },
    ),
  );
}
