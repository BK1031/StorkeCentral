import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:storke_central/pages/home/home_page.dart';
import 'package:storke_central/pages/maps/maps_page.dart';
import 'package:storke_central/pages/profile/profile_page.dart';
import 'package:storke_central/pages/schedule/schedule_page.dart';
import 'package:storke_central/utils/theme.dart';

class TabBarController extends StatefulWidget {
  const TabBarController({Key? key}) : super(key: key);

  @override
  _TabBarControllerState createState() => _TabBarControllerState();
}

class _TabBarControllerState extends State<TabBarController> {

  final PageController _pageController = PageController();
  int _currPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
        animationDuration: const Duration(milliseconds: 200),
        backgroundColor: Colors.transparent,
        color: Theme.of(context).cardColor,
        index: _currPage,
        items: <Widget>[
          Image.asset("images/icons/home-icon.png", height: 30, color: Theme.of(context).textTheme.bodyText1!.color),
          Image.asset("images/icons/calendar/calendar-${DateTime.now().day}.png", height: 30),
          Image.asset("images/icons/map-icon.png", height: 30),
          Image.asset("images/icons/user-icon.png", height: 30),
        ],
        onTap: (index) {
          setState(() {
            _currPage = index;
          });
          _pageController.animateToPage(index, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
        },
      ),
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: _pageController,
        onPageChanged: (page) {
          setState(() {
            _currPage = page;
          });
        },
        children: const [
          HomePage(),
          SchedulePage(),
          MapsPage(),
          ProfilePage()
        ],
      ),
    );
  }
}
