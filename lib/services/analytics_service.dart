import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static Future<FirebaseAnalytics> initialize() async {
    FirebaseAnalytics analytics = FirebaseAnalytics.instance;
    return analytics;
  }
}
