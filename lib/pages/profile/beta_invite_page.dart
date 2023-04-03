import 'dart:math';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:storke_central/models/user.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/theme.dart';

class BetaInvitePage extends StatefulWidget {
  const BetaInvitePage({Key? key}) : super(key: key);

  @override
  State<BetaInvitePage> createState() => _BetaInvitePageState();
}

class _BetaInvitePageState extends State<BetaInvitePage> {

  String inviteCode = "";
  DateTime expires = DateTime.now();
  List<User> invitedUsers = [];

  @override
  void initState() {
    super.initState();
    getExistingCode();
  }

  void getExistingCode() {
    FirebaseFirestore.instance.doc("beta/users").get().then((value) {
      try {
        log(value.get(currentUser.id));
        setState(() {
          inviteCode = value.get(currentUser.id);
        });
      } catch (err) {
        // No existing code
        setState(() {
          inviteCode = generateInviteCode();
        });
      }
    });
  }

  // Generate 6 character invite code
  String generateInviteCode() {
    var code = "";
    for (var i = 0; i < 6; i++) {
      code += Random().nextInt(26).toRadixString(26);
    }
    print("Generated invite code: $code");
    return code;
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
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const Padding(padding: EdgeInsets.all(8)),
            const Text(
              "Thank you for being a part of the StorkeCentral Public Beta! Your feedback is very important to us and we are excited to hear what you think about the app.",
              style: TextStyle(fontSize: 16),
            ),
            const Padding(padding: EdgeInsets.all(8)),
            const Text(
              "You can generate an invite code below to share with your friends. If you need more invites, let us know in the Discord. ",
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
                      trailing: const Icon(Icons.copy),
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: inviteCode));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
