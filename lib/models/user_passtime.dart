class UserPasstime {
  String userID = "";
  String quarter = "";
  DateTime passOneStart = DateTime.now().toUtc();
  DateTime passOneEnd = DateTime.now().toUtc();
  DateTime passTwoStart = DateTime.now().toUtc();
  DateTime passTwoEnd = DateTime.now().toUtc();
  DateTime passThreeStart = DateTime.now().toUtc();
  DateTime passThreeEnd = DateTime.now().toUtc();
  DateTime createdAt = DateTime.now().toUtc();

  UserPasstime();

  UserPasstime.fromJson(Map<String, dynamic> json) {
    userID = json["user_id"] ?? "";
    quarter = json["quarter"] ?? "";
    passOneStart = DateTime.tryParse(json["pass_one_start"]) ?? DateTime.now().toUtc();
    passOneEnd = DateTime.tryParse(json["pass_one_end"]) ?? DateTime.now().toUtc();
    passTwoStart = DateTime.tryParse(json["pass_two_start"]) ?? DateTime.now().toUtc();
    passTwoEnd = DateTime.tryParse(json["pass_two_end"]) ?? DateTime.now().toUtc();
    passThreeStart = DateTime.tryParse(json["pass_three_start"]) ?? DateTime.now().toUtc();
    passThreeEnd = DateTime.tryParse(json["pass_three_end"]) ?? DateTime.now().toUtc();
    createdAt = DateTime.tryParse(json["created_at"]) ?? DateTime.now().toUtc();
  }

}

