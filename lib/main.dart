import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:storke_central/pages/auth/auth_checker_page.dart';
import 'package:storke_central/pages/auth/register_page.dart';
import 'package:storke_central/pages/auth/server_status_page.dart';
import 'package:storke_central/pages/developer/logger_page.dart';
import 'package:storke_central/pages/home/dining/dining_hall_page.dart';
import 'package:storke_central/pages/maps/building_details_page.dart';
import 'package:storke_central/pages/notification_page.dart';
import 'package:storke_central/pages/onboarding_page.dart';
import 'package:storke_central/pages/profile/edit_profile_page.dart';
import 'package:storke_central/pages/profile/friends/add_friend_page.dart';
import 'package:storke_central/pages/profile/friends/friends_page.dart';
import 'package:storke_central/pages/profile/profile_page.dart';
import 'package:storke_central/pages/profile/user_profile_page.dart';
import 'package:storke_central/pages/schedule/load_schedule_page.dart';
import 'package:storke_central/pages/schedule/schedule_course_page.dart';
import 'package:storke_central/pages/schedule/user_schedule_page.dart';
import 'package:storke_central/pages/settings/settings_about_page.dart';
import 'package:storke_central/pages/settings/settings_page.dart';
import 'package:storke_central/pages/tab_bar_controller.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/logger.dart';
import 'package:storke_central/utils/theme.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
    return const Scaffold(
        body: Center(
            child: Text("Unexpected error. See log for details.")));
  };

  await dotenv.load(fileName: ".env");
  SC_API_KEY = dotenv.env["SC_API_KEY"]!;
  UCSB_API_KEY = dotenv.env["UCSB_API_KEY"]!;
  UCSB_DINING_CAM_KEY = dotenv.env['UCSB_DINING_KEY']!;
  MAPBOX_ACCESS_TOKEN = dotenv.env['MAPBOX_ACCESS_TOKEN']!;
  ONESIGNAL_APP_ID = dotenv.env['ONESIGNAL_APP_ID']!;

  log("StorkeCentral v${appVersion.toString()}");
  FirebaseApp app = await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  log("Initialized default app $app");
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  // Remove this method to stop OneSignal Debugging
  // OneSignal.shared.setLogLevel(OSLogLevel.debug, OSLogLevel.none);
  OneSignal.shared.setAppId(ONESIGNAL_APP_ID);

  // ROUTE DEFINITIONS
  router.define("/", handler: Handler(handlerFunc: (BuildContext? context, Map<String, dynamic>? params) {
    return const OnboardingPage();
  }));
  router.define("/check-auth", handler: Handler(handlerFunc: (BuildContext? context, Map<String, dynamic>? params) {
    return const AuthCheckerPage();
  }));
  router.define("/server-status", handler: Handler(handlerFunc: (BuildContext? context, Map<String, dynamic>? params) {
    return const ServerStatusPage();
  }));
  router.define("/register", handler: Handler(handlerFunc: (BuildContext? context, Map<String, dynamic>? params) {
    return const RegisterPage();
  }));

  router.define("/home", handler: Handler(handlerFunc: (BuildContext? context, Map<String, dynamic>? params) {
    return const TabBarController();
  }));
  router.define("/notifications", handler: Handler(handlerFunc: (BuildContext? context, Map<String, dynamic>? params) {
    return const NotificationPage();
  }));

  router.define("/dining/:diningHallID", handler: Handler(handlerFunc: (BuildContext? context, Map<String, dynamic>? params) {
    return DiningHallPage(diningHallID: params!["diningHallID"][0]);
  }));

  router.define("/schedule/load", handler: Handler(handlerFunc: (BuildContext? context, Map<String, dynamic>? params) {
    return const LoadSchedulePage();
  }));
  router.define("/schedule/view/:courseID", handler: Handler(handlerFunc: (BuildContext? context, Map<String, dynamic>? params) {
    return ScheduleCoursePage(courseID: params!["courseID"][0]);
  }));
  router.define("/schedule/user/:userID", handler: Handler(handlerFunc: (BuildContext? context, Map<String, dynamic>? params) {
    return UserSchedulePage(userID: params!["userID"][0]);
  }));

  router.define("/maps/buildings/:buildingID", handler: Handler(handlerFunc: (BuildContext? context, Map<String, dynamic>? params) {
    return BuildingDetailsPage(buildingID: params!["buildingID"][0]);
  }));

  router.define("/profile", handler: Handler(handlerFunc: (BuildContext? context, Map<String, dynamic>? params) {
    return const ProfilePage();
  }));
  router.define("/profile/edit", handler: Handler(handlerFunc: (BuildContext? context, Map<String, dynamic>? params) {
    return const EditProfilePage();
  }));
  router.define("/profile/friends", handler: Handler(handlerFunc: (BuildContext? context, Map<String, dynamic>? params) {
    return const FriendsPage();
  }));
  router.define("/profile/friends/add", handler: Handler(handlerFunc: (BuildContext? context, Map<String, dynamic>? params) {
    return const AddFriendPage();
  }));
  router.define("/profile/user/:userID", handler: Handler(handlerFunc: (BuildContext? context, Map<String, dynamic>? params) {
    return UserProfilePage(userID: params!["userID"][0]);
  }));

  router.define("/settings", handler: Handler(handlerFunc: (BuildContext? context, Map<String, dynamic>? params) {
    return const SettingsPage();
  }));
  router.define("/settings/about", handler: Handler(handlerFunc: (BuildContext? context, Map<String, dynamic>? params) {
    return const SettingsAboutPage();
  }));

  router.define("/developer/logger", handler: Handler(handlerFunc: (BuildContext? context, Map<String, dynamic>? params) {
    return const LoggerPage();
  }));

  runApp(AdaptiveTheme(
    light: lightTheme,
    dark: darkTheme,
    initial: AdaptiveThemeMode.light,
    builder: (theme, darkTheme) => MaterialApp(
      title: "StorkeCentral",
      initialRoute: kIsWeb ? "/" : "/check-auth",
      onGenerateRoute: router.generator,
      theme: theme,
      darkTheme: darkTheme,
      debugShowCheckedModeBanner: false,
      navigatorObservers: [
        routeObserver,
        FirebaseAnalyticsObserver(analytics: analytics),
      ],
    ),
  ));
}