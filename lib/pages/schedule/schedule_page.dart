import 'dart:convert';

import 'package:calendar_view/calendar_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:storke_central/models/gold_course.dart';
import 'package:storke_central/models/user_course.dart';
import 'package:storke_central/utils/auth_service.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/logger.dart';
import 'package:storke_central/utils/theme.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({Key? key}) : super(key: key);

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> with RouteAware {

  EventController calendarController = EventController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      routeObserver.subscribe(this, ModalRoute.of(context)!);
    });
    getUserCourses(selectedQuarter.id);
  }

  @override
  void didPopNext() {
    getUserCourses(selectedQuarter.id);
  }

  Future<void> getUserCourses(String quarter) async {
    try {
      await AuthService.getAuthToken();
      await http.get(Uri.parse("$API_HOST/users/courses/${currentUser.id}/${selectedQuarter.id}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}).then((value) {
        goldCourses.clear();
        if (jsonDecode(value.body)["data"].length == 0) {
          log("No courses found in db for this quarter. Trying to fetch from GOLD API", LogLevel.warn);
          fetchGoldSchedule(selectedQuarter.id);
        } else {
          for (var c in jsonDecode(value.body)["data"]) {
            UserCourse course = UserCourse.fromJson(c);
            getCourseSchedule(course.quarter, course.courseID);
          }
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
            UserCourse course = UserCourse.fromJson(c);
            getCourseSchedule(course.quarter, course.courseID);
          }
        } else {
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
      GoldCourse course = GoldCourse.fromJson(jsonDecode(value.body));
      goldCourses.add(course);
      log("Retrieved course info for ${course.toString()} ($id)");
      populateCourseEvents(course, id);
    });
  }

  // Big meaty function that actually creates the class events
  // for the whole quarter and adds them to the calendar
  // TODO: Add finals to calendar
  Future<void> populateCourseEvents(GoldCourse course, String sectionID) async {
    List<CalendarEventData> events = [];
    for (var section in course.sections) {
      if (section.enrollCode == sectionID) {
        for (var time in section.times) {
          List<int> daysOfTheWeek = dayStringToInt(time.days);
          print(daysOfTheWeek);
          for (int day in daysOfTheWeek) {
            DateTime cursor = selectedQuarter.firstDayOfClasses;
            print("First day of quarter: $cursor");
            while (getNextWeekDay(day, cursor).isBefore(selectedQuarter.lastDayOfClasses)) {
              cursor = getNextWeekDay(day, cursor);
              print("class on ${cursor.toString()}");
              events.add(CalendarEventData(
                title: course.courseID,
                description: time.room,
                date: cursor,
                startTime: cursor.add(Duration(hours: int.parse(time.beginTime.split(":")[0]), minutes: int.parse(time.beginTime.split(":")[1]))),
                endTime: cursor.add(Duration(hours: int.parse(time.endTime.split(":")[0]), minutes: int.parse(time.endTime.split(":")[1]))),
              ));
            }
          }
        }
      }
    }
    setState(() {
      calendarController.addAll(events);
    });
  }

  // Helper function to get the next occurring day of the week
  DateTime getNextWeekDay(int weekDay, DateTime from) {
    DateTime now = DateTime.now();
    if (from != null) {
      now = from;
    }
    int remainDays = weekDay - now.weekday + 7;
    return now.add(Duration(days: remainDays));
  }

  // Helper function to convert the days string that we get from GOLD to
  // a list of ints to represent the days of the week
  List<int> dayStringToInt(String dayString) {
    List<int> dayInts = [];
    for (int i = 0; i < dayString.length; i++) {
      if (dayString[i] == "M") {
        dayInts.add(1);
      } else if (dayString[i] == "T") {
        dayInts.add(2);
      } else if (dayString[i] == "W") {
        dayInts.add(3);
      } else if (dayString[i] == "R") {
        dayInts.add(4);
      } else if (dayString[i] == "F") {
        dayInts.add(5);
      } else if (dayString[i] == "S") {
        dayInts.add(6);
      } else if (dayString[i] == "U") {
        dayInts.add(7);
      }
    }
    return dayInts;
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
          floatingActionButton: FloatingActionButton(
            child: Icon(Icons.refresh),
            onPressed: () {
              fetchGoldSchedule(selectedQuarter.id);
            },
          ),
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
