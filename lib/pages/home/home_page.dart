import 'dart:async';
import 'dart:convert';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:storke_central/models/dining_hall.dart';
import 'package:storke_central/models/dining_hall_meal.dart';
import 'package:storke_central/models/news_article.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/logger.dart';
import 'package:storke_central/utils/string_extension.dart';
import 'package:storke_central/utils/theme.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  StreamSubscription<Position>? positionStream;
  Position? position;

  @override
  void initState() {
    super.initState();
    getNewsHeadline();
    getDining();
  }

  Future<void> getNewsHeadline() async {
    if (!offlineMode) {
      try {
        await Future.delayed(const Duration(milliseconds: 100));
        setState(() {
          selectedArticle = NewsArticle.fromJson({
            'headline': "Daily Nexus front page article",
            'byline': "Daily Nexus",
            'date': DateTime.now(),
            'excerpt': "The letter was published on Reddit on Oct. 26 following the Oct. 5 Design Review Committee (DRC) meeting.",
            'coverUrl': "https://i1.wp.com/dailynexus.s3.us-west-1.amazonaws.com/dailynexus/wp-content/uploads/2022/04/03135030/UCSBReturnsTuitions_DNFilePhoto.jpg",
            'articleUrl': "https://dailynexus.com",
          });
        });
      } catch(e) {
        CoolAlert.show(
            context: context,
            type: CoolAlertType.error,
            title: "Failed to retrieve news headlines!",
            text: e.toString(),
            backgroundColor: SB_NAVY,
            confirmBtnColor: SB_RED,
            confirmBtnText: "OK",
        );
      }
    } else {
      log("Offline mode, searching cache for news...");
    }
  }

  Future<void> getDining() async {
    if (!offlineMode) {
      try {
        await Future.delayed(const Duration(milliseconds: 100));
        diningHallList.clear();
        setState(() {
            diningHallList.add(DiningHall.fromJson({
              'name': "Dining Hall 1",
              'code': "carrillo",
              'hasSackMeal': false,
              'hasTakeOut': false,
              'hasDiningCam': true,
              'location': {'latitude': 0.0, 'longitude': 0.0}
            }));
            diningHallList.add(DiningHall.fromJson({
              'name': "Dining Hall 2",
              'code': "de-la-guerra",
              'hasSackMeal': false,
              'hasTakeOut': false,
              'hasDiningCam': true,
              'location': {'latitude': 0.0, 'longitude': 0.0}
            }));
            diningHallList.add(DiningHall.fromJson({
              'name': "Dining Hall 3",
              'code': "portola",
              'hasSackMeal': false,
              'hasTakeOut': false,
              'hasDiningCam': true,
              'location': {'latitude': 0.0, 'longitude': 0.0}
            }));
        });
      } catch(e) {
        CoolAlert.show(
            context: context,
            type: CoolAlertType.error,
            title: "Failed to retrieve dining information!",
            text: e.toString(),
            backgroundColor: SB_NAVY,
            confirmBtnColor: SB_RED,
            confirmBtnText: "OK",
        );
      }
    } else {
      log("Offline mode, searching cache for dining...");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    height: 175,
                    padding: const EdgeInsets.all(8),
                    child: Card(
                      child: GestureDetector(
                        onTap: () {
                          router.navigateTo(context, "/news/selected", transition: TransitionType.native);
                        },
                        child: ClipRRect(
                          borderRadius: const BorderRadius.all(Radius.circular(8)),
                          child: Stack(
                            children: [
                              // ExtendedImage.network(
                              //   selectedArticle.coverUrl,
                              //   fit: BoxFit.cover,
                              //   height: 175,
                              //   width: MediaQuery.of(context).size.width,
                              // ),
                              Container(
                                color: Colors.black.withOpacity(0.4),
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // ExtendedImage.network(
                                        //   "https://dailynexus.com/wp-content/themes/dailynexus/graphics/nexuslogo.png",
                                        //   height: 35,
                                        // ),
                                        Padding(padding: EdgeInsets.all(4)),
                                        Text("NEWS | ${DateFormat("yMMMMd").format(selectedArticle.date)}", style: const TextStyle(color: Colors.white, fontSize: 17)),
                                      ],
                                    ),
                                    Text(selectedArticle.headline, style: const TextStyle(color: Colors.white, fontSize: 20)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16, top: 8, bottom: 8),
                    child: Row(
                      children: const [
                        Icon(Icons.fastfood),
                        Padding(padding: EdgeInsets.all(4)),
                        Text("Dining", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      itemCount: diningHallList.length,
                      itemBuilder: (BuildContext context, int i) {
                        return Padding(
                          padding: EdgeInsets.only(right: 4, left: (i == 0) ? 8 : 0),
                          child: SizedBox(
                            width: 150,
                            child: Card(
                              child: GestureDetector(
                                onTap: () {
                                  selectedDiningHall = diningHallList[i];
                                  router.navigateTo(context, "/dining/${diningHallList[i].code}", transition: TransitionType.native);
                                },
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                                  child: Stack(
                                    children: [
                                      // Hero(
                                      //   tag: diningHallList[i].code,
                                      //   child: Image.asset(
                                      //     "images/${diningHallList[i].code}.jpeg",
                                      //     fit: BoxFit.cover,
                                      //     height: 150,
                                      //     width: 150,
                                      //   ),
                                      // ),
                                      Container(
                                        height: 350.0,
                                        decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                                begin: FractionalOffset.topCenter,
                                                end: FractionalOffset.bottomCenter,
                                                colors: [
                                                  Colors.grey.withOpacity(1.0),
                                                  // Colors.grey.withOpacity(0.0),
                                                  Colors.black,
                                                ],
                                                stops: const [0, 1]
                                            )
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Hero(
                                                      tag: diningHallList[i].name,
                                                      child: Text(diningHallList[i].name, style: const TextStyle(color: Colors.white),)
                                                  ),
                                                ),
                                                Text("${(diningHallList[i].distanceFromUser * UNITS_CONVERSION[PREF_UNITS]!).round()} m", style: const TextStyle(color: Colors.white, fontSize: 12),)
                                              ],
                                            ),
                                            Text(diningHallList[i].status, style: TextStyle(color: diningHallList[i].status.contains("until") ? Colors.green : diningHallList[i].status.contains("at") ? Colors.orangeAccent : diningHallList[i].status.contains("Closed") ? Colors.red : Colors.grey, fontSize: 12),)
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      scrollDirection: Axis.horizontal,
                    ),
                  )
                ],
              ),
            ),
          ),
          Visibility(
            // visible: true,
            visible: (DateTime.now().hour > 17 || DateTime.now().hour < 3) && (DateTime.now().weekday == 5 || DateTime.now().weekday == 6),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                color: SB_RED,
                child: InkWell(
                  onTap: () => router.navigateTo(context, "/overdose-response", transition: TransitionType.native),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.white,),
                        const Padding(padding: EdgeInsets.all(4)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text("Overdose Response", style: TextStyle(color: Colors.white, fontSize: 18),),
                              Padding(padding: EdgeInsets.all(2)),
                              Text("Stay safe out there! Check out the emergency response quick action guide.", style: TextStyle(color: Colors.white),)
                            ],
                          ),
                        ),
                        const Padding(padding: EdgeInsets.all(4)),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white,),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
