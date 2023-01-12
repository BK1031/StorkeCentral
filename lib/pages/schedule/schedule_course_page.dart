import 'package:flutter/material.dart';
import 'package:storke_central/models/user_schedule_item.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/logger.dart';

class ScheduleCoursePage extends StatefulWidget {
  String courseID = "";
  ScheduleCoursePage({Key? key, required this.courseID}) : super(key: key);

  @override
  State<ScheduleCoursePage> createState() => _ScheduleCoursePageState(courseID);
}

class _ScheduleCoursePageState extends State<ScheduleCoursePage> {

  String courseID = "";
  List<UserScheduleItem> scheduleItems = [];

  _ScheduleCoursePageState(this.courseID);

  @override
  void initState() {
    super.initState();
    getScheduleItems();
  }

  void getScheduleItems() {
    for (UserScheduleItem item in userScheduleItems) {
      if (item.title == courseID) {
        setState(() {
          scheduleItems.add(item);
        });
      }
    }
    log("Found ${scheduleItems.length} schedule items for this course");
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
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Text(scheduleItems.first.description.split("\n")[0], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
              const Padding(padding: EdgeInsets.all(8),),
            ],
          ),
        )
    );
  }
}
