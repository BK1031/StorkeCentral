import 'dart:convert';

import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:storke_central/models/user_final.dart';
import 'package:storke_central/models/user_passtime.dart';
import 'package:storke_central/utils/alert_service.dart';
import 'package:storke_central/utils/auth_service.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/logger.dart';
import 'package:storke_central/utils/theme.dart';
import 'package:storke_central/widgets/schedule/duo_card.dart';

class ScheduleFinalsPage extends StatefulWidget {
  const ScheduleFinalsPage({super.key});

  @override
  State<ScheduleFinalsPage> createState() => _ScheduleFinalsPageState();
}

class _ScheduleFinalsPageState extends State<ScheduleFinalsPage> {

  String deviceKey = "";

  bool fetchFinalsLoading = false;
  bool showFinalsDuo = false;
  bool fetchPasstimesLoading = false;
  bool showPasstimesDuo = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> fetchFinals(String quarter) async {
    if (prefs.containsKey("CREDENTIALS_KEY")) {
      log("[load_schedule_page] Found device key, fetching finals");
      deviceKey = prefs.getString("CREDENTIALS_KEY")!;
    } else {
      log("[load_schedule_page] No device key found", LogLevel.warn);
      AlertService.showErrorSnackbar(context, "Please fetch your GOLD schedule first!");
      return;
    }
    setState(() => fetchFinalsLoading = true);
    Future.delayed(const Duration(milliseconds: 1400), () {
      setState(() => showFinalsDuo = true);
    });
    try {
      Trace trace = FirebasePerformance.instance.newTrace("fetchFinals()");
      await trace.start();
      await AuthService.getAuthToken();
      await httpClient.get(Uri.parse("$API_HOST/users/schedule/${currentUser.id}/$quarter/finals/fetch"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN", "SC-Device-Key": deviceKey}).then((value) async {
        if (value.statusCode == 200) {
          // Successfully got finals
          setState(() {
            userFinals = jsonDecode(value.body)["data"].map<UserFinal>((json) => UserFinal.fromJson(json)).toList();
          });
          userFinals = jsonDecode(value.body)["data"].map<UserFinal>((json) => UserFinal.fromJson(json)).toList();
          if (quarter == currentQuarter.id && userFinals.isNotEmpty) {
            prefs.setStringList("USER_FINALS", userFinals.map((e) => jsonEncode(e).toString()).toList());
          }
        } else {
          log("[schedule_page] Failed to get finals: ${value.body}", LogLevel.error);
        }
      });
      trace.stop();
    } catch(err) {
      Future.delayed(Duration.zero, () => AlertService.showErrorSnackbar(context, "Failed to get finals!"));
      log("[schedule_page] ${err.toString()}", LogLevel.error);
      setState(() {
        fetchFinalsLoading = false;
        showFinalsDuo = false;
      });
    }
    setState(() {
      fetchFinalsLoading = false;
      showFinalsDuo = false;
    });
  }

  Future<void> fetchPasstime() async {
    if (prefs.containsKey("CREDENTIALS_KEY")) {
      log("[load_schedule_page] Found device key, fetching passtimes");
      deviceKey = prefs.getString("CREDENTIALS_KEY")!;
    } else {
      log("[load_schedule_page] No device key found", LogLevel.warn);
      AlertService.showErrorSnackbar(context, "Please fetch your GOLD schedule first!");
      return;
    }
    setState(() => fetchPasstimesLoading = true);
    Future.delayed(const Duration(milliseconds: 1400), () {
      setState(() => showPasstimesDuo = true);
    });
    try {
      Trace trace = FirebasePerformance.instance.newTrace("fetchPasstime()");
      await trace.start();
      await httpClient.get(Uri.parse("$API_HOST/users/passtime/${currentUser.id}/${currentPassQuarter.id}/fetch"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN", "SC-Device-Key": deviceKey}).then((value) async {
        if (value.statusCode == 200) {
          // Successfully got passtime
          setState(() {
            userPasstime = UserPasstime.fromJson(jsonDecode(utf8.decode(value.bodyBytes))["data"]);
          });
        } else {
          AlertService.showErrorSnackbar(context, "Failed to fetch passtime!");
          log("[schedule_page] Failed to fetch passtime: ${value.body}", LogLevel.error);
        }
      });
      trace.stop();
    } catch(err) {
      Future.delayed(Duration.zero, () => AlertService.showErrorSnackbar(context, "Failed to get passtimes!"));
      log("[schedule_page] ${err.toString()}", LogLevel.error);
      setState(() {
        fetchPasstimesLoading = false;
        showPasstimesDuo = false;
      });
    }
    setState(() {
      fetchPasstimesLoading = false;
      showPasstimesDuo = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${selectedQuarter.name} Finals", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Padding(padding: EdgeInsets.all(4)),
            const Text("No finals found for you this quarter."),
            const Padding(padding: EdgeInsets.all(4)),
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              height: showFinalsDuo ? 200 : 0,
              curve: Curves.easeInOut,
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      DuoCard(),
                      Padding(padding: EdgeInsets.all(4)),
                      Text("You should have received a Duo notification like the one above. Please approve it to allow us to fetch your course schedule from GOLD.", style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),
            fetchFinalsLoading ? Center(
              child: RefreshProgressIndicator(
                backgroundColor: SB_NAVY,
                color: Colors.white,
              ),
            ) : SizedBox(
              width: double.infinity,
              height: 35,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                color: SB_NAVY,
                child: const Text("Fetch Finals"),
                onPressed: () {
                  fetchFinals(selectedQuarter.id);
                },
              ),
            ),
            Column(
              children: userFinals.map((e) => Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(e.name, style: const TextStyle()),
                  ],
                )
              )).toList(),
            ),
            const Padding(padding: EdgeInsets.all(8)),
            Text("${currentPassQuarter.name} Registration", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Padding(padding: EdgeInsets.all(4)),
            const Text("No passtimes found for you."),
            const Padding(padding: EdgeInsets.all(4)),
            SizedBox(
              width: double.infinity,
              height: 35,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                color: SB_NAVY,
                child: const Text("Fetch Passtimes"),
                onPressed: () {
                },
              ),
            ),
            Column(
              children: userFinals.map((e) => Card(
                child: ListTile(
                  title: Text(e.name),
                  subtitle: Text(e.title),
                  trailing: Text(DateFormat().format(e.startTime)),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
