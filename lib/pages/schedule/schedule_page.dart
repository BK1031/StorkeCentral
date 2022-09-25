import 'package:calendar_view/calendar_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:storke_central/utils/config.dart';
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
    populateEvents();
  }

  Future<void> getCourseSchedule(String id) async {
    await http.get("https://api.ucsb.edu/academics/curriculums/v1/classes/${id}/schedule", headers: {
      "ucsb-api-key": UCSB_API_KEY
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
