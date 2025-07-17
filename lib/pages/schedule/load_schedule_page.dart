// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:storke_central/models/gold_course.dart';
import 'package:storke_central/models/gold_course_time.dart';
import 'package:storke_central/models/gold_section.dart';
import 'package:storke_central/models/user_course.dart';
import 'package:storke_central/models/user_schedule_item.dart';
import 'package:storke_central/utils/aes256gcm.dart';
import 'package:storke_central/utils/alert_service.dart';
import 'package:storke_central/utils/auth_service.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/logger.dart';
import 'package:storke_central/utils/theme.dart';
import 'package:storke_central/widgets/schedule/duo_card.dart';
import 'package:url_launcher/url_launcher_string.dart';

class LoadSchedulePage extends StatefulWidget {
  const LoadSchedulePage({Key? key}) : super(key: key);

  @override
  State<LoadSchedulePage> createState() => _LoadSchedulePageState();
}

class _LoadSchedulePageState extends State<LoadSchedulePage> {

  // 0 = fetching gold schedule
  // 1 = invalid credentials / Duo MFA timed out
  // 2 = have gold courses, getting course information
  // 3 = waiting for user to confirm courses
  // 4 = generating schedule
  // 5 = saving schedule
  // 6 = done
  int state = 0;
  bool showDuo = false;
  bool duoTimedOut = false;

  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  Map<GoldSection, bool> goldSectionMap = {};

