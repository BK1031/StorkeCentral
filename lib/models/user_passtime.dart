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

  List<DateTime> getPasstime(int i) {
    switch (i) {
      case 1:
        return [passOneStart, passOneEnd];
      case 2:
        return [passTwoStart, passTwoEnd];
      case 3:
        return [passThreeStart, passThreeEnd];
      default:
        return [passOneStart, passOneEnd];
    }
  }

  int getCurrentPasstime() {
    DateTime now = DateTime.now().toUtc();
    if (now.isBefore(passOneStart)) {
      return 0;
    } else if (now.isBefore(passOneEnd)) {
      return 1;
    } else if (now.isBefore(passTwoStart)) {
      return 0;
    } else if (now.isBefore(passTwoEnd)) {
      return 2;
    } else if (now.isBefore(passThreeStart)) {
      return 0;
    } else if (now.isBefore(passThreeEnd)) {
      return 3;
    } else {
      return 0;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "user_id": userID,
      "quarter": quarter,
      "pass_one_start": passOneStart.toIso8601String(),
      "pass_one_end": passOneEnd.toIso8601String(),
      "pass_two_start": passTwoStart.toIso8601String(),
      "pass_two_end": passTwoEnd.toIso8601String(),
      "pass_three_start": passThreeStart.toIso8601String(),
      "pass_three_end": passThreeEnd.toIso8601String(),
      "created_at": createdAt.toIso8601String()
    };
  }

}

