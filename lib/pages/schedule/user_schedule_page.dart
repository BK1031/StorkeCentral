import 'dart:convert';

import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:storke_central/models/quarter.dart';
import 'package:storke_central/models/user_schedule_item.dart';
import 'package:storke_central/utils/alert_service.dart';
import 'package:storke_central/utils/auth_service.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/logger.dart';
import 'package:storke_central/utils/syncfusion_meeting.dart';
import 'package:storke_central/utils/syncfusion_meeting_data_source.dart';
import 'package:storke_central/utils/theme.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../models/user.dart';

class UserSchedulePage extends StatefulWidget {
  String userID = "";
  UserSchedulePage({Key? key, required this.userID}) : super(key: key);

  @override
  State<UserSchedulePage> createState() => _UserSchedulePageState(userID);
}

class _UserSchedulePageState extends State<UserSchedulePage> {

  String userID = "";
  User user = User();

  List<UserScheduleItem> localUserScheduleItems = [];
  List<Meeting> localCalendarMeetings = [];

  int color = 0;
  bool classesFound = true;
  bool loading = false;
  final CalendarController _controller = CalendarController();



  _UserSchedulePageState(this.userID);

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    getUser();
    getUserSchedule(currentQuarter.id);

  }

  void getUser() async {
    await AuthService.getAuthToken();
    var response = await httpClient.get(Uri.parse("$API_HOST/users/$userID"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"});
    if (response.statusCode == 200) {
      setState(() {
        user = User.fromJson(jsonDecode(utf8.decode(response.bodyBytes))["data"]);
      });
    }
    else {
      log("[user_schedule_page] Account not found!");
    }
  }

  Future<void> getUserSchedule(String quarter) async {
    if (!offlineMode) {
      try {
        // Check if localUserScheduleItems is empty or if selectedQuarter is different from last item in localUserScheduleItems
        log("[user_schedule_page] ${localUserScheduleItems.length} existing localUserScheduleItems");
        if (localUserScheduleItems.isNotEmpty) log("Last Q: ${localUserScheduleItems.last.quarter}");
        log("[user_schedule_page] Selected Q: ${selectedQuarter.id}");
        if (localUserScheduleItems.isEmpty || localUserScheduleItems.last.quarter != selectedQuarter.id) {
          setState(() => loading = true);
          await AuthService.getAuthToken();
          await httpClient.get(Uri.parse("$API_HOST/users/schedule/$userID/${selectedQuarter.id}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}).then((value) {
            if (jsonDecode(utf8.decode(value.bodyBytes))["data"].length == 0) {
              log("[user_schedule_page] No schedule items found in db for this quarter.", LogLevel.warn);
              setState(() {
                classesFound = false;
                loading = false;
              });
              clearCalendar();
              localUserScheduleItems.clear();
            } else {
              setState(() {
                classesFound = true;
                loading = false;
                localUserScheduleItems = jsonDecode(value.body)["data"].map<UserScheduleItem>((json) => UserScheduleItem.fromJson(json)).toList();
              });
              buildCalendar();
            }
          });
        } else {
          log("[user_schedule_page] Schedule items already loaded for this quarter, skipping fetch.");
        }
      } catch(err) {
        Future.delayed(Duration.zero, () => AlertService.showErrorSnackbar(context, "Failed to get schedule!"));
        log("[user_schedule_page] ${err.toString()}", LogLevel.error);
        setState(() => classesFound = false);
      }
    } else {
      log("[user_schedule_page] Offline mode, can't get user schedule!");
    }
  }

  // Function that actually creates the class events
  // TODO: Add finals to calendar
  void buildCalendar() {
    log("[user_schedule_page] Building calendar...");
    clearCalendar();
    for (var item in localUserScheduleItems) {
      for (var day in dayStringToInt(item.days)) {
        DateTime cursor = getNextWeekDay(day);
        setState(() {
          localCalendarMeetings.add(Meeting(
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
  }

  void clearCalendar() {
    setState(() {
      localCalendarMeetings.clear();
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
    return Scaffold(
        appBar: AppBar(
          title: Text(
            "${user.firstName}'s Schedule",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      color: ACTIVE_ACCENT_COLOR,
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
                                dropdownColor: ACTIVE_ACCENT_COLOR,
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
                            dropdownColor: ACTIVE_ACCENT_COLOR,
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
                      todayHighlightColor: ACTIVE_ACCENT_COLOR,
                      selectionDecoration: BoxDecoration(),
                      allowDragAndDrop: false,
                      dataSource: MeetingDataSource(localCalendarMeetings),
                      cellEndPadding: 0,
                      headerHeight: 0,
                      appointmentBuilder: (BuildContext context, CalendarAppointmentDetails details) {
                        return InkWell(
                          onTap: () {
                            // router.navigateTo(context, "/schedule/view/${details.appointments.first.eventName.toString().split("\n")[0]}", transition: TransitionType.nativeModal);
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
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
                          const Icon(Icons.event_busy, size: 65, color: Colors.grey),
                          const Padding(padding: EdgeInsets.all(4),),
                          const Text(
                            "No Classes Found",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Padding(padding: EdgeInsets.all(4),),
                          Text(
                              "We didn't find any classes for ${user.firstName} this week! Let them know to sync their classes from GOLD!"
                          ),
                          const Padding(padding: EdgeInsets.all(8),),
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
                      color: ACTIVE_ACCENT_COLOR,
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
                            dropdownColor: ACTIVE_ACCENT_COLOR,
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
                  backgroundColor: ACTIVE_ACCENT_COLOR,
                  color: Colors.white,
                ),
              ),
            )
          ],
        )
    );
  }
}
