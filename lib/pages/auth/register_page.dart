import 'dart:async';
import 'dart:convert';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:extended_image/extended_image.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:storke_central/models/user.dart';
import 'package:storke_central/utils/auth_service.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/logger.dart';
import 'package:storke_central/utils/theme.dart';
import 'package:timeago/timeago.dart' as timeago;

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  StreamSubscription? _dynamicLinkSubscription;
  Timer? searchOnStoppedTyping;

  final PageController _pageController = PageController();
  User registerUser = User();
  bool validUsername = true;

  String inviteCode = "";
  bool validInvite = false;
  DateTime expires = DateTime.now();
  int codeCap = 5;
  List<String> invitedUsers = [];
  User invitedBy = User();

  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();

  var phoneMaskFormatter = MaskTextInputFormatter(
      mask: '(###) ###-####',
      filter: { "#": RegExp(r'[0-9]') },
      type: MaskAutoCompletionType.lazy
  );

  List<String> genderList = ["Male", "Female", "Other", "Prefer not to say"];

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  initState() {
    super.initState();
    checkAppUnderReview();
    _registerFirebaseDynamicLinkListener();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (ModalRoute.of(context)!.settings.name!.contains("?invite=")) {
        inviteCode = ModalRoute.of(context)!.settings.name!.split("?invite=")[1];
        verifyInvite();
      }
    });
  }

  @override
  void dispose() {
    searchOnStoppedTyping?.cancel();
    _dynamicLinkSubscription?.cancel();
    super.dispose();
  }

  void checkAppUnderReview() {
    FirebaseFirestore.instance.doc("meta/app-review").get().then((value) {
      setState(() {
        appUnderReview = value.get("underReview");
      });
      if (appUnderReview) {
        log("[registration_page] App is currently under review, features may be disabled when logged in anonymously", LogLevel.warn);
      }
    });
  }

  void _registerFirebaseDynamicLinkListener() {
    // Additional handler just for invite links since `initialLink` doesn't work reliably on iOS
    if (!kIsWeb) {
      _dynamicLinkSubscription =
          FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) {
            log("[registration_page] Firebase Dynamic Link received: ${dynamicLinkData.link}");
            if (dynamicLinkData.link.toString().contains("?invite=")) {
              inviteCode = dynamicLinkData.link.toString().split("?invite=")[1];
              verifyInvite();
            }
          });
      _dynamicLinkSubscription?.onError((error) {
        log("[registration_page] Firebase Dynamic Link error: $error", LogLevel.error);
      });
    }
  }

  Future<void> loginGoogle() async {
    // Google sign in
    GoogleSignIn googleSignIn = GoogleSignIn(scopes: ["email", "profile", "openid"]);
    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser != null) {
        log("[registration_page] Signed into Google as ${googleUser.displayName} (${googleUser.email})");
        if (googleUser.email.contains("ucsb.edu")) {
          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
          final credential = fb.GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          fb.UserCredential fbUser = await fb.FirebaseAuth.instance.signInWithCredential(credential);
          if (mounted) {
            setState(() {
              registerUser.id = fbUser.user!.uid;
              registerUser.firstName = fbUser.user!.displayName!.split(" ")[0];
              registerUser.lastName = fbUser.user!.displayName!.split(" ")[1];
              registerUser.email = fbUser.user!.email!;
              registerUser.phoneNumber = fbUser.user!.phoneNumber ?? "";
              registerUser.profilePictureURL = fbUser.user!.photoURL!;
            });
          }
          await checkIfUserExists().then((userExists) {
            if (userExists) {
              log("[registration_page] User already has StorkeCentral account");
              router.navigateTo(context, "/check-auth", transition: TransitionType.fadeIn, replace: true, clearStack: true);
            } else {
              log("[registration_page] User does not have a StorkeCentral account");
              if (kIsWeb) {
                router.navigateTo(context, "/download", transition: TransitionType.fadeIn, replace: true, clearStack: true);
              } else {
                firstNameController.text = registerUser.firstName;
                lastNameController.text = registerUser.lastName;
                emailController.text = registerUser.email;
                if (validInvite && DateTime.now().isBefore(expires) && invitedUsers.length < codeCap) {
                  _pageController.animateToPage(2, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
                } else {
                  _pageController.animateToPage(1, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
                }
              }
            }
          });
        } else {
          // ignore: use_build_context_synchronously
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
      log("[registration_page] $err", LogLevel.error);
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

  void verifyInvite() {
    try {
      FirebaseFirestore.instance.doc("beta/$inviteCode").get().then((value) async {
        if (value.exists) {
          setState(() {
            expires = value.get("expires").toDate();
            expires = expires.toLocal();
            codeCap = value.get("cap");
            validInvite = true;
          });
          invitedUsers.clear();
          value.get("uses").forEach((element) {
            invitedUsers.add(element.toString());
          });
          // await AuthService.getAuthToken();
          var response = await http.get(Uri.parse("$API_HOST/users/${value.get("createdBy")}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"});
          if (response.statusCode == 200) {
            setState(() {
              invitedBy = User.fromJson(jsonDecode(response.body)["data"]);
            });
          }
        } else {
          setState(() => validInvite = false);
        }
      });
    } catch (err) {
      // Invalid code
      setState(() => validInvite = false);
    }
  }

  void registerInviteCode() {
    try {
      FirebaseFirestore.instance.doc("beta/$inviteCode").update({
        "uses": FieldValue.arrayUnion([registerUser.id])
      });
    } catch (err) {
      log("[registration_page] $err", LogLevel.error);
    }
  }

  Future<void> loginAnon() async {
    fb.FirebaseAuth.instance.signInAnonymously().then((value) async {
      FirebaseAnalytics.instance.logSignUp(signUpMethod: "Anonymous");
      router.navigateTo(context, "/check-auth", transition: TransitionType.fadeIn, replace: true, clearStack: true);
    });
  }

  Future<bool> checkIfUserExists() async {
    var userExistCheck = await http.get(Uri.parse("$API_HOST/users/${registerUser.id}"), headers: {"SC-API-KEY": SC_API_KEY});
    if (userExistCheck.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> usernameCheck() async {
    http.get(Uri.parse("$API_HOST/users/${registerUser.userName}"), headers: {"SC-API-KEY": SC_API_KEY}).then((value) {
      if (value.statusCode == 200) {
        // User exists with username
        if (mounted) {
          setState(() {
            validUsername = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            validUsername = true;
          });
        }
      }
    });
  }

  Future<void> requestLocationAccess() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      log("[registration_page] Location services not enabled!");
      if (mounted) {
        setState(() {
          registerUser.privacy.location = "DISABLED";
        });
      }
    } else {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        log("[registration_page] Location permission denied");
        if (mounted) {
          setState(() {
            registerUser.privacy.location = "DISABLED";
          });
        }
      }
      if (permission == LocationPermission.deniedForever) {
        log("[registration_page] Location permission denied forever");
        if (mounted) {
          setState(() {
            registerUser.privacy.location = "DISABLED_FOREVER";
          });
        }
        showLocationDisabledAlert();
      }
      if (permission == LocationPermission.whileInUse) {
        log("[registration_page] Location permission enabled when in use");
        if (mounted) {
          setState(() {
            registerUser.privacy.location = "ENABLED_WHEN_IN_USE";
          });
        }
      }
      if (permission == LocationPermission.always) {
        log("[registration_page] Location permission enabled always");
        if (mounted) {
          setState(() {
            registerUser.privacy.location = "ENABLED_ALWAYS";
          });
        }
      }
    }
  }

  void showLocationDisabledAlert() {
    CoolAlert.show(
      context: context,
      type: CoolAlertType.error,
      title: "Permission Error",
      widget: const Text("Please enable location access under StorkeCentral in the Settings app."),
      confirmBtnColor: SB_RED,
      confirmBtnText: "OK"
    );
  }

  Future<void> requestNotifications() async {
    OneSignal.shared.promptUserForPushNotificationPermission().then((accepted) {
      log("[registration_page] Accepted permission: $accepted");
      if (mounted) {
        setState(() {
          registerUser.privacy.pushNotifications =
              accepted ? "ENABLED" : "DISABLED";
        });
      }
      if (!accepted) showNotificationsDisabledAlert();
    });
  }

  void showNotificationsDisabledAlert() {
    CoolAlert.show(
        context: context,
        type: CoolAlertType.error,
        title: "Permission Error",
        widget: const Text("Please enable push notifications under StorkeCentral in the Settings app."),
        confirmBtnColor: SB_RED,
        confirmBtnText: "OK"
    );
  }

  Future<void> registerUserAccount() async {
    try {
      // Verify that username is not already taken
      await AuthService.getAuthToken();
      var usernameCheck = await http.get(Uri.parse("$API_HOST/users/${registerUser.userName}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"});
      if (usernameCheck.statusCode == 200) {
        // User exists with username
        CoolAlert.show(
            context: context,
            type: CoolAlertType.error,
            title: "Invalid Username",
            widget: const Text("Unfortunately, someone already has that username. If you really want that name, reach out to us on Discord and we might be able to help."),
            backgroundColor: SB_NAVY,
            confirmBtnColor: SB_RED,
            confirmBtnText: "OK",
            onConfirmBtnTap: () {
              _pageController.animateToPage(1, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
            }
        );
      } else {
        // Setting privacy object's userID so privacy will be set in the backend
        registerUser.privacy.userID = registerUser.id;
        log("[registration_page] ${registerUser.toJson()}");
        await AuthService.getAuthToken();
        var createUser = await http.post(Uri.parse("$API_HOST/users/${registerUser.id}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}, body: jsonEncode(registerUser));
        FirebaseAnalytics.instance.logSignUp(signUpMethod: "Google");
        registerInviteCode();
        if (createUser.statusCode == 200) {
          CoolAlert.show(
              context: context,
              type: CoolAlertType.success,
              title: "Account Created",
              widget: const Text("Your account has been successfully created. Welcome to StorkeCentral!"),
              backgroundColor: SB_NAVY,
              confirmBtnColor: SB_GREEN,
              confirmBtnText: "OK",
              onConfirmBtnTap: () {
                router.navigateTo(context, "/check-auth", transition: TransitionType.fadeIn, clearStack: true, replace: true);
              }
          );
        } else {
          CoolAlert.show(
              context: context,
              type: CoolAlertType.error,
              title: "Account Creation Error",
              widget: Text(jsonDecode(createUser.body)["data"].toString()),
              backgroundColor: SB_NAVY,
              confirmBtnColor: SB_RED,
              confirmBtnText: "OK"
          );
        }
      }
    } catch (err) {
      log("[registration_page] $err", LogLevel.error);
      CoolAlert.show(
          context: context,
          type: CoolAlertType.error,
          title: "Account Creation Error",
          widget: Text(err.toString()),
          backgroundColor: SB_NAVY,
          confirmBtnColor: SB_RED,
          confirmBtnText: "OK"
      );
    }
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
          Visibility(
            visible: !appUnderReview,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: CupertinoButton(
                onPressed: () {
                  loginAnon();
                },
                child: const Text("Continue as guest"),
              ),
            ),
          ),
          Visibility(
            visible: appUnderReview,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: CupertinoButton(
                onPressed: () {
                  loginAnon();
                },
                child: const Text("Enter demo mode"),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: validInvite ? 150 : 0,
            child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
                      child: Text(
                        "Invited By",
                        style: TextStyle(color: AdaptiveTheme.of(context).brightness == Brightness.light ? SB_NAVY : Colors.white54, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            child: ExtendedImage.network(
                              invitedBy.profilePictureURL,
                              height: 50,
                              width: 50,
                              fit: BoxFit.cover,
                              borderRadius: const BorderRadius.all(Radius.circular(125)),
                              shape: BoxShape.rectangle,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${invitedBy.firstName} ${invitedBy.lastName}",
                                  style: const TextStyle(fontSize: 18),
                                ),
                                Text(
                                  "@${invitedBy.userName}",
                                  style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodySmall!.color),
                                )
                              ],
                            ),
                          ),
                          Text(
                            "${invitedUsers.length}/$codeCap",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: invitedUsers.length >= codeCap ? SB_RED : SB_GREEN),
                          )
                        ],
                      ),
                    ),
                    Visibility(
                      visible: DateTime.now().isBefore(expires),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16, left: 16, bottom: 8),
                          child: Text(
                            "Invite code expires ${DateFormat("MMMMd").format(expires)} (in ${timeago.format(expires, locale: "en_short", allowFromNow: true)})",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: DateTime.now().isAfter(expires),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16, left: 16, bottom: 8),
                          child: Text(
                            "Invite code expired ${DateFormat("MMMMd").format(expires)} (${timeago.format(expires, locale: "en_short", allowFromNow: true)} ago)",
                            style: TextStyle(fontSize: 16, color: SB_RED),
                          ),
                        ),
                      ),
                    )
                  ],
                )
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBetaPage(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Enter your invite code to get started.", style: TextStyle(fontSize: 18),),
          TextField(
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: "XXX-XXX",
            ),
            textCapitalization: TextCapitalization.characters,
            keyboardType: TextInputType.text,
            autocorrect: false,
            style: const TextStyle(fontSize: 25),
            onChanged: (input) {
              inviteCode = input;
              const duration = Duration(milliseconds: 800);
              if (searchOnStoppedTyping != null) {
                setState(() => searchOnStoppedTyping?.cancel());
              }
              setState(() => searchOnStoppedTyping = Timer(duration, () {
                if (inviteCode != "") verifyInvite();
              }));
            },
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: validInvite ? 150 : 0,
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
                    child: Text(
                      "Invited By",
                      style: TextStyle(color: AdaptiveTheme.of(context).brightness == Brightness.light ? SB_NAVY : Colors.white54, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          child: ExtendedImage.network(
                            invitedBy.profilePictureURL,
                            height: 50,
                            width: 50,
                            fit: BoxFit.cover,
                            borderRadius: const BorderRadius.all(Radius.circular(125)),
                            shape: BoxShape.rectangle,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${invitedBy.firstName} ${invitedBy.lastName}",
                                style: const TextStyle(fontSize: 18),
                              ),
                              Text(
                                "@${invitedBy.userName}",
                                style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodySmall!.color),
                              )
                            ],
                          ),
                        ),
                        Text(
                          "${invitedUsers.length}/$codeCap",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: invitedUsers.length >= codeCap ? SB_RED : SB_GREEN),
                        )
                      ],
                    ),
                  ),
                  Visibility(
                    visible: DateTime.now().isBefore(expires),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16, left: 16, bottom: 8),
                        child: Text(
                          "Invite code expires ${DateFormat("MMMMd").format(expires)} (in ${timeago.format(expires, locale: "en_short", allowFromNow: true)})",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: DateTime.now().isAfter(expires),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16, left: 16, bottom: 8),
                        child: Text(
                          "Invite code expired ${DateFormat("MMMMd").format(expires)} (${timeago.format(expires, locale: "en_short", allowFromNow: true)} ago)",
                          style: TextStyle(fontSize: 16, color: SB_RED),
                        ),
                      ),
                    ),
                  )
                ],
              )
            ),
          ),
          const Padding(padding: EdgeInsets.all(8),),
          Visibility(
            visible: validInvite && DateTime.now().isBefore(expires) && invitedUsers.length < codeCap,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: CupertinoButton.filled(
                child: const Text("Next"),
                onPressed: () {
                  _pageController.animateToPage(2, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
                },
              ),
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
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Center(child: Text("Welcome! Let's start by picking a username.", style: TextStyle(fontSize: 18), textAlign: TextAlign.center,)),
              Row(
                children: [
                  Text("@", style: TextStyle(color: registerUser.userName != "" ? Colors.black : Colors.black54, fontSize: 25),),
                  const Padding(padding: EdgeInsets.all(2)),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "bk1031",
                      ),
                      textCapitalization: TextCapitalization.none,
                      autocorrect: false,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                      ],
                      style: const TextStyle(fontSize: 25),
                      onChanged: (input) {
                        if (mounted) {
                          setState(() {
                            registerUser.userName = input.toLowerCase().replaceAll(" ", "-");
                          });
                        }
                        const duration = Duration(milliseconds: 800);
                        if (searchOnStoppedTyping != null) {
                          setState(() => searchOnStoppedTyping?.cancel());
                        }
                        setState(() => searchOnStoppedTyping = Timer(duration, () {
                          if (registerUser.userName != "") usernameCheck();
                        }));
                      },
                    ),
                  ),
                  registerUser.userName != "" ? validUsername ? Icon(Icons.check_circle, color: SB_GREEN,) : Icon(Icons.cancel, color: SB_RED,) : Container()
                ],
              ),
              validUsername ? Text("Your username will be @${registerUser.userName}", style: TextStyle(fontSize: 16, color: SB_GREEN),) : registerUser.userName != "" ? Text("That username is taken!", style: TextStyle(fontSize: 16, color: SB_RED)): Container(),
              const Padding(padding: EdgeInsets.all(8)),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: CupertinoButton.filled(
                  child: const Text("Next"),
                  onPressed: () {
                    if (validUsername && registerUser.userName != "") {
                      _pageController.animateToPage(3, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
                    } else {
                      CoolAlert.show(
                          context: context,
                          type: CoolAlertType.error,
                          title: "Invalid Username",
                          widget: const Text("Unfortunately, someone already has that username. If you really want that name, reach out to us on Discord and we might be able to help."),
                          backgroundColor: SB_NAVY,
                          confirmBtnColor: SB_RED,
                          confirmBtnText: "OK"
                      );
                    }
                  },
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget buildPage3(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Nice! Let's continue creating your account.", style: TextStyle(fontSize: 18),),
              Row(
                children: [
                  const Text("First Name", style: TextStyle(color: Colors.black54, fontSize: 25),),
                  const Padding(padding: EdgeInsets.all(2)),
                  Expanded(
                    child: TextField(
                      controller: firstNameController,
                      textAlign: TextAlign.end,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Alex",
                      ),
                      textCapitalization: TextCapitalization.words,
                      keyboardType: TextInputType.name,
                      style: const TextStyle(fontSize: 25),
                      onChanged: (input) {
                        if (mounted) {
                          setState(() {
                            registerUser.firstName = input;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text("Last Name", style: TextStyle(color: Colors.black54, fontSize: 25),),
                  const Padding(padding: EdgeInsets.all(2)),
                  Expanded(
                    child: TextField(
                      controller: lastNameController,
                      textAlign: TextAlign.end,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Lopes",
                      ),
                      textCapitalization: TextCapitalization.words,
                      keyboardType: TextInputType.name,
                      style: const TextStyle(fontSize: 25),
                      onChanged: (input) {
                        if (mounted) {
                          setState(() {
                            registerUser.lastName = input;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text("Email", style: TextStyle(color: Colors.black54, fontSize: 25),),
                  const Padding(padding: EdgeInsets.all(2)),
                  Expanded(
                    child: TextField(
                      controller: emailController,
                      textAlign: TextAlign.end,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "alopes@ucsb.edu",
                      ),
                      textCapitalization: TextCapitalization.words,
                      keyboardType: TextInputType.name,
                      enabled: false,
                      style: const TextStyle(fontSize: 25),
                      onChanged: (input) {},
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text("Phone #", style: TextStyle(color: Colors.black54, fontSize: 25),),
                  const Padding(padding: EdgeInsets.all(2)),
                  Expanded(
                    child: TextField(
                      controller: phoneNumberController,
                      inputFormatters: [phoneMaskFormatter],
                      textAlign: TextAlign.end,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "(510) 123-4567",
                      ),
                      keyboardType: TextInputType.datetime,
                      style: const TextStyle(fontSize: 25),
                      onChanged: (input) {
                        if (mounted) {
                          setState(() {
                            registerUser.phoneNumber = input;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const Padding(padding: EdgeInsets.all(8)),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: CupertinoButton.filled(
                  child: const Text("Next"),
                  onPressed: () {
                    if (validUsername && registerUser.userName != "") {
                      if (registerUser.firstName != "" && registerUser.lastName != "") {
                        _pageController.animateToPage(4, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
                      }
                      else {
                        CoolAlert.show(
                            context: context,
                            type: CoolAlertType.error,
                            title: "Empty Name",
                            widget: const Text("Please enter your first and last name."),
                            backgroundColor: SB_NAVY,
                            confirmBtnColor: SB_RED,
                            confirmBtnText: "OK"
                        );
                      }
                    } else {
                      CoolAlert.show(
                          context: context,
                          type: CoolAlertType.error,
                          title: "Invalid Username",
                          widget: const Text("Unfortunately, someone already has that username. If you really want that name, reach out to us on Discord and we might be able to help."),
                          backgroundColor: SB_NAVY,
                          confirmBtnColor: SB_RED,
                          confirmBtnText: "OK",
                          onConfirmBtnTap: () {
                            router.pop(context);
                            _pageController.animateToPage(2, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
                          }
                      );
                    }
                  },
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget buildPage4(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Looking good! Just need a few more things.", style: TextStyle(fontSize: 18),),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Gender", style: TextStyle(color: Colors.black54, fontSize: 25),),
              const Padding(padding: EdgeInsets.all(2)),
              Card(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: DropdownButton<String>(
                    value: registerUser.gender,
                    alignment: Alignment.centerRight,
                    underline: Container(),
                    style: TextStyle(fontSize: 18, color: AdaptiveTheme.of(context).theme.textTheme.bodyLarge!.color),
                    items: const [
                      DropdownMenuItem(
                        value: "Male",
                        child: Text("Male"),
                      ),
                      DropdownMenuItem(
                        value: "Female",
                        child: Text("Female"),
                      ),
                      DropdownMenuItem(
                        value: "Other",
                        child: Text("Other"),
                      ),
                      DropdownMenuItem(
                        value: "Prefer not to say",
                        child: Text("Prefer not to say"),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(8),
                    onChanged: (item) {
                      if (mounted) {
                        setState(() {
                          registerUser.gender = item!;
                        });
                      }
                    },
                  ),
                ),
              )
            ],
          ),
          const Padding(padding: EdgeInsets.all(8)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Location Access", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
              Visibility(
                visible: registerUser.privacy.location.contains("ENABLED"),
                child: Icon(Icons.check_circle, color: SB_GREEN,)
              )
            ],
          ),
          const Padding(padding: EdgeInsets.all(2)),
          Row(
            children: const [
              Icon(Icons.near_me, color: Colors.black54, size: 60),
              Padding(padding: EdgeInsets.all(4)),
              Expanded(child: Text("We ask that you share your location with us in order to see nearby buildings, travel times, and navigation directions.", style: TextStyle(fontSize: 16),)),
            ],
          ),
          Visibility(
            visible: registerUser.privacy.location.contains("DISABLED"),
            child: CupertinoButton(
              onPressed: requestLocationAccess,
              child: const Text("Share Location"),
            ),
          ),
          const Padding(padding: EdgeInsets.all(8)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Push Notifications", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
              Visibility(
                  visible: registerUser.privacy.pushNotifications == "ENABLED",
                  child: Icon(Icons.check_circle, color: SB_GREEN,)
              )
            ],
          ),
          const Padding(padding: EdgeInsets.all(2)),
          Row(
            children: const [
              Icon(Icons.notifications_active_rounded, color: Colors.black54, size: 60),
              Padding(padding: EdgeInsets.all(4)),
              Expanded(child: Text("Enabling push notifications will allow us to send you important updates and reminders. You can update this setting at any time.", style: TextStyle(fontSize: 16),)),
            ],
          ),
          Visibility(
            visible: registerUser.privacy.pushNotifications == "DISABLED",
            child: CupertinoButton(
              onPressed: requestNotifications,
              child: const Text("Allow Notifications")
            ),
          ),
          const Padding(padding: EdgeInsets.all(8)),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: CupertinoButton.filled(
              child: const Text("Create Account"),
              onPressed: () {
                // registerInviteCode();
                registerUserAccount();
              }
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
                buildBetaPage(context),
                buildPage2(context),
                buildPage3(context),
                buildPage4(context)
              ],
            ),
          )
        ],
      ),
    );
  }
}
