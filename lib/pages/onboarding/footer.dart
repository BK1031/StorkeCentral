import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class Footer extends StatefulWidget {
  const Footer({Key? key}) : super(key: key);

  @override
  State<Footer> createState() => _FooterState();
}

class _FooterState extends State<Footer> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Card(
        color: darkTheme.cardColor,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 250,
                    // color: Colors.greenAccent,
                    child: Column(
                      children: [
                        Text(
                          "Explore, Connect,\nThrive",
                          style: TextStyle(color: SB_LT_BLUE, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const Padding(padding: EdgeInsets.all(8)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(32),
                              onTap: () {
                                launchUrl(Uri.parse("https://twitter.com/storkecentral"));
                              },
                              child: Image.asset(
                                "images/icons/twitter.png",
                                color: Colors.white,
                                height: 32,
                              ),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(32),
                              onTap: () {
                                launchUrl(Uri.parse("https://instagram.com/storkecentral"));
                              },
                              child: Image.asset(
                                "images/icons/instagram.png",
                                color: Colors.white,
                                height: 32,
                              ),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(32),
                              onTap: () {
                                launchUrl(Uri.parse("https://tiktok.com/@storkecentral"));
                              },
                              child: Image.asset(
                                "images/icons/tiktok.png",
                                color: Colors.white,
                                height: 32,
                              ),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(32),
                              onTap: () {
                                launchUrl(Uri.parse("https://www.youtube.com/playlist?list=PLEjpQIEos_asOWcqOmBZMsAWdamz9b51e"));
                              },
                              child: Image.asset(
                                "images/icons/youtube.png",
                                color: Colors.white,
                                height: 32,
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CupertinoButton(
                            onPressed: () {},
                            padding: const EdgeInsets.all(0),
                            child: const Text(
                              "Product",
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: "Product Sans"),
                            ),
                          ),
                          CupertinoButton(
                            onPressed: () {
                              router.navigateTo(context, "/download", transition: TransitionType.fadeIn);
                            },
                            padding: const EdgeInsets.all(0),
                            child: const Text("Download", style: TextStyle(color: Colors.grey, fontSize: 16, fontFamily: "Product Sans")),
                          ),
                          CupertinoButton(
                            onPressed: () {
                              router.navigateTo(context, "/features", transition: TransitionType.fadeIn);
                            },
                            padding: const EdgeInsets.all(0),
                            child: const Text("Features", style: TextStyle(color: Colors.grey, fontSize: 16, fontFamily: "Product Sans")),
                          ),
                          CupertinoButton(
                            onPressed: () {
                              launchUrl(Uri.parse("https://storkecentral.statuspage.io"));
                            },
                            padding: const EdgeInsets.all(0),
                            child: const Text("Status", style: TextStyle(color: Colors.grey, fontSize: 16, fontFamily: "Product Sans")),
                          ),
                        ],
                      ),
                      const Padding(padding: EdgeInsets.all(16)),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CupertinoButton(
                            onPressed: () {},
                            padding: const EdgeInsets.all(0),
                            child: const Text(
                              "Resources",
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: "Product Sans"),
                            ),
                          ),
                          CupertinoButton(
                            onPressed: () {
                              launchUrl(Uri.parse("https://discord.storkecentr.al"));
                            },
                            padding: const EdgeInsets.all(0),
                            child: const Text("Support", style: TextStyle(color: Colors.grey, fontSize: 16, fontFamily: "Product Sans")),
                          ),
                          CupertinoButton(
                            onPressed: () {
                              launchUrl(Uri.parse("https://docs.storkecentr.al"));
                            },
                            padding: const EdgeInsets.all(0),
                            child: const Text("Documentation", style: TextStyle(color: Colors.grey, fontSize: 16, fontFamily: "Product Sans")),
                          ),
                          CupertinoButton(
                            onPressed: () {
                              launchUrl(Uri.parse("https://github.com/bk1031/storkecentral"));
                            },
                            padding: const EdgeInsets.all(0),
                            child: const Text("GitHub", style: TextStyle(color: Colors.grey, fontSize: 16, fontFamily: "Product Sans")),
                          ),
                        ],
                      ),
                      const Padding(padding: EdgeInsets.all(16)),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CupertinoButton(
                            onPressed: () {},
                            padding: const EdgeInsets.all(0),
                            child: const Text(
                              "Policies",
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: "Product Sans"),
                            ),
                          ),
                          CupertinoButton(
                            onPressed: () {
                              launchUrl(Uri.parse("https://docs.storkecentr.al"));
                            },
                            padding: const EdgeInsets.all(0),
                            child: const Text("Terms", style: TextStyle(color: Colors.grey, fontSize: 16, fontFamily: "Product Sans")),
                          ),
                          CupertinoButton(
                            onPressed: () {
                              launchUrl(Uri.parse("https://docs.storkecentr.al"));
                            },
                            padding: const EdgeInsets.all(0),
                            child: const Text("Privacy", style: TextStyle(color: Colors.grey, fontSize: 16, fontFamily: "Product Sans")),
                          ),
                          CupertinoButton(
                            onPressed: () {
                              showLicensePage(context: context);
                            },
                            padding: const EdgeInsets.all(0),
                            child: const Text("Licenses", style: TextStyle(color: Colors.grey, fontSize: 16, fontFamily: "Product Sans")),
                          ),
                        ],
                      ),
                      const Padding(padding: EdgeInsets.all(8)),
                    ],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0, top: 16),
                child: Divider(color: SB_LT_BLUE, thickness: 2, height: 0),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset("images/storke-sunset-icon/ios/iTunesArtwork@1x.png", width: 48, height: 48)
                      ),
                      const Padding(padding: EdgeInsets.all(8)),
                      Text(
                        "StorkeCentral v${appVersion.toString()}",
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white, side: const BorderSide(color: Colors.white, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          router.navigateTo(context, "/download", transition: TransitionType.fadeIn);
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Get Started", style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: "Product Sans"),),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
