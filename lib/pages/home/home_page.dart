import 'dart:async';
import 'dart:convert';

import 'package:card_loading/card_loading.dart';
import 'package:extended_image/extended_image.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:storke_central/models/dining_hall.dart';
import 'package:storke_central/models/dining_hall_meal.dart';
import 'package:storke_central/models/news_article.dart';
import 'package:storke_central/models/user_schedule_item.dart';
import 'package:storke_central/utils/alert_service.dart';
import 'package:storke_central/utils/auth_service.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/logger.dart';
import 'package:storke_central/utils/string_extension.dart';
import 'package:storke_central/utils/theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    getNewsHeadline();
    getDining();
    getNextClass(userScheduleItems);
  }

  Future<void> getNewsHeadline() async {
    if (!offlineMode) {
      try {
        if (headlineArticle.id == "" || DateTime.now().difference(lastHeadlineArticleFetch).inMinutes > 60) {
          Trace trace = FirebasePerformance.instance.newTrace("getNewsHeadline()");
          await trace.start();
          loadOfflineHeadlines();
          await AuthService.getAuthToken();
          var response = await http.get(Uri.parse("$API_HOST/news/latest"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"});
          setState(() {
            headlineArticle = NewsArticle.fromJson(jsonDecode(utf8.decode(response.bodyBytes))["data"]);
          });
          lastHeadlineArticleFetch = DateTime.now();
          prefs.setString("HEADLINE_ARTICLE", jsonEncode(headlineArticle).toString());
          trace.stop();
        } else {
          log("[home_page] Using cached headline article, last fetch was ${DateTime.now().difference(lastHeadlineArticleFetch).inMinutes} minutes ago (minimum 60 minutes)");
        }
      } catch(e) {
        log("[home_page] ${e.toString()}", LogLevel.error);
        AlertService.showErrorSnackbar(context, "Failed to fetch news headline!");
      }
    } else {
      log("[home_page] Offline mode, searching cache for news...");
      loadOfflineHeadlines();
    }
  }

  Future<void> loadOfflineHeadlines() async {
    Trace trace = FirebasePerformance.instance.newTrace("loadOfflineHeadlines()");
    await trace.start();
    if (prefs.containsKey("HEADLINE_ARTICLE")) {
      setState(() {
        headlineArticle = NewsArticle.fromJson(jsonDecode(prefs.getString("HEADLINE_ARTICLE")!));
      });
    }
    trace.stop();
  }

  Future<void> getDining() async {
    if (!offlineMode) {
      try {
        Trace trace = FirebasePerformance.instance.newTrace("getDining()");
        await trace.start();
        await Future.delayed(const Duration(milliseconds: 100));
        await http.get(Uri.parse("$API_HOST/dining"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}).then((value) {
          setState(() {
            diningHallList = jsonDecode(utf8.decode(value.bodyBytes))["data"].map<DiningHall>((json) => DiningHall.fromJson(json)).toList();
            for (int i = 0; i < diningHallList.length; i++) {
              diningHallList[i].distanceFromUser = Geolocator.distanceBetween(diningHallList[i].latitude, diningHallList[i].longitude, currentPosition!.latitude, currentPosition!.longitude);
            }
            diningHallList.sort((a, b) => a.distanceFromUser.compareTo(b.distanceFromUser));
          });
        });
        getDiningMenus().then((_) {
          for (int i = 0; i < diningHallList.length; i++) {
            diningHallList[i].status = getDiningStatus(diningHallList[i].id);
          }
        });
        trace.stop();
      } catch(e) {
        log("[home_page] ${e.toString()}", LogLevel.error);
        AlertService.showErrorSnackbar(context, "Failed to fetch dining halls!");
      }
    } else {
      log("[home_page] Offline mode, searching cache for dining...");
    }
  }

  Future<void> getDiningMenus() async {
    DateTime queryDate = DateTime.now();
    // DateTime queryDate = DateTime.parse("2023-03-23 08:00:00.000");
    if (!offlineMode) {
      try {
        Trace trace = FirebasePerformance.instance.newTrace("getDiningMenus()");
        await trace.start();
        await Future.delayed(const Duration(milliseconds: 100));
        await http.get(Uri.parse("$API_HOST/dining/meals/${DateFormat("yyyy-MM-dd").format(queryDate)}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}).then((value) {
          setState(() {
            diningMealList = jsonDecode(utf8.decode(value.bodyBytes))["data"].map<DiningHallMeal>((json) => DiningHallMeal.fromJson(json)).toList();
          });
        });
        trace.stop();
      } catch(e) {
        log("[home_page] ${e.toString()}", LogLevel.error);
        AlertService.showErrorSnackbar(context, "Failed to fetch dining hours!");
      }
    } else {
      log("[home_page] Offline mode, searching cache for dining...");
    }
  }

  String getDiningStatus(String diningHallID) {
    DateTime now = DateTime.now();
    // DateTime now = DateTime.parse("2023-03-23 11:00:00.100");
    List<DiningHallMeal> meals = diningMealList.where((element) => element.diningHallID == diningHallID).toList();
    meals.sort((a, b) => a.open.compareTo(b.open));
    if (meals.isEmpty) return "Closed Today";
    // log("[home_page] Current Time: $now - ${now.timeZoneName}");
    for (int j = 0; j < meals.length; j++) {
      // log("[home_page] ${meals[j].name} from ${DateFormat("MM/dd h:mm a").format(meals[j].open.toLocal())} to ${DateFormat("h:mm a").format(meals[j].close.toLocal())}");
      if (now.isBefore(meals[j].open.toLocal())) {
        return "${meals[j].name.capitalize()} at ${DateFormat("h:mm a").format(meals[j].open.toLocal())}";
      } else if (now.isAfter(meals[j].open.toLocal()) && now.isBefore(meals[j].close.toLocal())) {
        return "${meals[j].name.capitalize()} until ${DateFormat("h:mm a").format(meals[j].close.toLocal())}";
      }
    }
    // TODO: Get next days breakfast
    return "Closed";
  }

  // Helper function to convert the days string that we get from GOLD to
  // a list of ints to represent the days of the week
  List<int> dayStringToInt(String dayString) {
    List<int> dayInts = [];
    for (int i = 0; i < dayString.length; i++) {
      if (dayString[i] == "M") {
        dayInts.add(1);
      } else if (dayString[i] == "T") {
        dayInts.add(2);
      } else if (dayString[i] == "W") {
        dayInts.add(3);
      } else if (dayString[i] == "R") {
        dayInts.add(4);
      } else if (dayString[i] == "F") {
        dayInts.add(5);
      } else if (dayString[i] == "S") {
        dayInts.add(6);
      } else if (dayString[i] == "U") {
        dayInts.add(7);
      }
    }
    return dayInts;
  }

  Future<void> getNextClass(List<UserScheduleItem> scheduleItems) async {
    // DateTime now = DateTime.now();
    DateTime now = DateTime.parse("2023-04-25 11:00:00.100");
    log("[home_page] Current day: ${now.weekday}");
    if (userScheduleItems.isNotEmpty) {
      scheduleItems.removeWhere((element) => !dayStringToInt(element.days).contains(now.weekday));
      log("[home_page] ${scheduleItems.length} classes today");
      userScheduleItems.sort((a, b) => a.startTime.compareTo(b.startTime));
      for (int i = 0; i < userScheduleItems.length; i++) {
        if (now.add(Duration(hours: int.parse(userScheduleItems[i].startTime.split(":")[0]), minutes: int.parse(userScheduleItems[i].startTime.split(":")[1]))).isAfter(DateTime.now())) {
          print(userScheduleItems[i].title);
          break;
        }
      }
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
                  headlineArticle.id == "" ? CardLoading(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    height: 175,
                    margin: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Card(
                                child: SizedBox(
                                  height: 20,
                                  width: 30,
                                ),
                              ),
                              Padding(padding: EdgeInsets.all(4)),
                              Card(
                                child: SizedBox(
                                  height: 20,
                                  width: 100,
                                ),
                              ),
                            ],
                          ),
                          const Padding(padding: EdgeInsets.all(8)),
                          const Card(
                            child: SizedBox(
                              height: 20,
                              width: 500,
                            ),
                          ),
                          const Card(
                            child: SizedBox(
                              height: 20,
                              width: 200,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ) : Container(
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
                              headlineArticle.pictureUrl != "" ? ExtendedImage.network(
                                headlineArticle.pictureUrl,
                                fit: BoxFit.cover,
                                height: 175,
                                width: MediaQuery.of(context).size.width,
                              ) : Container(color: Colors.black.withOpacity(0.8)),
                              Container(
                                color: Colors.black.withOpacity(0.4),
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        ExtendedImage.network(
                                          "https://dailynexus.com/wp-content/themes/dailynexus/graphics/nexuslogo.png",
                                          height: 35,
                                        ),
                                        const Padding(padding: EdgeInsets.all(4)),
                                        Text(
                                          "NEWS | ${DateFormat("MMMM d, yyyy").format(DateTime.now())}",
                                          style: const TextStyle(color: Colors.white, fontSize: 17)
                                        ),
                                      ],
                                    ),
                                    Text(utf8.decode(headlineArticle.title.codeUnits), style: const TextStyle(color: Colors.white, fontSize: 20)),
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
                  (diningHallList.isEmpty) ? SizedBox(
                    height: 150,
                    child: ListView.builder(
                      itemCount: 4,
                      itemBuilder: (BuildContext context, int i) {
                        return Padding(
                          padding: EdgeInsets.only(right: 4, left: (i == 0) ? 8 : 0),
                          child: SizedBox(
                            width: 150,
                            child: CardLoading(
                              borderRadius: const BorderRadius.all(Radius.circular(8)),
                              height: 150,
                              margin: const EdgeInsets.all(8),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Card(
                                      child: SizedBox(
                                        height: 20,
                                        width: 75,
                                      ),
                                    ),
                                    Card(
                                      child: SizedBox(
                                        height: 20,
                                        width: 150,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      scrollDirection: Axis.horizontal,
                    ),
                  ) : SizedBox(
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
                                  router.navigateTo(context, "/dining/${diningHallList[i].id}", transition: TransitionType.native);
                                },
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                                  child: Stack(
                                    children: [
                                      Hero(
                                        tag: "${diningHallList[i].id}-image",
                                        child: Image.asset(
                                          "images/${diningHallList[i].id}.jpeg",
                                          fit: BoxFit.cover,
                                          height: 150,
                                          width: 150,
                                        ),
                                      ),
                                      Container(
                                        height: 350.0,
                                        decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                                begin: FractionalOffset.topCenter,
                                                end: FractionalOffset.bottomCenter,
                                                colors: [
                                                  // Colors.grey.withOpacity(1.0),
                                                  Colors.grey.withOpacity(0.0),
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
                                                      tag: "${diningHallList[i].id}-title",
                                                      child: Material(
                                                        color: Colors.transparent,
                                                        child: Text(diningHallList[i].name, style: const TextStyle(color: Colors.white))
                                                      )
                                                  ),
                                                ),
                                                Text("${(diningHallList[i].distanceFromUser * UNITS_CONVERSION[PREF_UNITS]!).round()} ${PREF_UNITS.toLowerCase()}", style: const TextStyle(color: Colors.white, fontSize: 12),)
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
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16, top: 8, bottom: 8),
                    child: Row(
                      children: const [
                        Icon(Icons.calendar_view_day_rounded),
                        Padding(padding: EdgeInsets.all(4)),
                        Text("Up Next", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
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
                                  router.navigateTo(context, "/dining/${diningHallList[i].id}", transition: TransitionType.native);
                                },
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                                  child: Stack(
                                    children: [
                                      Hero(
                                        tag: "${diningHallList[i].id}-image",
                                        child: Image.asset(
                                          "images/${diningHallList[i].id}.jpeg",
                                          fit: BoxFit.cover,
                                          height: 150,
                                          width: 150,
                                        ),
                                      ),
                                      Container(
                                        height: 350.0,
                                        decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                                begin: FractionalOffset.topCenter,
                                                end: FractionalOffset.bottomCenter,
                                                colors: [
                                                  // Colors.grey.withOpacity(1.0),
                                                  Colors.grey.withOpacity(0.0),
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
                                                      tag: "${diningHallList[i].id}-title",
                                                      child: Material(
                                                          color: Colors.transparent,
                                                          child: Text(diningHallList[i].name, style: const TextStyle(color: Colors.white))
                                                      )
                                                  ),
                                                ),
                                                Text("${(diningHallList[i].distanceFromUser * UNITS_CONVERSION[PREF_UNITS]!).round()} ${PREF_UNITS.toLowerCase()}", style: const TextStyle(color: Colors.white, fontSize: 12),)
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
            visible: false,
            // visible: (DateTime.now().hour > 17 || DateTime.now().hour < 3) && (DateTime.now().weekday == 5 || DateTime.now().weekday == 6),
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
