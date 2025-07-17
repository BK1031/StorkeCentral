import 'package:extended_image/extended_image.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:storke_central/utils/auth_service.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with RouteAware {

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      routeObserver.subscribe(this, ModalRoute.of(context)!);
    });
    AuthService.verifyUserSession(context, "/profile");
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
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
              const Padding(padding: EdgeInsets.all(2)),
              Text(
                "@${currentUser.userName}",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const Padding(padding: EdgeInsets.all(4)),
              Text(
                currentUser.bio != "" ? currentUser.bio : "No bio",
                style: const TextStyle(fontSize: 18),
              ),
              const Padding(padding: EdgeInsets.all(8)),
              Container(
                padding: const EdgeInsets.only(left: 8, top: 8, right: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        color: Theme.of(context).cardColor,
                        onPressed: () {
                          router.navigateTo(context, "/profile/edit", transition: TransitionType.nativeModal).then((value) => setState(() {}));
                        },
                        child: Text("Edit Profile", style: TextStyle(color: Theme.of(context).textTheme.labelLarge!.color)),
                      ),
                    ),
                    const Padding(padding: EdgeInsets.all(4)),
                    Expanded(
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        color: Theme.of(context).cardColor,
                        onPressed: () {
                          router.navigateTo(context, "/settings", transition: TransitionType.native);
                        },
                        child: Text("Settings", style: TextStyle(color: Theme.of(context).textTheme.labelLarge!.color),),
                      ),
                    )
                  ],
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
                          "Friends",
                          style: TextStyle(color: ACTIVE_ACCENT_COLOR, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ListTile(
                        title: const Row(
                          children: [
                            Icon(Icons.person_add),
                            Padding(padding: EdgeInsets.all(4)),
                            Text("Add Friends"),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded),
                        onTap: () {
                          router.navigateTo(context, "/profile/friends/add", transition: TransitionType.native);
                        },
                      ),
                      ListTile(
                        title: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.group),
                                Padding(padding: EdgeInsets.all(4)),
                                Text("My Friends"),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded),
                        onTap: () {
                          router.navigateTo(context, "/profile/friends", transition: TransitionType.native);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Visibility(
                visible: currentUser.hasRole("PUBLIC_BETA_PARTICIPANT"),
                child: Container(
                  padding: const EdgeInsets.only(left: 8, top: 8, right: 8),
                  child: Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
                          child: Text(
                            "Public Beta",
                            style: TextStyle(color: ACTIVE_ACCENT_COLOR, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ListTile(
                          title: const Row(
                            children: [
                              Icon(Icons.person_add),
                              Padding(padding: EdgeInsets.all(4)),
                              Text("Invite Friends"),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded),
                          onTap: () {
                            router.navigateTo(context, "/profile/beta", transition: TransitionType.native);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.all(8),
                child: CupertinoButton(
                  color: SB_RED,
                  onPressed: () {
                    AuthService.signOut();
                    router.navigateTo(context, "/check-auth", transition: TransitionType.fadeIn, replace: true);
                  },
                  child: const Text("Sign out", style: TextStyle(color: Colors.white),),
                ),
              ),
              const Padding(padding: EdgeInsets.all(16)),
            ],
          ),
        ),
      ),
    );
  }
}
