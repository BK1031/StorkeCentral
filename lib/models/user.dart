import 'package:storke_central/models/privacy.dart';
import 'package:storke_central/models/role.dart';

class User {
  String id = "";
  String userName = "";
  String firstName = "";
  String lastName = "";
  String preferredName = "";
  String pronouns = "";
  String email = "";
  String phoneNumber = "";
  String profilePictureURL = "";
  String bio = "";
  String gender = "Male";
  String status = "";
  List<Role> roles = [];
  Privacy privacy = Privacy();
  DateTime updatedAt = DateTime.now().toUtc();
  DateTime createdAt = DateTime.now().toUtc();

  User();

  User.fromJson(Map<String, dynamic> json) {
    id = json["id"] ?? "";
    userName = json["user_name"] ?? "";
    firstName = json["first_name"] ?? "";
    lastName = json["last_name"] ?? "";
    preferredName = json["preferred_name"] ?? "";
    pronouns = json["pronouns"] ?? "";
    email = json["email"] ?? "";
    phoneNumber = json["phone_number"] ?? "";
    profilePictureURL = json["profile_picture_url"] ?? "";
    bio = json["bio"] ?? "";
    gender = json["gender"] ?? "";
    status = json["status"] ?? "";
    for (int i = 0; i < json["roles"].length; i++) {
      roles.add(Role.fromJson(json["roles"][i]));
    }
    privacy = Privacy.fromJson(json["privacy"]);
    updatedAt = DateTime.tryParse(json["updated_at"]) ?? DateTime.now().toUtc();
    createdAt = DateTime.tryParse(json["created_at"]) ?? DateTime.now().toUtc();
  }

  bool hasRole(String role) {
    for (int i = 0; i < roles.length; i++) {
      if (roles[i].role == role) {
        return true;
      }
    }
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "user_name": userName,
      "first_name": firstName,
      "last_name": lastName,
      "preferred_name": preferredName,
      "pronouns": pronouns,
      "email": email,
      "phone_number": phoneNumber,
      "profile_picture_url": profilePictureURL,
      "bio": bio,
      "gender": gender,
      "status": status,
      "roles": roles,
      "privacy": privacy,
      "updated_at": updatedAt.toIso8601String(),
      "created_at": createdAt.toIso8601String()
    };
  }

  @override
  String toString() {
    return "[$id] $firstName $lastName (@$userName)";
  }
}

/*
{
    "id": "bye",
    "user_name": "",
    "first_name": "Neel",
    "last_name": "Tripathi",
    "preferred_name": "NLT319",
    "pronouns": "",
    "email": "ntripathi@ucsb.edu",
    "phone_number": "(510) 945-2131",
    "profile_picture_url": "https://example.com",
    "bio": "",
    "gender": "",
    "roles": [
      {
        "user_id": "bye",
        "role": "STUDENT",
        "created_at": "2022-05-29T05:00:47.958Z"
      }
    ],
    "friends": [
      {
        "id": "hi-bye",
        "from_user_id": "hi",
        "to_user_id": "bye",
        "status": "ACCEPTED",
        "updated_at": "2022-05-27T05:11:20.51011Z",
        "created_at": "2022-05-27T05:11:15.605154Z"
      }
    ],
    "privacy": {
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
    },
    "updated_at": "2022-05-27T00:25:26.858142Z",
    "created_at": "2022-05-20T11:14:39.482805Z"
}
*/