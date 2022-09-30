class UserScheduleItem {
  String userID = "";
  String courseID = "";
  String title = "";
  String description = "";
  String building = "";
  String room = "";
  String startTime = "";
  String endTime = "";
  String days = "";
  String quarter = "";
  DateTime createdAt = DateTime.now().toUtc();

  UserScheduleItem();

  UserScheduleItem.fromJson(Map<String, dynamic> json) {
    userID = json["user_id"] ?? "";
    courseID = json["course_id"] ?? "";
    title = json["title"] ?? "";
    description = json["description"] ?? "";
    building = json["building"] ?? "";
    room = json["room"] ?? "";
    startTime = json["start_time"] ?? "";
    endTime = json["end_time"] ?? "";
    days = json["days"] ?? "";
    quarter = json["quarter"] ?? "";
    createdAt = DateTime.tryParse(json["created_at"]) ?? DateTime.now().toUtc();
  }

  Map<String, dynamic> toJson() {
    return {
      "user_id": userID,
      "course_id": courseID,
      "title": title,
      "description": description,
      "building": building,
      "room": room,
      "start_time": startTime,
      "end_time": endTime,
      "days": days,
      "quarter": quarter,
      "created_at": createdAt.toIso8601String()
    };
  }
}

/*
{
      "user_id": "LFQh1TicTLbVhX4YDPTIZ3ARxgu2",
      "course_id": "test",
      "title": "Test Class",
      "description": "test description",
      "building": "BLDN",
      "room": "1001",
      "start_time": "13:00",
      "end_time": "14:30",
      "days": "MWF",
      "quarter": "20224",
      "created_at": "2022-09-29T22:35:43.767934Z"
    }
 */