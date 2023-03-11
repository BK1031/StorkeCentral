import 'dart:async';
import 'dart:convert';

import 'package:cool_alert/cool_alert.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:storke_central/models/dining_hall.dart';
import 'package:storke_central/models/dining_hall_meal.dart';
import 'package:storke_central/pages/home/dining/dining_hall_camera_page.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/string_extension.dart';
import 'package:storke_central/utils/theme.dart';
import 'package:storke_central/widgets/sliver_app_bar_delegate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/dining_hall_menu_item.dart';

// ignore: must_be_immutable
class DiningHallPage extends StatefulWidget {
  String id;
  DiningHallPage(this.id, {Key? key}) : super(key: key);
  @override
  // ignore: no_logic_in_create_state
  _DiningHallPageState createState() => _DiningHallPageState(id);
}

class _DiningHallPageState extends State<DiningHallPage> with SingleTickerProviderStateMixin {

  StreamSubscription<Position>? positionStream;
  Position? position;

  int currPage = 0;
  PageController _pageController = PageController();

  _DiningHallPageState(String id) {
    selectedDiningHall.code = id;
  }

  @override
  void initState() {
    super.initState();
    _determinePosition();
    getDiningHall();
  }

  @override
  void dispose() {
    super.dispose();
    positionStream?.cancel();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {}
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;
    positionStream = Geolocator.getPositionStream().listen((Position position) {
      // print(position == null ? 'Unknown' : position.latitude.toString() + ', ' + position.longitude.toString());
      if (mounted) {
        setState(() {
          this.position = position;
          selectedDiningHall.distanceFromUser = Geolocator.distanceBetween(selectedDiningHall.latitude, selectedDiningHall.longitude, position.latitude, position.longitude);
        });
      }
    });
  }

  Future<void> getDiningHall() async {
    try {
      http.get(Uri.parse("https://api.ucsb.edu/dining/commons/v1/${selectedDiningHall.code}"), headers: {"ucsb-api-key": UCSB_API_KEY}).then((value) {
        var diningHallJson = jsonDecode(value.body);
        setState(() {
          selectedDiningHall = DiningHall.fromJson(diningHallJson);
        });
        getDiningHallTimes();
      });
    } catch(e) {
      CoolAlert.show(
          context: context,
          type: CoolAlertType.error,
          title: "Failed to retrieve dining hall!",
          text: e.toString()
      );
    }
  }

  Future<void> getDiningHallTimes() async {
    try {
      http.get(Uri.parse("https://api.ucsb.edu/dining/commons/v1/hours/${DateFormat("yyyy-MM-dd").format(DateTime.now())}/${selectedDiningHall.code}"), headers: {"ucsb-api-key": UCSB_API_KEY}).then((value) {
        var diningHallJson = jsonDecode(value.body);
        for (int i = 0; i < diningHallJson.length; i++) {
          if (diningHallJson[i]["open"] != null) {
            DiningHallMeal meal = DiningHallMeal.fromJson(diningHallJson[i]);
            selectedDiningHall.meals.add(meal);
          }
        }
        getDiningMenu();
        setState(() {
          selectedDiningHall.status = getDiningHallStatus(selectedDiningHall);
        });
      });
    } catch(e) {
      CoolAlert.show(
          context: context,
          type: CoolAlertType.error,
          title: "Failed to retrieve dining halls!",
          text: e.toString()
      );
    }
  }

  String getDiningHallStatus(DiningHall diningHall) {
    // Calculate dining hall status
    for (int i = 0; i < diningHall.meals.length; i++) {
      print("${diningHall.meals[i].mealCode} ${diningHall.meals[i].open}");
      if (diningHall.meals[i].open.isAfter(DateTime.now())) {
        return ("${diningHall.meals[i].mealCode.capitalize()} at ${DateFormat("jm").format(diningHall.meals[i].open)}");
      }
      else if (diningHall.meals[i].open.isBefore(DateTime.now()) && diningHall.meals[i].close.isAfter(DateTime.now())) {
        return ("${diningHall.meals[i].mealCode.capitalize()} to ${DateFormat("jm").format(diningHall.meals[i].close)}");
      }
    }
    // TODO: get next days breakfast
    return "Closed Today";
  }


  Future<void> getDiningMenu() async {
    try {
      for (int i = 0; i < selectedDiningHall.meals.length; i++) {
        http.get(Uri.parse("https://api.ucsb.edu/dining/menu/v1/${DateFormat("yyyy-MM-dd").format(DateTime.now())}/${selectedDiningHall.code}/${selectedDiningHall.meals[i].mealCode}"), headers: {"ucsb-api-key": UCSB_API_KEY}).then((value) {
          var diningHallJson = jsonDecode(value.body);
          for (int j = 0; j < diningHallJson.length; j++) {
            setState(() {
              selectedDiningHall.meals[i].menuItems.add(DiningHallMenuItem.fromJson(diningHallJson[j]));
            });
          }
        });
      }
    } catch(e) {
      CoolAlert.show(
          context: context,
          type: CoolAlertType.error,
          title: "Failed to retrieve dining halls!",
          text: e.toString()
      );
    }
  }

