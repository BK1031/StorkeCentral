class NotificationData {
  String notificationID = "";
  String key = "";
  String value = "";

  NotificationData();

  NotificationData.fromJson(Map<String, dynamic> json) {
    notificationID = json["notification_id"] ?? "";
    key = json["key"] ?? "";
    value = json["value"] ?? "";
  }

  Map<String, dynamic> toJson() {
    return {
      "notification_id": notificationID,
      "key": key,
      "value": value
    };
  }
}