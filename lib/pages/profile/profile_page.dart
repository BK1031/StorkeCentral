import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:extended_image/extended_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: ExtendedImage.network(
                currentUser.profilePictureURL,
                height: 125,
                width: 125,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.all(Radius.circular(125)),
                shape: BoxShape.rectangle,
              ),
            ),
            Text(
              "${currentUser.firstName} ${currentUser.lastName}",
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            Text(
              "@${currentUser.userName}",
              style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.caption!.color),
            ),
            const Padding(padding: EdgeInsets.all(4)),
            Text(
              currentUser.bio != "" ? currentUser.bio : "No bio",
              style: TextStyle(fontSize: 18),
            ),
            Row(),
            SwitchListTile.adaptive(
              title: const Text("Dark Mode"),
              value: AdaptiveTheme.of(context).mode.isDark,
              onChanged: (val) {
                val ? AdaptiveTheme.of(context).setDark() : AdaptiveTheme.of(context).setLight();
                setState(() {});
              },
            ),
            CupertinoButton(
              child: const Text("Sign out"),
              color: SB_RED,
              onPressed: () {
                FirebaseAuth.instance.signOut();
                router.navigateTo(context, "/check-auth", transition: TransitionType.fadeIn, replace: true);
              },
            ),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text("Offline Mode"),
                      trailing: Text(offlineMode.toString())
                  ),
                  ListTile(
                    title: const Text("Anon Mode"),
                    trailing: Text(anonMode.toString())
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
