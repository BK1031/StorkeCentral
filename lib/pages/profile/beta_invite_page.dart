// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:math' as math;

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extended_image/extended_image.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:storke_central/models/user.dart';
import 'package:storke_central/utils/alert_service.dart';
import 'package:storke_central/utils/auth_service.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/logger.dart';
import 'package:storke_central/utils/theme.dart';
import 'package:timeago/timeago.dart' as timeago;

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
    getExistingCode();
  }

  void getExistingCode() {
    FirebaseFirestore.instance.doc("beta/users").get().then((value) {
      try {
        log("[beta_invite_page] ${value.get(currentUser.id)}");
        setState(() {
          inviteCode = value.get(currentUser.id);
        });
        FirebaseFirestore.instance.doc("beta/$inviteCode").get().then((value) {
          setState(() {
            inviteURL = value.get("url");
            expires = value.get("expires").toDate();
            expires = expires.toLocal();
            codeCap = value.get("cap");
          });
          if (expires.isBefore(DateTime.now())) {
            log("[beta_invite_page] Invite code has expired, generating new code...");
            setState(() {
              codeCap = 5;
              inviteCode = generateInviteCode();
              expires = DateTime.now().add(const Duration(days: 7));
            });
            if (!kIsWeb) {
              generateInviteLink().then((value) => uploadNewCode());
            } else {
              AlertService.showInfoSnackbar(context, "Unfortunately, we cannot generate an invite code for you on the web. Please try again in our mobile app.");
            }
          }
          value.get("uses").forEach((element) {
            log("[beta_invite_page] Adding user $element to invited users list");
            addUserToInvitedList(element.toString());
          });
        });
      } catch (err) {
        // No existing code
        setState(() {
          codeCap = 5;
          inviteCode = generateInviteCode();
          expires = DateTime.now().add(const Duration(days: 7));
        });
        if (!kIsWeb) {
          generateInviteLink().then((value) => uploadNewCode());
        } else {
          AlertService.showInfoSnackbar(context, "Unfortunately, we cannot generate an invite code for you on the web. Please try again in our mobile app.");
        }
      }
    });
  }

  Future<void> addUserToInvitedList(String userID) async {
    await AuthService.getAuthToken();
    var response = await httpClient.get(Uri.parse("$API_HOST/users/$userID"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"});
    if (response.statusCode == 200) {
      setState(() {
        invitedUsers.add(User.fromJson(jsonDecode(utf8.decode(response.bodyBytes))["data"]));
      });
    }
  }

  void uploadNewCode() {
    FirebaseFirestore.instance.doc("beta/users").update({currentUser.id: inviteCode}).then((value) {
      FirebaseFirestore.instance.doc("beta/$inviteCode").set({
        "createdBy": currentUser.id,
        "url": inviteURL,
        "expires": Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
        "cap": codeCap,
        "uses": []
      });
    });
  }

  // Generate 6 character invite code
  String generateInviteCode() {
    var code = "";
    for (var i = 0; i < 6; i++) {
      code += math.Random().nextInt(26).toRadixString(26);
    }
    print("Generated invite code: $code");
    return code.toUpperCase();
  }

  Future<void> generateInviteLink() async {
    final dynamicLinkParams = DynamicLinkParameters(
      link: Uri.parse("https://storkecentr.al/#/register?invite=$inviteCode"),
      uriPrefix: "https://launch.storkecentr.al",
      androidParameters: const AndroidParameters(
        packageName: "com.bk1031.storke_central"
      ),
      iosParameters: IOSParameters(
        bundleId: "com.example.app.ios",
        customScheme: "storkecentral",
        appStoreId: APP_STORE_URL.split("id")[1]
      ),
      socialMetaTagParameters: SocialMetaTagParameters(
        title: "StorkeCentral – Public Beta",
        description: "${currentUser.firstName} has invited you to join the StorkeCentral Public Beta!",
        imageUrl: Uri.parse("https://storkecentr.al/static/storke-banner-navy.png")
      )
    );
    final dynamicLink = await FirebaseDynamicLinks.instance.buildShortLink(dynamicLinkParams);
    log("[beta_invite_page] Generated invite link: $inviteURL");
    inviteURL = dynamicLink.shortUrl.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: SB_NAVY,
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
              "Thank you for being a part of the StorkeCentral Public Beta! Your feedback is very important to us and we are excited to hear what you think about the app.",
              style: TextStyle(fontSize: 16),
            ),
            const Padding(padding: EdgeInsets.all(8)),
            const Text(
              "You can share the code below with your friends to invite them to the beta. Come back here to get more invites each week!",
              style: TextStyle(fontSize: 16),
            ),
            const Padding(padding: EdgeInsets.all(8)),
            Container(
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
                      child: Text(
                        "My Invite Code",
                        // "Developer".toUpperCase(),
                        style: TextStyle(color: AdaptiveTheme.of(context).brightness == Brightness.light ? SB_NAVY : Colors.white54, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ListTile(
                      title: Text(inviteCode != "" ? inviteCode : "XXX-XXX", style: TextStyle(fontSize: 26, letterSpacing: 4, color: inviteCode != "" ? null : Colors.grey), textAlign: TextAlign.center),
                      subtitle: Text(inviteURL != "" ? inviteURL.replaceAll("https://", "") : "Generating invite url...", style: TextStyle(color: SB_NAVY, fontSize: 18), textAlign: TextAlign.center),
                      trailing: const Icon(Icons.copy),
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: "Hey, here's an invite code for StorkeCentral, the cool new app I was talking about: $inviteCode\n\n$inviteURL"));
                        AlertService.showInfoSnackbar(context, "Copied invite code to clipboard!");
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16, left: 16, bottom: 8),
                      child: Text("Invite code expires ${DateFormat("MMMMd").format(expires)} (in ${timeago.format(expires, locale: "en_short", allowFromNow: true)})"),
                    )
                  ],
                ),
              ),
            ),
            const Padding(padding: EdgeInsets.all(4)),
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
                    child: Text(
                      "Invited Users (${invitedUsers.length}/$codeCap)",
                      // "Developer".toUpperCase(),
                      style: TextStyle(color: AdaptiveTheme.of(context).brightness == Brightness.light ? SB_NAVY : Colors.white54, fontSize: 18, fontWeight: FontWeight.bold),
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
          ],
        ),
      ),
    );
  }
}
