import 'package:cool_alert/cool_alert.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:storke_central/utils/config.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  Future<void> loginGoogle() async {
    // Google sign in
    GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ["email", "profile", "openid"]);
    try {
      await _googleSignIn.signIn();
    } catch (err) {
      print(err);
      CoolAlert.show(context: context, type: CoolAlertType.error, title: "Error", widget: Text(err.toString()));
    }
  }

  Future<void> loginAnon() async {
    FirebaseAuth.instance.signInAnonymously().then((value) {
      router.navigateTo(context, "/check-auth", transition: TransitionType.fadeIn, replace: true, clearStack: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Stack(
            alignment: Alignment.bottomLeft,
            children: [
              SizedBox(
                height: 250,
                width: MediaQuery.of(context).size.width,
                child: const Hero(
                  tag: "storke-banner",
                  child: Image(
                    image: AssetImage('images/storke.jpeg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Welcome", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 35, color: Colors.white)),
              )
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    style: ButtonStyle(
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                side: const BorderSide(color: Colors.red)
                            )
                        )
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset("images/icons/google-icon.png", height: 25, width: 25,),
                        ),
                        const Padding(padding: EdgeInsets.all(4),),
                        const Text("Sign in with Google", style: TextStyle(fontSize: 16)),
                      ],
                    ),
                    onPressed: () {
                      loginGoogle();
                    },
                  ),
                  const Padding(padding: EdgeInsets.all(8),),
                  const Text("–– OR ––"),
                  // Padding(padding: EdgeInsets.all(8),),
                  CupertinoButton(
                    onPressed: () {
                      loginAnon();
                    },
                    child: const Text("Continue as guest"),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
