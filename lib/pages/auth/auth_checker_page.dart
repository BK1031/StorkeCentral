import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storke_central/utils/auth_service.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/theme.dart';

class AuthCheckerPage extends StatefulWidget {
  const AuthCheckerPage({Key? key}) : super(key: key);

  @override
  State<AuthCheckerPage> createState() => _AuthCheckerPageState();
}

class _AuthCheckerPageState extends State<AuthCheckerPage> {

  double percent = 0.0;
  bool connected = true;
  final info = NetworkInfo();

  @override
  void initState() {
    super.initState();
    checkConnectivity().then((value) => checkAuthState());
  }

  Future<void> checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.mobile) {
      print("Connected to Cellular");
    } else if (connectivityResult == ConnectivityResult.wifi) {
      print("Connected to WiFi");
    } else {
      print("No Connection!");
      offlineMode = true;
    }
    if (mounted) setState(() {percent = 0.2;});
  }

  Future<void> checkServerStatus() async {
    var serverStatus = await http.get(Uri.parse("$API_HOST/montecito/ping"), headers: {"SC-API-KEY": SC_API_KEY});
    print("Server Status: ${serverStatus.statusCode}");
    if (serverStatus.statusCode != 200) {
      offlineMode = true;
    }
  }

  Future<void> checkAuthState() async {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        // Not logged in
        await Future.delayed(const Duration(milliseconds: 500));
        router.navigateTo(context, "/register", transition: TransitionType.fadeIn, replace: true, clearStack: true);
      } else {
        // User logged in
        anonMode = user.isAnonymous;
        print("anonMode: $anonMode");
        try {
          if (!anonMode) {
            await AuthService.getUser(user.uid);
            if (currentUser.id == "") {
              router.navigateTo(context, "/register", transition: TransitionType.fadeIn, replace: true, clearStack: true);
              return;
            }
            FirebaseAnalytics.instance.logLogin(loginMethod: "Google");
          } else {
            FirebaseAnalytics.instance.logLogin(loginMethod: "Anonymous");
          }
          await loadPreferences();
          await Future.delayed(const Duration(milliseconds: 500));
          router.navigateTo(context, "/home", transition: TransitionType.fadeIn, replace: true, clearStack: true);
        } catch (err) {
          print(err);
          await loadOfflineMode();
          router.navigateTo(context, "/home", transition: TransitionType.fadeIn, replace: true, clearStack: true);
        }
      }
    });
  }

  Future<void> loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey("PREF_UNITS")) prefs.setString("PREF_UNITS", PREF_UNITS);
    PREF_UNITS = prefs.getString("PREF_UNITS")!;
    if (mounted) setState(() {percent = 1;});
  }

  Future<void> loadOfflineMode() async {
    print("Failed to reach server, entering offline mode!");
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