import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:storke_central/models/login.dart';
import 'package:storke_central/pages/home/home_page.dart';
import 'package:storke_central/pages/maps/maps_page.dart';
import 'package:storke_central/pages/profile/profile_page.dart';
import 'package:storke_central/pages/schedule/schedule_page.dart';
import 'package:storke_central/utils/auth_service.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/logger.dart';
import 'package:storke_central/utils/theme.dart';
import 'package:http/http.dart' as http;

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _determinePosition();
    firebaseAnalytics();
    if (!anonMode && !offlineMode) sendLoginEvent();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      log("App has been resumed");
      _determinePosition();
      if (!anonMode && !offlineMode) sendLoginEvent();
    } else {
      log("App has been backgrounded");
      if (!anonMode && !offlineMode) setUserStatus("OFFLINE");
      _positionStream?.cancel();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _positionStream?.cancel();
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

  Future<void> firebaseAnalytics() async {
    await FirebaseAnalytics.instance.setUserId(id: currentUser.id);
    FirebaseAnalytics.instance.logScreenView(screenName: "Home Page", screenClass: "TabBarController");
  }

  Future<void> sendLoginEvent() async {
    Login login = Login();
    login.userID = currentUser.id;

    if (Platform.isIOS) login.appVersion = "StorkeCentral iOS v${appVersion.toString()}";
    if (Platform.isAndroid) login.appVersion = "StorkeCentral Android v${appVersion.toString()}";
    if (kIsWeb) login.appVersion = "StorkeCentral Web v${appVersion.toString()}";

    login.deviceName = Platform.localHostname;
    login.deviceVersion = "${Platform.operatingSystem.toUpperCase()} ${Platform.operatingSystemVersion}";

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      currentUser.privacy.location = "DISABLED";
    } else if (permission == LocationPermission.deniedForever) {
      currentUser.privacy.location = "DISABLED_FOREVER";
    } else if (permission == LocationPermission.whileInUse) {
      currentUser.privacy.location = "ENABLED_WHEN_IN_USE";
    } else if (permission == LocationPermission.always) {
      currentUser.privacy.location = "ENABLED_ALWAYS";
    }
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      if (currentPosition?.latitude != null) {
        login.latitude = currentPosition!.latitude;
        login.longitude = currentPosition!.longitude;
      } else {
        Position? lastPosition = await Geolocator.getLastKnownPosition();
        login.latitude = lastPosition?.latitude ?? 0.0;
        login.longitude = lastPosition?.longitude ?? 0.0;
      }
    } else {
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

    final info = NetworkInfo();
    var wifiName = await info.getWifiName(); // FooNetwork
    var wifiIP = await info.getWifiIP(); // 192.168.1.43
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi) login.connectionType = "WiFi";
    if (connectivityResult == ConnectivityResult.mobile) login.connectionType = "Cellular";
    login.connectionSSID = wifiName ?? "error";
    login.connectionIP = wifiIP ?? "null";

    await AuthService.getAuthToken();
    var loginResponse = await http.post(Uri.parse("$API_HOST/users/${currentUser.id}/logins"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}, body: jsonEncode(login));
    if (loginResponse.statusCode == 200) log("Sent login event: ${loginResponse.body}");
    else log("Login event silently failed");

    OneSignal.shared.setExternalUserId(currentUser.id);
    OneSignal.shared.setEmail(email: currentUser.email);
    final oneSignal = await OneSignal.shared.getDeviceState();
    currentUser.privacy.pushNotificationToken = oneSignal?.userId ?? "";
    setUserStatus("ONLINE");
  }

  void setUserStatus(String status) {
    currentUser.status = status;
    FirebaseFirestore.instance.collection("status").doc(currentUser.id).set({"status": status, "timestamp": DateTime.now().toIso8601String()});
    AuthService.getAuthToken().then((_) {
      http.post(Uri.parse("$API_HOST/users"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}, body: jsonEncode(currentUser));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          pageTitles[_currPage],
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        animationDuration: const Duration(milliseconds: 200),
        backgroundColor: Colors.transparent,
        color: Theme.of(context).cardColor,
        index: _currPage,
        items: [
          Image.asset("images/icons/home-icon.png", height: 30, color: Theme.of(context).textTheme.bodyText1!.color),
          Image.asset("images/icons/calendar/calendar-${DateTime.now().day}.png", height: 30, color: Theme.of(context).textTheme.bodyText1!.color),
          Image.asset("images/icons/map-icon.png", height: 30, color: Theme.of(context).textTheme.bodyText1!.color),
          Image.asset("images/icons/user-icon.png", height: 30, color: Theme.of(context).textTheme.bodyText1!.color),
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
        ],
      ),
    );
  }
}
