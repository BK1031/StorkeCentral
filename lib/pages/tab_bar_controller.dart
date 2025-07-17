// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:storke_central/models/building.dart';
import 'package:storke_central/models/friend.dart';
import 'package:storke_central/models/login.dart';
import 'package:storke_central/models/notification.dart' as sc;
import 'package:storke_central/models/version.dart';
import 'package:storke_central/pages/home/home_page.dart';
import 'package:storke_central/pages/maps/maps_page.dart';
import 'package:storke_central/pages/profile/profile_page.dart';
import 'package:storke_central/pages/schedule/schedule_page.dart';
import 'package:storke_central/utils/alert_service.dart';
import 'package:storke_central/utils/auth_service.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/logger.dart';
import 'package:storke_central/utils/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class TabBarController extends StatefulWidget {
  const TabBarController({Key? key}) : super(key: key);

  @override
  State<TabBarController> createState() => _TabBarControllerState();
}

class _TabBarControllerState extends State<TabBarController> with WidgetsBindingObserver {

  int _currPage = 0;
  List<String> pageTitles = ["Home", "Schedule", "Maps", "Profile"];
  final PageController _pageController = PageController();
  StreamSubscription<Position>? _positionStream;

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (AuthService.verifyUserSession(context, "/home")) {
      checkAppVersion();
      _determinePosition();
      if (!kIsWeb) _registerOneSignalListeners();
      firebaseAnalytics();
      fetchBuildings();
      if (!offlineMode) {
        persistUser();
        sendLoginEvent();
        updateUserFriendsList();
        fetchNotifications();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!kIsWeb) {
      if (state == AppLifecycleState.resumed) {
        log("[tab_bar_controller] App has been resumed");
        AuthService.getUser(currentUser.id);
        _determinePosition();
        checkAppVersion();
        if (!offlineMode) sendLoginEvent();
      } else {
        log("[tab_bar_controller] App has been backgrounded");
        if (!offlineMode) setUserStatus("OFFLINE");
        _positionStream?.cancel();
      }
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void persistUser() async {
    // Get updated user from server before persisting
    await AuthService.getUser(currentUser.id);
    // Trace only for persisting
    Trace trace = FirebasePerformance.instance.newTrace("persistUser()");
    await trace.start();
    prefs.setString("CURRENT_USER", jsonEncode(currentUser).toString());
    log("[tab_bar_controller] Persisted user: ${currentUser.id}");
    trace.stop();
  }

  void checkAppVersion() {
    FirebaseFirestore.instance.doc("meta/version").get().then((value) {
      stableVersion = Version(value.get("stable"));
      log ("Stable version: ${stableVersion.toString()} (${stableVersion.getVersionCode()})");
      Version beta = Version(value.get("beta"));
      log ("Beta version: ${beta.toString()} (${beta.getVersionCode()})");
      if (appVersion.getVersionCode() < stableVersion.getVersionCode()) {
        log("[tab_bar_controller] App is behind stable version (${appVersion.toString()} < ${stableVersion.toString()})");
        if (!kIsWeb) {
          CoolAlert.show(
              context: context,
              type: CoolAlertType.warning,
              title: "Update Available",
              text: "A new version of Storke Central is available. Please update to receive the latest bug fixes and use our newest features.",
              backgroundColor: ACTIVE_ACCENT_COLOR,
              confirmBtnText: "UPDATE",
              confirmBtnColor: SB_AMBER,
              onConfirmBtnTap: () {
                router.pop(context);
                if (Platform.isAndroid) {
                  launchUrl(Uri.parse(PLAY_STORE_URL));
                } else if (Platform.isIOS) {
                  launchUrl(Uri.parse(APP_STORE_URL));
                }
              }
          );
        }
      } else if (currentUser.hasRole("PRIVATE_BETA") && appVersion.getVersionCode() < beta.getVersionCode()) {
        log("[tab_bar_controller] App is behind beta version (${appVersion.toString()} < ${beta.toString()})");
        if (!kIsWeb) {
          CoolAlert.show(
              context: context,
              type: CoolAlertType.warning,
              title: "New Beta Available",
              text: "A new version of the Storke Central Beta is available. Please update your app from TestFlight to receive the latest bug fixes and use our newest features.",
              backgroundColor: ACTIVE_ACCENT_COLOR,
              confirmBtnText: "UPDATE",
              confirmBtnColor: SB_AMBER,
              onConfirmBtnTap: () {
                router.pop(context);
                launchUrl(Uri.parse(TESTFLIGHT_URL));
              }
          );
        }
      } else {
        log("[tab_bar_controller] App is up to date (${appVersion.toString()})");
      }
    });
  }

  Future<void> _determinePosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      _positionStream = Geolocator.getPositionStream().listen((Position position) {
        // log(position == null ? 'Unknown' : position.latitude.toString() + ', ' + position.longitude.toString());
        currentPosition = position;
      });
    }
  }