  String deviceKey = "";

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    checkDeviceKey();
  }

  Future<void> checkDeviceKey() async {
    if (prefs.containsKey("CREDENTIALS_KEY")) {
      log("[load_schedule_page] Found device key, fetching schedule");
      deviceKey = prefs.getString("CREDENTIALS_KEY")!;
      fetchGoldSchedule();
    } else {
      log("[load_schedule_page] No device key found, launching login page", LogLevel.warn);
      setState(() {
        state = 1;
      });
    }
  }

  List<String> getListFromDayString(String days) {
    List<String> daysList = [];
    if (days.contains("M")) daysList.add("Monday");
    if (days.contains("T")) daysList.add("Tuesday");
    if (days.contains("W")) daysList.add("Wednesday");
    if (days.contains("R")) daysList.add("Thursday");
    if (days.contains("F")) daysList.add("Friday");
    return daysList;
  }

  String to12HourTime(String time) {
    int hour = int.parse(time.split(":")[0]);
    int minute = int.parse(time.split(":")[1]);
    String ampm = "AM";
    if (hour == 12) ampm = "PM";
    if (hour > 12) {
      hour -= 12;
      ampm = "PM";
    }
    return "$hour:${minute.toString().padLeft(2, "0")} $ampm";
  }

  Future<void> fetchGoldSchedule() async {
    Trace trace = FirebasePerformance.instance.newTrace("fetchGoldSchedule()");
    await trace.start();
    try {
      setState(() {
        state = 0;
        duoTimedOut = false;
      });
      Timer duoPromptTimer = Timer(const Duration(milliseconds: 1400), () {
        setState(() {
          showDuo = true;
        });
      });
      await AuthService.getAuthToken();
      await httpClient.get(Uri.parse("$API_HOST/users/courses/${currentUser.id}/fetch/${selectedQuarter.id}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN", "SC-Device-Key": deviceKey}).then((value) {
        setState(() {
          showDuo = false;
        });
        if (value.statusCode == 200) {
          userCourses = jsonDecode(value.body)["data"].map<UserCourse>((json) => UserCourse.fromJson(json)).toList();
          log("[load_schedule_page] Fetched ${userCourses.length} courses from Gold");
          getCourseInformation(selectedQuarter.id);
        } else {
          log("[load_schedule_page] Fetch error: ${value.body}", LogLevel.error);
          duoPromptTimer.cancel();
          setState(() {
            state = 1;
          });
          if (jsonDecode(value.body)["data"]["message"] == "Duo MFA prompt timed out") {
            log("[load_schedule_page] Duo MFA prompt timed out!", LogLevel.warn);
            setState(() {
              duoTimedOut = true;
            });
          } else {
            AlertService.showErrorSnackbar(context, jsonDecode(value.body)["data"]["message"]);
          }
        }
      });
    } catch(err) {
      log("[load_schedule_page] ${err.toString()}", LogLevel.error);
      AlertService.showErrorDialog(context, "Error Fetching Courses", err.toString(), () {});
      setState(() {
        state = 0;
        showDuo = false;
      });
    }
    trace.stop();
  }

  Future<void> saveCredentials() async {
    Trace trace = FirebasePerformance.instance.newTrace("saveCredentials()");
    await trace.start();
    setState(() {
      state = 0;
    });
    try {
      await AuthService.getAuthToken();
      String encryptionKey = Aes256Gcm.keygen(32);
      log("[load_schedule_page] Generated encryption key: ${encryptionKey.substring(0,32)}...", LogLevel.info);

      final encryptedUsername = Aes256Gcm.encrypt(usernameController.value.text, encryptionKey);
      final encryptedPassword = Aes256Gcm.encrypt(passwordController.value.text, encryptionKey);
      await http.post(Uri.parse("$API_HOST/users/credentials/${currentUser.id}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN", "SC-Device-Key": encryptionKey}, body: jsonEncode({
        "user_id": currentUser.id,
        "username": encryptedUsername,
        "password": encryptedPassword,
      })).then((value) {
        if (value.statusCode == 200) {
          log("[load_schedule_page] Successfully set credentials!");
          prefs.setString("CREDENTIALS_KEY", encryptionKey);
          deviceKey = encryptionKey;
          fetchGoldSchedule();
        } else {
          log("[load_schedule_page] Error saving credentials: ${value.body}", LogLevel.error);
          prefs.remove("CREDENTIALS_KEY");
          setState(() {
            state = 1;
          });
          CoolAlert.show(
            context: context,
            type: CoolAlertType.error,
            title: "GOLD Login Error",
            text: "Error saving credentials: ${jsonDecode(value.body)["data"]["message"]}",
            backgroundColor: ACTIVE_ACCENT_COLOR,
            confirmBtnColor: SB_RED,
            confirmBtnText: "OK",
          );
        }
      });
    } catch(err) {
      log("[load_schedule_page] ${err.toString()}", LogLevel.error);
      AlertService.showErrorDialog(context, "Error Saving Credentials", err.toString(), () {});
      prefs.remove("CREDENTIALS_KEY");
      setState(() {
        state = 0;
      });
    }
    trace.stop();
  }

  Future<void> getCourseInformation(String quarter) async {
    Trace trace = FirebasePerformance.instance.newTrace("getCourseInformation()");
    await trace.start();
    try {
      setState(() {
        state = 2;
      });
      goldCourses.clear();
      for (UserCourse course in userCourses) {
        await httpClient.get(Uri.parse("https://api.ucsb.edu/academics/curriculums/v3/classes/$quarter/${course.courseID}"), headers: {"ucsb-api-key": UCSB_API_KEY}).then((value) {
          GoldCourse goldCourse = GoldCourse.fromJson(jsonDecode(value.body));
          goldCourse.enrollCode = course.courseID;
          setState(() {
            goldCourses.add(goldCourse);
          });
          log("[load_schedule_page] Retrieved course info for ${goldCourse.toString()} (${course.courseID})");
        });
      }
      createUserSchedule(quarter);
    } catch(err) {
      log("[load_schedule_page] ${err.toString()}", LogLevel.error);
      setState(() {
        state = 0;
      });
      AlertService.showErrorDialog(context, "Error Retrieving Course Info", err.toString(), () {});
    }
    trace.stop();
  }

  Future<void> createUserSchedule(String quarter) async {
    Trace trace = FirebasePerformance.instance.newTrace("createUserSchedule()");
    await trace.start();
    try {
      for (GoldCourse course in goldCourses) {
        log("[load_schedule_page] Generating stock schedule for ${course.toString()} (${course.enrollCode}) - ${course.units} units, ${course.instructionType}");
        for (GoldSection section in course.sections) {
          if (section.enrollCode == course.enrollCode || section.section == "0100") {
            log("[load_schedule_page] [x] ${section.enrollCode} ${section.section == "0100" ? " (Lecture)" : ""}");
            goldSectionMap[section] = true;
          } else {
            log("[load_schedule_page] [ ] ${section.enrollCode}");
            goldSectionMap[section] = false;
          }
        }
      }
    } catch (err) {
      log("[load_schedule_page] ${err.toString()}", LogLevel.error);
      setState(() {
        state = 0;
      });
      AlertService.showErrorDialog(context, "Error Creating Schedule", err.toString(), () {});
    }
    setState(() => state = 3);
    trace.stop();
  }

  Future<void> generateUserSchedule(String quarter) async {
    Trace trace = FirebasePerformance.instance.newTrace("generateUserSchedule()");
    await trace.start();
    setState(() => state = 4);
    // Generate userScheduleItems from goldCourses and goldSectionMap
    userScheduleItems.clear();
    for (GoldCourse course in goldCourses) {
      log("[load_schedule_page] Generating finalized schedule for ${course.toString()} (${course.enrollCode}) - ${course.units} units, ${course.instructionType}");
      for (GoldSection section in course.sections) {
        if (goldSectionMap[section]!) {
          for (GoldCourseTime time in section.times) {
            setState(() {
              UserScheduleItem userScheduleItem = UserScheduleItem();
              userScheduleItem.userID = currentUser.id;
              userScheduleItem.courseID = section.enrollCode;
              userScheduleItem.title = course.courseID;
              userScheduleItem.description = "${course.title}\n${course.description}";
              userScheduleItem.building = time.building;
              userScheduleItem.room = time.room;
              userScheduleItem.startTime = time.beginTime;
              userScheduleItem.endTime = time.endTime;
              userScheduleItem.days = time.days;
              userScheduleItem.quarter = quarter;
              userScheduleItems.add(userScheduleItem);
            });
            log("[load_schedule_page] + ${time.days} ${time.beginTime} - ${time.endTime} in ${time.building} ${time.room}");
          }
        }
      }
    }
    log("[load_schedule_page] Generated ${userScheduleItems.length} schedule items");
    trace.stop();
    saveUserSchedule();
  }

  Future<void> saveUserSchedule() async {
    Trace trace = FirebasePerformance.instance.newTrace("saveUserSchedule()");
    await trace.start();
    try {
      setState(() {
        state = 5;
      });

      log("[load_schedule_page] Saving schedule to database...");

      await AuthService.getAuthToken();
      await http.post(Uri.parse("$API_HOST/users/schedule/${currentUser.id}/${selectedQuarter.id}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}, body: jsonEncode(userScheduleItems));
      log("[load_schedule_page] Saved schedule to database");
      setState(() {
        state = 6;
        // Set lastScheduleFetch to force a refresh
        lastScheduleFetch = DateTime.now().subtract(const Duration(days: 7));
      });
      Future.delayed(const Duration(seconds: 1), () {
        router.pop(context);
      });
    } catch(err) {
      log("[load_schedule_page] ${err.toString()}", LogLevel.error);
      setState(() {
        state = 0;
      });
      AlertService.showErrorDialog(context, "Error Saving Schedule", err.toString(), () {});
    }
    trace.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "GOLD Sync",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  Visibility(
                    visible: state > 1,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(Icons.check_circle_rounded, color: SB_GREEN, size: 32),
                    ),
                  ),
                  Visibility(
                    visible: state == 1,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(Icons.cancel_rounded, color: SB_RED, size: 32),
                    ),
                  ),
                  Visibility(
                    visible: state == 0,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                        child: Center(child: RefreshProgressIndicator())
                    ),
                  ),
                  const Text("Fetching courses from GOLD", style: TextStyle(fontSize: 16))
                ],
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: showDuo ? 250 : 0,
                curve: Curves.easeInOut,
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Text("Waiting for Duo MFA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                        Padding(padding: EdgeInsets.all(2)),
                        DuoCard(),
                        Padding(padding: EdgeInsets.all(4)),
                        Text("You should have received a Duo notification like the one above. Please approve it to allow us to fetch your course schedule from GOLD.", style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: state == 1 && duoTimedOut,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      const Text("Duo MFA Timed Out", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                      const Padding(padding: EdgeInsets.all(4)),
                      const Text("Please approve the Duo MFA prompt so we can fetch your course schedule from GOLD.", style: TextStyle(fontSize: 16),),
                      const Padding(padding: EdgeInsets.all(4)),
                      Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsets.all(8),
                        child: CupertinoButton(
                          color: ACTIVE_ACCENT_COLOR,
                          onPressed: () {
                            fetchGoldSchedule();
                          },
                          child: const Text("Try Again", style: TextStyle(color: Colors.white),),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Visibility(
                visible: state == 1 && !duoTimedOut,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      const Text("Invalid/Missing Credentials", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                      const Padding(padding: EdgeInsets.all(4)),
                      const Text("Please login with your UCSB NetID to allow us to fetch your course schedule from GOLD.", style: TextStyle(fontSize: 16),),
                      const Padding(padding: EdgeInsets.all(8)),
                      Row(
                        children: [
                          Text("NetID", style: TextStyle(color: AdaptiveTheme.of(context).brightness == Brightness.dark ? Colors.grey : Colors.black54, fontSize: 25),),
                          const Padding(padding: EdgeInsets.all(2)),
                          Expanded(
                            child: TextField(
                              controller: usernameController,
                              textAlign: TextAlign.end,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "UCSB NetID",
                              ),
                              autocorrect: false,
                              style: const TextStyle(fontSize: 25),
                              onChanged: (input) {
                              },
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text("Password", style: TextStyle(color: AdaptiveTheme.of(context).brightness == Brightness.dark ? Colors.grey : Colors.black54, fontSize: 25),),
                          const Padding(padding: EdgeInsets.all(2)),
                          Expanded(
                            child: TextField(
                              controller: passwordController,
                              textAlign: TextAlign.end,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "Password",
                              ),
                              obscureText: true,
                              style: const TextStyle(fontSize: 25),
                              onChanged: (input) {
                              },
                            ),
                          ),
                        ],
                      ),
                      const Padding(padding: EdgeInsets.all(8)),
                      Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsets.all(8),
                        child: CupertinoButton(
                          color: ACTIVE_ACCENT_COLOR,
                          onPressed: () {
                            if (passwordController.text.isNotEmpty) saveCredentials();
                          },
                          child: const Text("Login", style: TextStyle(color: Colors.white),),
                        ),
                      ),
                      ExpansionTile(
                        title: const Row(
                          children: [
                            Icon(Icons.security),
                            Padding(padding: EdgeInsets.all(4)),
                            Expanded(child: Text("Important Security Information", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),)),
                          ],
                        ),
                        controlAffinity: ListTileControlAffinity.platform,
                        childrenPadding: const EdgeInsets.all(8),
                        children: [
                          const Text("Your login credentials are encrypted using 256-bit AES encryption with a rolling key on device, and then once again encrypted on our backend for storage. Your credentials are never transmitted in plain text, and are never stored in plaintext.", style: TextStyle(fontSize: 16),),
                          const Padding(padding: EdgeInsets.all(4)),
                          const Text("Your privacy and security are always our number one priorities, check out our security white paper below for specific information about our security practices.  You can also always take a look at our GitHub repository to see exactly how your data is handled.", style: TextStyle(fontSize: 16),),
                          CupertinoButton(child: const Text("Security White Paper"), onPressed: () => launchUrlString("https://docs.storkecentr.al/ca66d208afbc410dad5271c75ded4fdb")),
                          const Text("StorkeCentral is not an official UCSB app, use at your own risk!", style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic), textAlign: TextAlign.center,),
                          const Padding(padding: EdgeInsets.all(8)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Visibility(
                    visible: state > 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(Icons.check_circle_rounded, color: SB_GREEN, size: 32),
                    ),
                  ),
                  Visibility(
                    visible: state == 2,
                    child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Center(child: RefreshProgressIndicator())
                    ),
                  ),
                  Visibility(
                    visible: state < 2,
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(null, size: 32),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Retrieving course information from GOLD",
                      style: TextStyle(
                        fontSize: 16,
                        color: state < 2 ? Theme.of(context).textTheme.bodySmall!.color : Theme.of(context).textTheme.bodyLarge!.color
                      ),
                    )
                  )
                ],
              ),
              Visibility(
                visible: state == 3,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    goldCourses.isNotEmpty ? "Please confirm the sections we found for you." : "It looks like we couldn't find any courses for you. Please try again later.",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  )
                ),
              ),
              state == 3 ? Column(
                  children: goldCourses.map((e) => Card(
                      child: ExpansionTile(
                        title: Text("${e.title} (${e.sections.where((element) => goldSectionMap[element]!).length} sections)"),
                        children: e.sections.map((s) => Container(
                          padding: const EdgeInsets.all(8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              setState(() {
                                goldSectionMap[s] = !goldSectionMap[s]!;
                              });
                            },
                            child: Row(
                              children: [
                                Icon(goldSectionMap[s]! ? Icons.check_box : Icons.check_box_outline_blank, color: goldSectionMap[s]! ? ACTIVE_ACCENT_COLOR : Theme.of(context).textTheme.bodySmall!.color),
                                const Padding(padding: EdgeInsets.all(8)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("${s.enrollCode} - ${s.section == "0100" ? "Lecture" : "Section"} @ ${s.times.isNotEmpty ? "${s.times.first.building} ${s.times.first.room}" : "TBA"}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      // Text("${s.times.first.building} ${s.times.first.room}", style: TextStyle(color: SB_NAVY)),
                                      s.times.isNotEmpty ? Text("${getListFromDayString(s.times.first.days).join(", ")} (${to12HourTime(s.times.first.beginTime)} - ${to12HourTime(s.times.first.endTime)})", style: TextStyle(color: ACTIVE_ACCENT_COLOR)) : Container(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )).toList(),
                      )
                  )).toList()
              ) : Container(),
              Visibility(
                visible: state == 3,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.all(8),
                  child: CupertinoButton(
                    color: ACTIVE_ACCENT_COLOR,
                    onPressed: () {
                      if (goldCourses.isNotEmpty) {
                        generateUserSchedule(selectedQuarter.id);
                      } else {
                        fetchGoldSchedule();
                      }
                    },
                    child: Text(goldCourses.isNotEmpty ? "Save Schedule" : "Try Again", style: const TextStyle(color: Colors.white),),
                  ),
                ),
              ),
              Row(
                children: [
                  Visibility(
                    visible: state > 4,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(Icons.check_circle_rounded, color: SB_GREEN, size: 32),
                    ),
                  ),
                  Visibility(
                    visible: state == 4,
                    child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Center(child: RefreshProgressIndicator())
                    ),
                  ),
                  Visibility(
                    visible: state < 4,
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(null, size: 32),
                    ),
                  ),
                  Expanded(
                      child: Text(
                        "Generating schedule",
                        style: TextStyle(
                            fontSize: 16,
                            color: state < 3 ? Theme.of(context).textTheme.bodySmall!.color : Theme.of(context).textTheme.bodyLarge!.color
                        ),
                      )
                  )
                ],
              ),
              Row(
                children: [
                  Visibility(
                    visible: state > 5,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(Icons.check_circle_rounded, color: SB_GREEN, size: 32),
                    ),
                  ),
                  Visibility(
                    visible: state == 5,
                    child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Center(child: RefreshProgressIndicator())
                    ),
                  ),
                  Visibility(
                    visible: state < 5,
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(null, size: 32),
                    ),
                  ),
                  Expanded(
                      child: Text(
                        "Saving schedule",
                        style: TextStyle(
                            fontSize: 16,
                            color: state < 4 ? Theme.of(context).textTheme.bodySmall!.color : Theme.of(context).textTheme.bodyLarge!.color
                        ),
                      )
                  )
                ],
              ),
              Visibility(
                visible: state == 6,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(Icons.check_circle_rounded, color: SB_GREEN, size: 32),
                    ),
                    const Expanded(
                        child: Text("All Done!", style: TextStyle(fontSize: 16))
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
