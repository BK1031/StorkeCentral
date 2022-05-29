import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:storke_central/utils/config.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
      ),
      body: Column(
        children: [
          const Center(
            child: Text("Profile page!"),
          ),
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
            color: Colors.redAccent,
            onPressed: () {
              FirebaseAuth.instance.signOut();
              router.navigateTo(context, "/check-auth", transition: TransitionType.fadeIn, replace: true);
            },
          )
        ],
      ),
    );
  }
}
