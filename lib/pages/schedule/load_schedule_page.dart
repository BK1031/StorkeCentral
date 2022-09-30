import 'dart:convert';
import 'dart:math';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:storke_central/models/gold_course.dart';
import 'package:storke_central/models/gold_course_time.dart';
import 'package:storke_central/models/gold_section.dart';
import 'package:storke_central/models/user_course.dart';
import 'package:storke_central/models/user_schedule_item.dart';
import 'package:storke_central/utils/auth_service.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/logger.dart';
import 'package:storke_central/utils/theme.dart';
import 'package:url_launcher/url_launcher_string.dart';

class LoadSchedulePage extends StatefulWidget {
  const LoadSchedulePage({Key? key}) : super(key: key);

  @override
  State<LoadSchedulePage> createState() => _LoadSchedulePageState();
}

class _LoadSchedulePageState extends State<LoadSchedulePage> {

  // 0 = fetching gold schedule
  // 1 = invalid credentials
  // 2 = have gold courses, getting course information
  // 3 = generating schedule
  // 4 = saving schedule
  // 5 = done
  int state = 0;

  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();


  @override
  void initState() {
    super.initState();
    fetchGoldSchedule();
  }

  Future<void> fetchGoldSchedule() async {
    try {
      setState(() {
        state = 0;
      });
      await AuthService.getAuthToken();
      await http.get(Uri.parse("$API_HOST/users/courses/${currentUser.id}/fetch/${selectedQuarter.id}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}).then((value) {
        if (value.statusCode == 200) {
          userCourses = jsonDecode(value.body)["data"].map<UserCourse>((json) => UserCourse.fromJson(json)).toList();
          log("Fetched ${userCourses.length} courses from Gold");
          getCourseInformation(selectedQuarter.id);
        } else {
          log("Invalid credentials, launching login page", LogLevel.warn);
          setState(() {
            state = 1;
          });
        }
      });
    } catch(err) {
      log(err.toString(), LogLevel.error);
      setState(() {
        state = 0;
      });
    }
  }

