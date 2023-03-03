import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:storke_central/models/user.dart';
import 'package:storke_central/utils/auth_service.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/logger.dart';
import 'package:storke_central/utils/theme.dart';

class UserProfilePage extends StatefulWidget {
  String userID = "";
  UserProfilePage({Key? key, required this.userID}) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState(userID);
}

class _UserProfilePageState extends State<UserProfilePage> {

  String userID = "";
  User user = User();

  _UserProfilePageState(this.userID);

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    getUser();
  }

  void getUser() async {
    await AuthService.getAuthToken();
    var response = await http.get(Uri.parse("$API_HOST/users/$userID"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"});
    if (response.statusCode == 200) {
      user = User.fromJson(jsonDecode(response.body)["data"]);
      log("====== USER PROFILE INFO ======");
      log("FIRST NAME: ${user.firstName}");
      log("LAST NAME: ${user.lastName}");
      log("EMAIL: ${user.email}");
      log("====== =============== ======");
    }
    else {
      log("Account not found!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: SB_NAVY,
        title: Text(
          "@${user.userName}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

          ],
        ),
      ),
    );
  }
}
