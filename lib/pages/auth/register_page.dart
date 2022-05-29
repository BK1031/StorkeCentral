import 'package:cool_alert/cool_alert.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:storke_central/models/user.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/theme.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  final PageController _pageController = PageController();
  User registerUser = User();

  Future<void> loginGoogle() async {
    // Google sign in
    GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ["email", "profile", "openid"]);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        print("Signed into Google as ${googleUser.displayName} (${googleUser.email})");
        if (googleUser.email.contains("ucsb.edu")) {
          final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
          final credential = fb.GoogleAuthProvider.credential(
            accessToken: googleAuth?.accessToken,
            idToken: googleAuth?.idToken,
          );
          fb.UserCredential fbUser = await fb.FirebaseAuth.instance.signInWithCredential(credential);
          setState(() {
              registerUser.id = fbUser.user!.uid;
              registerUser.firstName = fbUser.user!.displayName!.split(" ")[0];
              registerUser.lastName = fbUser.user!.displayName!.split(" ")[1];
              registerUser.email = fbUser.user!.email!;
              registerUser.profilePictureURL = fbUser.user!.photoURL!;
          });
          _pageController.animateToPage(1, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
        } else {
          CoolAlert.show(
              context: context,
              type: CoolAlertType.warning,
              title: "Authentication Error",
              widget: const Text("You must be a UCSB student and use a ucsb email addresss to sign in."),
              backgroundColor: SB_NAVY,
              confirmBtnColor: SB_AMBER,
              confirmBtnText: "OK"
          );
        }
      }
    } catch (err) {
      print(err);
      CoolAlert.show(
          context: context,
          type: CoolAlertType.error,
          title: "Google Sign-in Error",
          widget: Text(err.toString()),
          backgroundColor: SB_NAVY,
          confirmBtnColor: SB_RED,
          confirmBtnText: "OK"
      );
    }
  }

  Future<void> loginAnon() async {
    fb.FirebaseAuth.instance.signInAnonymously().then((value) {
      router.navigateTo(context, "/check-auth", transition: TransitionType.fadeIn, replace: true, clearStack: true);
    });
  }

  Widget buildPage1(BuildContext context) {
    return SingleChildScrollView(
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
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: CupertinoButton(
              onPressed: () {
                loginAnon();
              },
              child: const Text("Continue as guest"),
            ),
          )
        ],
      ),
    );
  }

  Widget buildPage2(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Let's start by picking a username.", style: TextStyle(fontSize: 18),),
          TextField(
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "@bk1031",
            ),
            style: TextStyle(fontSize: 25),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: CupertinoButton.filled(
              child: const Text("Next"),
              onPressed: () {

              },
            ),
          )
        ],
      ),
    );
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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(registerUser.firstName == "" ? "Welcome" : "Hey there,\n${registerUser.firstName}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 35, color: Colors.white)),
              )
            ],
          ),
          Expanded(
            child: PageView(
              physics: const NeverScrollableScrollPhysics(),
              controller: _pageController,
              children: [
                buildPage1(context),
                buildPage2(context)
              ],
            ),
          )
        ],
      ),
    );
  }
}
