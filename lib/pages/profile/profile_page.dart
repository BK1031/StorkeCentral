import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:storke_central/utils/config.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile", style: TextStyle(fontWeight: FontWeight.bold),),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: anonMode ? Column(
          children: [
            Text("Signed in anonymously"),
            SwitchListTile.adaptive(
              value: Theme.of(context).brightness == Brightness.dark,
              title: const Text("Dark Mode"),
              onChanged: (value) {
                setState(() {
                  AdaptiveTheme.of(context).setThemeMode(value ? AdaptiveThemeMode.dark : AdaptiveThemeMode.light);
                });
              },
            ),
            CupertinoButton(
              child: Text("Sign Out", style: TextStyle(color: Colors.red),),
              onPressed: () {
                FirebaseAuth.instance.signOut();
                router.navigateTo(context, "/auth", transition: TransitionType.fadeIn, clearStack: true, replace: true);
              },
            )
          ],
        ) : Column(
          children: [
            SwitchListTile.adaptive(
              value: Theme.of(context).brightness == Brightness.dark,
              title: const Text("Dark Mode"),
              onChanged: (value) {
                setState(() {
                  AdaptiveTheme.of(context).setThemeMode(value ? AdaptiveThemeMode.dark : AdaptiveThemeMode.light);
                });
              },
            ),
            CupertinoButton(
              child: Text("Sign Out", style: TextStyle(color: Colors.red),),
              onPressed: () {
                FirebaseAuth.instance.signOut();
                router.navigateTo(context, "/auth", transition: TransitionType.fadeIn, clearStack: true, replace: true);
              },
            )
          ],
        ),
      ),
    );
  }
}
