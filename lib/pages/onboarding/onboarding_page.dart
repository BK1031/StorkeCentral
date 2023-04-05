import 'package:flutter/material.dart';
import 'package:storke_central/pages/onboarding/footer.dart';
import 'package:storke_central/pages/onboarding/header.dart';
import 'package:video_player/video_player.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _scrollController.position.isScrollingNotifier.addListener(() {
        if (!_scrollController.position.isScrollingNotifier.value) {
          if (_scrollController.position.pixels > 1 * (MediaQuery.of(context).size.width > 1500 ? 800 : MediaQuery.of(context).size.width > 800 ? 400 : 150) && !videoPlayed[1]) {
            _controller2.setVolume(0.0);
            _controller2.seekTo(const Duration(seconds: 0));
            _controller2.play();
            videoPlayed[1] = true;
          } else if (_scrollController.position.pixels > 2 * (MediaQuery.of(context).size.width > 1500 ? 800 : MediaQuery.of(context).size.width > 800 ? 400 : 150) && !videoPlayed[2]) {
            _controller3.setVolume(0.0);
            _controller3.seekTo(const Duration(seconds: 0));
            _controller3.play();
            videoPlayed[2] = true;
          } else if (_scrollController.position.pixels > 3 * (MediaQuery.of(context).size.width > 1500 ? 800 : MediaQuery.of(context).size.width > 800 ? 400 : 150) && !videoPlayed[3]) {
            _controller4.setVolume(0.0);
            _controller4.seekTo(const Duration(seconds: 0));
            _controller4.play();
            videoPlayed[3] = true;
          } else if (_scrollController.position.pixels > 4 * (MediaQuery.of(context).size.width > 1500 ? 800 : MediaQuery.of(context).size.width > 800 ? 400 : 150) && !videoPlayed[4]) {
            _controller5.setVolume(0.0);
            _controller5.seekTo(const Duration(seconds: 0));
            _controller5.play();
            videoPlayed[4] = true;
          } else if (_scrollController.position.pixels > 5 * (MediaQuery.of(context).size.width > 1500 ? 800 : MediaQuery.of(context).size.width > 800 ? 400 : 150) && !videoPlayed[5]) {
            _controller6.setVolume(0.0);
            _controller6.seekTo(const Duration(seconds: 0));
            _controller6.play();
            videoPlayed[5] = true;
          }
        }
      });
    });
    setupPlayers();
  }

  void setupPlayers() {
    _controller1 = VideoPlayerController.network("https://storkecentr.al/static/Landing1.mp4")..initialize().then((_) {
      setState(() {});
    });
    _controller1.setVolume(0.0);
    _controller1.play();

    _controller2 = VideoPlayerController.network("https://storkecentr.al/static/Landing2.mp4")..initialize().then((_) {
      setState(() {});
    });
    _controller3 = VideoPlayerController.network("https://storkecentr.al/static/Landing3.mp4")..initialize().then((_) {
      setState(() {});
    });
    _controller4 = VideoPlayerController.network("https://storkecentr.al/static/Landing4.mp4")..initialize().then((_) {
      setState(() {});
    });
    _controller5 = VideoPlayerController.network("https://storkecentr.al/static/Landing5.mp4")..initialize().then((_) {
      setState(() {});
    });
    _controller6 = VideoPlayerController.network("https://storkecentr.al/static/Landing6.mp4")..initialize().then((_) {
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
              // color: Colors.greenAccent,
              // width: MediaQuery.of(context).size.width > 1500 ? 1500 : MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.width > 1500 ? MediaQuery.of(context).size.height - 200 : null,
              child: _controller1.value.isInitialized
                  ? AspectRatio(
                aspectRatio: _controller1.value.aspectRatio,
                child: VideoPlayer(_controller1),
              )
                  : Container(),
            ),
            Container(
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
            Container(
              padding: MediaQuery.of(context).size.width > 800 ? const EdgeInsets.all(32) : const EdgeInsets.only(bottom: 32),
              // color: Colors.greenAccent,
              // width: MediaQuery.of(context).size.width > 1500 ? 1500 : MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.width > 1500 ? MediaQuery.of(context).size.height - 200 : null,
              child: _controller3.value.isInitialized
                  ? AspectRatio(
                aspectRatio: _controller3.value.aspectRatio,
                child: VideoPlayer(_controller3),
              )
                  : Container(),
            ),
            Container(
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
            Container(
              padding: MediaQuery.of(context).size.width > 800 ? const EdgeInsets.all(32) : const EdgeInsets.only(bottom: 32),
              // color: Colors.greenAccent,
              // width: MediaQuery.of(context).size.width > 1500 ? 1500 : MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.width > 1500 ? MediaQuery.of(context).size.height - 200 : null,
              child: _controller5.value.isInitialized
                  ? AspectRatio(
                aspectRatio: _controller5.value.aspectRatio,
                child: VideoPlayer(_controller5),
              )
                  : Container(),
            ),
            Container(
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
            const Footer(),
          ],
        ),
      )
    );
  }
}
