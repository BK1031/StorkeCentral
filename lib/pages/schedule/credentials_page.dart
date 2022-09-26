import 'dart:convert';
import 'dart:math';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/logger.dart';
import 'package:storke_central/utils/theme.dart';
import 'package:url_launcher/url_launcher_string.dart';

class CredentialsPage extends StatefulWidget {
  const CredentialsPage({Key? key}) : super(key: key);

  @override
  State<CredentialsPage> createState() => _CredentialsPageState();
}

class _CredentialsPageState extends State<CredentialsPage> {

  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  String encryptionKey = "";

  bool loading = false;

  Future<void> saveCredentials() async {
    if (mounted) {
      setState(() {
        loading = true;
      });
    }
    try {
      generateEncryptionKey();
      await http.post(Uri.parse("$API_HOST/users/credentials/${currentUser.id}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}, body: jsonEncode({
        "user_id": currentUser.id,
        "username": usernameController.text,
        "password": passwordController.text,
        "encryption_key": encryptionKey
      })).then((value) {
        if (value.statusCode == 200) {
          fetchGoldSchedule(selectedQuarter.id);
        } else {
          log("Error saving credentials: ${jsonDecode(value.body)["data"]}", LogLevel.error);
          passwordController.clear();
          if (mounted) {
            setState(() {
              loading = false;
            });
          }
          CoolAlert.show(
            context: context,
            type: CoolAlertType.error,
            title: "Error",
            text: "Error saving credentials: ${jsonDecode(value.body)["data"]}",
            backgroundColor: SB_NAVY,
            confirmBtnColor: SB_RED,
            confirmBtnText: "OK",
          );
        }
      });
    } catch(err) {
      log(err.toString(), LogLevel.error);
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> fetchGoldSchedule(String quarter) async {
    try {
      await http.get(Uri.parse("$API_HOST/users/courses/${currentUser.id}/fetch/${selectedQuarter.id}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}).then((value) {
        if (value.statusCode == 200) {
          CoolAlert.show(
              context: context,
              type: CoolAlertType.success,
              title: "Login successful!",
              widget: const Text("Your GOLD courses have successfully been fetched and added to your schedule."),
              backgroundColor: SB_NAVY,
              confirmBtnColor: SB_GREEN,
              confirmBtnText: "OK",
              onConfirmBtnTap: () {
                router.pop(context);
                router.pop(context);
              }
          );
        } else {
          log("Error using saved credentials: ${jsonDecode(value.body)["data"]}", LogLevel.error);
          passwordController.clear();
          if (mounted) {
            setState(() {
              loading = false;
            });
          }
          CoolAlert.show(
            context: context,
            type: CoolAlertType.error,
            title: "Error",
            text: "The credentials you have entered did not work! Please check your NetID and password and try again.",
            backgroundColor: SB_NAVY,
            confirmBtnColor: SB_RED,
            confirmBtnText: "OK",
          );
        }
      });
    } catch(err) {
      log(err.toString(), LogLevel.error);
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void generateEncryptionKey() {
    const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    Random _rnd = Random.secure();
    encryptionKey = String.fromCharCodes(Iterable.generate(32, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
    log("Generated encryption key", LogLevel.info);
  }

  @override
  void initState() {
    super.initState();
    usernameController.text = currentUser.email.split("@")[0];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: SB_NAVY,
        title: const Text(
          "GOLD Login",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Text("Please login with your UCSB NetID to allow us to fetch your course schedule from GOLD.", style: TextStyle(fontSize: 16),),
            const Padding(padding: EdgeInsets.all(8)),
            Row(
              children: [
                Text("NetID", style: TextStyle(color: AdaptiveTheme.of(context).brightness == Brightness.dark ? Colors.grey : Colors.black54, fontSize: 25),),
                const Padding(padding: EdgeInsets.all(2)),
                Expanded(
                  child: TextField(
                    controller: usernameController,
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "UCSB NetID",
                    ),
                    textCapitalization: TextCapitalization.words,
                    keyboardType: TextInputType.name,
                    style: const TextStyle(fontSize: 25),
                    onChanged: (input) {
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text("Password", style: TextStyle(color: AdaptiveTheme.of(context).brightness == Brightness.dark ? Colors.grey : Colors.black54, fontSize: 25),),
                const Padding(padding: EdgeInsets.all(2)),
                Expanded(
                  child: TextField(
                    controller: passwordController,
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "password",
                    ),
                    obscureText: true,
                    style: const TextStyle(fontSize: 25),
                    onChanged: (input) {
                    },
                  ),
                ),
              ],
            ),
            const Padding(padding: EdgeInsets.all(8)),
            loading ? const Center(child: CircularProgressIndicator()) : Container(
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.all(8),
              child: CupertinoButton(
                color: SB_NAVY,
                onPressed: () {
                  if (passwordController.text.isNotEmpty) saveCredentials();
                },
                child: const Text("Login", style: TextStyle(color: Colors.white),),
              ),
            ),
            ExpansionTile(
              title: Row(
                children: const [
                  Icon(Icons.security),
                  Padding(padding: EdgeInsets.all(4)),
                  Text("Important Security Information", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                ],
              ),
              controlAffinity: ListTileControlAffinity.platform,
              childrenPadding: const EdgeInsets.all(8),
              children: [
                const Text("Your login credentials are encrypted using 256-bit AES encryption with a rolling key on device, and then once again encrypted on our backend for storage. Your credentials are never transmitted in plain text, and are never stored in plaintext.", style: TextStyle(fontSize: 16),),
                const Padding(padding: EdgeInsets.all(4)),
                const Text("Your privacy and security are always our number one priorities, so you can always take a look at our GitHub repository to see how your data is handled.", style: TextStyle(fontSize: 16),),
                CupertinoButton(child: Text("GitHub Repository"), onPressed: () => launchUrlString("https://github.com/BK1031/StorkeCentral")),
                const Text("StorkeCentral is not an official UCSB app, use at your own risk!", style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic), textAlign: TextAlign.center,),
                const Padding(padding: EdgeInsets.all(8)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
