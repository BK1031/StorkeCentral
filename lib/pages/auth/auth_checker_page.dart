// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storke_central/utils/auth_service.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/logger.dart';
import 'package:storke_central/utils/theme.dart';

class AuthCheckerPage extends StatefulWidget {
  const AuthCheckerPage({Key? key}) : super(key: key);

  @override
  State<AuthCheckerPage> createState() => _AuthCheckerPageState();
}

class _AuthCheckerPageState extends State<AuthCheckerPage> {

  double percent = 0.0;
  StreamSubscription<User?>? _fbAuthSubscription;

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    checkAppUnderReview();
    checkInitialDynamicLink().then((_) {
      checkServerStatus().then((value) => checkAuthState());
    });
  }

  @override
  void dispose() {
    super.dispose();
    _fbAuthSubscription?.cancel();
  }

  void checkAppUnderReview() {
    FirebaseFirestore.instance.doc("meta/app-review").get().then((value) {
      setState(() {
        appUnderReview = value.get("underReview");
      });
      if (appUnderReview) {
        log("App is currently under review, features may be disabled when logged in anonymously", LogLevel.warn);
      }
    });
  }

  Future<void> checkInitialDynamicLink() async {
    if (!kIsWeb) {
      final PendingDynamicLinkData? initialLink = await FirebaseDynamicLinks.instance.getInitialLink();
      if (initialLink != null) {
        launchDynamicLink = initialLink.link.toString();
      }
    }
  }

  Future<void> checkServerStatus() async {
    try {
      var serverStatus = await http.get(Uri.parse("$API_HOST/montecito/ping"), headers: {"SC-API-KEY": SC_API_KEY});
      log("Server Status: ${serverStatus.statusCode}");
      if (serverStatus.statusCode != 200) {
        offlineMode = true;
      } else {
        offlineMode = false;
      }
    } catch (err) {
      offlineMode = true;
    }
    if (mounted) setState(() {percent = 0.45;});
  }

  Future<void> checkAuthState() async {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() {percent = 1;});
    });
    _fbAuthSubscription = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        // Not logged in
        if (!offlineMode) {
          if (launchDynamicLink.contains("/#/register")) {
            Future.delayed(const Duration(milliseconds: 0), () {
              router.navigateTo(context, launchDynamicLink.split("/#")[1], transition: TransitionType.native);
              launchDynamicLink = "";
            });
            return;
          }
          router.navigateTo(context, "/register", transition: TransitionType.fadeIn, replace: true, clearStack: true);
        }
        else {
          router.navigateTo(context, "/server-status", transition: TransitionType.fadeIn, replace: true, clearStack: true);
          return;
        }
      } else {
        // User logged in
        anonMode = user.isAnonymous;
        log("anonMode: $anonMode");
        try {
          if (!anonMode) {
            // User is not anonymous
            if (offlineMode) {
              // Server is offline, use cached data
              await loadPreferences();
              await loadOfflineMode();
              router.navigateTo(context, "/home", transition: TransitionType.fadeIn, replace: true, clearStack: true);
              return;
            } else {
              // Server is online, get user data
              await AuthService.getUser(user.uid);
              if (currentUser.id == "") {
                // Failed to get user data from server, go to register page
                if (launchDynamicLink.contains("/#/register")) {
                  Future.delayed(const Duration(milliseconds: 0), () {
                    router.navigateTo(context, launchDynamicLink.split("/#")[1], transition: TransitionType.native);
                    launchDynamicLink = "";
                  });
                  return;
                }
                router.navigateTo(context, "/register", transition: TransitionType.fadeIn, replace: true, clearStack: true);
                return;
              }
              FirebaseAnalytics.instance.logLogin(loginMethod: "Google");
            }
          } else {
            // User is anonymous
            FirebaseAnalytics.instance.logLogin(loginMethod: "Anonymous");
            if (appUnderReview) {
              log("App is currently under review, features may be disabled when logged in anonymously", LogLevel.warn);
              await AuthService.getUser(appReviewUserID);
            }
          }
          await loadPreferences();
          if (ModalRoute.of(context)!.settings.name!.contains("?route=")) {
            String route = ModalRoute.of(context)!.settings.name!.split("?route=")[1];
            String routeDecoded = Uri.decodeComponent(route);
            router.navigateTo(context, routeDecoded, transition: TransitionType.fadeIn, replace: true, clearStack: true);
          } else {
            router.navigateTo(context, "/home", transition: TransitionType.fadeIn, replace: true, clearStack: true);
          }
        } catch (err) {
          log(err);
          // loadOfflineMode();
          router.navigateTo(context, "/home", transition: TransitionType.fadeIn, replace: true, clearStack: true);
        }
      }
    });
  }

  Future<void> loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey("PREF_UNITS")) prefs.setString("PREF_UNITS", PREF_UNITS);
    if (!prefs.containsKey("BUILDINGS_LAST_FETCH")) prefs.setString("BUILDINGS_LAST_FETCH", lastBuildingFetch.toIso8601String());
    PREF_UNITS = prefs.getString("PREF_UNITS")!;
    lastBuildingFetch = DateTime.parse(prefs.getString("BUILDINGS_LAST_FETCH")!);
  }

  Future<void> loadOfflineMode() async {
    log("Failed to reach server, entering offline mode!");
    // TODO: Load user info from local storage
    offlineMode = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Hero(
              tag: "storke-banner",
              child: Image.asset(
                "images/storke.jpeg",
                height: MediaQuery.of(context).size.height,
                alignment: const Alignment(0.4,0),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  CircularPercentIndicator(
                    radius: 42,
                    lineWidth: 7,
                    circularStrokeCap: CircularStrokeCap.round,
                    percent: 1,
                    // progressColor: sbNavy,
                    progressColor: Colors.white,
                  ),
                  CircularPercentIndicator(
                    radius: 48,
                    lineWidth: 7,
                    circularStrokeCap: CircularStrokeCap.round,
                    percent: 1,
                    // progressColor: sbNavy,
                    progressColor: Colors.white,
                  ),
                  CircularPercentIndicator(
                    radius: 45,
                    lineWidth: 7,
                    circularStrokeCap: CircularStrokeCap.round,
                    animateFromLastPercent: true,
                    animation: true,
                    percent: percent,
                    // progressColor: Colors.white,
                    progressColor: SB_NAVY,
                    // backgroundColor: sbNavy,
                    backgroundColor: Colors.white
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}