import 'dart:convert';

import 'package:calendar_view/calendar_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:storke_central/models/gold_course.dart';
import 'package:storke_central/utils/auth_service.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/logger.dart';
import 'package:storke_central/utils/theme.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({Key? key}) : super(key: key);

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {

  EventController calendarController = EventController();

  @override
  void initState() {
    super.initState();
    getUserCourses(selectedQuarter.id);
  }

  Future<void> getUserCourses(String quarter) async {
    try {
      await AuthService.getAuthToken();
      await http.get(Uri.parse("$API_HOST/users/courses/${currentUser.id}/${selectedQuarter.id}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}).then((value) {
        goldCourses.clear();
        for (var c in jsonDecode(value.body)["data"]) {
          GoldCourse course = GoldCourse.fromJson(c);
          goldCourses.add(course);
        }
        if (goldCourses.isEmpty) {
          // No courses found in db for this quarter
          // Try to fetch from GOLD API
          log("No courses found in db for this quarter. Trying to fetch from GOLD API", LogLevel.warn);
          fetchGoldSchedule(selectedQuarter.id);
        }
      });
    } catch(err) {
      log(err.toString(), LogLevel.error);
    }
  }

  Future<void> fetchGoldSchedule(String quarter) async {
    try {
      await http.get(Uri.parse("$API_HOST/users/courses/${currentUser.id}/fetch/${selectedQuarter.id}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}).then((value) {
        if (value.statusCode == 200) {
          goldCourses.clear();
          for (var c in jsonDecode(value.body)["data"]) {
            GoldCourse course = GoldCourse.fromJson(c);
            goldCourses.add(course);
          }
        } else if (value.statusCode == 404) {
          // Invalid/missing credentials
          log("Invalid credentials, launching login page", LogLevel.warn);
          router.navigateTo(context, "/schedule/credentials", transition: TransitionType.nativeModal);
        }
      });
    } catch(err) {
      log(err.toString(), LogLevel.error);
    }
  }

  Future<void> getCourseSchedule(String quarter, String id) async {
    await http.get(Uri.parse("https://api.ucsb.edu/academics/curriculums/v3/classes/$quarter/$id"), headers: {"ucsb-api-key": UCSB_API_KEY}).then((value) {
      goldCourses.add(GoldCourse.fromJson(jsonDecode(value.body)));
    });
  }

  Future<void> populateEvents() async {
    final event = CalendarEventData(
      date: DateTime.now(),
      startTime: DateTime.parse("2022-09-25 16:56:53.650485 +00:00").toLocal(),
      endTime: DateTime.parse("2022-09-25 17:56:53.650485 +00:00").toLocal(),
      title: "Test Event",
      description: "This is a test event",
      color: Colors.red,
    );
    // getCourseSchedule("07997");
    setState(() {
      calendarController.add(event);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (anonMode) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                Icon(Icons.lock_person_outlined, size: 100, color: Theme.of(context).textTheme.caption!.color,),
                const Padding(padding: EdgeInsets.all(8),),
                const Text("It looks like you are currently logged in as a guest.\n\nPlease login to view your class schedule!", style: TextStyle(fontSize: 16), textAlign: TextAlign.center,),
                const Padding(padding: EdgeInsets.all(8),),
                OutlinedButton(
                  style: ButtonStyle(
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              side: const BorderSide(color: Colors.red)
                          )
                      )
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset("images/icons/google-icon.png", height: 25, width: 25,),
                      ),
                      const Padding(padding: EdgeInsets.all(4),),
                      const Text("Sign in with Google", style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  onPressed: () {
                    FirebaseAuth.instance.signOut();
                    router.navigateTo(context, "/check-auth", transition: TransitionType.fadeIn, replace: true);
                  },
                ),
              ],
            ),
          )
        )
      );
    } else {
      return Scaffold(
          body: WeekView(
            controller: calendarController,
            showWeekends: true,
            liveTimeIndicatorSettings: HourIndicatorSettings(
              color: SB_NAVY
            ),
          )
      );
    }
  }
}
