// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';

import 'package:card_loading/card_loading.dart';
import 'package:extended_image/extended_image.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:storke_central/models/dining_hall.dart';
import 'package:storke_central/models/dining_hall_meal.dart';
import 'package:storke_central/models/news_article.dart';
import 'package:storke_central/models/up_next_schedule_item.dart';
import 'package:storke_central/models/waitz_building.dart';
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
    getWaitz();
    Future.delayed(const Duration(milliseconds: 100), () => getUpNextFriends());
  }

  Future<void> getNewsHeadline() async {
    if (!offlineMode) {
      try {
        if (headlineArticle.id == "" || DateTime.now().difference(lastHeadlineArticleFetch).inMinutes > 60) {
          Trace trace = FirebasePerformance.instance.newTrace("getNewsHeadline()");
          await trace.start();
          loadOfflineHeadlines();
          await AuthService.getAuthToken();
          var response = await httpClient.get(Uri.parse("$API_HOST/news/latest"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"});
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
        await httpClient.get(Uri.parse("$API_HOST/dining"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}).then((value) {
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
        await httpClient.get(Uri.parse("$API_HOST/dining/meals/${DateFormat("yyyy-MM-dd").format(queryDate)}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}).then((value) {
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

  Future<void> getUpNextFriends() async {
    if (!offlineMode) {
      if (upNextSchedules.isEmpty || DateTime.now().difference(lastUpNextFetch).inMinutes > 5) {
        upNextSchedules.clear();
        // Handle current users up next items
        getUserUpNext(currentUser.id).then((items) async {
          UpNextScheduleItem scheduleItem = await getNextClass(items);
          if (scheduleItem.status != "") {
            setState(() {
              upNextSchedules.add(scheduleItem);
            });
          }
        });
        // Handle friends up next items
        // If the user has more than 7 friends, only get up next for 2/3 of them
        for (int i = 0; (friends.length > 7) ? i < friends.length * 2/3 : i < friends.length; i++) {
          getUserUpNext(friends[i].user.id).then((items) async {
            print("Getting up next for ${friends[i].user.id}");
            UpNextScheduleItem scheduleItem = await getNextClass(items);
            if (scheduleItem.status != "") {
              setState(() {
                upNextSchedules.add(scheduleItem);
              });
            }
          });
        }
        lastUpNextFetch = DateTime.now();
      } else {
        log("[home_page] Using cached up next schedules, last fetch was ${DateTime.now().difference(lastUpNextFetch).inMinutes} minutes ago (minimum 15 minutes)");
      }
    } else {
      log("[home_page] Offline mode, not displaying up next schedules");
    }
  }

  Future<List<UpNextScheduleItem>> getUserUpNext(String userID) async {
    Trace trace = FirebasePerformance.instance.newTrace("getUserUpNext()");
    await trace.start();
    List<UpNextScheduleItem> scheduleItems = [];
    try {
      await AuthService.getAuthToken();
      await httpClient.get(Uri.parse("$API_HOST/users/schedule/$userID/${currentQuarter.id}/next"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}).then((value) {
        if (jsonDecode(utf8.decode(value.bodyBytes))["data"].length != 0) {
          scheduleItems = jsonDecode(utf8.decode(value.bodyBytes))["data"].map<UpNextScheduleItem>((json) => UpNextScheduleItem.fromJson(json)).toList();
        }
      });
      for (var element in scheduleItems) {
        if (userID == currentUser.id) {
          element.user = currentUser;
        } else {
          element.user = friends.firstWhere((friend) => friend.user.id == userID).user;
        }
      }
    } catch(e) {
      log("[home_page] ${e.toString()}", LogLevel.error);
      // AlertService.showErrorSnackbar(context, "Failed to fetch up next!");
    }
    trace.stop();
    return scheduleItems;
  }

  Future<UpNextScheduleItem> getNextClass(List<UpNextScheduleItem> scheduleItems) async {
    UpNextScheduleItem returnItem = UpNextScheduleItem();
    if (scheduleItems.isNotEmpty) {
      scheduleItems[0].user.id == currentUser.id ? returnItem.user = currentUser : returnItem.user = friends.firstWhere((element) => element.user.id == scheduleItems[0].user.id).user;
      scheduleItems.sort((a, b) => a.startTime.compareTo(b.startTime));
      for (int i = 0; i < scheduleItems.length; i++) {
        if (scheduleItems[i].endTime.isAfter(DateTime.now())) {
          returnItem = scheduleItems[i];
          if (scheduleItems[i].startTime.isAfter(DateTime.now())) {
            returnItem.status = "at";
          } else {
            returnItem.status = "until";
          }
          return returnItem;
        }
      }
      returnItem.status = "done";
    }
    return returnItem;
  }

  Future<void> getWaitz() async {
    if (!offlineMode) {
      try {
        if (waitzBuildings.isEmpty || DateTime.now().difference(lastWaitzFetch).inMinutes > 60) {
          Trace trace = FirebasePerformance.instance.newTrace("getWaitz()");
          await trace.start();
          var response = await httpClient.get(Uri.parse("https://waitz.io/live/ucsb"));
          setState(() {
            waitzBuildings = jsonDecode(response.body)["data"].map<WaitzBuilding>((json) => WaitzBuilding.fromJson(json)).toList();
          });
          lastWaitzFetch = DateTime.now();
          trace.stop();
        } else {
          log("[home_page] Using cached waitz data, last fetch was ${DateTime.now().difference(lastWaitzFetch).inMinutes} minutes ago (minimum 60 minutes)");
        }
      } catch(e) {
        log("[home_page] ${e.toString()}", LogLevel.error);
        AlertService.showErrorSnackbar(context, "Failed to fetch waitz data!");
      }
    } else {
      log("[home_page] Offline mode, no waitz data to display!", LogLevel.warn);
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
                              child: InkWell(
                                borderRadius: const BorderRadius.all(Radius.circular(8)),
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
                  Visibility(
                    visible: friends.isNotEmpty,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16, top: 8, bottom: 8),
                      child: Row(
                        children: const [
                          Icon(Icons.calendar_view_day_rounded),
                          Padding(padding: EdgeInsets.all(4)),
                          Text("Up Next", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
                        ],
                      ),
                    ),
                  ),
                  Visibility(
                    visible: friends.isNotEmpty,
                    child: (upNextSchedules.isEmpty) ? SizedBox(
                      height: 100,
                      child: ListView.builder(
                        itemCount: 4,
                        itemBuilder: (BuildContext context, int i) {
                          return Padding(
                            padding: EdgeInsets.only(right: 4, left: (i == 0) ? 8 : 0),
                            child: SizedBox(
                              width: 175,
                              child: CardLoading(
                                borderRadius: const BorderRadius.all(Radius.circular(8)),
                                height: 150,
                                margin: const EdgeInsets.all(8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: const [
                                          Card(
                                            shape: CircleBorder(),
                                            child: SizedBox(
                                              height: 25,
                                              width: 25,
                                            ),
                                          ),
                                          Padding(padding: EdgeInsets.all(4)),
                                          Card(
                                            child: SizedBox(
                                              height: 20,
                                              width: 75,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Padding(padding: EdgeInsets.all(2)),
                                      const Card(
                                        child: SizedBox(
                                          height: 20,
                                          width: 75,
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
                      height: 100,
                      child: ListView.builder(
                        itemCount: upNextSchedules.length,
                        itemBuilder: (BuildContext context, int i) {
                          return Padding(
                            padding: EdgeInsets.only(right: 4, left: (i == 0) ? 8 : 0),
                            child: SizedBox(
                              width: 175,
                              child: Card(
                                child: InkWell(
                                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                                  onTap: () {
                                    if (upNextSchedules[i].user.id == currentUser.id && upNextSchedules[i].status != "done") {
                                      router.navigateTo(context, "/schedule/view/${upNextSchedules[i].title}", transition: TransitionType.native);
                                    } else {
                                      router.navigateTo(context, "/schedule/user/${upNextSchedules[i].user.id}", transition: TransitionType.native);
                                    }
                                  },
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                                    child: Stack(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  ClipRRect(
                                                    borderRadius: const BorderRadius.all(Radius.circular(64)),
                                                    child: ExtendedImage.network(
                                                      upNextSchedules[i].user.profilePictureURL,
                                                      height: 30,
                                                    ),
                                                  ),
                                                  const Padding(padding: EdgeInsets.all(4)),
                                                  Text(
                                                    upNextSchedules[i].user.id == currentUser.id ?
                                                    "Me" : upNextSchedules[i].user.firstName,
                                                    style: const TextStyle(fontSize: 18),
                                                  )
                                                ],
                                              ),
                                              const Padding(padding: EdgeInsets.all(4)),
                                              upNextSchedules[i].status != "done" ?
                                              Text(
                                                upNextSchedules[i].title,
                                              ) : const Text(
                                                  "Done for the day! 🎉",
                                                  style: TextStyle(color: Colors.green)
                                              ),
                                              Visibility(
                                                visible: upNextSchedules[i].status != "done",
                                                child: Text(
                                                  upNextSchedules[i].status == "until" ?
                                                  "Class until ${DateFormat("jm").format(upNextSchedules[i].endTime.toLocal())}" : "Class at ${DateFormat("jm").format(upNextSchedules[i].startTime.toLocal())}",
                                                  style: TextStyle(color: upNextSchedules[i].status == "until" ? Colors.orangeAccent : SB_NAVY, fontSize: 12),
                                                ),
                                              )
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
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16, top: 8, bottom: 8),
                    child: Row(
                      children: const [
                        Icon(Icons.menu_book_rounded),
                        Padding(padding: EdgeInsets.all(4)),
                        Text("Library", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
                      ],
                    ),
                  ),
                  (waitzBuildings.isEmpty) ? Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                    child: Column(
                      children: [0,1,2].map((e) => CardLoading(
                        margin: const EdgeInsets.all(8),
                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                        height: 150,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    children: const [
                                      Card(
                                        child: SizedBox(
                                          height: 25,
                                          width: 200,
                                        ),
                                      ),
                                      Card(
                                        child: SizedBox(
                                          height: 15,
                                          width: 200,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Card(
                                    child: SizedBox(
                                      height: 30,
                                      width: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )).toList()
                    ),
                  ) : Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                    child: Card(
                      child: Column(
                        children: waitzBuildings.map((b) => ExpansionTile(
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          tilePadding: const EdgeInsets.all(8),
                          childrenPadding: const EdgeInsets.all(8),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    b.name,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const Padding(padding: EdgeInsets.all(2)),
                                  Text(
                                    "Capacity: ${b.people} / ${b.capacity}",
                                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                                ],
                              ),
                              Text(
                                b.summary,
                                style: TextStyle(fontSize: 18, color: b.summary.contains("Very Busy") ? SB_RED : b.summary.contains("Not Busy") ? Colors.green : SB_AMBER),
                              )
                            ],
                          ),
                          children: b.floors.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          e.name,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        Text(
                                          "Capacity: ${e.people} / ${e.capacity}",
                                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      "${e.busyness}%",
                                      style: TextStyle(fontSize: 16, color: e.summary.contains("Very Busy") ? SB_RED : e.summary.contains("Not Busy") ? Colors.green : SB_AMBER),
                                    )
                                  ],
                                ),
                                const Padding(padding: EdgeInsets.all(2)),
                                ClipRRect(
                                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                                  child: LinearProgressIndicator(
                                    color: e.summary.contains("Very Busy") ? SB_RED : e.summary.contains("Not Busy") ? Colors.green : SB_AMBER,
                                    value: e.busyness / 100,
                                  ),
                                )
                              ],
                            ),
                          )).toList(),
                        )).toList()
                      ),
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
