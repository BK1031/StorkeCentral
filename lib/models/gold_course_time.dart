class GoldCourseTime {
  String room = "";
  String building = "";
  int roomCapacity = 0;
  String days = "";
  String beginTime = "";
  String endTime = "";

  GoldCourseTime();

  GoldCourseTime.fromJson(Map<String, dynamic> json) {
    room = json["room"] ?? "";
    building = json["building"] ?? "";
    roomCapacity = json["roomCapacity"] ?? 0;
    days = json["days"] ?? "";
    beginTime = json["beginTime"] ?? "0:00";
    endTime = json["endTime"] ?? "0:00";
  }
}