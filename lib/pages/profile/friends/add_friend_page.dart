import 'dart:async';
import 'dart:convert';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:storke_central/models/friend.dart';
import 'package:storke_central/models/user.dart';
import 'package:storke_central/utils/auth_service.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/logger.dart';
import 'package:storke_central/utils/theme.dart';

class AddFriendPage extends StatefulWidget {
  const AddFriendPage({Key? key}) : super(key: key);

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {

  Timer? searchOnStoppedTyping;
  User searchedUser = User();
  List<User> suggestedFriends = [];
  TextEditingController textEditingController = TextEditingController();

  _onChangedHandler(String input) {
    const duration = Duration(milliseconds: 800);
    if (searchOnStoppedTyping != null) {
      setState(() => searchOnStoppedTyping?.cancel());
    }
    setState(() => searchOnStoppedTyping = Timer(duration, () => getSearchedUser(input)));
  }

  Future<void> getSearchedUser(String id) async {
    if (id != "") {
      await AuthService.getAuthToken();
      var response = await http.get(Uri.parse("$API_HOST/users/$id"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"});
      setState(() {
        if (response.statusCode == 200) {
          searchedUser = User.fromJson(jsonDecode(response.body)["data"]);
        } else {
          searchedUser = User();
        }
      });
    } else {
      setState(() {
        searchedUser = User();
      });
    }
  }

  Future<void> addFriend(User user) async {
    Friend friend = Friend();
    friend.id = "${currentUser.id}-${user.id}";
    friend.fromUserID = currentUser.id;
    friend.toUserID = user.id;
    friend.status = "REQUESTED";
    await AuthService.getAuthToken();
    var response = await http.post(Uri.parse("$API_HOST/users/${currentUser.id}/friends"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}, body: jsonEncode(friend));
    if (response.statusCode == 200) {
      log("Sent friend request");
      await updateUserFriendsList();
      if (searchedUser.id != "") {
        // Rebuild searched user widget
        getSearchedUser(user.id);
        log("Rebuilt searched user widget");
      } else {
        // Rebuild in suggested list
        log("Rebuilt in suggested list");
      }
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

  Future<void> updateUserFriendsList() async {
    await AuthService.getAuthToken();
    var response = await http.get(Uri.parse("$API_HOST/users/${currentUser.id}/friends"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"});
    if (response.statusCode == 200) {
      log("Successfully updated local friend list");
      setState(() {
        currentUser.friends = (jsonDecode(response.body)["data"] as List<dynamic>).map((e) => Friend.fromJson(e)).toList();
      });
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

  Future<void> getSuggestedFriends() async {
    await AuthService.getAuthToken();
    var response = await http.get(Uri.parse("$API_HOST/users"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"});
    if (response.statusCode == 200) {
      log("Retrieved suggested users");
      setState(() {
        suggestedFriends = (jsonDecode(response.body)["data"] as List<dynamic>).map((e) => User.fromJson(e)).toList();
        suggestedFriends.removeWhere((element) => element.id == currentUser.id);
      });
    } else {
      log(response.body, LogLevel.error);
      CoolAlert.show(
          context: context,
          type: CoolAlertType.error,
          title: "Failed to retrieve suggested friends list",
          widget: Text(response.body.toString()),
          backgroundColor: SB_NAVY,
          confirmBtnColor: SB_RED,
          confirmBtnText: "OK"
      );
    }
  }

  @override
  void initState() {
    super.initState();
    updateUserFriendsList();
    getSuggestedFriends();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: SB_NAVY,
        title: const Text(
          "Add Friend",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(left: 8, top: 8, right: 8),
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
                    child: Text(
                      "Add By Username",
                      style: TextStyle(color: AdaptiveTheme.of(context).brightness == Brightness.light ? SB_NAVY : Colors.white54, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text(
                              "@",
                              style: TextStyle(fontSize: 16),
                            ),
                            const Padding(padding: EdgeInsets.all(4)),
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "bk1031",
                                ),
                                style: const TextStyle(fontSize: 20),
                                controller: textEditingController,
                                onChanged: _onChangedHandler
                              ),
                            ),
                          ],
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: searchedUser.id != "" ? 100 : 0,
                          padding: const EdgeInsets.only(left: 8, top: 4, right: 8),
                          child: Card(
                            child: Visibility(
                              visible: searchedUser.id != "",
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    child: ExtendedImage.network(
                                      searchedUser.profilePictureURL,
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
                                          "${searchedUser.firstName} ${searchedUser.lastName}",
                                          style: TextStyle(fontSize: 18),
                                        ),
                                        Text(
                                          "@${searchedUser.userName}",
                                          style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.caption!.color),
                                        )
                                      ],
                                    ),
                                  ),
                                  Visibility(
                                    visible: searchedUser.id != currentUser.id && Friend.getFriendshipFromList(searchedUser, currentUser.friends) == "NULL",
                                    child: CupertinoButton(
                                      padding: const EdgeInsets.only(left: 16, top: 4, right: 16, bottom: 4),
                                      color: SB_NAVY,
                                      child: Row(
                                        children: const [
                                          Icon(Icons.person_add, color: Colors.white),
                                          const Padding(padding: EdgeInsets.all(4)),
                                          Text("Add"),
                                        ],
                                      ),
                                      onPressed: () {
                                        addFriend(searchedUser);
                                      },
                                    ),
                                  ),
                                  Visibility(
                                    visible: searchedUser.id != currentUser.id && Friend.getFriendshipFromList(searchedUser, currentUser.friends) == "ACCEPTED",
                                    child: CupertinoButton(
                                      padding: const EdgeInsets.only(left: 16, top: 4, right: 16, bottom: 4),
                                      color: Theme.of(context).backgroundColor,
                                      child: Row(
                                        children: [
                                          Icon(Icons.how_to_reg, color: Theme.of(context).iconTheme.color),
                                          const Padding(padding: EdgeInsets.all(2)),
                                          Text("Friends", style: TextStyle(color: Theme.of(context).textTheme.bodyText1?.color),),
                                        ],
                                      ),
                                      onPressed: () {},
                                    ),
                                  ),
                                  Visibility(
                                    visible: searchedUser.id != currentUser.id && Friend.getFriendshipFromList(searchedUser, currentUser.friends) == "REQUESTED",
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
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.only(left: 8, top: 8, right: 8),
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
                    child: Text(
                      "Suggested Friends",
                      style: TextStyle(color: AdaptiveTheme.of(context).brightness == Brightness.light ? SB_NAVY : Colors.white54, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Visibility(
                    visible: suggestedFriends.isEmpty,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Center(child: RefreshProgressIndicator())
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: suggestedFriends.length,
                    itemBuilder: (context, index) {
                      return Card(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              child: ExtendedImage.network(
                                suggestedFriends[index].profilePictureURL,
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
                                    "${suggestedFriends[index].firstName} ${suggestedFriends[index].lastName}",
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  Text(
                                    "@${suggestedFriends[index].userName}",
                                    style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.caption!.color),
                                  )
                                ],
                              ),
                            ),
                            Visibility(
                              visible: suggestedFriends[index].id != currentUser.id && Friend.getFriendshipFromList(suggestedFriends[index], currentUser.friends) == "NULL",
                              child: CupertinoButton(
                                padding: const EdgeInsets.only(left: 16, top: 4, right: 16, bottom: 4),
                                color: SB_NAVY,
                                child: Row(
                                  children: const [
                                    Icon(Icons.person_add, color: Colors.white),
                                    const Padding(padding: EdgeInsets.all(4)),
                                    Text("Add"),
                                  ],
                                ),
                                onPressed: () {
                                  addFriend(suggestedFriends[index]);
                                },
                              ),
                            ),
                            Visibility(
                              visible: suggestedFriends[index].id != currentUser.id && Friend.getFriendshipFromList(suggestedFriends[index], currentUser.friends) == "REQUESTED",
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
                      );
                    },
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
