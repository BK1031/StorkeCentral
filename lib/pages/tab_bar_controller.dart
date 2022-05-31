import 'dart:convert';
import 'dart:io';
import 'dart:math';
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
import 'package:storke_central/utils/theme.dart';
import 'package:http/http.dart' as http;

class TabBarController extends StatefulWidget {
  const TabBarController({Key? key}) : super(key: key);

  @override
  State<TabBarController> createState() => _TabBarControllerState();
}

class _TabBarControllerState extends State<TabBarController> {

  int _currPage = 0;
  List<String> pageTitles = ["Home", "Schedule", "Maps", "Profile"];
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    firebaseAnalytics();
    sendLoginEvent();
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
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      Position position = await Geolocator.getCurrentPosition();
      login.latitude = position.latitude;
      login.longitude = position.longitude;
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
    if (loginResponse.statusCode == 200) print("Sent login event: ${loginResponse.body}");
    else print("Login event silently failed");

    OneSignal.shared.setExternalUserId(currentUser.id);
    OneSignal.shared.setEmail(email: currentUser.email);
    final oneSignal = await OneSignal.shared.getDeviceState();
    currentUser.privacy.pushNotificationToken = oneSignal!.userId ?? "";
    await AuthService.getAuthToken();
    var createUser = await http.post(Uri.parse("$API_HOST/users"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}, body: jsonEncode(currentUser));
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
