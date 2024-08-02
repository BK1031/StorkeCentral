import 'package:flutter/material.dart';
import 'package:storke_central/pages/onboarding/footer.dart';
import 'package:storke_central/pages/onboarding/header.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {

  final ScrollController _scrollController = ScrollController();
  late VideoPlayerController _controller1;
  late VideoPlayerController _controller2;
  late VideoPlayerController _controller3;
  late VideoPlayerController _controller4;
  late VideoPlayerController _controller5;
  late VideoPlayerController _controller6;

  List<bool> videoPlayed = [false, false, false, false, false, false];

  @override
  void initState() {
    super.initState();
    setupPlayers();
  }

  void setupPlayers() {
    _controller1 = VideoPlayerController.networkUrl(Uri.parse("https://storkecentr.al/static/Landing1.mp4"))..initialize().then((_) {
      setState(() {});
    });
    _controller1.setVolume(0.0);
    _controller1.play();

    _controller2 = VideoPlayerController.networkUrl(Uri.parse("https://storkecentr.al/static/Landing2.mp4"))..initialize().then((_) {
      setState(() {});
    });
    _controller3 = VideoPlayerController.networkUrl(Uri.parse("https://storkecentr.al/static/Landing3.mp4"))..initialize().then((_) {
      setState(() {});
    });
    _controller4 = VideoPlayerController.networkUrl(Uri.parse("https://storkecentr.al/static/Landing4.mp4"))..initialize().then((_) {
      setState(() {});
    });
    _controller5 = VideoPlayerController.networkUrl(Uri.parse("https://storkecentr.al/static/Landing5.mp4"))..initialize().then((_) {
      setState(() {});
    });
    _controller6 = VideoPlayerController.networkUrl(Uri.parse("https://storkecentr.al/static/Landing6.mp4"))..initialize().then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            const Header(),
            Container(
              padding: MediaQuery.of(context).size.width > 800 ? const EdgeInsets.all(32) : const EdgeInsets.only(bottom: 32),
              // color: Colors.purpleAccent,
              // width: MediaQuery.of(context).size.width > 1500 ? 1500 : MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.width > 1500 ? MediaQuery.of(context).size.height - 200 : null,
              child: _controller1.value.isInitialized
                  ? AspectRatio(
                aspectRatio: _controller1.value.aspectRatio,
                child: VideoPlayer(_controller1),
              )
                  : Container(),
            ),
            VisibilityDetector(
              key: const Key('Landing2'),
              onVisibilityChanged: (visibilityInfo) {
                var visiblePercentage = visibilityInfo.visibleFraction * 100;
                if (visiblePercentage > 80 && !videoPlayed[1]) {
                  _controller2.setVolume(0.0);
                  _controller2.seekTo(const Duration(seconds: 0));
                  _controller2.play();
                  videoPlayed[1] = true;
                }
              },
              child: Container(
                padding: MediaQuery.of(context).size.width > 800 ? const EdgeInsets.all(32) : const EdgeInsets.only(bottom: 32),
                // color: Colors.greenAccent,
                // width: MediaQuery.of(context).size.width > 1500 ? 1500 : MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.width > 1500 ? MediaQuery.of(context).size.height - 200 : null,
                child: _controller2.value.isInitialized
                    ? AspectRatio(
                  aspectRatio: _controller2.value.aspectRatio,
                  child: VideoPlayer(_controller2),
                )
                    : Container(),
              ),
            ),
            VisibilityDetector(
              key: const Key('Landing3'),
              onVisibilityChanged: (visibilityInfo) {
                var visiblePercentage = visibilityInfo.visibleFraction * 100;
                if (visiblePercentage > 80 && !videoPlayed[2]) {
                  _controller3.setVolume(0.0);
                  _controller3.seekTo(const Duration(seconds: 0));
                  _controller3.play();
                  videoPlayed[2] = true;
                }
              },
              child: Container(
                padding: MediaQuery.of(context).size.width > 800 ? const EdgeInsets.all(32) : const EdgeInsets.only(bottom: 32),
                // color: Colors.orangeAccent,
                // width: MediaQuery.of(context).size.width > 1500 ? 1500 : MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.width > 1500 ? MediaQuery.of(context).size.height - 200 : null,
                child: _controller3.value.isInitialized
                    ? AspectRatio(
                  aspectRatio: _controller3.value.aspectRatio,
                  child: VideoPlayer(_controller3),
                )
                    : Container(),
              ),
            ),
            VisibilityDetector(
              key: const Key('Landing4'),
              onVisibilityChanged: (visibilityInfo) {
                var visiblePercentage = visibilityInfo.visibleFraction * 100;
                if (visiblePercentage > 80 && !videoPlayed[3]) {
                  _controller4.setVolume(0.0);
                  _controller4.seekTo(const Duration(seconds: 0));
                  _controller4.play();
                  videoPlayed[3] = true;
                }
              },
              child: Container(
                padding: MediaQuery.of(context).size.width > 800 ? const EdgeInsets.all(32) : const EdgeInsets.only(bottom: 32),
                // color: Colors.greenAccent,
                // width: MediaQuery.of(context).size.width > 1500 ? 1500 : MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.width > 1500 ? MediaQuery.of(context).size.height - 200 : null,
                child: _controller4.value.isInitialized
                    ? AspectRatio(
                  aspectRatio: _controller4.value.aspectRatio,
                  child: VideoPlayer(_controller4),
                )
                    : Container(),
              ),
            ),
            VisibilityDetector(
              key: const Key('Landing5'),
              onVisibilityChanged: (visibilityInfo) {
                var visiblePercentage = visibilityInfo.visibleFraction * 100;
                if (visiblePercentage > 80 && !videoPlayed[4]) {
                  _controller5.setVolume(0.0);
                  _controller5.seekTo(const Duration(seconds: 0));
                  _controller5.play();
                  videoPlayed[4] = true;
                }
              },
              child: Container(
                padding: MediaQuery.of(context).size.width > 800 ? const EdgeInsets.all(32) : const EdgeInsets.only(bottom: 32),
                // color: Colors.orangeAccent,
                // width: MediaQuery.of(context).size.width > 1500 ? 1500 : MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.width > 1500 ? MediaQuery.of(context).size.height - 200 : null,
                child: _controller5.value.isInitialized
                    ? AspectRatio(
                  aspectRatio: _controller5.value.aspectRatio,
                  child: VideoPlayer(_controller5),
                )
                    : Container(),
              ),
            ),
            VisibilityDetector(
              key: const Key('Landing6'),
              onVisibilityChanged: (visibilityInfo) {
                var visiblePercentage = visibilityInfo.visibleFraction * 100;
                if (visiblePercentage > 80 && !videoPlayed[5]) {
                  _controller6.setVolume(0.0);
                  _controller6.seekTo(const Duration(seconds: 0));
                  _controller6.play();
                  videoPlayed[5] = true;
                }
              },
              child: Container(
                padding: MediaQuery.of(context).size.width > 800 ? const EdgeInsets.all(32) : const EdgeInsets.only(bottom: 32),
                // color: Colors.greenAccent,
                // width: MediaQuery.of(context).size.width > 1500 ? 1500 : MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.width > 1500 ? MediaQuery.of(context).size.height - 200 : null,
                child: _controller6.value.isInitialized
                    ? AspectRatio(
                  aspectRatio: _controller6.value.aspectRatio,
                  child: VideoPlayer(_controller6),
                )
                    : Container(),
              ),
            ),
            const Footer(),
          ],
        ),
      )
    );
  }
}
