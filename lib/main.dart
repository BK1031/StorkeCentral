import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:storke_central/pages/auth/auth_checker_page.dart';
import 'package:storke_central/pages/auth/register_page.dart';
import 'package:storke_central/pages/home/home_page.dart';
import 'package:storke_central/pages/onboarding_page.dart';
import 'package:storke_central/pages/tab_bar_controller.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  SC_API_KEY = dotenv.env["SC_API_KEY"]!;
  UCSB_API_KEY = dotenv.env["UCSB_API_KEY"]!;
  UCSB_DINING_CAM_KEY = dotenv.env['UCSB_DINING_KEY']!;
  MAPBOX_ACCESS_TOKEN = dotenv.env['MAPBOX_ACCESS_TOKEN']!;

  print("StorkeCentral v${appVersion.toString()}");
  FirebaseApp app = await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Initialized default app $app");
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  // ROUTE DEFINITIONS
  router.define("/", handler: Handler(handlerFunc: (BuildContext? context, Map<String, dynamic>? params) {
    return const OnboardingPage();
  }));
  router.define("/check-auth", handler: Handler(handlerFunc: (BuildContext? context, Map<String, dynamic>? params) {
    return const AuthCheckerPage();
  }));
  router.define("/register", handler: Handler(handlerFunc: (BuildContext? context, Map<String, dynamic>? params) {
    return const RegisterPage();
  }));

  router.define("/home", handler: Handler(handlerFunc: (BuildContext? context, Map<String, dynamic>? params) {
    return const TabBarController();
  }));

  runApp(AdaptiveTheme(
    light: lightTheme,
    dark: darkTheme,
    initial: AdaptiveThemeMode.light,
    builder: (theme, darkTheme) => MaterialApp(
      title: "StorkeCentral",
      initialRoute: "/check-auth",
      onGenerateRoute: router.generator,
      theme: theme,
      darkTheme: darkTheme,
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: analytics)
      ],
    ),
  ));
}