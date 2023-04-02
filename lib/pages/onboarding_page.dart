import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:storke_central/utils/theme.dart';
import 'package:video_player/video_player.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {

  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(
        'https://streamable.com/zdcu33.mp4')
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
      });
    _controller.setVolume(0.0);
    _controller.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
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
                            },
                            child: Text("Docs", style: TextStyle(color: Colors.white, fontSize: 24, fontFamily: "Product Sans"),),
                          ),
                          CupertinoButton(
                            onPressed: () {
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
            ),
            Container(
              padding: const EdgeInsets.all(32),
              child: _controller.value.isInitialized
                  ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
                  : Container(),
            )
          ],
        ),
      )
    );
  }
}
