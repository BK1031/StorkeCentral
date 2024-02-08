// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extended_image/extended_image.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:storke_central/models/user.dart';
import 'package:storke_central/utils/auth_service.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/logger.dart';
import 'package:storke_central/utils/theme.dart';

class BetaInvitePage extends StatefulWidget {
  const BetaInvitePage({Key? key}) : super(key: key);

  @override
  State<BetaInvitePage> createState() => _BetaInvitePageState();
}

class _BetaInvitePageState extends State<BetaInvitePage> {

  String inviteCode = "";
  String inviteURL = "";
  DateTime expires = DateTime.now().add(const Duration(days: 7));
  int codeCap = 5;
  List<User> currentInvitedUsers = [];
  List<User> invitedUsers = [];

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    getPreviousCodes();
  }

  void getPreviousCodes() {
    FirebaseFirestore.instance.collection("beta").where("createdBy", isEqualTo: currentUser.id).get().then((value) {
      value.docs.forEach((element) {
        element.get("uses").forEach((user) {
          log("[beta_invite_page] Adding user $user to previous invited users list");
          addUserToPreviousInvitedList(user.toString());
        });
      });
    });
  }

  Future<void> addUserToPreviousInvitedList(String userID) async {
    await AuthService.getAuthToken();
    var response = await httpClient.get(Uri.parse("$API_HOST/users/$userID"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"});
    if (response.statusCode == 200) {
      setState(() {
        invitedUsers.add(User.fromJson(jsonDecode(response.body)["data"]));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
            "Public Beta",
            style: TextStyle(fontWeight: FontWeight.bold)
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            const Padding(padding: EdgeInsets.all(8)),
            ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset("images/storke-sunset-icon/ios/iTunesArtwork@1x.png", width: 64, height: 64)
            ),
            const Padding(padding: EdgeInsets.all(8)),
            const Text(
              "StorkeCentral",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              "Beta v${appVersion.toString()}",
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const Padding(padding: EdgeInsets.all(8)),
            const Text(
              "Thank you for being a part of the StorkeCentral Public Beta! We were very excited to hear all the positive feedback from everyone. We will continue to work hard to make StorkeCentral the best app it can be",
              style: TextStyle(fontSize: 16),
            ),
            const Padding(padding: EdgeInsets.all(8)),
            const Text(
              "Thanks for all the new users you've invited throughout the beta! You can check out the list of users you've invited below.",
              style: TextStyle(fontSize: 16),
            ),
            const Padding(padding: EdgeInsets.all(8)),
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
                    child: Text(
                      "Invited Users",
                      // "Developer".toUpperCase(),
                      style: TextStyle(color: ACTIVE_ACCENT_COLOR, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Visibility(
                    visible: invitedUsers.isEmpty,
                    child: const ListTile(
                      title: Text("No users have joined yet."),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: invitedUsers.length,
                    itemBuilder: (context, index) {
                      return Card(
                        child: InkWell(
                          onTap: () {
                            router.navigateTo(context, "/profile/user/${invitedUsers[index].id}", transition: TransitionType.native);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  child: ExtendedImage.network(
                                    invitedUsers[index].profilePictureURL,
                                    height: 50,
                                    width: 50,
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
                                        "${invitedUsers[index].firstName} ${invitedUsers[index].lastName}",
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                      Text(
                                        "@${invitedUsers[index].userName}",
                                        style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodySmall!.color),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Padding(padding: EdgeInsets.all(8)),
          ],
        ),
      ),
    );
  }
}