  Future<void> saveCredentials() async {
    setState(() {
      state = 0;
    });
    try {
      await AuthService.getAuthToken();
      await http.post(Uri.parse("$API_HOST/users/credentials/${currentUser.id}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}, body: jsonEncode({
        "user_id": currentUser.id,
        "username": usernameController.text,
        "password": passwordController.text,
        "encryption_key": generateEncryptionKey()
      })).then((value) {
        if (value.statusCode == 200) {
          fetchGoldSchedule();
        } else {
          log("Error saving credentials: ${jsonDecode(value.body)["data"]}", LogLevel.error);
          passwordController.clear();
          setState(() {
            state = 1;
          });
          CoolAlert.show(
            context: context,
            type: CoolAlertType.error,
            title: "Error",
            text: "Error saving credentials: ${jsonDecode(value.body)["data"]}",
            backgroundColor: SB_NAVY,
            confirmBtnColor: SB_RED,
            confirmBtnText: "OK",
          );
        }
      });
    } catch(err) {
      log(err.toString(), LogLevel.error);
      setState(() {
        state = 0;
      });
    }
  }

  String generateEncryptionKey() {
    const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    Random _rnd = Random.secure();
    log("Generated encryption key", LogLevel.info);
    return String.fromCharCodes(Iterable.generate(32, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
  }

  Future<void> getCourseInformation(String quarter) async {
    try {
      setState(() {
        state = 2;
      });
      for (UserCourse course in userCourses) {
        await http.get(Uri.parse("https://api.ucsb.edu/academics/curriculums/v3/classes/$quarter/${course.courseID}"), headers: {"ucsb-api-key": UCSB_API_KEY}).then((value) {
          GoldCourse goldCourse = GoldCourse.fromJson(jsonDecode(value.body));
          goldCourse.enrollCode = course.courseID;
          setState(() {
            goldCourses.add(goldCourse);
          });
          log("Retrieved course info for ${goldCourse.toString()} (${course.courseID})");
        });
      }
      createUserSchedule(quarter);
    } catch(err) {
      log(err.toString(), LogLevel.error);
      setState(() {
        state = 0;
      });
    }
  }

  Future<void> createUserSchedule(String quarter) async {
    setState(() {
      state = 3;
    });
    userScheduleItems.clear();
    for (GoldCourse course in goldCourses) {
      log("Generating schedule for ${course.toString()}");
      for (GoldSection section in course.sections) {
        if (section.enrollCode == course.enrollCode || (section.instructors.isNotEmpty && section.instructors.first.role == "Teaching and in charge")) {
          log("Including section ${section.enrollCode}");
          for (GoldCourseTime time in section.times) {
            log("Adding ${time.days}");
            setState(() {
              // userScheduleItems.add(UserScheduleItem.fromJson({
              //   "user_id": currentUser.id,
              //   "course_id": course.enrollCode,
              //   "title": course.courseID,
              //   "description": course.title,
              //   "building": time.building,
              //   "room": time.room,
              //   "start_time": time.beginTime,
              //   "end_time": time.endTime,
              //   "days": time.days,
              //   "quarter": quarter,
              // }));
            });
            log("Added ${time.days} ${time.beginTime} - ${time.endTime} in ${time.building} ${time.room}");
          }
        } else {
          log("Skipping section ${section.enrollCode}");
        }
      }
    }
    log("Generated ${userScheduleItems.length} schedule items");
    saveUserSchedule();
  }

  Future<void> saveUserSchedule() async {
    try {
      setState(() {
        state = 4;
      });
      await AuthService.getAuthToken();
      await http.delete(Uri.parse("$API_HOST/users/schedule/${currentUser.id}/${selectedQuarter.id}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"});
      for (UserScheduleItem item in userScheduleItems) {
        await AuthService.getAuthToken();
        await http.post(Uri.parse("$API_HOST/users/schedule/${currentUser.id}/${selectedQuarter.id}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}, body: jsonEncode(item));
      }
      log("Saved schedule to database");
      setState(() {
        state = 5;
      });
      Future.delayed(const Duration(seconds: 2), () {
        router.pop(context);
      });
    } catch(err) {
      log(err.toString(), LogLevel.error);
      setState(() {
        state = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: SB_NAVY,
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
              Visibility(
                visible: state == 1,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text("Invalid/Missing Credentials", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
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
                              textCapitalization: TextCapitalization.words,
                              keyboardType: TextInputType.name,
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
                                hintText: "password",
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
                          color: SB_NAVY,
                          onPressed: () {
                            if (passwordController.text.isNotEmpty) saveCredentials();
                          },
                          child: const Text("Login", style: TextStyle(color: Colors.white),),
                        ),
                      ),
                      ExpansionTile(
                        title: Row(
                          children: const [
                            Icon(Icons.security),
                            Padding(padding: EdgeInsets.all(4)),
                            Text("Important Security Information", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                          ],
                        ),
                        controlAffinity: ListTileControlAffinity.platform,
                        childrenPadding: const EdgeInsets.all(8),
                        children: [
                          const Text("Your login credentials are encrypted using 256-bit AES encryption with a rolling key on device, and then once again encrypted on our backend for storage. Your credentials are never transmitted in plain text, and are never stored in plaintext.", style: TextStyle(fontSize: 16),),
                          const Padding(padding: EdgeInsets.all(4)),
                          const Text("Your privacy and security are always our number one priorities, so you can always take a look at our GitHub repository to see how your data is handled.", style: TextStyle(fontSize: 16),),
                          CupertinoButton(child: Text("GitHub Repository"), onPressed: () => launchUrlString("https://github.com/BK1031/StorkeCentral")),
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
                        color: state < 2 ? Theme.of(context).textTheme.caption!.color : Theme.of(context).textTheme.bodyText1!.color
                      ),
                    )
                  )
                ],
              ),
              Row(
                children: [
                  Visibility(
                    visible: state > 3,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(Icons.check_circle_rounded, color: SB_GREEN, size: 32),
                    ),
                  ),
                  Visibility(
                    visible: state == 3,
                    child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Center(child: RefreshProgressIndicator())
                    ),
                  ),
                  Visibility(
                    visible: state < 3,
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
                            color: state < 3 ? Theme.of(context).textTheme.caption!.color : Theme.of(context).textTheme.bodyText1!.color
                        ),
                      )
                  )
                ],
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
                        "Saving schedule",
                        style: TextStyle(
                            fontSize: 16,
                            color: state < 4 ? Theme.of(context).textTheme.caption!.color : Theme.of(context).textTheme.bodyText1!.color
                        ),
                      )
                  )
                ],
              ),
              Visibility(
                visible: state == 5,
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