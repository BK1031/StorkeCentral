import 'package:fluro/fluro.dart';
import 'package:geolocator/geolocator.dart';
import 'package:storke_central/models/dining_hall.dart';
import 'package:storke_central/models/news_article.dart';
import 'package:storke_central/models/user.dart';
import 'package:storke_central/models/version.dart';

final router = FluroRouter();

Version appVersion = Version("2.2.2+1");

// ignore: non_constant_identifier_names
// String API_HOST = "https://api.storkecentr.al";
String API_HOST = "http://localhost:4001";
// ignore: non_constant_identifier_names
String SC_API_KEY = "sc-api-key";
// ignore: non_constant_identifier_names
String SC_AUTH_TOKEN = "sc-auth-token";
// ignore: non_constant_identifier_names
String UCSB_API_KEY = "ucsb-api-key";
// ignore: non_constant_identifier_names
String UCSB_DINING_CAM_KEY = "ucsb-dining-key";
// ignore: non_constant_identifier_names
String MAPBOX_ACCESS_TOKEN = "mapbox-access-token";
// ignore: non_constant_identifier_names
String ONESIGNAL_APP_ID = "onesignal-app-id";

bool offlineMode = false;
bool anonMode = false;

User currentUser = User();

Position? currentPosition;

List<DiningHall> diningHallList = [];
DiningHall selectedDiningHall = DiningHall();

NewsArticle selectedArticle = NewsArticle();

/// Units can be [m] or [ft]
// ignore: non_constant_identifier_names
String PREF_UNITS = "M";
// ignore: non_constant_identifier_names
Map<String, double> UNITS_CONVERSION = {
  "M": 1,
  "FT": 3.28084
};
