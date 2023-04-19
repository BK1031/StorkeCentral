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
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
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
      if (!kIsWeb) _registerFirebaseDynamicLinkListener();
      if (!kIsWeb) _registerOneSignalListeners();
      fetchBuildings();
      if (!anonMode && !offlineMode) {
        firebaseAnalytics();
        sendLoginEvent();
        updateUserFriendsList();
        fetchNotifications();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      log("[tab_bar_controller] App has been resumed");
      AuthService.getUser(currentUser.id);
      _determinePosition();
      checkAppVersion();
      if (!anonMode && !offlineMode) sendLoginEvent();
    } else {
      log("[tab_bar_controller] App has been backgrounded");
      if (!anonMode && !offlineMode) setUserStatus("OFFLINE");
      _positionStream?.cancel();
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
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
              backgroundColor: SB_NAVY,
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
      } else if (currentUser.roles.where((r) => r.role == "PRIVATE_BETA").isNotEmpty && appVersion.getVersionCode() < beta.getVersionCode()) {
        log("[tab_bar_controller] App is behind beta version (${appVersion.toString()} < ${beta.toString()})");
        if (!kIsWeb) {
          CoolAlert.show(
              context: context,
              type: CoolAlertType.warning,
              title: "New Beta Available",
              text: "A new version of the Storke Central Beta is available. Please update your app from TestFlight to receive the latest bug fixes and use our newest features.",
              backgroundColor: SB_NAVY,
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

  void _registerFirebaseDynamicLinkListener() {
    // Handle initial link if app is opened from a dynamic link
    if (launchDynamicLink != "") {
      Future.delayed(const Duration(milliseconds: 900), () {
        router.navigateTo(context, launchDynamicLink.split("/#")[1], transition: TransitionType.native);
        launchDynamicLink = "";
      });
    }
    FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) {
      launchDynamicLink = dynamicLinkData.link.toString();
      log("[tab_bar_controller] Firebase Dynamic Link received: ${dynamicLinkData.link}");
      Future.delayed(const Duration(milliseconds: 200), () {
        router.navigateTo(context, launchDynamicLink.split("/#")[1], transition: TransitionType.native);
        launchDynamicLink = "";
      });
    }).onError((error) {
      log("[tab_bar_controller] Firebase Dynamic Link error: $error", LogLevel.error);
    });
  }

  void _registerOneSignalListeners() {
    OneSignal.shared.setNotificationWillShowInForegroundHandler((event) {
      log("[tab_bar_controller] OneSignal notification received: ${event.notification.notificationId}");
      fetchNotifications().then((value) {
        log("[tab_bar_controller] You now have ${notifications.where((element) => !element.read).length} unread notifications");
      });
      event.complete(event.notification);
    });
    OneSignal.shared.setNotificationOpenedHandler((result) {
      log("[tab_bar_controller] OneSignal notification opened: ${result.notification.notificationId}");
      router.navigateTo(context, "/notifications", transition: TransitionType.nativeModal);
    });
  }

  Future<void> fetchNotifications() async {
    try {
      await AuthService.getAuthToken();
      await http.get(Uri.parse("$API_HOST/notifications/user/${currentUser.id}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}).then((value) {
        setState(() {
          notifications = jsonDecode(utf8.decode(value.bodyBytes))["data"].map<sc.Notification>((json) => sc.Notification.fromJson(json)).toList();
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        });
      });
    } catch(err) {
      // TODO: Show error snackbar
      log("[tab_bar_controller] ${err.toString()}", LogLevel.error);
    }
  }

  Future<void> requestNotifications() async {
    OneSignal.shared.promptUserForPushNotificationPermission().then((accepted) {
      log("[tab_bar_controller] Accepted notification permissions: $accepted");
      if (mounted) {
        setState(() {
          currentUser.privacy.pushNotifications = accepted ? "ENABLED" : "DISABLED";
        });
        if (currentUser.privacy.pushNotifications == "DISABLED") showNotificationsDisabledAlert();
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
    Login login = Login();
    login.userID = currentUser.id;

    if (kIsWeb) login.appVersion = "StorkeCentral Web v${appVersion.toString()}";
    else if (Platform.isIOS) login.appVersion = "StorkeCentral iOS v${appVersion.toString()}";
    else if (Platform.isAndroid) login.appVersion = "StorkeCentral Android v${appVersion.toString()}";

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
    if (loginResponse.statusCode == 200) log("[tab_bar_controller] Sent login event: ${loginResponse.body}");
    else log("[tab_bar_controller] Login event silently failed");

    if (!kIsWeb) {
      // Don't change any onesignal shit on the web
      await requestNotifications();
      OneSignal.shared.setExternalUserId(currentUser.id);
      OneSignal.shared.setEmail(email: currentUser.email);
      final oneSignal = await OneSignal.shared.getDeviceState();
      currentUser.privacy.pushNotificationToken = oneSignal?.userId ?? "";
      currentUser.privacy.pushNotifications = oneSignal!.hasNotificationPermission ? "ENABLED" : "DISABLED";
    }

    setUserStatus("ONLINE");
  }

  void setUserStatus(String status) {
    currentUser.status = status;
    FirebaseFirestore.instance.collection("status").doc(currentUser.id).set({"status": status, "timestamp": DateTime.now().toIso8601String()});
    AuthService.getAuthToken().then((_) {
      http.post(Uri.parse("$API_HOST/users/${currentUser.id}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}, body: jsonEncode(currentUser));
    });
  }

  Future<void> updateUserFriendsList() async {
    await AuthService.getAuthToken();
    var response = await http.get(Uri.parse("$API_HOST/users/${currentUser.id}/friends"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"});
    if (response.statusCode == 200) {
      log("[tab_bar_controller] Successfully updated local friend list");
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
      log("[tab_bar_controller] ${response.body}", LogLevel.error);
      // TODO: show error snackbar
    }
  }

  void fetchBuildings() async {
    if (!offlineMode) {
      if (buildings.isEmpty || DateTime.now().difference(lastBuildingFetch).inMinutes > 1440) {
        try {
          await AuthService.getAuthToken();
          await http.get(Uri.parse("$API_HOST/maps/buildings"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}).then((value) {
            setState(() {
              buildings = jsonDecode(utf8.decode(value.bodyBytes))["data"].map<Building>((json) => Building.fromJson(json)).toList();
            });
            lastBuildingFetch = DateTime.now();
          });
        } catch(err) {
          // TODO: Show error snackbar
          log("[tab_bar_controller] ${err.toString()}", LogLevel.error);
        }
      } else {
        log("[tab_bar_controller] Using cached building list, last fetch was ${DateTime.now().difference(lastBuildingFetch).inMinutes} minutes ago (minimum 1440 minutes)");
      }
    } else {
      log("[tab_bar_controller] Offline mode, searching cache for buildings...");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: SB_NAVY,
        title: Text(
          pageTitles[_currPage],
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        actions: [
          Visibility(
            visible: !anonMode,
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
      bottomNavigationBar: CurvedNavigationBar(
        animationDuration: const Duration(milliseconds: 200),
        backgroundColor: Colors.transparent,
        color: Theme.of(context).cardColor,
        index: _currPage,
        items: !anonMode ? [
          Image.asset("images/icons/home-icon.png", height: 30, color: Theme.of(context).textTheme.bodyText1!.color),
          Image.asset("images/icons/calendar/calendar-${DateTime.now().day}.png", height: 30, color: Theme.of(context).textTheme.bodyText1!.color),
          Image.asset("images/icons/map-icon.png", height: 30, color: Theme.of(context).textTheme.bodyText1!.color),
          Image.asset("images/icons/user-icon.png", height: 30, color: Theme.of(context).textTheme.bodyText1!.color),
        ] : [
          Image.asset("images/icons/home-icon.png", height: 30, color: Theme.of(context).textTheme.bodyText1!.color),
          Image.asset("images/icons/calendar/calendar-${DateTime.now().day}.png", height: 30, color: Theme.of(context).textTheme.bodyText1!.color),
          Image.asset("images/icons/map-icon.png", height: 30, color: Theme.of(context).textTheme.bodyText1!.color),
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
        children: !anonMode ? const [
          HomePage(),
          SchedulePage(),
          MapsPage(),
          ProfilePage()
        ] : const [
          HomePage(),
          SchedulePage(),
          MapsPage(),
        ]
      ),
    );
  }
}
