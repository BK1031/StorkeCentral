// ignore_for_file: use_build_context_synchronously, no_logic_in_create_state, must_be_immutable

import 'dart:convert';
import 'dart:math';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:storke_central/models/building.dart';
import 'package:storke_central/models/user_schedule_item.dart';
import 'package:storke_central/utils/alert_service.dart';
import 'package:storke_central/utils/auth_service.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/logger.dart';
import 'package:storke_central/utils/theme.dart';

class ScheduleCoursePage extends StatefulWidget {
  String courseID = "";
  ScheduleCoursePage({Key? key, required this.courseID}) : super(key: key);

  @override
  State<ScheduleCoursePage> createState() => _ScheduleCoursePageState(courseID);
}

class _ScheduleCoursePageState extends State<ScheduleCoursePage> {

  String courseID = "";
  List<UserScheduleItem> scheduleItems = [];
  List<Building> scheduleBuildings = [];
  MapboxMapController? mapController;

  _ScheduleCoursePageState(this.courseID);

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    getScheduleItems();
  }

  Future<void> getScheduleItems() async {
    if (userScheduleItems.isEmpty) {
      await getUserSchedule(currentQuarter.id);
    }
    for (UserScheduleItem item in userScheduleItems) {
      if (item.title == courseID) {
        setState(() {
          scheduleItems.add(item);
        });
      }
    }
    log("[schedule_course_page] Found ${scheduleItems.length} schedule items for this course");
    getBuildings();
  }

  Future<void> getUserSchedule(String quarter) async {
    Trace trace = FirebasePerformance.instance.newTrace("getUserSchedule()");
    await trace.start();
    try {
        await AuthService.getAuthToken();
        await httpClient.get(Uri.parse("$API_HOST/users/schedule/${currentUser.id}/$quarter"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}).then((value) {
          if (jsonDecode(value.body)["data"].length == 0) {
            log("[schedule_page] No schedule items found in db for this quarter.", LogLevel.warn);
          } else {
            setState(() {
              userScheduleItems = jsonDecode(value.body)["data"].map<UserScheduleItem>((json) => UserScheduleItem.fromJson(json)).toList();
            });
          }
        });
    } catch(err) {
      Future.delayed(Duration.zero, () => AlertService.showErrorSnackbar(context, "Failed to get schedule!"));
      log("[schedule_page] ${err.toString()}", LogLevel.error);
    }
    trace.stop();
  }

  void getBuildings() {
    for (UserScheduleItem item in scheduleItems) {
      setState(() {
        scheduleBuildings.add(extractOne(
          query: item.building,
          choices: buildings,
          cutoff: 50,
          getter: (Building b) => b.id,
        ).choice);
      });
    }
    // Delay to allow map to load
    Future.delayed(const Duration(milliseconds: 400)).then((value) => addBuildingsToMap());
  }

  void addBuildingsToMap() {
    for (Building b in scheduleBuildings) {
      mapController?.addSymbol(
        SymbolOptions(
          geometry: LatLng(b.latitude, b.longitude),
          iconSize: kIsWeb ? 0.5 : 1.5,
          iconOffset: const Offset(0, -10),
          iconImage: getBuildingTypeIcon(b.type),
        ),
      );
    }
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng((scheduleBuildings.first.latitude + scheduleBuildings.last.latitude) / 2, (scheduleBuildings.first.longitude + scheduleBuildings.last.longitude) / 2),
          zoom: Geolocator.distanceBetween(scheduleBuildings.first.latitude, scheduleBuildings.first.longitude, scheduleBuildings.last.latitude, scheduleBuildings.last.longitude) < 400 ? 15.5 : 14,
        ),
      ),
    );
  }

  String getBuildingTypeIcon(String type) {
    switch (type) {
      case "Research Laboratory":
        return "images/markers/lab-marker.png";
      case "Trailer":
        return "images/markers/trailer-marker.png";
      case "Dining Hall":
        return "images/markers/dining-marker.png";
      case "Recreation":
        return "images/markers/recreation-marker.png";
      default:
        return "images/markers/building-marker.png";
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
    try {
      int hour = int.parse(time.split(":")[0]);
      int minute = int.parse(time.split(":")[1]);
      String ampm = "AM";
      if (hour == 12) ampm = "PM";
      if (hour > 12) {
        hour -= 12;
        ampm = "PM";
      }
      return "$hour:${minute.toString().padLeft(2, "0")} $ampm";
    } catch(err) {
      return time;
    }
  }

  void _onMapCreated(MapboxMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
              courseID,
              style: const TextStyle(fontWeight: FontWeight.bold)
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(scheduleItems.isEmpty ? "Class Not Found" : scheduleItems.first.description.split("\n")[0], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Padding(padding: EdgeInsets.all(4),),
              Text(scheduleItems.isEmpty ? "No class description found." : scheduleItems.first.description.split("\n")[1], style: const TextStyle(fontSize: 16)),
              const Padding(padding: EdgeInsets.all(4),),
              SizedBox(
                height: 250,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: MapboxMap(
                    styleString: AdaptiveTheme.of(context).brightness == Brightness.light ? MAPBOX_LIGHT_THEME : MAPBOX_DARK_THEME,
                    accessToken: kIsWeb ? MAPBOX_PUBLIC_TOKEN : MAPBOX_ACCESS_TOKEN,
                    onMapCreated: _onMapCreated,
                    attributionButtonMargins: const Point(-32, -32),
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(34.412278, -119.847787),
                      zoom: 14.0,
                    ),
                    dragEnabled: false,
                  ),
                ),
              ),
              const Padding(padding: EdgeInsets.all(4),),
              Column(
                children: scheduleItems.map((e) => Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      router.navigateTo(context, "/maps/buildings/${scheduleBuildings[scheduleItems.indexOf(e)].id}", transition: TransitionType.native);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${scheduleItems.indexOf(e) == 0 ? "Lecture" : "Section"} (${to12HourTime(e.startTime)} - ${to12HourTime(e.endTime)})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text("${scheduleBuildings[scheduleItems.indexOf(e)].name} ${e.room}", style: TextStyle(color: ACTIVE_ACCENT_COLOR)),
                                Text(getListFromDayString(e.days).join(", "), style: const TextStyle()),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
              ).toList()
              )
            ],
          ),
        )
    );
  }
}
