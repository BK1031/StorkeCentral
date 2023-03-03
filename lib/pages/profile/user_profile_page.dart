import 'dart:convert';

import 'package:extended_image/extended_image.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:storke_central/models/user.dart';
import 'package:storke_central/utils/auth_service.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/logger.dart';
import 'package:storke_central/utils/theme.dart';

class UserProfilePage extends StatefulWidget {
  String userID = "";
  UserProfilePage({Key? key, required this.userID}) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState(userID);
}

class _UserProfilePageState extends State<UserProfilePage> {

  String userID = "";
  User user = User();

  bool loading = false;

  _UserProfilePageState(this.userID);

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    getUser();
    getFriendshipStatus();
  }

  void getUser() async {
    await AuthService.getAuthToken();
    var response = await http.get(Uri.parse("$API_HOST/users/$userID"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"});
    if (response.statusCode == 200) {
      setState(() {
        user = User.fromJson(jsonDecode(response.body)["data"]);
      });
      log("====== USER PROFILE INFO ======");
      log("FIRST NAME: ${user.firstName}");
      log("LAST NAME: ${user.lastName}");
      log("EMAIL: ${user.email}");
      log("====== =============== ======");
    }
    else {
      log("Account not found!");
    }
  }
  
  String getFriendshipStatus() {
    String status = "NULL";
    if (friends.any((element) => element.id.contains(userID))) {
      status = "FRIEND";
    } else if (requests.any((element) => element.toUserID == userID)) {
      status = "REQUESTED";
    } else if (requests.any((element) => element.fromUserID == userID)) {
      status = "PENDING";
    }
    log("FRIENDSHIP STATUS: $status");
    return status;
  }

  bool showPronouns() {
    log("PRONOUNS: ${user.privacy.pronouns}");
    if (user.pronouns != "") {
      if (user.privacy.pronouns == "PUBLIC") {
        return true;
      } else if (user.privacy.pronouns == "FRIENDS" && getFriendshipStatus() == "FRIEND") {
        return true;
      }
    }
    return false;
  }

  bool showEmail() {
    log("EMAIL: ${user.privacy.email}");
    if (user.email != "") {
      if (user.privacy.email == "PUBLIC") {
        return true;
      } else if (user.privacy.email == "FRIENDS" && getFriendshipStatus() == "FRIEND") {
        return true;
      }
    }
    return false;
  }

  bool showPhoneNumber() {
    log("PHONE NUMBER: ${user.privacy.phoneNumber}");
    if (user.phoneNumber != "") {
      if (user.privacy.phoneNumber == "PUBLIC") {
        return true;
      } else if (user.privacy.phoneNumber == "FRIENDS" && getFriendshipStatus() == "FRIEND") {
        return true;
      }
    }
    return false;
  }

  void getFriendsForUser(String userID) {
    
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: SB_NAVY,
        title: Text(
          "@${user.userName}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: user.userName == "" ? Padding(
            padding: const EdgeInsets.all(8),
            child: Center(
                child: RefreshProgressIndicator(
                    color: Colors.white,
                    backgroundColor: SB_NAVY
                )
            )
        ) : Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: ExtendedImage.network(
                user.profilePictureURL,
                height: 125,
                width: 125,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.all(Radius.circular(125)),
                shape: BoxShape.rectangle,
              ),
            ),
            Text(
              "${user.firstName} ${user.lastName}",
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const Padding(padding: EdgeInsets.all(2)),
            Text(
              showPronouns() ? "@${user.userName}  •  ${user.pronouns}" : "@${user.userName}",
              style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodySmall!.color),
            ),
            const Padding(padding: EdgeInsets.all(4)),
            Text(
              user.bio != "" ? user.bio : "No bio",
              style: const TextStyle(fontSize: 18),
            ),
            const Padding(padding: EdgeInsets.all(8)),
            Container(
              padding: const EdgeInsets.only(left: 8, top: 8, right: 8),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      color: Theme.of(context).cardColor,
                      onPressed: () {
                        router.navigateTo(context, "/profile/edit", transition: TransitionType.nativeModal).then((value) => setState(() {}));
                      },
                      child: Text("Edit Profile", style: TextStyle(color: Theme.of(context).textTheme.labelLarge!.color)),
                    ),
                  ),
                  const Padding(padding: EdgeInsets.all(4)),
                  Expanded(
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      color: Theme.of(context).cardColor,
                      onPressed: () {
                        router.navigateTo(context, "/settings", transition: TransitionType.native);
                      },
                      child: Text("Settings", style: TextStyle(color: Theme.of(context).textTheme.labelLarge!.color),),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
