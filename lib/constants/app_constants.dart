import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static String mapsApiKey = dotenv.env['MAPS_API_KEY']!;
}
