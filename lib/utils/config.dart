// ignore_for_file: non_constant_identifier_names

import 'package:fluro/fluro.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:storke_central/models/building.dart';
import 'package:storke_central/models/dining_hall.dart';
import 'package:storke_central/models/dining_hall_meal.dart';
import 'package:storke_central/models/friend.dart';
import 'package:storke_central/models/gold_course.dart';
import 'package:storke_central/models/news_article.dart';
import 'package:storke_central/models/notification.dart' as sc;
import 'package:storke_central/models/quarter.dart';
import 'package:storke_central/models/user.dart';
import 'package:storke_central/models/user_course.dart';
import 'package:storke_central/models/user_schedule_item.dart';
import 'package:storke_central/models/version.dart';
import 'package:storke_central/utils/syncfusion_meeting.dart';

final router = FluroRouter();
final RouteObserver<ModalRoute> routeObserver = RouteObserver<ModalRoute>();

Version appVersion = Version("2.4.2+1");

String API_HOST = "https://api.storkecentr.al";
// String API_HOST = "http://localhost:4001";
// String API_HOST = "https://77c0-169-231-9-220.ngrok.io";

String SC_API_KEY = "sc-api-key";
String SC_AUTH_TOKEN = "sc-auth-token";
String UCSB_API_KEY = "ucsb-api-key";
String UCSB_DINING_CAM_KEY = "ucsb-dining-key";
String MAPBOX_PUBLIC_TOKEN = "mapbox-public-token";
String MAPBOX_ACCESS_TOKEN = "mapbox-access-token";
String ONESIGNAL_APP_ID = "onesignal-app-id";

String APP_STORE_URL = "https://apps.apple.com/us/app/apple-store/id1594777645";
String PLAY_STORE_URL = "https://play.google.com/store/apps/details?id=com.bk1031.storke_central";
String TESTFLIGHT_URL = "https://beta.itunes.apple.com/v1/app/1594777645";

bool offlineMode = false;
bool anonMode = false;

String launchDynamicLink = "/#/register?invite=STKCRL";

User currentUser = User();
List<Friend> friends = [];
List<Friend> requests = [];

List<sc.Notification> notifications = [];

Position? currentPosition;

List<DiningHall> diningHallList = [];
List<DiningHallMeal> diningMealList = [];
DiningHall selectedDiningHall = DiningHall();

NewsArticle headlineArticle = NewsArticle();
DateTime lastHeadlineArticleFetch = DateTime.now();

List<UserCourse> userCourses = [];
List<GoldCourse> goldCourses = [];
List<UserScheduleItem> userScheduleItems = [];
List<Meeting> calendarMeetings = [];
DateTime lastScheduleFetch = DateTime.now();

List<Building> buildings = [];
DateTime lastBuildingFetch = DateTime.now();
Building selectedBuilding = Building();

/// Units can be [m] or [ft]
// ignore: non_constant_identifier_names
String PREF_UNITS = "M";
// ignore: non_constant_identifier_names
Map<String, double> UNITS_CONVERSION = {
  "M": 1,
  "FT": 3.28084
};

// Quarter Information
Quarter currentQuarter = spring23;
Quarter selectedQuarter = currentQuarter;
List<Quarter> availableQuarters = [fall22, winter23, spring23];

// Quarters

Quarter spring23 = Quarter.fromJson({
  "id": "20232",
  "name": "Spring 2023",
  "firstDayOfClasses": "2023-04-03 00:00:00.000",
  "lastDayOfClasses": "2023-06-09 23:59:00.000",
  "firstDayOfFinals": "2023-06-10 00:00:00.000",
  "lastDayOfFinals": "2023-06-16 00:00:00.000",
  "weeks": [
    "2023-04-01 00:00:00.000",
    "2023-04-02 00:00:00.000",
    "2023-04-09 00:00:00.000",
    "2023-04-16 00:00:00.000",
    "2023-04-23 00:00:00.000",
    "2023-04-30 00:00:00.000",
    "2023-05-07 00:00:00.000",
    "2023-05-14 00:00:00.000",
    "2023-05-21 00:00:00.000",
    "2023-05-28 00:00:00.000",
    "2023-06-04 00:00:00.000",
  ]
});

// Current Quarter with full week information
Quarter winter23 = Quarter.fromJson({
  "id": "20231",
  "name": "Winter 2023",
  "firstDayOfClasses": "2023-01-09 00:00:00.000",
  "lastDayOfClasses": "2023-03-17 23:59:00.000",
  "firstDayOfFinals": "2023-03-18 00:00:00.000",
  "lastDayOfFinals": "2023-03-24 00:00:00.000",
  "weeks": [
    "2023-01-05 00:00:00.000",
    "2023-01-08 00:00:00.000",
    "2023-01-15 00:00:00.000",
    "2023-01-22 00:00:00.000",
    "2023-01-29 00:00:00.000",
    "2023-02-05 00:00:00.000",
    "2023-02-12 00:00:00.000",
    "2023-02-19 00:00:00.000",
    "2023-02-26 00:00:00.000",
    "2023-03-05 00:00:00.000",
    "2023-03-12 00:00:00.000",
  ]
});

Quarter fall22 = Quarter.fromJson({
  "id": "20224",
  "name": "Fall 2022",
  "firstDayOfClasses": "2022-09-22 00:00:00.000",
  "lastDayOfClasses": "2022-12-02 23:59:00.000",
  "firstDayOfFinals": "2022-12-03 00:00:00.000",
  "lastDayOfFinals": "2022-12-09 00:00:00.000",
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

Quarter summer22 = Quarter.fromJson({
  "id": "20223",
  "name": "Summer 2022",
  "firstDayOfClasses": "2022-06-21 00:00:00.000",
  "lastDayOfClasses": "2022-09-09 23:59:00.000"
});
Quarter spring22 = Quarter.fromJson({
  "id": "20222",
  "name": "Spring 2022",
  "firstDayOfClasses": "2022-03-28 00:00:00.000",
  "lastDayOfClasses": "2022-06-03 23:59:00.000"
});
Quarter winter22 = Quarter.fromJson({
  "id": "20221",
  "name": "Winter 2022",
  "firstDayOfClasses": "2022-01-03 00:00:00.000",
  "lastDayOfClasses": "2022-03-11 23:59:00.000"
});
Quarter fall21 = Quarter.fromJson({
  "id": "20214",
  "name": "Fall 2021",
  "firstDayOfClasses": "2021-09-23 00:00:00.000",
  "lastDayOfClasses": "2021-12-03 23:59:00.000"
});