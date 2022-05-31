class Role {
  String userID = "";
  String role = "";
  DateTime createdAt = DateTime.now().toUtc();

  Role();

  Role.fromJson(Map<String, dynamic> json) {
    userID = json["user_id"] ?? "";
    role = json["role"] ?? "";
    createdAt = DateTime.tryParse(json["createdAt"]) ?? DateTime.now().toUtc();
  }

  Map<String, dynamic> toJson() {
    return {
      "user_id": userID,
      "role": role,
      "createdAt": createdAt.toIso8601String()
    };
  }
}

/*
{
    "user_id": "bye",
    "role": "STUDENT",
    "created_at": "2022-05-29T05:00:47.958Z"
}
 */