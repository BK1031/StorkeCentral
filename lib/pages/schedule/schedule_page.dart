import 'dart:convert';

import 'package:calendar_view/calendar_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:storke_central/models/quarter.dart';
import 'package:storke_central/models/user_schedule_item.dart';
import 'package:storke_central/utils/auth_service.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/logger.dart';
import 'package:storke_central/utils/syncfusion_meeting.dart';
import 'package:storke_central/utils/syncfusion_meeting_data_source.dart';
import 'package:storke_central/utils/theme.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({Key? key}) : super(key: key);

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> with RouteAware, AutomaticKeepAliveClientMixin {

  int color = 0;
  bool classesFound = true;
  final CalendarController _controller = CalendarController();

  @override
  bool get wantKeepAlive => false;

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
      try {
        await AuthService.getAuthToken();
        await http.get(Uri.parse("$API_HOST/users/schedule/${currentUser.id}/${selectedQuarter.id}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}).then((value) {
          if (jsonDecode(value.body)["data"].length == 0) {
            log("No schedule items found in db for this quarter.", LogLevel.warn);
            setState(() {
              classesFound = false;
            });
            clearCalendar();
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
      log("Offline mode, searching cache for schedule...");
    }
  }

  // Adds a placeholder 1 minute event to the calendar so we can scroll the
  // main course times into view
  void scrollToView() {
  }

  // Big meaty function that actually creates the class events
  // TODO: Add finals to calendar
  void buildCalendar() {
    clearCalendar();
    for (var item in userScheduleItems) {
      for (var day in dayStringToInt(item.days)) {
        DateTime cursor = getNextWeekDay(day);
        setState(() {
          calendarMeetings.add(Meeting(
              "${item.title}\n${item.building} ${item.room}",
              cursor.add(Duration(hours: int.parse(item.startTime.split(":")[0]), minutes: int.parse(item.startTime.split(":")[1]))),
              cursor.add(Duration(hours: int.parse(item.endTime.split(":")[0]), minutes: int.parse(item.endTime.split(":")[1]))),
              SB_COLORS[color],
              false
          ));
        });
      }
      if (color == SB_COLORS.length - 1) {
        color = 0;
      } else {
        color++;
      }
    }
    scrollToView();
  }

  void clearCalendar() {
    setState(() {
      calendarMeetings.clear();
    });
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
              Column(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        color: SB_NAVY,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          width: MediaQuery.of(context).size.width,
                          child: selectedQuarter.getWeek(getNextWeekDay(1)) > 0 ? Row(
                            children: [
                              Expanded(
                                child: Text(
                                  selectedQuarter.getWeek(getNextWeekDay(1)) <= 10 ? "Week ${selectedQuarter.getWeek(getNextWeekDay(1))}" : "Finals Week",
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const Icon(Icons.circle, color: Colors.white, size: 8,),
                              const Padding(padding: EdgeInsets.all(8),),
                              Expanded(
                                child: DropdownButton<String>(
                                  value: selectedQuarter.id,
                                  onChanged: (String? newValue) {
                                    print("New quarter selected: $newValue");
                                    print(selectedQuarter.getWeek(getNextWeekDay(1)));
                                    setState(() {
                                      selectedQuarter = availableQuarters.firstWhere((element) => element.id == newValue);
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  underline: Container(),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  dropdownColor: SB_NAVY,
                                  isDense: true,
                                  alignment: Alignment.centerRight,
                                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white,),
                                  items: availableQuarters.map<DropdownMenuItem<String>>((Quarter quarter) {
                                    return DropdownMenuItem<String>(
                                        value: quarter.id,
                                        child: Text(quarter.name)
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ) : Center(
                            child: DropdownButton<String>(
                              value: selectedQuarter.id,
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedQuarter = availableQuarters.firstWhere((element) => element.id == newValue);
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              underline: Container(),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              dropdownColor: SB_NAVY,
                              isDense: true,
                              alignment: Alignment.center,
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.white,),
                              items: availableQuarters.map<DropdownMenuItem<String>>((Quarter quarter) {
                                return DropdownMenuItem<String>(
                                  value: quarter.id,
                                  child: Text(quarter.name),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SfCalendar(
                      controller: _controller,
                      // firstDayOfWeek: 1,
                      view: CalendarView.week,
                      timeSlotViewSettings: const TimeSlotViewSettings(
                        timeIntervalHeight: 40,
                        // timeInterval: Duration(minutes: 30),
                        timeFormat: "h a",
                        startHour: 7,
                        endHour: 24,
                      ),
                      allowDragAndDrop: false,
                      dataSource: MeetingDataSource(calendarMeetings),
                      cellEndPadding: 0,
                      headerHeight: 0,
                      appointmentBuilder: (BuildContext context, CalendarAppointmentDetails details) {
                          return Container(
                            decoration: BoxDecoration(
                              color: details.appointments.first.background.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            width: details.bounds.width,
                            height: details.bounds.height,
                            child: Column(
                              children: [
                                FittedBox(
                                  fit: BoxFit.fitWidth,
                                  child: Text(details.appointments.first.eventName.toString().split("\n")[0], style: const TextStyle(color: Colors.white))
                                ),
                                FittedBox(
                                    fit: BoxFit.fitWidth,
                                    child: Text(details.appointments.first.eventName.toString().split("\n")[1], style: const TextStyle(color: Colors.white))
                                ),
                              ],
                            ),
                          );
                      }
                    ),
                  ),
                ],
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
              ),
              Visibility(
                visible: !classesFound,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Card(
                        color: SB_NAVY,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          width: MediaQuery.of(context).size.width,
                          child: Center(
                            child: DropdownButton<String>(
                              value: selectedQuarter.id,
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedQuarter = availableQuarters.firstWhere((element) => element.id == newValue);
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              underline: Container(),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              dropdownColor: SB_NAVY,
                              isDense: true,
                              alignment: Alignment.center,
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.white,),
                              items: availableQuarters.map<DropdownMenuItem<String>>((Quarter quarter) {
                                return DropdownMenuItem<String>(
                                  value: quarter.id,
                                  child: Text(quarter.name),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
      );
    }
  }
}
