import 'dart:async';
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
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    getFinals(selectedQuarter.id);
    getPasstime();
  }

  Future<void> getFinals(String quarter) async {
    if (!offlineMode) {
      try {
        loadOfflineFinals();
        Trace trace = FirebasePerformance.instance.newTrace("getFinals()");
        await trace.start();
        await AuthService.getAuthToken();
        await httpClient.get(Uri.parse("$API_HOST/users/schedule/${currentUser.id}/$quarter/finals"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}).then((value) async {
          if (value.statusCode == 200) {
            // Successfully got finals
            setState(() {
              userFinals = jsonDecode(value.body)["data"].map<UserFinal>((json) => UserFinal.fromJson(json)).toList();
            });
            if (quarter == currentQuarter.id && userFinals.isNotEmpty) {
              prefs.setStringList("USER_FINALS", userFinals.map((e) => jsonEncode(e).toString()).toList());
            }
          } else {
            log("[schedule_finals_page] Failed to get finals: ${value.body}", LogLevel.error);
          }
        });
        trace.stop();
      } catch(err) {
        Future.delayed(Duration.zero, () => AlertService.showErrorSnackbar(context, "Failed to get finals!"));
        log("[schedule_finals_page] ${err.toString()}", LogLevel.error);
      }
    } else {
      log("[schedule_finals_page] Offline mode, searching cache for finals...");
      if (quarter == currentQuarter.id) {
        loadOfflineFinals();
      } else {
        log("[schedule_finals_page] Can't load offline finals for this quarter!", LogLevel.warn);
        AlertService.showErrorSnackbar(context, "Can't load offline finals for this quarter!");
      }
    }
  }

  void loadOfflineFinals() async {
    Trace trace = FirebasePerformance.instance.newTrace("loadOfflineFinals()");
    await trace.start();
    if (prefs.containsKey("USER_FINALS")) {
      setState(() {
        userFinals = prefs.getStringList("USER_FINALS")!.map((e) => UserFinal.fromJson(jsonDecode(e))).toList();
      });
      log("[schedule_finals_page] Loaded ${userFinals.length} finals from cache.");
      if (offlineMode) {
        Future.delayed(Duration.zero, () => AlertService.showSuccessSnackbar(context, "Loaded offline finals!"));
      }
    }
    trace.stop();
  }

  Future<void> fetchFinals(String quarter) async {
    prefs.setString("CREDENTIALS_KEY", "arzjydwigSjRj0OEit8cVWyKLmThdfRv"); // TODO: REMOVE THIS FOR DEBUG ONLY
    if (prefs.containsKey("CREDENTIALS_KEY")) {
      log("[schedule_finals_page] Found device key, fetching finals");
      deviceKey = prefs.getString("CREDENTIALS_KEY")!;
    } else {
      log("[schedule_finals_page] No device key found", LogLevel.warn);
      AlertService.showErrorSnackbar(context, "Please fetch your GOLD schedule first!");
      return;
    }
    setState(() => fetchFinalsLoading = true);
    Timer duoPromptTimer = Timer(const Duration(milliseconds: 1400), () {
      setState(() {
        showFinalsDuo = true;
      });
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
          if (quarter == currentQuarter.id && userFinals.isNotEmpty) {
            prefs.setStringList("USER_FINALS", userFinals.map((e) => jsonEncode(e).toString()).toList());
          }
        } else {
          AlertService.showErrorSnackbar(context, jsonDecode(value.body)["data"]["message"] ?? "Failed to fetch finals!");
          duoPromptTimer.cancel();
          log("[schedule_finals_page] Failed to fetch finals: ${value.body}", LogLevel.error);
        }
      });
      trace.stop();
    } catch(err) {
      Future.delayed(Duration.zero, () => AlertService.showErrorSnackbar(context, "Failed to get finals!"));
      log("[schedule_finals_page] ${err.toString()}", LogLevel.error);
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

  Future<void> getPasstime() async {
    if (!offlineMode) {
      try {
        loadOfflinePasstime();
        Trace trace = FirebasePerformance.instance.newTrace("getPasstime()");
        await trace.start();
        await AuthService.getAuthToken();
        await httpClient.get(Uri.parse("$API_HOST/users/passtime/${currentUser.id}/${currentPassQuarter.id}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}).then((value) async {
          if (value.statusCode == 200) {
            // Successfully got passtime
            setState(() {
              userPasstime = UserPasstime.fromJson(jsonDecode(value.body)["data"]);
            });
            prefs.setString("USER_PASSTIME", jsonEncode(userPasstime).toString());
          } else {
            log("[schedule_finals_page] Failed to get passtime: ${value.body}", LogLevel.error);
          }
        });
        trace.stop();
      } catch(err) {
        Future.delayed(Duration.zero, () => AlertService.showErrorSnackbar(context, "Failed to get passtime!"));
        log("[schedule_finals_page] ${err.toString()}", LogLevel.error);
      }
    } else {
      log("[schedule_finals_page] Offline mode, searching cache for passtime...");
      loadOfflinePasstime();
    }
  }

  void loadOfflinePasstime() async {
    Trace trace = FirebasePerformance.instance.newTrace("loadOfflinePasstime()");
    await trace.start();
    if (prefs.containsKey("USER_PASSTIME")) {
      setState(() {
        userPasstime = UserPasstime.fromJson(jsonDecode(prefs.getString("USER_PASSTIME")!));
      });
      log("[schedule_finals_page] Loaded passtime from cache.");
      if (offlineMode) {
        Future.delayed(Duration.zero, () => AlertService.showSuccessSnackbar(context, "Loaded offline passtime!"));
      }
    }
    trace.stop();
  }

  Future<void> fetchPasstime() async {
    if (prefs.containsKey("CREDENTIALS_KEY")) {
      log("[schedule_finals_page] Found device key, fetching passtimes");
      deviceKey = prefs.getString("CREDENTIALS_KEY")!;
    } else {
      log("[schedule_finals_page] No device key found", LogLevel.warn);
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
            userPasstime = UserPasstime.fromJson(jsonDecode(value.body)["data"]);
          });
          prefs.setString("USER_PASSTIME", jsonEncode(userPasstime).toString());
        } else {
          AlertService.showErrorSnackbar(context, jsonDecode(value.body)["data"]["message"] ?? "Failed to fetch passtime!");
          log("[schedule_finals_page] Failed to fetch passtime: ${value.body}", LogLevel.error);
        }
      });
      trace.stop();
    } catch(err) {
      Future.delayed(Duration.zero, () => AlertService.showErrorSnackbar(context, "Failed to get passtimes!"));
      log("[schedule_finals_page] ${err.toString()}", LogLevel.error);
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${selectedQuarter.name} Finals", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(512)),
                  color: SB_NAVY,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(512),
                    onTap: () {
                      fetchFinals(selectedQuarter.id);
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Icon(Icons.refresh_rounded, color: Colors.white),
                    ),
                  ),
                )
              ]
            ),
            const Padding(padding: EdgeInsets.all(4)),
            Visibility(
              visible: userFinals.isEmpty,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("No finals found for you this quarter."),
                  const Padding(padding: EdgeInsets.all(4)),
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
                ],
              ),
            ),
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
            Visibility(
              visible: userFinals.isNotEmpty,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: userFinals.map((e) => Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(e.name, style: const TextStyle()),
                      Text("${DateFormat("EEE, MMM d, yyyy h:mm a").format(e.startTime.toLocal())} - ${DateFormat("h:mm a").format(e.endTime.toLocal())}", style: TextStyle(color: SB_NAVY)),
                    ],
                  )
                )).toList(),
              ),
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
                  fetchPasstime();
                },
              ),
            ),
            Visibility(
              visible: userPasstime.userID != "",
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Pass 1:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(DateFormat("MM/dd/yyyy hh:mm a").format(userPasstime.passOneStart.toLocal()), style: const TextStyle()),
                            Text(DateFormat("MM/dd/yyyy hh:mm a").format(userPasstime.passOneEnd.toLocal()), style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.all(4)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Pass 2:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(DateFormat("MM/dd/yyyy hh:mm a").format(userPasstime.passTwoStart.toLocal()), style: const TextStyle()),
                            Text(DateFormat("MM/dd/yyyy hh:mm a").format(userPasstime.passTwoEnd.toLocal()), style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.all(4)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Pass 3:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(DateFormat("MM/dd/yyyy hh:mm a").format(userPasstime.passThreeStart.toLocal()), style: const TextStyle()),
                            Text(DateFormat("MM/dd/yyyy hh:mm a").format(userPasstime.passThreeEnd.toLocal()), style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
