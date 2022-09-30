class UserCourse {
  String userID = "";
  String courseID = "";
  String quarter = "";
  DateTime createdAt = DateTime.now().toUtc();

  UserCourse();

  UserCourse.fromJson(Map<String, dynamic> json) {
    userID = json["user_id"] ?? "";
    courseID = json["course_id"] ?? "";
    quarter = json["quarter"] ?? "";
    createdAt = DateTime.tryParse(json["created_at"]) ?? DateTime.now().toUtc();
  }

  Map<String, dynamic> toJson() {
    return {
      "user_id": userID,
      "course_id": courseID,
      "quarter": quarter,
      "created_at": createdAt.toIso8601String()
    };
  }
}

/*
{
      "user_id": "LFQh1TicTLbVhX4YDPTIZ3ARxgu2",
      "course_id": "07997",
      "quarter": "Fall 2022",
      "created_at": "2022-09-25T03:11:47.167218Z"
    }
 */