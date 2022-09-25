class GoldCourseInstructor {
  String name = "";
  String role = "";

  GoldCourseInstructor();

  GoldCourseInstructor.fromJson(Map<String, dynamic> json) {
    name = json["instructor"] ?? "";
    role = json["functionCode"] ?? "";
  }
}