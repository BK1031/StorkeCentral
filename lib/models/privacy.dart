class Privacy {
  String userID = "";
  String email = "PUBLIC";
  String phoneNumber = "FRIENDS";
  String pronouns = "PRIVATE";
  String gender = "PRIVATE";
  String location = "DISABLED";
  String status = "PUBLIC";
  String pushNotifications = "DISABLED";
  String pushNotificationToken = "";
  String scheduleReminders = "";
  DateTime updatedAt = DateTime.now().toUtc();
  DateTime createdAt = DateTime.now().toUtc();

  Privacy();

  Privacy.fromJson(Map<String, dynamic> json) {
    userID = json["user_id"] ?? "";
    email = json["email"] ?? "PUBLIC";
    phoneNumber = json["phone_number"] ?? "FRIENDS";
    pronouns = json["pronouns"] ?? "PRIVATE";
    gender = json["gender"] ?? "PRIVATE";
    location = json["location"] ?? "DISABLED";
    status = json["status"] ?? "PUBLIC";
    pushNotifications = json["push_notifications"] ?? "DISABLED";
    pushNotificationToken = json["push_notification_token"] ?? "";
    scheduleReminders = json["schedule_reminders"] ?? "";
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
      "status": status,
      "push_notifications": pushNotifications,
      "push_notification_token": pushNotificationToken,
      "schedule_reminders": scheduleReminders,
      "updated_at": updatedAt.toIso8601String(),
      "created_at": createdAt.toIso8601String()
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