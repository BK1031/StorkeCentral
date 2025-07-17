// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';

import 'package:extended_image/extended_image.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:fluro/fluro.dart';
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

  List<String> loadingList = [];
  bool refreshing = false;

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  _onChangedHandler(String input) {
    const duration = Duration(milliseconds: 800);
    if (searchOnStoppedTyping != null) {
      setState(() => searchOnStoppedTyping?.cancel());
    }
    setState(() => searchOnStoppedTyping = Timer(duration, () => getSearchedUser(input)));
  }

  Future<void> getSearchedUser(String id) async {
    if (id != "") {
      Trace trace = FirebasePerformance.instance.newTrace("getSearchedUser()");
      await trace.start();
      await AuthService.getAuthToken();
      var response = await http.get(Uri.parse("$API_HOST/users/$id"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"});
      setState(() {
        if (response.statusCode == 200) {
          searchedUser = User.fromJson(jsonDecode(utf8.decode(response.bodyBytes))["data"]);
        } else {
          searchedUser = User();
        }
      });
      trace.stop();
    } else {
      setState(() {
        searchedUser = User();
      });
    }
  }

  Future<void> acceptFriend(User user) async {
    Trace trace = FirebasePerformance.instance.newTrace("acceptFriend()");
    await trace.start();
    Friend friend = requests.where((element) => element.fromUserID == user.id).first;
    friend.status = "ACCEPTED";
    setState(() {
      loadingList.add(friend.fromUserID);
    });
    await AuthService.getAuthToken();
    var response = await http.post(Uri.parse("$API_HOST/users/${currentUser.id}/friends/${friend.fromUserID}/accept"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}, body: jsonEncode(friend));
    if (response.statusCode == 200) {
      log("[friends_page] Friend request accepted!");
      setState(() {
        requests.removeWhere((element) => element.fromUserID == friend.fromUserID);
        friends.add(Friend.fromJson(jsonDecode(response.body)["data"]));
      });
      updateUserFriendsList();
      AlertService.showSuccessSnackbar(context, "You are now friends with ${friend.user.firstName}!");
    } else {
      log("[friends_page] ${response.body}", LogLevel.error);
      AlertService.showErrorSnackbar(context, "Failed to send friend request");
    }
    setState(() {
      loadingList.remove(friend.fromUserID);
    });
    trace.stop();
  }

  Future<void> requestFriend(User user) async {
    Trace trace = FirebasePerformance.instance.newTrace("requestFriend()");
    await trace.start();
    setState(() {
      loadingList.add(user.id);
    });
    await AuthService.getAuthToken();
    var response = await http.post(Uri.parse("$API_HOST/users/${currentUser.id}/friends/${user.id}/request"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"});
    if (response.statusCode == 200) {
      log("[add_friend_page] Sent friend request");
      setState(() {
        requests.add(Friend.fromJson(jsonDecode(response.body)["data"]));
      });
      updateUserFriendsList();
      if (searchedUser.id != "") {
        // Rebuild searched user widget
        getSearchedUser(user.id);
        log("[add_friend_page] Rebuilt searched user widget");
      } else {
        // Rebuild in suggested list
        log("[add_friend_page] Rebuilt in suggested list");
      }
    } else {
      log("[add_friend_page] ${response.body}", LogLevel.error);
      AlertService.showErrorSnackbar(context, "Failed to send friend request!");
    }
    setState(() {
      loadingList.remove(user.id);
    });
    trace.stop();
  }

  Future<void> removeFriend(User user) async {
    Trace trace = FirebasePerformance.instance.newTrace("acceptFriend()");
    await trace.start();
    setState(() {
      friends.removeWhere((element) => element.fromUserID == user.id || element.toUserID == user.id);
      requests.removeWhere((element) => element.fromUserID == user.id || element.toUserID == user.id);
    });
    await AuthService.getAuthToken();
    var response = await http.delete(Uri.parse("$API_HOST/users/${currentUser.id}/friends/${user.id}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"});
    if (response.statusCode == 200) {
      log("[friends_page] Friend removed!");
      updateUserFriendsList();
      AlertService.showSuccessSnackbar(context, "Removed friend!");
    } else {
      log("[friends_page] ${response.body}", LogLevel.error);
      AlertService.showErrorSnackbar(context, "Failed to remove friend");
    }
    trace.stop();
  }

  Future<void> updateUserFriendsList() async {
    Trace trace = FirebasePerformance.instance.newTrace("updateUserFriendsList()");
    await trace.start();
    await AuthService.getAuthToken();
    setState(() => refreshing = true);
    var response = await httpClient.get(Uri.parse("$API_HOST/users/${currentUser.id}/friends"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"});
    if (response.statusCode == 200) {
      log("[add_friend_page] Successfully updated local friend list");
      friends.clear();
      requests.clear();
      var responseJson = jsonDecode(response.body);
      // Persist friends list
      List<dynamic> friendsDynamic = responseJson["data"].map((e) => jsonEncode(e).toString()).toList();
      prefs.setStringList("CURRENT_USER_FRIENDS", friendsDynamic.map((e) => e.toString()).toList());

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
      log("[add_friend_page] ${response.body}", LogLevel.error);
      AlertService.showErrorSnackbar(context, "Failed to update friends list!");
    }
    setState(() => refreshing = false);
    trace.stop();
  }

  Future<void> getSuggestedFriends() async {
    Trace trace = FirebasePerformance.instance.newTrace("getSuggestedFriends()");
    await trace.start();
    setState(() => refreshing = true);
    await AuthService.getAuthToken();
    var response = await http.get(Uri.parse("$API_HOST/users"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"});
    if (response.statusCode == 200) {
      // TODO: make this an actual mutual friends endpoint
      log("[add_friend_page] Retrieved suggested users");
      var responseJson = jsonDecode(utf8.decode(response.bodyBytes));
      for (int i = 0; i < responseJson["data"].length; i++) {
        User user = User.fromJson(responseJson["data"][i]);
        if (user.id != currentUser.id && !friends.any((element) => element.user.id == user.id)) {
            suggestedFriends.add(user);
        }
      }
      setState(() {
        suggestedFriends.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        suggestedFriends = suggestedFriends.sublist(0, 20);
        refreshing = false;
      });
    } else {
      log("[add_friend_page] ${response.body}", LogLevel.error);
      AlertService.showErrorSnackbar(context, "Failed to get suggested friends!");
    }
    trace.stop();
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
        title: const Text(
          "Add Friend",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
                    child: Text(
                      "Add By Username",
                      style: TextStyle(color: ACTIVE_ACCENT_COLOR, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
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
                                autocorrect: false,
                                controller: textEditingController,
                                onChanged: _onChangedHandler
                              ),
                            ),
                          ],
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: searchedUser.id != "" ? 100 : 0,
                          child: Card(
                            child: InkWell(
                              onTap: () {
                                router.navigateTo(context, "/profile/user/${searchedUser.id}", transition: TransitionType.native);
                              },
                              borderRadius: BorderRadius.circular(8),
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
                                        borderRadius: const BorderRadius.all(Radius.circular(125)),
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
                                            style: const TextStyle(fontSize: 18),
                                          ),
                                          Text(
                                            "@${searchedUser.userName}",
                                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                                          )
                                        ],
                                      ),
                                    ),
                                    Visibility(
                                      visible: loadingList.contains(searchedUser.id),
                                      child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Center(child: RefreshProgressIndicator(
                                              color: Colors.white,
                                              backgroundColor: ACTIVE_ACCENT_COLOR
                                          ))
                                      ),
                                    ),
                                    Visibility(
                                      // Searched user is not current user, is not already requested, is not already friend
                                      visible: searchedUser.id != currentUser.id && !requests.any((element) => element.user.id == searchedUser.id) && !friends.any((element) => element.user.id == searchedUser.id) && !loadingList.contains(searchedUser.id),
                                      child: CupertinoButton(
                                        padding: const EdgeInsets.only(left: 16, top: 4, right: 16, bottom: 4),
                                        color: ACTIVE_ACCENT_COLOR,
                                        child: const Row(
                                          children: [
                                            Icon(Icons.person_add, color: Colors.white),
                                            Padding(padding: EdgeInsets.all(4)),
                                            Text("Add"),
                                          ],
                                        ),
                                        onPressed: () {
                                          requestFriend(searchedUser);
                                        },
                                      ),
                                    ),
                                    Visibility(
                                      // Searched user is not current user, is already friend
                                      visible: searchedUser.id != currentUser.id && friends.any((element) => element.user.id.contains(searchedUser.id)) && !loadingList.contains(searchedUser.id),
                                      child: CupertinoButton(
                                        padding: const EdgeInsets.only(left: 16, top: 4, right: 16, bottom: 4),
                                        color: Theme.of(context).scaffoldBackgroundColor,
                                        child: Row(
                                          children: [
                                            Icon(Icons.how_to_reg, color: Theme.of(context).iconTheme.color),
                                            const Padding(padding: EdgeInsets.all(2)),
                                            Text("Friends", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),),
                                          ],
                                        ),
                                        onPressed: () {
                                          AlertService.showConfirmationDialog(context, "Remove Friend", "Are you sure you want to remove ${searchedUser.firstName} as a friend?", () {
                                            removeFriend(searchedUser);
                                          });
                                        },
                                      ),
                                    ),
                                    // Searched user is not current user, is already requested
                                    Visibility(
                                      visible: searchedUser.id != currentUser.id && requests.any((element) => element.toUserID.contains(searchedUser.id)) && !loadingList.contains(searchedUser.id),
                                      child: CupertinoButton(
                                        padding: const EdgeInsets.only(left: 16, top: 4, right: 16, bottom: 4),
                                        color: Theme.of(context).scaffoldBackgroundColor,
                                        child: Row(
                                          children: [
                                            Icon(Icons.how_to_reg, color: Theme.of(context).iconTheme.color),
                                            const Padding(padding: EdgeInsets.all(2)),
                                            Text("Requested", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),),
                                          ],
                                        ),
                                        onPressed: () {
                                          AlertService.showConfirmationDialog(context, "Cancel Friend Request", "Are you sure you want to cancel your friend request to ${searchedUser.firstName}?", () {
                                            removeFriend(searchedUser);
                                          });
                                        },
                                      ),
                                    ),
                                    Visibility(
                                      visible: searchedUser.id != currentUser.id && requests.any((element) => element.fromUserID.contains(searchedUser.id)) && !loadingList.contains(searchedUser.id),
                                      child: CupertinoButton(
                                        padding: const EdgeInsets.only(left: 16, top: 4, right: 16, bottom: 4),
                                        color: ACTIVE_ACCENT_COLOR,
                                        child: const Row(
                                          children: [
                                            Icon(Icons.person_add, color: Colors.white),
                                            Padding(padding: EdgeInsets.all(4)),
                                            Text("Accept", style: TextStyle(color: Colors.white),),
                                          ],
                                        ),
                                        onPressed: () {
                                          acceptFriend(searchedUser);
                                        },
                                      )
                                    )
                                  ],
                                ),
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
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
                      child: Text(
                        "Suggested Friends",
                        style: TextStyle(color: ACTIVE_ACCENT_COLOR, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Visibility(
                      visible: refreshing,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Center(child: RefreshProgressIndicator(color: Colors.white, backgroundColor: ACTIVE_ACCENT_COLOR,))
                      ),
                    ),
                    Visibility(
                      visible: suggestedFriends.isEmpty && !refreshing,
                      child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Center(child: Text("No suggested friends available"))
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: suggestedFriends.length,
                        itemBuilder: (context, index) {
                          return Card(
                            child: InkWell(
                              onTap: () {
                                router.navigateTo(context, "/profile/user/${suggestedFriends[index].id}", transition: TransitionType.native);
                              },
                              borderRadius: BorderRadius.circular(8),
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
                                      borderRadius: const BorderRadius.all(Radius.circular(125)),
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
                                          style: const TextStyle(fontSize: 18),
                                        ),
                                        Text(
                                          "@${suggestedFriends[index].userName}",
                                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                                        )
                                      ],
                                    ),
                                  ),
                                  Visibility(
                                    visible: loadingList.contains(suggestedFriends[index].id),
                                    child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Center(child: RefreshProgressIndicator(
                                            color: Colors.white,
                                            backgroundColor: ACTIVE_ACCENT_COLOR
                                        ))
                                    ),
                                  ),
                                  Visibility(
                                    // User is not current user, is not already requested, is not already friend
                                    visible: suggestedFriends[index].id != currentUser.id && !requests.any((element) => element.user.id == suggestedFriends[index].id) && !friends.any((element) => element.user.id == suggestedFriends[index].id) && !loadingList.contains(suggestedFriends[index].id),
                                    child: CupertinoButton(
                                      padding: const EdgeInsets.only(left: 16, top: 4, right: 16, bottom: 4),
                                      color: ACTIVE_ACCENT_COLOR,
                                      child: const Row(
                                        children: [
                                          Icon(Icons.person_add, color: Colors.white),
                                          Padding(padding: EdgeInsets.all(4)),
                                          Text("Add"),
                                        ],
                                      ),
                                      onPressed: () {
                                        requestFriend(suggestedFriends[index]);
                                      },
                                    ),
                                  ),
                                  Visibility(
                                    // User is not current user, is already requested to
                                    visible: suggestedFriends[index].id != currentUser.id && requests.any((element) => element.toUserID.contains(suggestedFriends[index].id)) && !loadingList.contains(suggestedFriends[index].id),
                                    child: CupertinoButton(
                                      padding: const EdgeInsets.only(left: 16, top: 4, right: 16, bottom: 4),
                                      color: Theme.of(context).scaffoldBackgroundColor,
                                      child: Row(
                                        children: [
                                          Icon(Icons.how_to_reg, color: Theme.of(context).iconTheme.color),
                                          const Padding(padding: EdgeInsets.all(2)),
                                          Text("Requested", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),),
                                        ],
                                      ),
                                      onPressed: () {
                                        AlertService.showConfirmationDialog(context, "Cancel Friend Request", "Are you sure you want to cancel your friend request to ${suggestedFriends[index].firstName}?", () {
                                          removeFriend(suggestedFriends[index]);
                                        });
                                      },
                                    ),
                                  ),
                                  Visibility(
                                    // User is not current user, is already requested from
                                    visible: suggestedFriends[index].id != currentUser.id && requests.any((element) => element.fromUserID.contains(suggestedFriends[index].id)) && !loadingList.contains(suggestedFriends[index].id),
                                    child: CupertinoButton(
                                      padding: const EdgeInsets.only(left: 16, top: 4, right: 16, bottom: 4),
                                      color: ACTIVE_ACCENT_COLOR,
                                      child: const Row(
                                        children: [
                                          Icon(Icons.person_add, color: Colors.white),
                                          Padding(padding: EdgeInsets.all(4)),
                                          Text("Accept", style: TextStyle(color: Colors.white),),
                                        ],
                                      ),
                                      onPressed: () {
                                        acceptFriend(suggestedFriends[index]);
                                      },
                                    )
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
