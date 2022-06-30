import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: SB_NAVY,
        title: const Text(
            "Settings",
            style: TextStyle(fontWeight: FontWeight.bold)
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SwitchListTile.adaptive(
              title: const Text("Dark Mode"),
              value: AdaptiveTheme.of(context).mode.isDark,
              onChanged: (val) {
                val ? AdaptiveTheme.of(context).setDark() : AdaptiveTheme.of(context).setLight();
                setState(() {});
              },
            ),
            Container(
              padding: const EdgeInsets.all(8),
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
                      child: Text(
                        "Developer",
                        // "Developer".toUpperCase(),
                        style: TextStyle(color: SB_NAVY, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ListTile(
                        title: const Text("Offline Mode"),
                        trailing: Text(offlineMode.toString())
                    ),
                    ListTile(
                        title: const Text("Anon Mode"),
                        trailing: Text(anonMode.toString())
                    ),
                    ListTile(
                      title: const Text("Session Logs"),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded),
                      onTap: () {
                        router.navigateTo(context, "/developer/logger", transition: TransitionType.native);
                      },
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
