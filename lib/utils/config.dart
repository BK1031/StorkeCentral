import 'package:fluro/fluro.dart';
import 'package:storke_central/models/version.dart';

import '../models/dining_hall.dart';
import '../models/news_article.dart';

final router = FluroRouter();

Version appVersion = Version("1.0.0+1");

// ignore: non_constant_identifier_names
String UCSB_API_KEY = "ucsb-api-key";

// ignore: non_constant_identifier_names
String UCSB_DINING_CAM_KEY = "ucsb-dining-key";

// ignore: non_constant_identifier_names
String MAPBOX_ACCESS_TOKEN = "mapbox-access-token";

bool offlineMode = false;
bool anonMode = false;

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

// ignore: constant_identifier_names
const Map<String, String> DINING_HALL_IG = {
  "carrillo": "creamingatcarrillo",
  "portola": "portola.areola",
  "de-la-guerra": "dlgdefined",
  "ortega": "orgasmingatortega"
};