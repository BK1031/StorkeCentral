import 'package:storke_central/models/user.dart';

class Friend {
  String id = "";
  String fromUserID = "";
  String toUserID = "";
  String status = "";
  DateTime updatedAt = DateTime.now().toUtc();
  DateTime createdAt = DateTime.now().toUtc();

  Friend();

  Friend.fromJson(Map<String, dynamic> json) {
    id = json["id"] ?? "";
    fromUserID = json["from_user_id"] ?? "";
    toUserID = json["to_user_id"] ?? "";
    status = json["status"] ?? "";
    updatedAt = DateTime.tryParse(json["updated_at"]) ?? DateTime.now().toUtc();
    createdAt = DateTime.tryParse(json["created_at"]) ?? DateTime.now().toUtc();
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "from_user_id": fromUserID,
      "to_user_id": toUserID,
      "status": status,
      "updated_at": updatedAt.toIso8601String(),
      "created_at": createdAt.toIso8601String()
    };
  }

  // Searches through [friendList] for matching friend object with given [user]
  // Returns the friendship status with the [currentUser] using this list
  static String getFriendshipFromList(User user, List<Friend> friendList) {
    for (int i = 0; i < friendList.length; i++) {
      if (friendList[i].id.contains(user.id)) return friendList[i].status;
    }
    return "NULL";
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