import 'package:concentric_transition/page_view.dart';
import 'package:flutter/material.dart';
import 'package:storke_central/models/onboarding_data.dart';
import 'package:storke_central/pages/onboarding/register_page.dart';
import 'package:storke_central/utils/theme.dart';
import 'package:storke_central/widgets/page_card.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final List<OnboardingData> pages = [
    OnboardingData(
      icon: Icons.format_size,
      title: "Choose your\ninterests",
      textColor: Colors.white,
      bgColor: sbNavy,
    ),
    OnboardingData(
      icon: Icons.hdr_weak,
      title: "Drag and\ndrop to move",
      bgColor: sbGold,
    ),
    OnboardingData(
      icon: Icons.bubble_chart,
      title: "Local news\nstories",
      bgColor: sbNavy,
      textColor: Colors.white,
    ),
  ];

  List<Color> get colors => pages.map((p) => p.bgColor).toList();

  int imageFlex = 4;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: ConcentricPageView(
          colors: colors,
          opacityFactor: 1.0,
          scaleFactor: 0.0,
          radius: 30,
          curve: Curves.ease,
          duration: Duration(seconds: 2),
          verticalPosition: 0.7,
          // direction: Axis.vertical,
          itemCount: pages.length + 1,
//          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (index, value) {
            OnboardingData page = pages[index % pages.length];
            // For example scale or transform some widget by [value] param
            //            double scale = (1 - (value.abs() * 0.4)).clamp(0.0, 1.0);
            return (index != 3) ? Container(
              child: Theme(
                data: ThemeData(
                  textTheme: TextTheme(
                    headline6: TextStyle(
                      color: page.textColor,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Helvetica',
                      letterSpacing: 0.0,
                      fontSize: 17,
                    ),
                    subtitle2: TextStyle(
                      color: page.textColor,
                      fontWeight: FontWeight.w300,
                      fontSize: 18,
                    ),
                  ),
                ),
                child: PageCard(page: page),
              ),
            ) : RegisterPage();
          },
        ),
      ),
    );
  }
}