  void _registerOneSignalListeners() {
    OneSignal.Notifications.addClickListener((event) {
      log("[tab_bar_controller] OneSignal notification clicked: ${event.notification.notificationId}");
      router.navigateTo(context, "/notifications", transition: TransitionType.nativeModal);
    });
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      log("[tab_bar_controller] OneSignal notification will display: ${event.notification.notificationId}");
      fetchNotifications().then((value) {
        log("[tab_bar_controller] You now have ${notifications.where((element) => !element.read).length} unread notifications");
      });
    });
  }

  Future<void> fetchNotifications() async {
    Trace trace = FirebasePerformance.instance.newTrace("fetchNotifications()");
    await trace.start();
    try {
      await AuthService.getAuthToken();
      await httpClient.get(Uri.parse("$API_HOST/notifications/user/${currentUser.id}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}).then((value) {
        setState(() {
          notifications = jsonDecode(value.body)["data"].map<sc.Notification>((json) => sc.Notification.fromJson(json)).toList();
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        });
      });
    } catch(err) {
      AlertService.showErrorSnackbar(context, "Failed to get notifications!");
      log("[tab_bar_controller] ${err.toString()}", LogLevel.error);
    }
    trace.stop();
  }

  Future<void> requestNotifications() async {
    OneSignal.Notifications.requestPermission(true).then((accepted) {
      log("[tab_bar_controller] Accepted notification permissions: $accepted");
      if (mounted) {
        setState(() {
          currentUser.privacy.pushNotifications = accepted ? "ENABLED" : "DISABLED";
        });
        if (!accepted) showNotificationsDisabledAlert();
      }
    });
  }

  void showNotificationsDisabledAlert() {
    if (Random().nextBool()) {
      CoolAlert.show(
        context: context,
        type: CoolAlertType.warning,
        title: "Notifications Disabled",
        widget: const Text("Please considering enabling push notifications to unlock the full potential of StorkeCentral."),
        confirmBtnColor: SB_AMBER,
        confirmBtnText: "OK",
      );
    }
  }

  Future<void> firebaseAnalytics() async {
    await FirebaseAnalytics.instance.setUserId(id: currentUser.id);
    FirebaseAnalytics.instance.logScreenView(screenName: "Home Page", screenClass: "TabBarController");
  }

  Future<void> sendLoginEvent() async {
    Trace trace = FirebasePerformance.instance.newTrace("sendLoginEvent()");
    await trace.start();

    Login login = Login();
    login.userID = currentUser.id;

    if (kIsWeb) {
      login.appVersion = "StorkeCentral Web v${appVersion.toString()}";
    } else if (Platform.isIOS) {
      login.appVersion = "StorkeCentral iOS v${appVersion.toString()}";
    } else if (Platform.isAndroid) {
      login.appVersion = "StorkeCentral Android v${appVersion.toString()}";
    }

    if (!kIsWeb) {
      login.deviceName = Platform.localHostname;
      login.deviceVersion = "${Platform.operatingSystem.toUpperCase()} ${Platform.operatingSystemVersion}";
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (!kIsWeb) {
      // Don't override the user's privacy settings if they're using the web version
      if (permission == LocationPermission.denied) {
        currentUser.privacy.location = "DISABLED";
      } else if (permission == LocationPermission.deniedForever) {
        currentUser.privacy.location = "DISABLED_FOREVER";
      } else if (permission == LocationPermission.whileInUse) {
        currentUser.privacy.location = "ENABLED_WHEN_IN_USE";
      } else if (permission == LocationPermission.always) {
        currentUser.privacy.location = "ENABLED_ALWAYS";
      }
    }
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      if (currentPosition?.latitude != null) {
        login.latitude = currentPosition!.latitude;
        login.longitude = currentPosition!.longitude;
      } else if (!kIsWeb) {
        // getLastKnownPosition() doesn't work on web
        Position? lastPosition = await Geolocator.getLastKnownPosition();
        login.latitude = lastPosition?.latitude ?? 0.0;
        login.longitude = lastPosition?.longitude ?? 0.0;
      }
    } else {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (Random().nextBool()) {
          CoolAlert.show(
            context: context,
            type: CoolAlertType.warning,
            title: "Location Disabled",
            widget: const Text("Please considering enabling location access to unlock the full potential of StorkeCentral."),
            confirmBtnColor: SB_AMBER,
            confirmBtnText: "OK",
          );
        }
      }
    }

    if (!kIsWeb) {
      // None of this shit works on web lol
      final info = NetworkInfo();
      var wifiName = await info.getWifiName(); // FooNetwork
      var wifiIP = await info.getWifiIP(); // 192.168.1.43
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.wifi) login.connectionType = "WiFi";
      if (connectivityResult == ConnectivityResult.mobile) login.connectionType = "Cellular";
      login.connectionSSID = wifiName ?? "error";
      login.connectionIP = wifiIP ?? "null";
    }

    await AuthService.getAuthToken();
    var loginResponse = await http.post(Uri.parse("$API_HOST/users/${currentUser.id}/logins"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}, body: jsonEncode(login));
    if (loginResponse.statusCode == 200) {
      log("[tab_bar_controller] Sent login event: ${loginResponse.body}");
    } else {
      log("[tab_bar_controller] Login event silently failed");
    }

    if (!kIsWeb) {
      // Don't change any onesignal shit on the web
      await requestNotifications();
      await OneSignal.login(currentUser.id);
      await OneSignal.User.addEmail(currentUser.email);
      log("[tab_bar_controller] OneSignal DEBUG optedIn: ${OneSignal.User.pushSubscription.optedIn}");
      log("[tab_bar_controller] OneSignal DEBUG id: ${OneSignal.User.pushSubscription.id}");
      log("[tab_bar_controller] OneSignal DEBUG token: ${OneSignal.User.pushSubscription.token}");
      log("[tab_bar_controller] OneSignal DEBUG: ${OneSignal.User.pushSubscription.toString()}");
      currentUser.privacy.pushNotificationToken = OneSignal.User.pushSubscription.id ?? "";
      currentUser.privacy.pushNotifications = OneSignal.User.pushSubscription.optedIn! ? "ENABLED" : "DISABLED";
    }

    setUserStatus("ONLINE");
    trace.stop();
  }

  void setUserStatus(String status) {
    if (!kIsWeb) {
      currentUser.status = status;
      FirebaseFirestore.instance.collection("status").doc(currentUser.id).set({"status": status, "timestamp": DateTime.now().toIso8601String()});
    }
    AuthService.getAuthToken().then((_) {
      http.post(Uri.parse("$API_HOST/users/${currentUser.id}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}, body: jsonEncode(currentUser));
    });
  }

  Future<void> updateUserFriendsList() async {
    Trace trace = FirebasePerformance.instance.newTrace("updateUserFriendsList()");
    await trace.start();
    await AuthService.getAuthToken();
    var response = await httpClient.get(Uri.parse("$API_HOST/users/${currentUser.id}/friends"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"});
    if (response.statusCode == 200) {
      log("[tab_bar_controller] Successfully updated local friend list");
      friends.clear();
      requests.clear();
      var responseJson = jsonDecode(response.body);
      // Persist friends list
      List<dynamic> friendsDynamic = responseJson["data"].map((e) => jsonEncode(e).toString()).toList();
      prefs.setStringList("CURRENT_USER_FRIENDS", friendsDynamic.map((e) => e.toString()).toList());

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
      log("[tab_bar_controller] ${response.body}", LogLevel.error);
      AlertService.showErrorSnackbar(context, "Failed to update friends list!");
    }
    trace.stop();
  }

  void fetchBuildings() async {
    if (!offlineMode) {
      if (buildings.isEmpty || DateTime.now().difference(lastBuildingFetch).inMinutes > 80) {
        try {
          Trace trace = FirebasePerformance.instance.newTrace("fetchBuildings()");
          await trace.start();
          await AuthService.getAuthToken();
          await httpClient.get(Uri.parse("$API_HOST/maps/buildings"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}).then((value) {
            setState(() {
              buildings = jsonDecode(value.body)["data"].map<Building>((json) => Building.fromJson(json)).toList();
            });
            lastBuildingFetch = DateTime.now();
          });
          prefs.setStringList("BUILDINGS_LIST", buildings.map((e) => jsonEncode(e).toString()).toList());
          prefs.setString("BUILDINGS_LAST_FETCH", lastBuildingFetch.toString());
          log("[tab_bar_controller] Fetched ${buildings.length} buildings from server");
          trace.stop();
        } catch(err) {
          AlertService.showErrorSnackbar(context, "Failed to get buildings!");
          log("[tab_bar_controller] ${err.toString()}", LogLevel.error);
        }
      } else {
        log("[tab_bar_controller] Using cached building list, last fetch was ${DateTime.now().difference(lastBuildingFetch).inMinutes} minutes ago (minimum 10080 minutes)");
      }
    } else {
      log("[tab_bar_controller] Offline mode, searching cache for buildings...");
      loadOfflineBuildings();
    }
  }

  void loadOfflineBuildings() async {
    Trace trace = FirebasePerformance.instance.newTrace("loadOfflineBuildings()");
    await trace.start();
    if (prefs.containsKey("BUILDINGS_LIST")) {
      setState(() {
        buildings = prefs.getStringList("BUILDINGS_LIST")!.map((e) => Building.fromJson(jsonDecode(e))).toList();
      });
      log("[tab_bar_controller] Loaded ${buildings.length} buildings from cache");
    }
    trace.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          pageTitles[_currPage],
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        actions: [
          Visibility(
            visible: true,
            child: IconButton(
              icon: Badge(
                isLabelVisible: notifications.where((element) => !element.read).isNotEmpty,
                label: Text(notifications.where((element) => !element.read).length.toString(), style: const TextStyle(color: Colors.white)),
                child: Icon(notifications.where((element) => !element.read).isEmpty ? Icons.notifications_none_outlined : Icons.notifications_active)
              ),
              onPressed: () {
                router.navigateTo(context, "/notifications", transition: TransitionType.nativeModal).then((value) => setState(() {}));
              },
            ),
          )
        ],
      ),
      extendBody: true,
      bottomNavigationBar: CurvedNavigationBar(
        animationDuration: const Duration(milliseconds: 200),
        backgroundColor: Colors.transparent,
        color: Theme.of(context).cardColor,
        index: _currPage,
        items: [
          Image.asset("images/icons/home-icon.png", height: 30, color: Theme.of(context).textTheme.bodyMedium!.color),
          Image.asset("images/icons/calendar/calendar-${DateTime.now().day}.png", height: 30, color: Theme.of(context).textTheme.bodyMedium!.color),
          Image.asset("images/icons/map-icon.png", height: 30, color: Theme.of(context).textTheme.bodyMedium!.color),
          Image.asset("images/icons/user-icon.png", height: 30, color: Theme.of(context).textTheme.bodyMedium!.color),
        ],
        onTap: (index) {
          setState(() {
            _currPage = index;
          });
          _pageController.animateToPage(index, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
        },
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currPage = index;
          });
        },
        children: const [
          HomePage(),
          SchedulePage(),
          MapsPage(),
          ProfilePage()
        ]
      ),
    );
  }
}
