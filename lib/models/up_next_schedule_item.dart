import 'package:storke_central/models/user.dart';

class UpNextScheduleItem {
  User user = User();
  String status = "";

  String courseID = "";
  String title = "";
  DateTime startTime = DateTime.now().toUtc();
  DateTime endTime = DateTime.now().toUtc();
  String quarter = "";
  DateTime createdAt = DateTime.now().toUtc();

  UpNextScheduleItem();

  UpNextScheduleItem.fromJson(Map<String, dynamic> json) {
    user.id = json["user_id"] ?? "";
    courseID = json["course_id"] ?? "";
    title = json["title"] ?? "";
    startTime = DateTime.tryParse(json["start_time"]) ?? DateTime.now().toUtc();
    endTime = DateTime.tryParse(json["end_time"]) ?? DateTime.now().toUtc();
    quarter = json["quarter"] ?? "";
    createdAt = DateTime.tryParse(json["created_at"]) ?? DateTime.now().toUtc();
  }

  Map<String, dynamic> toJson() {
    return {
      "user_id": user.id,
      "course_id": courseID,
      "title": title,
      "start_time": startTime.toIso8601String(),
      "end_time": endTime.toIso8601String(),
      "quarter": quarter,
      "created_at": createdAt.toIso8601String()
    };
  }
}