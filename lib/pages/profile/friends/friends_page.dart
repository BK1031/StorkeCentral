import 'dart:convert';

import 'package:badges/badges.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:storke_central/models/friend.dart';
import 'package:storke_central/models/user.dart';
import 'package:storke_central/utils/auth_service.dart';
import 'package:storke_central/utils/logger.dart';
import 'package:storke_central/utils/theme.dart';

import '../../../utils/config.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({Key? key}) : super(key: key);

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {

  List<User> friends = [];
  List<User> requests = [];

  int currPage = 0;
  PageController pageController = PageController();

  @override
  void initState() {
    super.initState();
    updateUserFriendsList();
  }

  Future<void> updateUserFriendsList() async {
    await AuthService.getAuthToken();
    var response = await http.get(Uri.parse("$API_HOST/users/${currentUser.id}/friends"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"});
    if (response.statusCode == 200) {
      log("Successfully updated local friend list");
      setState(() {
        currentUser.friends = (jsonDecode(response.body)["data"] as List<dynamic>).map((e) => Friend.fromJson(e)).toList();
      });
      friends.clear();
      requests.clear();
      for (var friend in currentUser.friends) {
        if (friend.status == "ACCEPTED") {
          friends.add(await getFriend(friend.toUserID != currentUser.id ? friend.toUserID : friend.fromUserID));
        } else if (friend.status == "REQUESTED") {
          requests.add(await getFriend(friend.toUserID != currentUser.id ? friend.toUserID : friend.fromUserID));
        }
      }
      setState(() {});
    } else {
      log(response.body, LogLevel.error);
      CoolAlert.show(
          context: context,
          type: CoolAlertType.error,
          title: "Failed to update friends list",
          widget: Text(response.body.toString()),
          backgroundColor: SB_NAVY,
          confirmBtnColor: SB_RED,
          confirmBtnText: "OK"
      );
    }
  }

  Future<User> getFriend(String id) async {
    User user = User();
    await AuthService.getAuthToken();
    var response = await http.get(Uri.parse("$API_HOST/users/$id"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"});
    if (response.statusCode == 200) {
      user = User.fromJson(jsonDecode(response.body)["data"]);
    } else {
      log("Failed to retrieve friend with id: $id", LogLevel.error);
      log(response.body, LogLevel.error);
      CoolAlert.show(
          context: context,
          type: CoolAlertType.error,
          title: "Failed to retrieve friend with id: $id",
          widget: Text(response.body.toString()),
          backgroundColor: SB_NAVY,
          confirmBtnColor: SB_RED,
          confirmBtnText: "OK"
      );
    }
    return user;
  }

  Future<void> addFriend(User user) async {
    Friend friend = Friend();
    friend = currentUser.friends.where((element) => element.id.contains(user.id)).first;
    friend.status = "ACCEPTED";
    await AuthService.getAuthToken();
    var response = await http.post(Uri.parse("$API_HOST/users/${currentUser.id}/friends"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}, body: jsonEncode(friend));
    if (response.statusCode == 200) {
      log("Sent friend request");
      await updateUserFriendsList();
      CoolAlert.show(
          context: context,
          type: CoolAlertType.success,
          title: "Friend Request Accepted",
          widget: Text("You are now friends with ${user.firstName}!"),
          backgroundColor: SB_NAVY,
          confirmBtnColor: SB_GREEN,
          confirmBtnText: "OK"
      );
    } else {
      log(response.body, LogLevel.error);
      CoolAlert.show(
          context: context,
          type: CoolAlertType.error,
          title: "Friend Request Error",
          widget: Text(response.body.toString()),
          backgroundColor: SB_NAVY,
          confirmBtnColor: SB_RED,
          confirmBtnText: "OK"
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: SB_NAVY,
        title: const Text(
          "Friends",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(left: 8, top: 8, right: 8),
            child: Card(
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      color: currPage == 0 ? SB_NAVY : null,
                      onPressed: () {
                        setState(() {
                          currPage = 0;
                        });
                        pageController.animateToPage(0, duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
                      },
                      child: Text("My Friends", style: TextStyle(color: currPage == 0 ? Colors.white : Theme.of(context).textTheme.button!.color)),
                    ),
                  ),
                  Expanded(
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      color: currPage == 1 ? SB_NAVY : null,
                      onPressed: () {
                        setState(() {
                          currPage = 1;
                        });
                        pageController.animateToPage(1, duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
                      },
                      child: Badge(
                        position: BadgePosition.topEnd(top: -10, end: -20),
                        showBadge: currentUser.friends.where((element) => element.fromUserID != currentUser.id && element.status == "REQUESTED").isNotEmpty,
                        badgeContent: Text(currentUser.friends.where((element) => element.fromUserID != currentUser.id && element.status == "REQUESTED").length.toString(), style: const TextStyle(color: Colors.white)),
                        child: Text("Requests", style: TextStyle(color: currPage == 1 ? Colors.white : Theme.of(context).textTheme.button!.color)),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              child: PageView(
                controller: pageController,
                onPageChanged: (int page) {
                  setState(() {
                    currPage = page;
                  });
                },
                children: [
                  friends.isEmpty ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: Center(child: RefreshProgressIndicator())
                  ) : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                child: ExtendedImage.network(
                                  friends[index].profilePictureURL,
                                  height: 60,
                                  width: 60,
                                  fit: BoxFit.cover,
                                  borderRadius: BorderRadius.all(Radius.circular(125)),
                                  shape: BoxShape.rectangle,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${friends[index].firstName} ${friends[index].lastName}",
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    Text(
                                      "@${friends[index].userName}",
                                      style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.caption!.color),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  requests.isEmpty ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: Center(child: RefreshProgressIndicator())
                  ) : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                child: ExtendedImage.network(
                                  requests[index].profilePictureURL,
                                  height: 60,
                                  width: 60,
                                  fit: BoxFit.cover,
                                  borderRadius: BorderRadius.all(Radius.circular(125)),
                                  shape: BoxShape.rectangle,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${requests[index].firstName} ${requests[index].lastName}",
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    Text(
                                      "@${requests[index].userName}",
                                      style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.caption!.color),
                                    )
                                  ],
                                ),
                              ),
                              Visibility(
                                visible: currentUser.friends.where((element) => element.id.contains(requests[index].id)).first.fromUserID != currentUser.id,
                                child: CupertinoButton(
                                  padding: const EdgeInsets.only(left: 16, top: 4, right: 16, bottom: 4),
                                  color: SB_NAVY,
                                  child: Row(
                                    children: const [
                                      Icon(Icons.person_add, color: Colors.white),
                                      const Padding(padding: EdgeInsets.all(4)),
                                      Text("Accept", style: TextStyle(color: Colors.white),),
                                    ],
                                  ),
                                  onPressed: () {
                                    addFriend(requests[index]);
                                  },
                                ),
                              ),
                              Visibility(
                                visible: currentUser.friends.where((element) => element.id.contains(requests[index].id)).first.fromUserID == currentUser.id,
                                child: CupertinoButton(
                                  padding: const EdgeInsets.only(left: 16, top: 4, right: 16, bottom: 4),
                                  color: Theme.of(context).backgroundColor,
                                  child: Row(
                                    children: [
                                      Icon(Icons.how_to_reg, color: Theme.of(context).iconTheme.color),
                                      const Padding(padding: EdgeInsets.all(2)),
                                      Text("Requested", style: TextStyle(color: Theme.of(context).textTheme.bodyText1?.color),),
                                    ],
                                  ),
                                  onPressed: () {},
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  )
                ],
              )
            ),
          ),
        ],
      ),
    );
  }
}
