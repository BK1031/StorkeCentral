// ignore_for_file: non_constant_identifier_names

import 'package:fluro/fluro.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storke_central/models/building.dart';
import 'package:storke_central/models/dining_hall.dart';
import 'package:storke_central/models/dining_hall_meal.dart';
import 'package:storke_central/models/friend.dart';
import 'package:storke_central/models/gold_course.dart';
import 'package:storke_central/models/news_article.dart';
import 'package:storke_central/models/notification.dart' as sc;
import 'package:storke_central/models/quarter.dart';
import 'package:storke_central/models/subscribed_up_next.dart';
import 'package:storke_central/models/user.dart';
import 'package:storke_central/models/user_course.dart';
import 'package:storke_central/models/user_final.dart';
import 'package:storke_central/models/user_passtime.dart';
import 'package:storke_central/models/user_schedule_item.dart';
import 'package:storke_central/models/version.dart';
import 'package:storke_central/models/waitz_building.dart';
import 'package:storke_central/models/weather.dart';
import 'package:storke_central/utils/syncfusion_meeting.dart';

final router = FluroRouter();
final RouteObserver<ModalRoute> routeObserver = RouteObserver<ModalRoute>();

var httpClient = http.Client();

late SharedPreferences prefs;

Version appVersion = Version("2.7.0+1");
Version stableVersion = Version("1.0.0+1");

String API_HOST = "https://api.storkecentr.al";

String SC_API_KEY = "sc-api-key";
String SC_AUTH_TOKEN = "sc-auth-token";
String UCSB_API_KEY = "ucsb-api-key";
String UCSB_DINING_CAM_KEY = "ucsb-dining-key";
String MAPBOX_PUBLIC_TOKEN = "mapbox-public-token";
String MAPBOX_ACCESS_TOKEN = "mapbox-access-token";
String WEATHER_API_KEY = "weather-api-key";
String ONESIGNAL_APP_ID = "onesignal-app-id";

String APP_STORE_URL = "https://apps.apple.com/us/app/apple-store/id1594777645";
String PLAY_STORE_URL = "https://play.google.com/store/apps/details?id=com.bk1031.storke_central";
String TESTFLIGHT_URL = "https://beta.itunes.apple.com/v1/app/1594777645";

bool offlineMode = false;
bool demoMode = false;

bool appUnderReview = false;
String appReviewUserID = "RPrcOUuQPrQEcL7vIF0BHTNxojY2";

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

Weather weather = Weather();
DateTime lastWeatherFetch = DateTime.now();

List<UserCourse> userCourses = [];
List<GoldCourse> goldCourses = [];
List<UserScheduleItem> userScheduleItems = [];
List<Meeting> calendarMeetings = [];
DateTime lastScheduleFetch = DateTime.now();

List<UserFinal> userFinals = [];

UserPasstime userPasstime = UserPasstime();

List<String> upNextUserIDs = [];
List<SubscribedUpNext> upNextSubscriptions = [];
DateTime lastUpNextFetch = DateTime.now();

List<WaitzBuilding> waitzBuildings = [];
DateTime lastWaitzFetch = DateTime.now();

List<Building> buildings = [];
DateTime lastBuildingFetch = DateTime.now();
Building selectedBuilding = Building();

/// Units can be [m] or [ft]
String PREF_UNITS = "M";
Map<String, double> UNITS_CONVERSION = {
  "M": 1,
  "FT": 3.28084
};

// Quarter Information
Quarter currentQuarter = winter25;
Quarter selectedQuarter = currentQuarter;
List<Quarter> availableQuarters = [fall24, winter25];
// Quarter for the next passtime
Quarter currentPassQuarter = winter25;

// Quarters
Quarter winter25 = Quarter.fromJson({
  "id": "20251",
  "name": "Winter 2025",
  "firstDayOfClasses": "2025-01-06 00:00:00.000",
  "lastDayOfClasses": "2025-03-14 23:59:00.000",
  "firstDayOfFinals": "2025-03-15 00:00:00.000",
  "lastDayOfFinals": "2025-03-21 23:59:00.000",
  "weeks": [
    "2025-01-04 00:00:00.000", // Week 0
    "2025-01-05 00:00:00.000", // Week 1
    "2025-01-12 00:00:00.000", // Week 2
    "2025-01-19 00:00:00.000", // Week 3
    "2025-01-26 00:00:00.000", // Week 4
    "2025-02-02 00:00:00.000", // Week 5
    "2025-02-09 00:00:00.000", // Week 6
    "2025-02-16 00:00:00.000", // Week 7
    "2025-02-23 00:00:00.000", // Week 8
    "2025-03-02 00:00:00.000", // Week 9
    "2025-03-09 00:00:00.000", // Week 10
  ]
});

Quarter fall24 = Quarter.fromJson({
  "id": "20244",
  "name": "Fall 2024",
  "firstDayOfClasses": "2024-09-26 00:00:00.000",
  "lastDayOfClasses": "2024-12-06 23:59:00.000",
  "firstDayOfFinals": "2024-12-07 00:00:00.000",
  "lastDayOfFinals": "2024-12-13 23:59:00.000",
  "weeks": [
    "2024-09-22 00:00:00.000", // Week 0
    "2024-09-29 00:00:00.000", // Week 1
    "2024-10-06 00:00:00.000", // Week 2
    "2024-10-13 00:00:00.000", // Week 3
    "2024-10-20 00:00:00.000", // Week 4
    "2024-10-27 00:00:00.000", // Week 5
    "2024-11-03 00:00:00.000", // Week 6
    "2024-11-10 00:00:00.000", // Week 7
    "2024-11-17 00:00:00.000", // Week 8
    "2024-11-24 00:00:00.000", // Week 9
    "2024-12-01 00:00:00.000", // Week 10
  ]
});

