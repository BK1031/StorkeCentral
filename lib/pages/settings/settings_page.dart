import 'dart:convert';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storke_central/utils/auth_service.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/logger.dart';
import 'package:storke_central/utils/theme.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  void setNotificationPreference(String value) {
    currentUser.privacy.pushNotifications = value;
    AuthService.getAuthToken().then((_) {
      http.post(Uri.parse("$API_HOST/users/${currentUser.id}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}, body: jsonEncode(currentUser));
    });
  }

  Future<void> setUnitsPreference(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    PREF_UNITS = value;
    prefs.setString("PREF_UNITS", PREF_UNITS);
  }

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
            Container(
              padding: const EdgeInsets.only(left: 8, top: 8, right: 8),
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
                      child: Text(
                        "General",
                        // "Developer".toUpperCase(),
                        style: TextStyle(color: AdaptiveTheme.of(context).brightness == Brightness.light ? SB_NAVY : Colors.white54, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ListTile(
                      title: const Text("About"),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded),
                      onTap: () {
                        router.navigateTo(context, "/settings/about", transition: TransitionType.native);
                      },
                    ),
                    ListTile(
                      title: const Text("Documentation"),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded),
                      onTap: () async {
                        const url = 'https://docs.storkecentr.al';
                        if (await canLaunchUrlString(url)) {
                        await launchUrlString(url);
                        } else {
                        log("Could not launch $url", LogLevel.error);
                        }
                      },
                    ),
                    ListTile(
                      title: const Text("Help"),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded),
                      onTap: () async {
                        const url = 'https://discord.storkecentr.al';
                        if (await canLaunchUrlString(url)) {
                          await launchUrlString(url);
                        } else {
                          log("Could not launch $url", LogLevel.error);
                        }
                      },
                    ),
                    ListTile(
                      title: const Text("Legal"),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded),
                      onTap: () {
                        showLicensePage(
                          context: context,
                          applicationVersion: appVersion.toString(),
                          applicationName: "StorkeCentral",
                        );
                      },
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
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
                      child: Text(
                        "Preferences",
                        // "Developer".toUpperCase(),
                        style: TextStyle(color: AdaptiveTheme.of(context).brightness == Brightness.light ? SB_NAVY : Colors.white54, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SwitchListTile.adaptive(
                      title: const Text("Dark Mode"),
                      activeColor: SB_LT_BLUE,
                      value: AdaptiveTheme.of(context).mode.isDark,
                      onChanged: (val) {
                        val ? AdaptiveTheme.of(context).setDark() : AdaptiveTheme.of(context).setLight();
                        setState(() {});
                      },
                    ),
                    SwitchListTile.adaptive(
                      title: const Text("Push Notifications"),
                      activeColor: AdaptiveTheme.of(context).brightness == Brightness.light ? SB_NAVY : SB_LT_BLUE,
                      value: currentUser.privacy.pushNotifications == "ENABLED",
                      onChanged: (val) {
                        setNotificationPreference(val ? "ENABLED" : "DISABLED");
                        setState(() {});
                      },
                    ),
                    ListTile(
                      title: const Text("Distance Units"),
                      trailing: DropdownButton<String>(
                        value: PREF_UNITS,
                        onChanged: (String? newValue) {
                          setUnitsPreference(newValue!);
                          setState(() {});
                        },
                        borderRadius: BorderRadius.circular(8),
                        underline: Container(),
                        items: <String>["M", "FT"].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value == "M" ? "Meters" : "Feet"),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Visibility(
              visible: currentUser.roles.any((element) => element.role == "ADMIN"),
              child: Container(
                padding: const EdgeInsets.only(left: 8, top: 8, right: 8),
                child: Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
                        child: Text(
                          "Developer",
                          // "Developer".toUpperCase(),
                          style: TextStyle(color: AdaptiveTheme.of(context).brightness == Brightness.light ? SB_NAVY : Colors.white54, fontSize: 18, fontWeight: FontWeight.bold),
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
              ),
            )
          ],
        ),
      ),
    );
  }
}
