import 'dart:convert';
import 'dart:math';

import 'package:cool_alert/cool_alert.dart';
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
  }

  Future<void> fetchGoldSchedule(String quarter) async {
    try {
      setState(() {
        state = 0;
      });
      await AuthService.getAuthToken();
      await http.get(Uri.parse("$API_HOST/users/courses/${currentUser.id}/fetch/${selectedQuarter.id}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}).then((value) {
        if (value.statusCode == 200) {
          userCourses = jsonDecode(value.body)["data"].map((e) => UserCourse.fromJson(e)).toList();
          log("Fetched ${userCourses.length} courses from Gold");
          getCourseInformation(quarter);
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
          fetchGoldSchedule(selectedQuarter.id);
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
          log("Retrieved course info for ${course.toString()} (${course.courseID})");
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
    try {
      setState(() {
        state = 3;
      });
      userScheduleItems.clear();
      for (GoldCourse course in goldCourses) {
        for (GoldSection section in course.sections) {
          if (section.enrollCode == course.enrollCode || section.instructors.first.role == "Teaching and in charge") {
            for (GoldCourseTime time in section.times) {
              setState(() {
                userScheduleItems.add(UserScheduleItem.fromJson({
                  "user_id": currentUser.id,
                  "course_id": course.enrollCode,
                  "title": course.courseID,
                  "description": course.title,
                  "building": time.building,
                  "room": time.room,
                  "start_time": time.beginTime,
                  "end_time": time.endTime,
                  "days": time.days,
                  "quarter": quarter,
                }));
              });
            }
          }
        }
      }
      log("Generated ${userScheduleItems.length} schedule items");
      saveUserSchedule();
    } catch(err) {
      log(err.toString(), LogLevel.error);
      setState(() {
        state = 0;
      });
    }
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
        child: Column(
          children: [
            const Text("Please login with your UCSB NetID to allow us to fetch your course schedule from GOLD.", style: TextStyle(fontSize: 16),),
            const Padding(padding: EdgeInsets.all(8)),

          ],
        ),
      ),
    );
  }
}
