// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:storke_central/models/friend.dart';
import 'package:storke_central/models/user.dart' as sc;
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
        log("[auth_checker_page] App is currently under review, features may be disabled when logged in anonymously", LogLevel.warn);
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
    Trace trace = FirebasePerformance.instance.newTrace("checkServerStatus()");
    await trace.start();
    try {
      var serverStatus = await httpClient.get(Uri.parse("$API_HOST/montecito/ping"), headers: {"SC-API-KEY": SC_API_KEY});
      log("[auth_checker_page] Server Status: ${serverStatus.statusCode}");
      if (serverStatus.statusCode != 200) {
        offlineMode = true;
      } else {
        offlineMode = false;
      }
    } catch (err) {
      offlineMode = true;
    }
    if (mounted) setState(() {percent = 0.45;});
    trace.stop();
  }

  Future<void> checkAuthState() async {
    Trace trace = FirebasePerformance.instance.newTrace("checkAuthState()");
    await trace.start();
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
            trace.stop();
            return;
          }
          router.navigateTo(context, "/register", transition: TransitionType.fadeIn, replace: true, clearStack: true);
          trace.stop();
          return;
        }
        else {
          router.navigateTo(context, "/server-status", transition: TransitionType.fadeIn, replace: true, clearStack: true);
          trace.stop();
          return;
        }
      } else {
        // User logged in
        anonMode = user.isAnonymous;
        log("[auth_checker_page] anonMode: $anonMode");
        try {
          if (!anonMode) {
            // User is not anonymous
            if (offlineMode) {
              // Server is offline, use cached data
              await loadPreferences();
              await loadOfflineMode();
              router.navigateTo(context, "/home", transition: TransitionType.fadeIn, replace: true, clearStack: true);
              trace.stop();
              return;
            } else {
              // Server is online, get user data
              bool userCached = await loadOfflineUser();
              if (!userCached) {
                // User data not cached, get from server
                await AuthService.getUser(user.uid);
                if (currentUser.id == "") {
                  // Failed to get user data from server, go to register page
                  if (launchDynamicLink.contains("/#/register")) {
                    Future.delayed(const Duration(milliseconds: 0), () {
                      router.navigateTo(context, launchDynamicLink.split("/#")[1], transition: TransitionType.native);
                      launchDynamicLink = "";
                    });
                    trace.stop();
                    return;
                  }
                  router.navigateTo(context, "/register", transition: TransitionType.fadeIn, replace: true, clearStack: true);
                  trace.stop();
                  return;
                }
              }
              FirebaseAnalytics.instance.logLogin(loginMethod: "Google");
              bool friendsCached = await loadOfflineFriendsList();
              if (!friendsCached) {
                // Friends list not cached, get from server
                await updateUserFriendsList();
              }
            }
          } else {
            // User is anonymous
            FirebaseAnalytics.instance.logLogin(loginMethod: "Anonymous");
            if (appUnderReview) {
              anonMode = false;
              log("[auth_checker_page] App is currently under review, logging in as $appReviewUserID, certain features may be disabled in this mode.", LogLevel.warn);
              await AuthService.getUser(appReviewUserID);
            }
          }
          await loadPreferences();
          if (ModalRoute.of(context)!.settings.name!.contains("?route=")) {
            String route = ModalRoute.of(context)!.settings.name!.split("?route=")[1];
            String routeDecoded = Uri.decodeComponent(route);
            router.navigateTo(context, routeDecoded, transition: TransitionType.fadeIn, replace: true, clearStack: true);
            trace.stop();
            return;
          } else {
            router.navigateTo(context, "/home", transition: TransitionType.fadeIn, replace: true, clearStack: true);
            trace.stop();
            return;
          }
        } catch (err) {
          log("[auth_checker_page] $err", LogLevel.error);
          // loadOfflineMode();
          router.navigateTo(context, "/home", transition: TransitionType.fadeIn, replace: true, clearStack: true);
          trace.stop();
          return;
        }
      }
    });
  }

  Future<void> loadPreferences() async {
    // Load general app preferences
    // Should be things that would be relevant whether user is logged in or not
    if (!prefs.containsKey("PREF_UNITS")) prefs.setString("PREF_UNITS", PREF_UNITS);
    if (!prefs.containsKey("BUILDINGS_LAST_FETCH")) prefs.setString("BUILDINGS_LAST_FETCH", lastBuildingFetch.toIso8601String());
    PREF_UNITS = prefs.getString("PREF_UNITS")!;
    lastBuildingFetch = DateTime.parse(prefs.getString("BUILDINGS_LAST_FETCH")!);
  }

  Future<void> loadOfflineMode() async {
    // Load specifc user information that was cached
    // App will never enter offline mode if user was not logged in before!
    log("[auth_checker_page] Failed to reach server, entering offline mode!");
    loadOfflineUser();
    loadOfflineFriendsList();
    offlineMode = true;
  }

  Future<bool> loadOfflineUser() async {
    Trace trace = FirebasePerformance.instance.newTrace("loadOfflineUser()");
    await trace.start();
    bool success = false;
    try {
      if (prefs.containsKey("CURRENT_USER")) {
        setState(() {
          currentUser = sc.User.fromJson(jsonDecode(prefs.getString("CURRENT_USER")!));
        });
        log("[auth_checker_page] Successfully loaded offline user");
        success = true;
      } else {
        log("[auth_checker_page] No offline user cached");
        success = false;
      }
    } catch (err) {
      log("[auth_checker_page] Failed to load offline user: $err", LogLevel.error);
      success = false;
    }
    trace.stop();
    return success;
  }

  Future<bool> loadOfflineFriendsList() async {
    Trace trace = FirebasePerformance.instance.newTrace("loadOfflineFriendsList()");
    await trace.start();
    bool success = false;
    try {
      if (prefs.containsKey("CURRENT_USER_FRIENDS")) {
        List<Friend> offlineFriendsList = prefs.getStringList("CURRENT_USER_FRIENDS")!.map((e) => Friend.fromJson(jsonDecode(e))).toList();
        friends.clear();
        requests.clear();
        for (int i = 0; i < offlineFriendsList.length; i++) {
          if (offlineFriendsList[i].status == "REQUESTED") {
            requests.add(offlineFriendsList[i]);
          } else if (offlineFriendsList[i].status == "ACCEPTED") {
            friends.add(offlineFriendsList[i]);
          }
        }
        setState(() {
          friends.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
          requests.sort((a, b) => a.toUserID == currentUser.id ? -1 : 1);
        });
        log("[auth_checker_page] Successfully loaded offline friends list");
        success = true;
      } else {
        log("[auth_checker_page] No offline friends list cached");
        success = false;
      }
    } catch (err) {
      log("[auth_checker_page] Failed to load offline friends list: $err", LogLevel.error);
      success = false;
    }
    trace.stop();
    return success;
  }

  Future<void> updateUserFriendsList() async {
    Trace trace = FirebasePerformance.instance.newTrace("updateUserFriendsList()");
    await trace.start();
    await AuthService.getAuthToken();
    var response = await httpClient.get(Uri.parse("$API_HOST/users/${currentUser.id}/friends"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"});
    if (response.statusCode == 200) {
      log("[auth_checker_page] Successfully updated local friend list");
      friends.clear();
      requests.clear();
      var responseJson = jsonDecode(utf8.decode(response.bodyBytes));
      for (int i = 0; i < responseJson["data"].length; i++) {
        Friend friend = Friend.fromJson(responseJson["data"][i]);
        if (friend.status == "REQUESTED") {
          requests.add(friend);
        } else if (friend.status == "ACCEPTED") {
          friends.add(friend);
        }
      }
      setState(() {
        friends.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        requests.sort((a, b) => a.toUserID == currentUser.id ? -1 : 1);
      });
    } else {
      log("[auth_checker_page] ${response.body}", LogLevel.error);
    }
    trace.stop();
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