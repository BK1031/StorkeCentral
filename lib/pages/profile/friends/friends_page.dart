import 'dart:convert';

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

  Future<User> getFriend() async {
    User user = User();
    await AuthService.getAuthToken();
    return user;
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
                      },
                      child: Text("Requests", style: TextStyle(color: currPage == 1 ? Colors.white : Theme.of(context).textTheme.button!.color)),
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
                children: [
                  ListView.builder(
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      return Container(
                        padding: const EdgeInsets.only(left: 8, top: 4, right: 8),
                        child: Card(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
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
                                      "Haarika Kathi",
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    Text(
                                      "@haarika",
                                      style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.caption!.color),
                                    )
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.cancel_outlined, color: Theme.of(context).textTheme.caption!.color),
                                onPressed: () {

                                },
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  ListView.builder(
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      return Container(
                        padding: const EdgeInsets.only(left: 8, top: 4, right: 8),
                        child: Card(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
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
                                      "Haarika Kathi",
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    Text(
                                      "@haarika",
                                      style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.caption!.color),
                                    )
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.cancel_outlined, color: Theme.of(context).textTheme.caption!.color),
                                onPressed: () {

                                },
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              )
            ),
          ),
        ],
      ),
    );
  }
}
