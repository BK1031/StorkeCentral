class Privacy {
  String userID = "";
  String email = "";
  String phoneNumber = "";
  String pronouns = "";
  String gender = "";
  String location = "";
  String pushNotifications = "";
  String pushNotificationToken = "";
  DateTime updatedAt = DateTime.now().toUtc();
  DateTime createdAt = DateTime.now().toUtc();

  Privacy();

  Privacy.fromJson(Map<String, dynamic> json) {
    userID = json["user_id"] ?? "";
    email = json["email"] ?? "";
    phoneNumber = json["phone_number"] ?? "";
    pronouns = json["pronouns"] ?? "";
    gender = json["gender"] ?? "";
    location = json["location"] ?? "";
    pushNotifications = json["push_notifications"] ?? "";
    pushNotificationToken = json["push_notification_token"] ?? "";
    updatedAt = DateTime.tryParse(json["updated_at"]) ?? DateTime.now().toUtc();
    createdAt = DateTime.tryParse(json["created_at"]) ?? DateTime.now().toUtc();
  }

  Map<String, dynamic> toJson() {
    return {
      "user_id": userID,
      "email": email,
      "phone_number": phoneNumber,
      "pronouns": pronouns,
      "gender": gender,
      "location": location,
      "push_notifications": pushNotifications,
      "push_notification_token": pushNotificationToken,
      "updated_at": updatedAt.toString(),
      "created_at": createdAt.toString()
    };
  }
}

/*
{
    "user_id": "bye",
    "email": "PUBLIC",
    "phone_number": "PRIVATE",
    "pronouns": "",
    "gender": "",
    "location": "DISABLED",
    "push_notifications": "ENABLED",
    "push_notification_token": "FCM-TOKEN-1239",
    "updated_at": "2022-05-27T00:25:26.862199Z",
    "created_at": "2022-05-27T00:16:17.483235Z"
}
 */