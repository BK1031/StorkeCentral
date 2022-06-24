import 'dart:convert';
import 'package:cool_alert/cool_alert.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storke_central/models/user.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/logger.dart';

class AuthService {

  /// only call this function when fb auth state has been verified!
  /// sets the [currentUser] to retrieved user with [id] from db
  static Future<void> getUser(String id) async {
    await AuthService.getAuthToken();
    var response = await http.get(Uri.parse("$API_HOST/users/$id"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"});
    if (response.statusCode == 200) {
      currentUser = User.fromJson(jsonDecode(response.body)["data"]);
      log("====== USER DEBUG INFO ======");
      log("FIRST NAME: ${currentUser.firstName}");
      log("LAST NAME: ${currentUser.lastName}");
      log("EMAIL: ${currentUser.email}");
      log("====== =============== ======");
    }
    else {
      // logged but not user data found!
      log("StorkeCentral account not found!");
      // signOut();
    }
  }

  static Future<void> signOut() async {
    await fb.FirebaseAuth.instance.signOut();
    currentUser = User();
  }

  static Future<void> getAuthToken() async {
    SC_AUTH_TOKEN = await fb.FirebaseAuth.instance.currentUser!.getIdToken(true);
    log("Retrieved auth token: ...${SC_AUTH_TOKEN.substring(SC_AUTH_TOKEN.length - 20)}");
    // await Future.delayed(const Duration(milliseconds: 100));
  }
}