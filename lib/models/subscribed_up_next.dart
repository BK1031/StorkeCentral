import 'package:storke_central/models/up_next_schedule_item.dart';
import 'package:storke_central/models/user.dart';

class SubscribedUpNext {
  User user = User();
  String status = "";

  String userID = "";
  String subscribedUserID = "";
  List<UpNextScheduleItem> upNextItems = [];

  SubscribedUpNext();

  SubscribedUpNext.fromJson(Map<String, dynamic> json) {
    userID = json["user_id"] ?? "";
    subscribedUserID = json["subscribed_user_id"] ?? "";
    for (int i = 0; i < json["up_next"].length; i++) {
      upNextItems.add(UpNextScheduleItem.fromJson(json["up_next"][i]));
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "user_id": user.id,
      "subscribed_user_id": subscribedUserID,
      "up_next": upNextItems
    };
  }
}