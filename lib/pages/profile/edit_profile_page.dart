import 'dart:convert';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:extended_image/extended_image.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:storke_central/utils/auth_service.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/logger.dart';
import 'package:storke_central/utils/theme.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {

  TextEditingController bioController = TextEditingController();
  TextEditingController pronounController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();

  String editBio = currentUser.bio;
  String editPronouns = currentUser.pronouns;
  String editPhone = currentUser.phoneNumber;
  String editGender = currentUser.gender;

  var phoneMaskFormatter = MaskTextInputFormatter(
      mask: '(###) ###-####',
      filter: { "#": RegExp(r'[0-9]') },
      type: MaskAutoCompletionType.lazy
  );

  List<String> genderList = ["Male", "Female", "Other", "Prefer not to say"];

  bool loading = false;

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    initializeTextFields();
  }

  void initializeTextFields() {
    bioController.text = currentUser.bio;
    pronounController.text = currentUser.pronouns;
    phoneNumberController.text = currentUser.phoneNumber;
  }

  Future<void> saveUser() async {
    Trace trace = FirebasePerformance.instance.newTrace("saveUser()");
    await trace.start();
    currentUser.bio = editBio;
    currentUser.pronouns = editPronouns;
    currentUser.phoneNumber = editPhone;
    currentUser.gender = editGender;
    log("[edit_profile_page] ${currentUser.toJson()}");
    setState(() => loading = true);
    await AuthService.getAuthToken();
    await httpClient.post(Uri.parse("$API_HOST/users/${currentUser.id}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}, body: jsonEncode(currentUser));
    setState(() => loading = false);
    trace.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ACTIVE_ACCENT_COLOR,
        title: const Text(
          "Edit Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: ExtendedImage.network(
                currentUser.profilePictureURL,
                height: 125,
                width: 125,
                fit: BoxFit.cover,
                borderRadius: const BorderRadius.all(Radius.circular(125)),
                shape: BoxShape.rectangle,
              ),
            ),
            Text(
              "${currentUser.firstName} ${currentUser.lastName}",
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            Text(
              "@${currentUser.userName}",
              style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodySmall!.color),
            ),
            const Padding(padding: EdgeInsets.all(4)),
            TextField(
              controller: bioController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(8),
                hintText: "Write your bio here...",
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
              onChanged: (input) {
                editBio = input;
                print(editBio);
                print(currentUser.bio);
              },
            ),
            Row(
              children: [
                const Text("Pronouns", style: TextStyle(color: Colors.black54, fontSize: 22),),
                const Padding(padding: EdgeInsets.all(2)),
                Expanded(
                  child: TextField(
                    controller: pronounController,
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "they/them",
                    ),
                    style: const TextStyle(fontSize: 22),
                    onChanged: (input) {
                      editPronouns = input;
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Text("Phone #", style: TextStyle(color: Colors.black54, fontSize: 22),),
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
                    style: const TextStyle(fontSize: 22),
                    onChanged: (input) {
                      editPhone = input;
                    },
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Gender", style: TextStyle(color: Colors.black54, fontSize: 22),),
                const Padding(padding: EdgeInsets.all(2)),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: DropdownButton<String>(
                      value: editGender,
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
                            editGender = item!;
                          });
                        }
                      },
                    ),
                  ),
                )
              ],
            ),
            const Padding(padding: EdgeInsets.all(8)),
            SizedBox(
              width: double.infinity,
              child: loading ? Padding(
                padding: const EdgeInsets.all(8),
                  child: Center(
                    child: RefreshProgressIndicator(
                      color: Colors.white,
                      backgroundColor: ACTIVE_ACCENT_COLOR
                    )
                  )
                ) : CupertinoButton(
                  color: ACTIVE_ACCENT_COLOR,
                  onPressed: () {
                    saveUser();
                    router.pop(context);
                  },
                  child: const Text("Save Changes", style: TextStyle(color: Colors.white)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
