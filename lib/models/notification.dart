import 'notification_data.dart';

class Notification {
  String id = "";
  String userID = "";
  String sender = "";
  String title = "";
  String body = "";
  String pictureURL = "";
  String launchURL = "";
  String route = "";
  String priority = "";
  bool push = true;
  bool read = false;
  List<NotificationData> data = [];
  DateTime createdAt = DateTime.now().toUtc();

  Notification();

  Notification.fromJson(Map<String, dynamic> json) {
    id = json["id"] ?? "";
    userID = json["user_id"] ?? "";
    sender = json["sender"] ?? "";
    title = json["title"] ?? "";
    body = json["body"] ?? "";
    pictureURL = json["picture_url"] ?? "";
    launchURL = json["launch_url"] ?? "";
    route = json["route"] ?? "";
    priority = json["priority"] ?? "";
    push = json["push"] ?? true;
    read = json["read"] ?? false;
    for (int i = 0; i < json["data"].length; i++) {
      data.add(NotificationData.fromJson(json["data"][i]));
    }
    createdAt = DateTime.tryParse(json["created_at"]) ?? DateTime.now().toUtc();
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "user_id": userID,
      "sender": sender,
      "title": title,
      "body": body,
      "picture_url": pictureURL,
      "launch_url": launchURL,
      "route": route,
      "priority": priority,
      "push": push,
      "read": read,
      "data": data,
      "created_at": createdAt.toIso8601String()
    };
  }
}

/*
{
      "id": "id4",
      "user_id": "LFQh1TicTLbVhX4YDPTIZ3ARxgu2",
      "sender": "Miranda",
      "title": "Hello World!",
      "body": "Neel Tripathi has just sent you a friend request!",
      "picture_url": "",
      "launch_url": "",
      "route": "",
      "priority": "HIGH",
      "push": true,
      "read": false,
      "data": [],
      "created_at": "2023-02-28T02:17:20.628Z"
    }
 */