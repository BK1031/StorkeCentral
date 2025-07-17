import 'dart:async';
import 'dart:convert';

import 'package:firebase_performance/firebase_performance.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
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
            if (quarter == currentQuarter.id) {
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
    if (prefs.containsKey("USER_FINALS") && selectedQuarter == currentQuarter) {
      setState(() {
        userFinals = prefs.getStringList("USER_FINALS")!.map((e) => UserFinal.fromJson(jsonDecode(e))).toList();
        if (userFinals.isNotEmpty && userFinals.first.quarter != currentQuarter.id) {
          log("[schedule_page] Cached finals are not for the current quarter, clearing cache.", LogLevel.warn);
          prefs.remove("USER_FINALS");
          userScheduleItems.clear();
        }
      });
      log("[schedule_finals_page] Loaded ${userFinals.length} finals from cache.");
      if (offlineMode) {
        Future.delayed(Duration.zero, () => AlertService.showSuccessSnackbar(context, "Loaded offline finals!"));
      }
    }
    trace.stop();
  }

  Future<void> fetchFinals(String quarter) async {
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
          Future.delayed(Duration.zero, () => AlertService.showSuccessSnackbar(context, "Fetched ${userFinals.length} finals!"));
        } else {
          duoPromptTimer.cancel();
          AlertService.showErrorSnackbar(context, jsonDecode(value.body)["data"]["message"] ?? "Failed to fetch finals!");
          log("[schedule_finals_page] Failed to fetch finals: ${value.body}", LogLevel.error);
        }
      });
      trace.stop();
    } catch(err) {
      Future.delayed(Duration.zero, () => AlertService.showErrorSnackbar(context, "Failed to get finals!"));
      log("[schedule_finals_page] ${err.toString()}", LogLevel.error);
      duoPromptTimer.cancel();
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
            setState(() {
              userPasstime = UserPasstime();
            });
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
      UserPasstime passtime = UserPasstime.fromJson(jsonDecode(prefs.getString("USER_PASSTIME")!));
      if (passtime.quarter == currentPassQuarter.id) {
        setState(() {
          userPasstime = passtime;
        });
        log("[schedule_finals_page] Loaded passtime from cache.");
      } else {
        log("[schedule_page] Cached passtimes are not for the current pass quarter, clearing cache.", LogLevel.warn);
        prefs.remove("USER_PASSTIME");
      }
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
    Timer duoPromptTimer = Timer(const Duration(milliseconds: 1400), () {
      setState(() {
        showPasstimesDuo = true;
      });
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
          Future.delayed(Duration.zero, () => AlertService.showSuccessSnackbar(context, "Fetched passtimes!"));
        } else {
          duoPromptTimer.cancel();
          AlertService.showErrorSnackbar(context, jsonDecode(value.body)["data"]["message"] ?? "Failed to fetch passtime!");
          log("[schedule_finals_page] Failed to fetch passtime: ${value.body}", LogLevel.error);
        }
      });
      trace.stop();
    } catch(err) {
      Future.delayed(Duration.zero, () => AlertService.showErrorSnackbar(context, "Failed to get passtimes!"));
      log("[schedule_finals_page] ${err.toString()}", LogLevel.error);
      duoPromptTimer.cancel();
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
                Visibility(
                  visible: userFinals.isNotEmpty,
                  child: fetchFinalsLoading ? Center(
                    child: RefreshProgressIndicator(
                      backgroundColor: ACTIVE_ACCENT_COLOR,
                      color: Colors.white,
                    ),
                  ) : Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(512)),
                    color: ACTIVE_ACCENT_COLOR,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(512),
                      onTap: () {
                        if (kIsWeb) {
                          AlertService.showWarningDialog(
                              context,
                              "Finals Fetch Unavailable",
                              "In order to keep your credentials as secure as possible, you can only sync your schedule from our mobile app.\n\nWe apologize for the inconvenience!",
                                  () {}
                          );
                        } else {
                          fetchFinals(selectedQuarter.id);
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.refresh_rounded, color: Colors.white),
                      ),
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
                      backgroundColor: ACTIVE_ACCENT_COLOR,
                      color: Colors.white,
                    ),
                  ) : SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      color: ACTIVE_ACCENT_COLOR,
                      child: const Text("Fetch Finals"),
                      onPressed: () {
                        if (kIsWeb) {
                          AlertService.showWarningDialog(
                              context,
                              "Finals Fetch Unavailable",
                              "In order to keep your credentials as secure as possible, you can only sync your schedule from our mobile app.\n\nWe apologize for the inconvenience!",
                                  () {}
                          );
                        } else {
                          fetchFinals(selectedQuarter.id);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              height: showFinalsDuo ? 250 : 0,
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
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      router.navigateTo(context, "/schedule/view/${e.title}", transition: TransitionType.nativeModal);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(e.name, style: const TextStyle()),
                                Text("${DateFormat("EEE, MMM d, yyyy h:mm a").format(e.startTime.toLocal())} - ${DateFormat("h:mm a").format(e.endTime.toLocal())}", style: TextStyle(color: ACTIVE_ACCENT_COLOR)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey)
                        ],
                      ),
                    ),
                  )
                )).toList(),
              ),
            ),
            const Padding(padding: EdgeInsets.all(8)),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${currentPassQuarter.name} Registration", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Visibility(
                    visible: userPasstime.userID != "",
                    child: fetchPasstimesLoading ? Center(
                      child: RefreshProgressIndicator(
                        backgroundColor: ACTIVE_ACCENT_COLOR,
                        color: Colors.white,
                      ),
                    ) : Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(512)),
                      color: ACTIVE_ACCENT_COLOR,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(512),
                        onTap: () {
                          if (kIsWeb) {
                            AlertService.showWarningDialog(
                                context,
                                "Passtime Fetch Unavailable",
                                "In order to keep your credentials as secure as possible, you can only sync your schedule from our mobile app.\n\nWe apologize for the inconvenience!",
                                    () {}
                            );
                          } else {
                            fetchPasstime();
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(Icons.refresh_rounded, color: Colors.white),
                        ),
                      ),
                    ),
                  )
                ]
            ),
            const Padding(padding: EdgeInsets.all(4)),
            Visibility(
              visible: userPasstime.userID == "",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("No passtimes found for you this quarter."),
                  const Padding(padding: EdgeInsets.all(4)),
                  fetchPasstimesLoading ? Center(
                    child: RefreshProgressIndicator(
                      backgroundColor: ACTIVE_ACCENT_COLOR,
                      color: Colors.white,
                    ),
                  ) : SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      color: ACTIVE_ACCENT_COLOR,
                      child: const Text("Fetch Passtimes"),
                      onPressed: () {
                        if (kIsWeb) {
                          AlertService.showWarningDialog(
                              context,
                              "Passtime Fetch Unavailable",
                              "In order to keep your credentials as secure as possible, you can only sync your schedule from our mobile app.\n\nWe apologize for the inconvenience!",
                                  () {}
                          );
                        } else {
                          fetchPasstime();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              height: showPasstimesDuo ? 250 : 0,
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
              visible: userPasstime.userID != "",
              child: Column(
                children: [1, 2, 3].map((e) => Card(
                  color: userPasstime.getCurrentPasstime() == e ? ACTIVE_ACCENT_COLOR : Theme.of(context).cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Pass $e:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: userPasstime.getCurrentPasstime() == e ? Colors.white : null)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                DateFormat("M/dd/yyyy h:mm a").format(userPasstime.getPasstime(e)[0].toLocal()),
                                style: TextStyle(color: userPasstime.getCurrentPasstime() == e ? Colors.white : null)
                              ),
                              Text(
                                DateFormat("M/dd/yyyy h:mm a").format(userPasstime.getPasstime(e)[1].toLocal()),
                                style: TextStyle(color: userPasstime.getCurrentPasstime() == e ? Colors.white : null)
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )).toList(),
              ),
            ),
            const Padding(padding: EdgeInsets.all(32)),
          ],
        ),
      ),
    );
  }
}
