import 'dart:convert';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storke_central/utils/auth_service.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/logger.dart';
import 'package:storke_central/utils/string_extension.dart';
import 'package:storke_central/utils/theme.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  Future<void> savePreferences() async {
    await AuthService.getAuthToken();
    await httpClient.post(Uri.parse("$API_HOST/users/${currentUser.id}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}, body: jsonEncode(currentUser)).then((value) => setState(() {}));
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
        backgroundColor: SC_MAIN,
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
                        style: TextStyle(color: AdaptiveTheme.of(context).brightness == Brightness.light ? SC_MAIN : Colors.white54, fontSize: 18, fontWeight: FontWeight.bold),
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
                        log("[settings_page] Could not launch $url", LogLevel.error);
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
                          log("[settings_page] Could not launch $url", LogLevel.error);
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
                        style: TextStyle(color: AdaptiveTheme.of(context).brightness == Brightness.light ? SC_MAIN : Colors.white54, fontSize: 18, fontWeight: FontWeight.bold),
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
                      activeColor: AdaptiveTheme.of(context).brightness == Brightness.light ? SC_MAIN : SB_LT_BLUE,
                      value: currentUser.privacy.pushNotifications == "ENABLED",
                      onChanged: (val) {
                        currentUser.privacy.pushNotifications = val ? "ENABLED" : "DISABLED";
                        savePreferences();
                        setState(() {});
                      },
                    ),
                    ListTile(
                      title: const Text("Schedule Reminders"),
                      trailing: DropdownButton<String>(
                        value: currentUser.privacy.scheduleReminders,
                        onChanged: (String? newValue) {
                          setState(() {
                            currentUser.privacy.scheduleReminders = newValue!;
                          });
                          savePreferences();
                        },
                        borderRadius: BorderRadius.circular(8),
                        underline: Container(),
                        items: <String>["DISABLED", "ALERT_15", "ALERT_10", "ALERT_5"].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text({
                              "DISABLED": "Off",
                              "ALERT_15": "15 Minutes Before",
                              "ALERT_10": "10 Minutes Before",
                              "ALERT_5": "5 Minutes Before",
                            }[value]!),
                          );
                        }).toList(),
                      ),
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
            Container(
              padding: const EdgeInsets.only(left: 8, top: 8, right: 8),
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
                      child: Text(
                        "Privacy",
                        style: TextStyle(color: AdaptiveTheme.of(context).brightness == Brightness.light ? SC_MAIN : Colors.white54, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ListTile(
                      title: const Text("Pronouns Visibility"),
                      trailing: DropdownButton<String>(
                        value: currentUser.privacy.pronouns,
                        onChanged: (String? newValue) {
                          currentUser.privacy.pronouns = newValue!;
                          savePreferences();
                        },
                        borderRadius: BorderRadius.circular(8),
                        underline: Container(),
                        items: <String>["PUBLIC", "FRIENDS", "PRIVATE"].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value.capitalize()),
                          );
                        }).toList(),
                      ),
                    ),
                    ListTile(
                      title: const Text("Email Visibility"),
                      trailing: DropdownButton<String>(
                        value: currentUser.privacy.email,
                        onChanged: (String? newValue) {
                          currentUser.privacy.email = newValue!;
                          savePreferences();
                        },
                        borderRadius: BorderRadius.circular(8),
                        underline: Container(),
                        items: <String>["PUBLIC", "FRIENDS", "PRIVATE"].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value.capitalize()),
                          );
                        }).toList(),
                      ),
                    ),
                    ListTile(
                      title: const Text("Phone Number Visibility"),
                      trailing: DropdownButton<String>(
                        value: currentUser.privacy.phoneNumber,
                        onChanged: (String? newValue) {
                          currentUser.privacy.phoneNumber = newValue!;
                          savePreferences();
                        },
                        borderRadius: BorderRadius.circular(8),
                        underline: Container(),
                        items: <String>["PUBLIC", "FRIENDS", "PRIVATE"].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value.capitalize()),
                          );
                        }).toList(),
                      ),
                    ),
                    ListTile(
                      title: const Text("Status Visibility"),
                      trailing: DropdownButton<String>(
                        value: currentUser.privacy.status,
                        onChanged: (String? newValue) {
                          currentUser.privacy.status = newValue!;
                          savePreferences();
                        },
                        borderRadius: BorderRadius.circular(8),
                        underline: Container(),
                        items: <String>["PUBLIC", "FRIENDS", "PRIVATE"].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value.capitalize()),
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
                          style: TextStyle(color: AdaptiveTheme.of(context).brightness == Brightness.light ? SC_MAIN : Colors.white54, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ListTile(
                          title: const Text("Offline Mode"),
                          trailing: Text(offlineMode.toString())
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