  void showDiningCamera() {
    showDialog(
        context: context,
        builder: (builder) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: EdgeInsets.zero,
            content: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                  height: 185,
                  child: DiningHallCameraPage(selectedDiningHall.code)
              ),
            )
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                expandedHeight: 175.0,
                floating: false,
                pinned: true,
                actions: [
                  CupertinoButton(
                    padding: const EdgeInsets.only(right: 16),
                    onPressed: () {
                      showDiningCamera();
                      // router.navigateTo(context, "/dining/${selectedDiningHall.code}/cam", transition: TransitionType.nativeModal);
                    },
                    child: Image.asset("images/icons/camera-icon.png", height: 30, color: Colors.white),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Hero(
                      tag: selectedDiningHall.name,
                      child: Material(
                          color: Colors.transparent,
                          child: Text(
                              selectedDiningHall.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)
                          )
                      )
                  ),
                  background: Hero(
                    tag: selectedDiningHall.code,
                    child: Image.asset(
                      'images/${selectedDiningHall.code}.jpeg',
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),
            ];
          },
          body: Column(
            children: [
              // Padding(
              //   padding: const EdgeInsets.all(16.0),
              //   child: Row(
              //     children: [
              //       Expanded(
              //         child: CupertinoButton(
              //           padding: EdgeInsets.zero,
              //           onPressed: () {},
              //           color: Theme.of(context).cardColor,
              //           child: Icon(Icons.check_box_outline_blank, color: Theme.of(context).iconTheme.color),
              //         ),
              //       ),
              //       const Padding(padding: EdgeInsets.all(8),),
              //       Expanded(
              //         child: CupertinoButton(
              //           padding: EdgeInsets.zero,
              //           onPressed: () {},
              //           color: Theme.of(context).cardColor,
              //           child: Icon(Icons.check_box_outline_blank, color: Theme.of(context).iconTheme.color),
              //         ),
              //       ),
              //       const Padding(padding: EdgeInsets.all(8),),
              //       Expanded(
              //         child: CupertinoButton(
              //           padding: EdgeInsets.zero,
              //           onPressed: () {
              //             router.navigateTo(context, "/dining/${selectedDiningHall.code}/cam", transition: TransitionType.nativeModal);
              //           },
              //           color: Theme.of(context).cardColor,
              //           child: Image.asset("images/camera-icon.png", height: 30, color: Theme.of(context).iconTheme.color),
              //         ),
              //       ),
              //       const Padding(padding: EdgeInsets.all(8),),
              //       Expanded(
              //         child: CupertinoButton(
              //           padding: EdgeInsets.zero,
              //           onPressed: () async {
              //             await canLaunch("instagram://user?username=${DINING_HALL_IG[selectedDiningHall.code]!}") ? launch("instagram://user?username=${DINING_HALL_IG[selectedDiningHall.code]!}") : launch("https://instagram.com/${DINING_HALL_IG[selectedDiningHall.code]!}");
              //           },
              //           color: Theme.of(context).cardColor,
              //           child: Image.asset("images/instagram-icon.png", height: 30, color: Theme.of(context).iconTheme.color),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16, top: 16),
                child: Row(
                  children: [
                    Icon(Icons.restaurant),
                    Padding(padding: EdgeInsets.all(4)),
                    Text("Menu (${selectedDiningHall.status})", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                child: Card(
                  color: Theme.of(context).cardColor,
                  child: Row(
                      children: selectedDiningHall.meals.map((e) => Expanded(
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          color: e.mealCode == selectedDiningHall.meals[currPage].mealCode ? sbNavy : Colors.transparent,
                          child: Text(
                            e.mealCode.capitalize(),
                            style: TextStyle(color: e.mealCode == selectedDiningHall.meals[currPage].mealCode ? Colors.white : sbNavy),
                          ),
                          onPressed: () {
                            currPage = selectedDiningHall.meals.indexOf(e);
                            _pageController.animateToPage(currPage, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
                          },
                        ),
                      )).toList()
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  itemCount: selectedDiningHall.meals.length,
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      currPage = index;
                    });
                  },
                  itemBuilder: (context, position) {
                    return ListView.builder(
                      itemCount: selectedDiningHall.meals[position].menuItems.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Card(
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(selectedDiningHall.meals[position].menuItems[index].name),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
