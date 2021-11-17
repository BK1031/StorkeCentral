import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:storke_central/pages/home/dining/dining_hall_camera_page.dart';
import 'package:storke_central/pages/home/dining/dining_hall_page.dart';
import 'package:storke_central/pages/home/news/news_article_page.dart';
import 'package:storke_central/pages/home/overdose_response/overdose_response_page.dart';
import 'package:storke_central/pages/onboarding/auth_checker.dart';
import 'package:storke_central/pages/onboarding/onboarding_page.dart';
import 'package:storke_central/pages/onboarding/register_page.dart';
import 'package:storke_central/pages/tab_bar_controller.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/theme.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  UCSB_API_KEY = dotenv.env['ucsb-api-key']!;
  UCSB_DINING_CAM_KEY = dotenv.env['ucsb-dining-key']!;
  MAPBOX_ACCESS_TOKEN = dotenv.env['mapbox-access-token']!;

  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  ErrorWidget.builder = (FlutterErrorDetails details) => SizedBox(
    height: 100.0,
    child: Material(
      child: Center(
        child: Text(details.exceptionAsString(), style: const TextStyle(color: Colors.red)),
      ),
    ),
  );

  print('StorkeCentral v${appVersion.toString()}');
  FirebaseApp app = await Firebase.initializeApp();
  print('Initialized default app $app');
  FirebaseAnalytics analytics = FirebaseAnalytics();

  router.define('/', handler: Handler(handlerFunc: (BuildContext? context, Map<String, dynamic>? params) {
    return const OnboardingPage();
  }));
  router.define('/auth', handler: Handler(handlerFunc: (BuildContext? context, Map<String, dynamic>? params) {
    return const AuthCheckerPage();
  }));
  router.define('/register', handler: Handler(handlerFunc: (BuildContext? context, Map<String, dynamic>? params) {
    return const RegisterPage();
  }));

  router.define('/home', handler: Handler(handlerFunc: (BuildContext? context, Map<String, dynamic>? params) {
    return const TabBarController();
  }));

  router.define('/overdose-response', handler: Handler(handlerFunc: (BuildContext? context, Map<String, dynamic>? params) {
    return const OverdoseResponsePage();
  }));

  router.define('/news/selected', handler: Handler(handlerFunc: (BuildContext? context, Map<String, dynamic>? params) {
    return const NewsArticlePage();
  }));

  router.define('/dining/:id', handler: Handler(handlerFunc: (BuildContext? context, Map<String, dynamic>? params) {
    return DiningHallPage(params?["id"][0]);
  }));
  router.define('/dining/:id/cam', handler: Handler(handlerFunc: (BuildContext? context, Map<String, dynamic>? params) {
    return DiningHallCameraPage(params?["id"][0]);
  }));

  runApp(AdaptiveTheme(
      light: lightTheme,
      dark: darkTheme,
      initial: savedThemeMode ?? AdaptiveThemeMode.light,
      builder: (theme, darkTheme) => MaterialApp(
        title: "StorkeCentral",
        debugShowCheckedModeBanner: false,
        initialRoute: '/auth',
        theme: theme,
        darkTheme: darkTheme,
        onGenerateRoute: router.generator,
        navigatorObservers: [
          FirebaseAnalyticsObserver(analytics: analytics),
        ],
      )));
}