class Friend {
  String userID = "";
  String fromUserID = "";
  String toUserID = "";
  String status = "";
  DateTime updatedAt = DateTime.now().toUtc();
  DateTime createdAt = DateTime.now().toUtc();

  Friend();

  Friend.fromJson(Map<String, dynamic> json) {
    userID = json["user_id"] ?? "";
    fromUserID = json["from_user_id"] ?? "";
    toUserID = json["to_user_id"] ?? "";
    status = json["status"] ?? "";
    updatedAt = DateTime.tryParse(json["updated_at"]) ?? DateTime.now().toUtc();
    createdAt = DateTime.tryParse(json["created_at"]) ?? DateTime.now().toUtc();
  }

  Map<String, dynamic> toJson() {
    return {
      "user_id": userID,
      "from_user_id": fromUserID,
      "to_user_id": toUserID,
      "status": status,
      "updated_at": updatedAt.toIso8601String(),
      "created_at": createdAt.toIso8601String()
    };
  }
}

/*
{
    "id": "hi-bye",
    "from_user_id": "hi",
    "to_user_id": "bye",
    "status": "ACCEPTED",
    "updated_at": "2022-05-27T05:11:20.51011Z",
    "created_at": "2022-05-27T05:11:15.605154Z"
}
 */