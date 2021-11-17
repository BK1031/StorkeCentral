import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/theme.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthCheckerPage extends StatefulWidget {
  const AuthCheckerPage({Key? key}) : super(key: key);

  @override
  _AuthCheckerPageState createState() => _AuthCheckerPageState();
}

class _AuthCheckerPageState extends State<AuthCheckerPage> {

  double percent = 0.2;
  bool connected = true;
  final info = NetworkInfo();

  @override
  void initState() {
    super.initState();
    checkConnectivity().then((value) {
      FirebaseAuth.instance.authStateChanges().listen((User? user) async {
        if (user == null) {
          await loadPreferences();
          router.navigateTo(context, "/register", transition: TransitionType.fadeIn, replace: true, clearStack: true);
        } else {
          anonMode = user.isAnonymous;
          router.navigateTo(context, "/home", transition: TransitionType.fadeIn, replace: true, clearStack: true);
        }
      });
    });
  }

  Future<void> checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile) {
      print("Connected to Cellular");
    } else if (connectivityResult == ConnectivityResult.wifi) {
      print("Connected to WiFi");
    }
    else {
      // No connection
      print("OFFLINE MODE");
      offlineMode = true;
    }
    setState(() {
      percent = 0.7;
    });
  }

  Future<void> loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey("PREF_UNITS")) prefs.setString("PREF_UNITS", PREF_UNITS);
    PREF_UNITS = prefs.getString("PREF_UNITS")!;
    setState(() {
      percent = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Center(
            child: Image.asset(
              "images/storke.jpeg",
              width: 100,
            ),
          ),
          Center(
            child: CircularPercentIndicator(
              radius: 75,
              circularStrokeCap: CircularStrokeCap.round,
              lineWidth: 7,
              animateFromLastPercent: true,
              animation: true,
              percent: percent,
              progressColor: sbNavy,
            ),
          )
        ],
      ),
    );
  }
}
