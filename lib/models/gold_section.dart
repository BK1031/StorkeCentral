import 'package:storke_central/models/gold_course_instructor.dart';
import 'package:storke_central/models/gold_course_time.dart';

class GoldSection {
  String enrollCode = "";
  String section = "";
  int enrolledTotal = 0;
  int maxEnroll = 0;
  List<GoldCourseTime> times = [];
  List<GoldCourseInstructor> instructors = [];

  GoldSection();

  GoldSection.fromJson(Map<String, dynamic> json) {
    enrollCode = json["enrollCode"] ?? "";
    section = json["section"] ?? "";
    enrolledTotal = json["enrolledTotal"] ?? 0;
    maxEnroll = json["maxEnroll"] ?? 0;
    for (int i = 0; i < json["timeLocations"].length; i++) {
      times.add(GoldCourseTime.fromJson(json["timeLocations"][i]));
    }
    for (int i = 0; i < json["instructors"].length; i++) {
      instructors.add(GoldCourseInstructor.fromJson(json["instructors"][i]));
    }
  }

}

/*
{
			"enrollCode": "07989",
			"section": "0100",
			"session": null,
			"classClosed": null,
			"courseCancelled": null,
			"gradingOptionCode": null,
			"enrolledTotal": 137,
			"maxEnroll": 150,
			"secondaryStatus": "R",
			"departmentApprovalRequired": false,
			"instructorApprovalRequired": false,
			"restrictionLevel": null,
			"restrictionMajor": "+CMPSC+CMPEN+CPSCI+EE",
			"restrictionMajorPass": null,
			"restrictionMinor": null,
			"restrictionMinorPass": null,
			"concurrentCourses": [],
			"timeLocations": [
				{
					"room": "1001",
					"building": "LSB",
					"roomCapacity": 159,
					"days": "M W    ",
					"beginTime": "09:30",
					"endTime": "10:45"
				}
			],
			"instructors": [
				{
					"instructor": "VIGODA E J",
					"functionCode": "Teaching and in charge"
				}
			]
		},
 */