Quarter spring24 = Quarter.fromJson({
  "id": "20242",
  "name": "Spring 2024",
  "firstDayOfClasses": "2024-04-01 00:00:00.000",
  "lastDayOfClasses": "2024-06-07 23:59:00.000",
  "firstDayOfFinals": "2024-06-08 00:00:00.000",
  "lastDayOfFinals": "2024-06-14 00:00:00.000",
  "weeks": [
    "2024-03-30 00:00:00.000", // Week 0
    "2024-03-31 00:00:00.000", // Week 1
    "2024-04-07 00:00:00.000", // Week 2
    "2024-04-14 00:00:00.000", // Week 3
    "2024-04-21 00:00:00.000", // Week 4
    "2024-04-28 00:00:00.000", // Week 5
    "2024-05-05 00:00:00.000", // Week 6
    "2024-05-12 00:00:00.000", // Week 7
    "2024-05-19 00:00:00.000", // Week 8
    "2024-05-26 00:00:00.000", // Week 9
    "2024-06-02 00:00:00.000", // Week 10
  ]
});

Quarter winter24 = Quarter.fromJson({
  "id": "20241",
  "name": "Winter 2024",
  "firstDayOfClasses": "2024-01-08 00:00:00.000",
  "lastDayOfClasses": "2024-03-15 23:59:00.000",
  "firstDayOfFinals": "2024-03-16 00:00:00.000",
  "lastDayOfFinals": "2024-03-22 00:00:00.000",
  "weeks": [
    "2024-01-06 00:00:00.000", // Week 0
    "2024-01-07 00:00:00.000", // Week 1
    "2024-01-14 00:00:00.000", // Week 2
    "2024-01-21 00:00:00.000", // Week 3
    "2024-01-28 00:00:00.000", // Week 4
    "2024-02-04 00:00:00.000", // Week 5
    "2024-02-11 00:00:00.000", // Week 6
    "2024-02-18 00:00:00.000", // Week 7
    "2024-02-25 00:00:00.000", // Week 8
    "2024-03-03 00:00:00.000", // Week 9
    "2024-03-10 00:00:00.000", // Week 10
  ]
});

Quarter fall23 = Quarter.fromJson({
  "id": "20234",
  "name": "Fall 2023",
  "firstDayOfClasses": "2023-09-28 00:00:00.000",
  "lastDayOfClasses": "2023-12-08 23:59:00.000",
  "firstDayOfFinals": "2023-12-09 00:00:00.000",
  "lastDayOfFinals": "2023-12-15 00:00:00.000",
  "weeks": [
    "2023-09-24 00:00:00.000", // Week 0
    "2023-10-01 00:00:00.000", // Week 1
    "2023-10-08 00:00:00.000", // Week 2
    "2023-10-15 00:00:00.000", // Week 3
    "2023-10-22 00:00:00.000", // Week 4
    "2023-10-29 00:00:00.000", // Week 5
    "2023-11-05 00:00:00.000", // Week 6
    "2023-11-12 00:00:00.000", // Week 7
    "2023-11-19 00:00:00.000", // Week 8
    "2023-11-26 00:00:00.000", // Week 9
    "2023-12-03 00:00:00.000", // Week 10
  ]
});

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

Map<int, String> weatherCodeToIcon = {
  201: "thunderstorm",
  202: "thunderstorm",
  210: "lightning",
  211: "lightning",
  212: "lightning",
  221: "lightning",
  230: "thunderstorm",
  231: "thunderstorm",
  232: "thunderstorm",
  300: "sprinkle",
  301: "sprinkle",
  302: "rain",
  310: "rain-mix",
  311: "rain",
  312: "rain",
  313: "showers",
  314: "rain",
  321: "sprinkle",
  500: "sprinkle",
  501: "rain",
  502: "rain",
  503: "rain",
  504: "rain",
  511: "rain-mix",
  520: "showers",
  521: "showers",
  522: "showers",
  531: "storm-showers",
  600: "snow",
  601: "snow",
  602: "sleet",
  611: "rain-mix",
  612: "rain-mix",
  615: "rain-mix",
  616: "rain-mix",
  620: "rain-mix",
  621: "snow",
  622: "snow",
  701: "showers",
  711: "smoke",
  721: "haze",
  731: "dust",
  741: "fog",
  761: "dust",
  762: "dust",
  771: "cloudy-gusts",
  781: "tornado",
  800: "sunny",
  801: "cloudy-gusts",
  802: "cloudy-gusts",
  803: "cloudy-gusts",
  804: "cloudy",
  900: "tornado",
  901: "storm-showers",
  902: "hurricane",
  903: "snowflake-cold",
  904: "hot",
  905: "windy",
  906: "hail",
  957: "strong-wind",
  200: "thunderstorm"
};