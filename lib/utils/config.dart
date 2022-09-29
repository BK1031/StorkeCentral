import 'package:fluro/fluro.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:storke_central/models/dining_hall.dart';
import 'package:storke_central/models/gold_course.dart';
import 'package:storke_central/models/news_article.dart';
import 'package:storke_central/models/quarter.dart';
import 'package:storke_central/models/user.dart';
import 'package:storke_central/models/user_course.dart';
import 'package:storke_central/models/version.dart';

final router = FluroRouter();
final RouteObserver<ModalRoute> routeObserver = RouteObserver<ModalRoute>();

Version appVersion = Version("2.2.4+1");

// ignore: non_constant_identifier_names
// String API_HOST = "https://api.storkecentr.al";
// String API_HOST = "http://localhost:4001";
String API_HOST = "https://eb2b-169-231-109-83.ngrok.io";
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
List<User> friends = [];
List<User> requests = [];

Position? currentPosition;

List<DiningHall> diningHallList = [];
DiningHall selectedDiningHall = DiningHall();

NewsArticle headlineArticle = NewsArticle();
DateTime lastHeadlineArticleFetch = DateTime.now();

List<UserCourse> userCourses = [];
List<GoldCourse> goldCourses = [];

/// Units can be [m] or [ft]
// ignore: non_constant_identifier_names
String PREF_UNITS = "M";
// ignore: non_constant_identifier_names
Map<String, double> UNITS_CONVERSION = {
  "M": 1,
  "FT": 3.28084
};

// Quarter Information
Quarter currentQuarter = Quarter.fromJson({
  "id": "20224",
  "name": "Fall 2022",
  "firstDayOfClasses": "2022-09-22 00:00:00.000",
  "lastDayOfClasses": "2022-12-02 23:59:00.000",
  "weeks": [
    "2022-09-18 00:00:00.000",
    "2022-09-25 00:00:00.000",
    "2022-10-02 00:00:00.000",
    "2022-10-09 00:00:00.000",
    "2022-10-16 00:00:00.000",
    "2022-10-23 00:00:00.000",
    "2022-10-30 00:00:00.000",
    "2022-11-06 00:00:00.000",
    "2022-11-13 00:00:00.000",
    "2022-11-20 00:00:00.000",
    "2022-11-27 00:00:00.000",
  ]
});
Quarter selectedQuarter = currentQuarter;