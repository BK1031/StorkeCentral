// ignore_for_file: use_build_context_synchronously, duplicate_ignore

import 'dart:convert';

import 'package:extended_image/extended_image.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:storke_central/models/friend.dart';
import 'package:storke_central/models/user.dart';
import 'package:storke_central/utils/alert_service.dart';
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
    updateUserFriendsList().then((value) => getFriendshipStatus());
  }

  void getUser() async {
    Trace trace = FirebasePerformance.instance.newTrace("getUser()");
    await trace.start();
    // Check if user is already stored in friends list
    if (friends.any((element) => element.id.contains(userID))) {
      setState(() {
        user = friends.firstWhere((element) => element.id.contains(userID)).user;
      });
    }
    await AuthService.getAuthToken();
    var response = await http.get(Uri.parse("$API_HOST/users/$userID"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"});
    if (response.statusCode == 200) {
      setState(() {
        user = User.fromJson(jsonDecode(utf8.decode(response.bodyBytes))["data"]);
      });
      log("[user_profile_page] ====== USER PROFILE INFO ======");
      log("[user_profile_page] FIRST NAME: ${user.firstName}");
      log("[user_profile_page] LAST NAME: ${user.lastName}");
      log("[user_profile_page] EMAIL: ${user.email}");
      log("[user_profile_page] ====== =============== ======");
    }
    else {
      log("[user_profile_page] Account not found!");
    }
    trace.stop();
  }
  
  String getFriendshipStatus() {
    String status = "NULL";
    if (userID == currentUser.id) {
      status = "SELF";
    } else if (friends.any((element) => element.id.contains(userID))) {
      status = "FRIEND";
    } else if (requests.any((element) => element.toUserID == userID)) {
      status = "REQUESTED";
    } else if (requests.any((element) => element.fromUserID == userID)) {
      status = "PENDING";
    }
    log("[user_profile_page] FRIENDSHIP STATUS: $status");
    return status;
  }

  bool showPronouns() {
    log("[user_profile_page] PRONOUNS: ${user.privacy.pronouns}");
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
    log("[user_profile_page] EMAIL: ${user.privacy.email}");
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
    log("[user_profile_page] PHONE NUMBER: ${user.privacy.phoneNumber}");
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

  Future<void> acceptFriend(User user) async {
    Trace trace = FirebasePerformance.instance.newTrace("acceptFriend()");
    await trace.start();
    Friend friend = requests.where((element) => element.fromUserID == user.id).first;
    friend.status = "ACCEPTED";
    setState(() => loading = true);
    await AuthService.getAuthToken();
    var response = await http.post(Uri.parse("$API_HOST/users/${currentUser.id}/friends"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}, body: jsonEncode(friend));
    if (response.statusCode == 200) {
      log("[user_profile_page] Friend request accepted!");
      setState(() {
        requests.removeWhere((element) => element.id == friend.id);
        friends.add(friend);
      });
      updateUserFriendsList();
      AlertService.showSuccessSnackbar(context, "You are now friends with ${friend.user.firstName}!");
    } else {
      log("[user_profile_page] ${response.body}", LogLevel.error);
      AlertService.showErrorSnackbar(context, "Failed to accept friend request!");
    }
    setState(() => loading = false);
    trace.stop();
  }

  Future<void> requestFriend(User user) async {
    Trace trace = FirebasePerformance.instance.newTrace("requestFriend()");
    await trace.start();
    Friend friend = Friend();
    friend.id = "${currentUser.id}-${user.id}";
    friend.fromUserID = currentUser.id;
    friend.toUserID = user.id;
    friend.status = "REQUESTED";
    setState(() => loading = true);
    await AuthService.getAuthToken();
    var response = await http.post(Uri.parse("$API_HOST/users/${currentUser.id}/friends"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}, body: jsonEncode(friend));
    if (response.statusCode == 200) {
      log("[user_profile_page] Sent friend request");
      setState(() {
        requests.add(friend);
      });
      updateUserFriendsList();
    } else {
      log("[user_profile_page] ${response.body}", LogLevel.error);
      AlertService.showErrorSnackbar(context, "Failed to send friend request!");
    }
    setState(() => loading = false);
    trace.stop();
  }

  Future<void> removeFriend(User user) async {
    Trace trace = FirebasePerformance.instance.newTrace("removeFriend()");
    await trace.start();
    Friend friend = friends.where((element) => element.id.contains(user.id)).first;
    setState(() => loading = true);
    await AuthService.getAuthToken();
    var response = await http.delete(Uri.parse("$API_HOST/users/${currentUser.id}/friends/${friend.id}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"});
    if (response.statusCode == 200) {
      log("[user_profile_page] Friend removed!");
      setState(() {
        friends.removeWhere((element) => element.id == friend.id);
      });
      updateUserFriendsList();
    } else {
      log("[user_profile_page] ${response.body}", LogLevel.error);
    }
    setState(() => loading = false);
    trace.stop();
  }

  Future<void> updateUserFriendsList() async {
    Trace trace = FirebasePerformance.instance.newTrace("updateUserFriendsList()");
    await trace.start();
    await AuthService.getAuthToken();
    var response = await http.get(Uri.parse("$API_HOST/users/${currentUser.id}/friends"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"});
    if (response.statusCode == 200) {
      log("[user_profile_page] Successfully updated local friend list");
      friends.clear();
      requests.clear();
      var responseJson = jsonDecode(utf8.decode(response.bodyBytes));
      for (int i = 0; i < responseJson["data"].length; i++) {
        Friend friend = Friend.fromJson(responseJson["data"][i]);
        if (friend.status == "REQUESTED") {
          requests.add(friend);
        } else if (friend.status == "ACCEPTED") {
          friends.add(friend);
        }
      }
      setState(() {
        friends.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        requests.sort((a, b) => a.toUserID == currentUser.id ? -1 : 1);
      });
    } else {
      log("[user_profile_page] ${response.body}", LogLevel.error);
      AlertService.showErrorSnackbar(context, "Failed to update friends list!");
    }
    trace.stop();
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
        padding: const EdgeInsets.all(8),
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
                borderRadius: const BorderRadius.all(Radius.circular(125)),
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
              // user.bio != "" ? utf8.decode(user.bio.runes.toList()) : "No bio",
              user.bio != "" ? user.bio : "No bio",
              style: const TextStyle(fontSize: 18),
            ),
            const Padding(padding: EdgeInsets.all(4)),
            Visibility(
              visible: loading,
              child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Center(child: RefreshProgressIndicator(color: Colors.white, backgroundColor: SB_NAVY,))
              ),
            ),
            Visibility(
              visible: getFriendshipStatus() == "NULL" && !loading,
              child: Container(
                padding: const EdgeInsets.only(left: 8, top: 8, right: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    padding: const EdgeInsets.only(left: 16, top: 4, right: 16, bottom: 4),
                    color: SB_NAVY,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.person_add, color: Colors.white),
                        Padding(padding: EdgeInsets.all(4)),
                        Text("Add Friend"),
                      ],
                    ),
                    onPressed: () {
                      requestFriend(user);
                    },
                  ),
                ),
              ),
            ),
            Visibility(
              visible: getFriendshipStatus() == "REQUESTED" && !loading,
              child: Container(
                padding: const EdgeInsets.only(left: 8, top: 8, right: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    padding: const EdgeInsets.only(left: 16, top: 4, right: 16, bottom: 4),
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.how_to_reg, color: Theme.of(context).iconTheme.color),
                        const Padding(padding: EdgeInsets.all(4)),
                        Text("Requested", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),),
                      ],
                    ),
                    onPressed: () {},
                  ),
                ),
              ),
            ),
            Visibility(
              visible: getFriendshipStatus() == "PENDING" && !loading,
              child: Container(
                padding: const EdgeInsets.only(left: 8, top: 8, right: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    padding: const EdgeInsets.only(left: 16, top: 4, right: 16, bottom: 4),
                    color: SB_NAVY,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.person_add, color: Colors.white),
                        Padding(padding: EdgeInsets.all(4)),
                        Text("Accept", style: TextStyle(color: Colors.white),),
                      ],
                    ),
                    onPressed: () {
                      acceptFriend(user);
                    },
                  ),
                ),
              ),
            ),
            Visibility(
              visible: getFriendshipStatus() == "FRIEND" && !loading,
              child: Container(
                padding: const EdgeInsets.only(left: 8, top: 8, right: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    padding: const EdgeInsets.only(left: 16, top: 4, right: 16, bottom: 4),
                    color: Theme.of(context).cardColor,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off_rounded, color: Theme.of(context).iconTheme.color),
                        const Padding(padding: EdgeInsets.all(4)),
                        Text("Remove Friend", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),),
                      ],
                    ),
                    onPressed: () {
                      removeFriend(user);
                    },
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Text(
                "Email",
                style: TextStyle(fontSize: 18),
              ),
              trailing: Text(
                showEmail() ? user.email : "Private",
                style: const TextStyle(fontSize: 18),
              ),
            ),
            ListTile(
              leading: const Text(
                "Phone Number",
                style: TextStyle(fontSize: 18),
              ),
              trailing: Text(
                showPhoneNumber() ? user.phoneNumber : "Private",
                style: const TextStyle(fontSize: 18),
              ),
            ),
            Visibility(
              visible: getFriendshipStatus() == "FRIEND",
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_month_rounded),
                  title: const Text("View Schedule"),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded),
                  onTap: () {
                    router.navigateTo(context, "/schedule/user/${user.id}");
                  },
                )
              ),
            )
          ],
        ),
      ),
    );
  }
}
