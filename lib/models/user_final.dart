class UserFinal {
  String userID = "";
  String title = "";
  String name = "";
  DateTime startTime = DateTime.now().toUtc();
  DateTime endTime = DateTime.now().toUtc();
  String quarter = "";
  DateTime createdAt = DateTime.now().toUtc();

  UserFinal();

  UserFinal.fromJson(Map<String, dynamic> json) {
    userID = json["user_id"] ?? "";
    title = json["title"] ?? "";
    name = json["name"] ?? "";
    startTime = DateTime.tryParse(json["start_time"]) ?? DateTime.now().toUtc();
    endTime = DateTime.tryParse(json["end_time"]) ?? DateTime.now().toUtc();
    quarter = json["quarter"] ?? "";
    createdAt = DateTime.tryParse(json["created_at"]) ?? DateTime.now().toUtc();
  }

  Map<String, dynamic> toJson() {
    return {
      "user_id": userID,
      "title": title,
      "name": name,
      "start_time": startTime.toIso8601String(),
      "end_time": endTime.toIso8601String(),
      "quarter": quarter,
      "created_at": createdAt.toIso8601String()
    };
  }
}



/*
{
      "user_id": "LFQh1TicTLbVhX4YDPTIZ3ARxgu2",
      "title": "CMPSC153A",
      "name": "HRDW/SFTW INTERFACE",
      "start_time": "2023-12-14T12:00:00-08:00",
      "end_time": "2023-12-14T15:00:00-08:00",
      "quarter": "20234",
      "created_at": "2023-11-02T15:15:42.438683-07:00"
  }
 */