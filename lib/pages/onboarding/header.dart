import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class Header extends StatefulWidget {
  const Header({Key? key}) : super(key: key);

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Card(
        color: darkTheme.cardColor,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset("images/storke-sunset-icon/ios/iTunesArtwork@1x.png", width: 64, height: 64)
                  ),
                  const Padding(padding: EdgeInsets.all(8)),
                  const Text(
                    "StorkeCentral",
                    style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  CupertinoButton(
                    onPressed: () {
                      router.navigateTo(context, "/beta", transition: TransitionType.fadeIn);
                    },
                    child: Text("Beta", style: TextStyle(color: Colors.white, fontSize: 24, fontFamily: "Product Sans"),),
                  ),
                  CupertinoButton(
                    onPressed: () {
                      router.navigateTo(context, "/features", transition: TransitionType.fadeIn);
                    },
                    child: Text("Features", style: TextStyle(color: Colors.white, fontSize: 24, fontFamily: "Product Sans"),),
                  ),
                  CupertinoButton(
                    onPressed: () {
                      launchUrl(Uri.parse("https://docs.storkecentr.al"));
                    },
                    child: Text("Docs", style: TextStyle(color: Colors.white, fontSize: 24, fontFamily: "Product Sans"),),
                  ),
                  const Padding(padding: EdgeInsets.all(8)),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white, side: BorderSide(color: Colors.white, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      router.navigateTo(context, "/download", transition: TransitionType.fadeIn);
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("Get Started", style: TextStyle(color: Colors.white, fontSize: 24, fontFamily: "Product Sans"),),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
