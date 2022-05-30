import 'dart:convert';
import 'package:cool_alert/cool_alert.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storke_central/models/user.dart';
import 'package:storke_central/utils/config.dart';

class AuthService {

  /// only call this function when fb auth state has been verified!
  /// sets the [currentUser] to retrieved user with [id] from db
  static Future<void> getUser(String id) async {
    await AuthService.getAuthToken();
    var response = await http.get(Uri.parse("$API_HOST/users/$id"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"});
    if (response.statusCode == 200) {
      currentUser = User.fromJson(jsonDecode(response.body)["data"]);
      print("====== USER DEBUG INFO ======");
      print("FIRST NAME: ${currentUser.firstName}");
      print("LAST NAME: ${currentUser.lastName}");
      print("EMAIL: ${currentUser.email}");
      print("====== =============== ======");
    }
    else {
      // logged but not user data found!
      print("StorkeCentral account not found! Signing user out.");
      signOut();
    }
  }

  static Future<void> signOut() async {
    await fb.FirebaseAuth.instance.signOut();
    currentUser = User();
  }

  static Future<void> getAuthToken() async {
    SC_AUTH_TOKEN = await fb.FirebaseAuth.instance.currentUser!.getIdToken(true);
    // await Future.delayed(const Duration(milliseconds: 100));
  }
}