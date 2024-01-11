import 'dart:convert';

import 'package:calendar_view/calendar_view.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:storke_central/models/quarter.dart';
import 'package:storke_central/models/user_passtime.dart';
import 'package:storke_central/models/user_schedule_item.dart';
import 'package:storke_central/pages/schedule/schedule_finals_page.dart';
import 'package:storke_central/utils/alert_service.dart';
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

  int currTab = 0;

  int color = 0;
  bool classesFound = true;
  bool loading = false;
  final PageController _pageController = PageController();
  final CalendarController _controller = CalendarController();

  bool passtimeExpanded = false;

  @override
  bool get wantKeepAlive => false;

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    getUserSchedule(selectedQuarter.id);
    getPasstime();
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      routeObserver.subscribe(this, ModalRoute.of(context)!);
    });
  }

  @override
  void didPopNext() {
    if (DateTime.now().difference(lastScheduleFetch).inMinutes > 60) {
      buildCalendar();
    }
  }

  Future<void> getUserSchedule(String quarter) async {
    if (!offlineMode) {
      try {
        // Check if userScheduleItems is empty or if queried quarter is different from last item in userScheduleItems
        log("[schedule_page] ${userScheduleItems.length} existing userScheduleItems");
        if (userScheduleItems.isEmpty || userScheduleItems.last.quarter != quarter) {
          Trace trace = FirebasePerformance.instance.newTrace("getUserSchedule()");
          await trace.start();
          if (quarter == currentQuarter.id) {
            // We only want to persist/load the current quarter
            loadOfflineSchedule();
            // getPasstime();
          } else {
            // Only show the loading indicator if we're not loading from offline storage
            setState(() => loading = true);
          }
          await AuthService.getAuthToken();
          await httpClient.get(Uri.parse("$API_HOST/users/schedule/${currentUser.id}/$quarter"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}).then((value) {
            if (jsonDecode(value.body)["data"].length == 0) {
              log("[schedule_page] No schedule items found in db for this quarter.", LogLevel.warn);
              setState(() {
                classesFound = false;
                loading = false;
              });
              clearCalendar();
              userScheduleItems.clear();
            } else {
              setState(() {
                classesFound = true;
                loading = false;
                userScheduleItems = jsonDecode(value.body)["data"].map<UserScheduleItem>((json) => UserScheduleItem.fromJson(json)).toList();
              });
              if (quarter == currentQuarter.id) {
                prefs.setStringList("USER_SCHEDULE_ITEMS", userScheduleItems.map((e) => jsonEncode(e).toString()).toList());
              }
              buildCalendar();
            }
          });
          trace.stop();
        } else {
          log("[schedule_page] Schedule items already loaded for this quarter, skipping fetch.");
          buildCalendar();
        }
      } catch(err) {
        Future.delayed(Duration.zero, () => AlertService.showErrorSnackbar(context, "Failed to get schedule!"));
        log("[schedule_page] ${err.toString()}", LogLevel.error);
        setState(() => classesFound = true);
      }
    } else {
      log("[schedule_page] Offline mode, searching cache for schedule...");
      if (quarter == currentQuarter.id) {
        loadOfflineSchedule();
      } else {
        log("[schedule_page] Can't load offline schedule for this quarter!", LogLevel.warn);
        AlertService.showErrorSnackbar(context, "Can't load offline schedule for this quarter!");
      }
    }
  }

  void loadOfflineSchedule() async {
    Trace trace = FirebasePerformance.instance.newTrace("loadOfflineSchedule()");
    await trace.start();
    if (prefs.containsKey("USER_SCHEDULE_ITEMS")) {
      setState(() {
        userScheduleItems = prefs.getStringList("USER_SCHEDULE_ITEMS")!.map((e) => UserScheduleItem.fromJson(jsonDecode(e))).toList();
      });
      log("[schedule_page] Loaded ${userScheduleItems.length} schedule items from cache.");
      buildCalendar();
      if (offlineMode) {
        Future.delayed(Duration.zero, () => AlertService.showSuccessSnackbar(context, "Loaded offline schedule!"));
      }
    }
    trace.stop();
  }

  Future<void> getPasstime() async {
    Trace trace = FirebasePerformance.instance.newTrace("getPasstime()");
    await trace.start();
    await AuthService.getAuthToken();
    await httpClient.get(Uri.parse("$API_HOST/users/passtime/${currentUser.id}/${currentPassQuarter.id}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}).then((value) async {
      if (value.statusCode == 200) {
        // Successfully got passtime
        setState(() {
          userPasstime = UserPasstime.fromJson(jsonDecode(utf8.decode(value.bodyBytes))["data"]);
        });
        if (DateTime.now().difference(userPasstime.createdAt).inDays > 7) {
          log("[schedule_page] Passtime is older than 7 days!", LogLevel.warn);
        }
      } else if (value.statusCode == 404) {
        log("[schedule_page] No passtime found for this quarter.", LogLevel.warn);
      } else {
        log("[schedule_page] Failed to get passtime: ${value.body}", LogLevel.error);
      }
    });
    trace.stop();
  }

  // Returns the next passtime start time based on the current date
  // Will always return pass 3 is current date is after pass 1 and 2
  Map<String, DateTime> getNextPasstime(UserPasstime passtime) {
    Map<String, DateTime> returnMap = {};
    if (passtime.passOneStart.isAfter(DateTime.now())) {
      returnMap["Pass 1"] = passtime.passOneStart;
    } else if (passtime.passTwoStart.isAfter(DateTime.now())) {
      returnMap["Pass 2"] = passtime.passTwoStart;
    } else {
      returnMap["Pass 3"] = passtime.passThreeStart;
    }
    return returnMap;
  }

  // Function that actually creates the class events
  // TODO: Add finals to calendar
  Future<void> buildCalendar() async {
    Trace trace = FirebasePerformance.instance.newTrace("buildCalendar()");
    await trace.start();
    log("[schedule_page] Building calendar...");
    lastScheduleFetch = DateTime.now();
    clearCalendar();
    if (userScheduleItems.isNotEmpty) {
      setState(() => classesFound = true);
    }
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
    trace.stop();
  }

  void clearCalendar() {
    setState(() {
      calendarMeetings.clear();
    });
  }

  // Helper function to get a certain day of the current week
  DateTime getNextWeekDay(int weekDay) {
    DateTime sunday = DateTime.now().withoutTime;
    // DateTime sunday = DateTime.parse("2023-04-10 11:00:00.100").withoutTime;
    if (sunday.weekday != 7) sunday = sunday.withoutTime.subtract(Duration(days: sunday.weekday));
    return sunday.add(Duration(days: weekDay));
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
    super.build(context);
    return SafeArea(
      child: Scaffold(
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 16.0, right: 8.0),
            child: Row(
              mainAxisAlignment: currTab == 0 ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Visibility(
                      visible: currTab == 0,
                      child: FloatingActionButton(
                        backgroundColor: SB_NAVY,
                        child: const Icon(Icons.refresh),
                        onPressed: () {
                          if (kIsWeb) {
                            AlertService.showWarningDialog(
                                context,
                                "Schedule Sync Unavailable",
                                "In order to keep your credentials as secure as possible, you can only sync your schedule from our mobile app.\n\nWe apologize for the inconvenience!",
                                    () {}
                            );
                          } else {
                            router.navigateTo(context, "/schedule/load", transition: TransitionType.nativeModal).then((value) => buildCalendar());
                          }
                        },
                      ),
                    ),
                    const Padding(padding: EdgeInsets.all(4)),
                    currTab == 1 ? Card(
                        color: SB_NAVY,
                        elevation: 4,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            _pageController.animateToPage(0, duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
                          },
                          child: Container(
                            padding: const EdgeInsets.only(left: 8, right: 16, top: 8, bottom: 8),
                            child: const Row(
                              children: [
                                Icon(Icons.arrow_back_ios_rounded, color: Colors.white,),
                                Padding(padding: EdgeInsets.all(4)),
                                Text("Schedule", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),),
                              ],
                            ),
                          ),
                        )
                    ) : Card(
                        color: SB_NAVY,
                        elevation: 4,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            _pageController.animateToPage(1, duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
                          },
                          child: Container(
                            padding: const EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 8),
                            child: const Row(
                              children: [
                                Text("Finals & Registration", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                Padding(padding: EdgeInsets.all(4)),
                                Icon(Icons.arrow_forward_ios_rounded, color: Colors.white)
                              ],
                            ),
                          ),
                        )
                    ),
                  ],
                ),
              ],
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (int page) {
              setState(() {
                currTab = page;
              });
            },
            children: [
              Stack(
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
                                        setState(() {
                                          selectedQuarter = availableQuarters.firstWhere((element) => element.id == newValue);
                                        });
                                        getUserSchedule(selectedQuarter.id);
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
                                    getUserSchedule(selectedQuarter.id);
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
                            // allowViewNavigation: true,
                            viewNavigationMode: ViewNavigationMode.none,
                            timeSlotViewSettings: const TimeSlotViewSettings(
                              timeIntervalHeight: 40,
                              timeFormat: "h a",
                              startHour: 7,
                              endHour: 24,
                            ),
                            selectionDecoration: const BoxDecoration(),
                            allowDragAndDrop: false,
                            dataSource: MeetingDataSource(calendarMeetings),
                            cellEndPadding: 0,
                            headerHeight: 0,
                            appointmentBuilder: (BuildContext context, CalendarAppointmentDetails details) {
                              return InkWell(
                                onTap: () {
                                  router.navigateTo(context, "/schedule/view/${details.appointments.first.eventName.toString().split("\n")[0]}", transition: TransitionType.nativeModal);
                                },
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: details.appointments.first.background.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  width: details.bounds.width,
                                  height: details.bounds.height,
                                  child: SingleChildScrollView(
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
                                  ),
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
                                    getUserSchedule(selectedQuarter.id);
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
                  Visibility(
                    visible: loading,
                    child: Center(
                      child: RefreshProgressIndicator(
                        backgroundColor: SB_NAVY,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const ScheduleFinalsPage()
            ],
          )
      ),
    );
  }
}
