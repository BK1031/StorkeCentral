import 'dart:convert';

import 'package:calendar_view/calendar_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:storke_central/models/gold_course.dart';
import 'package:storke_central/models/user_schedule_item.dart';
import 'package:storke_central/utils/auth_service.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/logger.dart';
import 'package:storke_central/utils/theme.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({Key? key}) : super(key: key);

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> with RouteAware, AutomaticKeepAliveClientMixin {

  EventController calendarController = EventController();
  int color = 0;
  bool classesFound = true;
  final _weekCalendarKey = GlobalKey();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    getUserSchedule(selectedQuarter.id);
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      routeObserver.subscribe(this, ModalRoute.of(context)!);
    });
  }

  @override
  void didPopNext() {
    getUserSchedule(selectedQuarter.id);
  }

  Future<void> getUserSchedule(String quarter) async {
    if (!offlineMode) {
      if (userScheduleItems.isEmpty || DateTime.now().difference(lastScheduleFetch).inMinutes > 180) {
        try {
          await AuthService.getAuthToken();
          await http.get(Uri.parse("$API_HOST/users/schedule/${currentUser.id}/${selectedQuarter.id}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}).then((value) {
            if (jsonDecode(value.body)["data"].length == 0) {
              log("No schedule items found in db for this quarter.", LogLevel.warn);
              setState(() {
                classesFound = false;
              });
            } else {
              setState(() {
                classesFound = true;
                userScheduleItems = jsonDecode(value.body)["data"].map<UserScheduleItem>((json) => UserScheduleItem.fromJson(json)).toList();
              });
              lastScheduleFetch = DateTime.now();
              buildCalendar();
            }
          });
        } catch(err) {
          // TODO: Show error snackbar
          log(err.toString(), LogLevel.error);
        }
      } else {
        log("Using cached schedule, last fetch was ${DateTime.now().difference(lastHeadlineArticleFetch).inMinutes} minutes ago (minimum 180 minutes)");
      }
    } else {
      log("Offline mode, searching cache for schedule...");
    }
  }

  // Adds a placeholder 1 minute event to the calendar so we can scroll the
  // main course times into view
  void scrollToView() {
    WeekViewState weekViewState = _weekCalendarKey.currentState as WeekViewState;
    for (var element in calendarController.events) {
      if (element.title == "Start") {
        calendarController.remove(element);
      }
    }
    CalendarEventData startEvent = CalendarEventData(
      date: getNextWeekDay(1),
      title: "Start",
      description: "Start",
      startTime: getNextWeekDay(1).add(const Duration(hours: 12)),
      endTime: getNextWeekDay(1).add(const Duration(hours: 12, minutes: 1)),
      color: Colors.greenAccent,
    );
    calendarController.add(startEvent);
    weekViewState.animateToEvent(
      startEvent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Big meaty function that actually creates the class events
  // TODO: Add finals to calendar
  void buildCalendar() {
    for (var event in calendarController.events) {
      calendarController.remove(event);
    }
    for (var item in userScheduleItems) {
      for (var day in dayStringToInt(item.days)) {
        DateTime cursor = getNextWeekDay(day);
        calendarController.add(CalendarEventData(
          title: item.title,
          description: "${item.building} ${item.room}",
          date: cursor,
          color: SB_COLORS[color],
          startTime: cursor.add(Duration(hours: int.parse(item.startTime.split(":")[0]), minutes: int.parse(item.startTime.split(":")[1]))),
          endTime: cursor.add(Duration(hours: int.parse(item.endTime.split(":")[0]), minutes: int.parse(item.endTime.split(":")[1]))),
        ));
      }
      if (color == SB_COLORS.length - 1) {
        color = 0;
      } else {
        color++;
      }
    }
    scrollToView();
  }

  Future<void> populateCourseEvents(GoldCourse course, String sectionID) async {
    for (var element in calendarController.events) {
      if (element.title == course.courseID) {
        calendarController.remove(element);
      }
    }
    for (var section in course.sections) {
      if (section.enrollCode == sectionID || section.instructors.first.role == "Teaching and in charge") {
        for (var time in section.times) {
          List<int> daysOfTheWeek = dayStringToInt(time.days);
          for (int day in daysOfTheWeek) {
            DateTime cursor = getNextWeekDay(day);
            calendarController.add(CalendarEventData(
              title: course.courseID,
              description: "${time.building} ${time.room}",
              date: cursor,
              color: SB_COLORS[color],
              startTime: cursor.add(Duration(hours: int.parse(time.beginTime.split(":")[0]), minutes: int.parse(time.beginTime.split(":")[1]))),
              endTime: cursor.add(Duration(hours: int.parse(time.endTime.split(":")[0]), minutes: int.parse(time.endTime.split(":")[1]))),
            ));
          }
        }
      }
    }
    if (color == SB_COLORS.length - 1) {
      color = 0;
    } else {
      color++;
    }
    if (mounted) setState(() {});
  }

  // Helper function to get a certain day of the current week
  DateTime getNextWeekDay(int weekDay) {
    DateTime monday = DateTime.now().withoutTime.subtract(Duration(days: DateTime.now().weekday - 1));
    return monday.add(Duration(days: weekDay - 1));
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
            child: const Icon(Icons.refresh),
            onPressed: () {
              router.navigateTo(context, "/schedule/load", transition: TransitionType.nativeModal);
            },
          ),
          body: Stack(
            children: [
              WeekView(
                key: _weekCalendarKey,
                controller: calendarController,
                backgroundColor: Theme.of(context).backgroundColor,
                minDay: DateTime.now().withoutTime.subtract(Duration(days: DateTime.now().weekday - 1)),
                maxDay: DateTime.now().withoutTime.add(Duration(days: 7 - DateTime.now().weekday)),
                showWeekends: false,
                liveTimeIndicatorSettings: HourIndicatorSettings(
                  color: SB_NAVY,
                ),
                eventTileBuilder: (DateTime date, List<CalendarEventData> events, Rect boundary, DateTime startDuration, DateTime endDuration) {
                  if (events.isNotEmpty && events[0].title != "Start") {
                    return Card(
                      color: events[0].color.withOpacity(0.25),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.fitWidth,
                            child: Text(
                              events[0].title,
                              style: TextStyle(color: events[0].color, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                          FittedBox(
                            child: Text(
                              events[0].description,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Container();
                  }
                },
                weekPageHeaderBuilder: (weekStart, weekEnd) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      color: SB_NAVY,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        width: MediaQuery.of(context).size.width,
                        child: Text(
                          "Week ${selectedQuarter.getWeek(weekStart.add(const Duration(days: 1)))}",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: !classesFound,
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Card(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        width: 250,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event_busy, size: 65, color: Theme.of(context).textTheme.caption!.color,),
                            const Padding(padding: EdgeInsets.all(4),),
                            const Text(
                              "No Classes Found",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const Padding(padding: EdgeInsets.all(4),),
                            const Text(
                              "We didn't find any classes for you this week! Would you like us to try and sync your classes from GOLD?"
                            ),
                            const Padding(padding: EdgeInsets.all(8),),
                            SizedBox(
                              width: MediaQuery.of(context).size.width,
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                color: SB_NAVY,
                                onPressed: () {
                                  router.navigateTo(context, "/schedule/load", transition: TransitionType.nativeModal);
                                },
                                child: const Text("Sync Classes", style: TextStyle(color: Colors.white),),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ],
          )
      );
    }
  }
}
