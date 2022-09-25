import 'package:storke_central/models/gold_section.dart';

class GoldCourse {
  String quarter = "";
  String courseID = "";
  String title = "";
  String description = "";
  String college = "";
  String deptCode = "";
  double units = 0.0;
  String gradingOption = "";
  String instructionType = "";
  List<GoldSection> sections = [];

  GoldCourse();

  GoldCourse.fromJson(Map<String, dynamic> json) {
    quarter = json["quarter"] ?? "";
    courseID = json["courseId"] ?? "";
    title = json["title"] ?? "";
    description = json["description"] ?? "";
    college = json["college"] ?? "";
    deptCode = json["deptCode"] ?? "";
    units = json["unitsFixed"] ?? 0.0;
    gradingOption = json["gradingOption"] ?? "";
    instructionType = json["instructionType"] ?? "";
    for (int i = 0; i < json["classSections"].length; i++) {
      sections.add(GoldSection.fromJson(json["classSections"][i]));
    }
  }

  @override
  String toString() {
    return "$courseID - $title";
  }
}

/*
{
	"quarter": "20224",
	"courseId": "CMPSC   130A ",
	"title": "DATA STRUCT ALGOR",
	"contactHours": 30.0,
	"description": "Data structures and applications with proofs of correctness and analysis. H ash tables, priority queues (heaps); balanced search trees. Graph traversal techniques and their applications.",
	"college": "ENGR",
	"objLevelCode": "U",
	"subjectArea": "CMPSC   ",
	"unitsFixed": 4.0,
	"unitsVariableHigh": null,
	"unitsVariableLow": null,
	"delayedSectioning": null,
	"inProgressCourse": null,
	"gradingOption": "L",
	"instructionType": "LEC",
	"onLineCourse": false,
	"deptCode": "CMPSC",
	"generalEducation": [],
	"classSections": []
}
 */