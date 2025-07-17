import 'dart:async';
import 'dart:convert';

import 'package:extended_image/extended_image.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:storke_central/models/dining_hall.dart';
import 'package:storke_central/models/dining_hall_meal.dart';
import 'package:storke_central/models/news_article.dart';
import 'package:storke_central/models/subscribed_up_next.dart';
import 'package:storke_central/models/up_next_schedule_item.dart';
import 'package:storke_central/models/waitz_building.dart';
import 'package:storke_central/models/weather.dart';
import 'package:storke_central/pages/home/add_up_next_dialog.dart';
import 'package:storke_central/utils/alert_service.dart';
import 'package:storke_central/utils/auth_service.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/logger.dart';
import 'package:storke_central/utils/string_extension.dart';
import 'package:storke_central/utils/theme.dart';
import 'package:storke_central/widgets/home/dining_placeholder.dart';
import 'package:storke_central/widgets/home/headline_article_placeholder.dart';
import 'package:storke_central/widgets/home/up_next_placeholder.dart';
import 'package:storke_central/widgets/home/waitz_placeholder.dart';
import 'package:weather_icons/weather_icons.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  bool loadingUpNext = false;

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
    getWeather();
    getDining();
    getWaitz();
    Future.delayed(const Duration(milliseconds: 100), () => getUpNextSubscriptions());
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
            headlineArticle = NewsArticle.fromJson(jsonDecode(response.body)["data"]);
          });
          lastHeadlineArticleFetch = DateTime.now();
          prefs.setString("HEADLINE_ARTICLE", jsonEncode(headlineArticle).toString());
          trace.stop();
        } else {
          log("[home_page] Using cached headline article, last fetch was ${DateTime.now().difference(lastHeadlineArticleFetch).inMinutes} minutes ago (minimum 60 minutes)");
        }
      } catch(e) {
        log("[home_page] ${e.toString()}", LogLevel.error);
        Future.delayed(Duration.zero, () => AlertService.showErrorSnackbar(context, "Failed to fetch news headline!"));
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

  Future<void> getWeather() async {
    if (!offlineMode && !kIsWeb) {
      try {
        if (weather.id == 0 || DateTime.now().difference(lastWeatherFetch).inMinutes > 60) {
          Trace trace = FirebasePerformance.instance.newTrace("getWeather()");
          await trace.start();
          Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          await httpClient.get(Uri.parse("https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$WEATHER_API_KEY"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}).then((value) {
            if (value.statusCode == 200) {
              setState(() {
                weather = Weather.fromJson(jsonDecode(value.body));
              });
              lastWeatherFetch = DateTime.now();
            } else {
              log("[home_page] Failed to fetch weather, status code ${value.statusCode}", LogLevel.error);
              AlertService.showErrorSnackbar(context, "Failed to fetch weather!");
            }
          });
          trace.stop();
        } else {
          log("[home_page] Using cached weather, last fetch was ${DateTime.now().difference(lastWeatherFetch).inMinutes} minutes ago (minimum 60 minutes)");
        }
      } catch(e) {
        log("[home_page] ${e.toString()}", LogLevel.error);
        Future.delayed(Duration.zero, () => AlertService.showErrorSnackbar(context, "Failed to fetch weather!"));
      }
    } else {
      log("[home_page] Offline mode, not displaying weather", LogLevel.warn);
    }
  }

  Future<void> getDining() async {
    if (!offlineMode) {
      try {
        Trace trace = FirebasePerformance.instance.newTrace("getDining()");
        await trace.start();
        await Future.delayed(const Duration(milliseconds: 100));
        await httpClient.get(Uri.parse("$API_HOST/dining"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}).then((value) {
          log("[home_page] Fetched dining halls");
          setState(() {
            diningHallList = jsonDecode(value.body)["data"].map<DiningHall>((json) => DiningHall.fromJson(json)).toList();
            if (!kIsWeb) {
              // Only calculate distance if not on web
              for (int i = 0; i < diningHallList.length; i++) {
                diningHallList[i].distanceFromUser = Geolocator.distanceBetween(diningHallList[i].latitude, diningHallList[i].longitude, currentPosition!.latitude, currentPosition!.longitude);
              }
              diningHallList.sort((a, b) => a.distanceFromUser.compareTo(b.distanceFromUser));
            }
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
        Future.delayed(Duration.zero, () => AlertService.showErrorSnackbar(context, "Failed to fetch dining halls!"));
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
        await httpClient.get(Uri.parse("$API_HOST/dining/meals/${DateFormat("MM-dd-yyyy").format(queryDate)}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}).then((value) {
          log("[home_page] Fetched today's dining meals");
          setState(() {
            diningMealList = jsonDecode(value.body)["data"].map<DiningHallMeal>((json) => DiningHallMeal.fromJson(json)).toList();
          });
        });
        await httpClient.get(Uri.parse("$API_HOST/dining/meals/${DateFormat("MM-dd-yyyy").format(queryDate.add(const Duration(days: 1)))}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}).then((value) {
          log("[home_page] Fetched tomorrow's dining meals");
          setState(() {
            List<DiningHallMeal> addMealList = jsonDecode(value.body)["data"].map<DiningHallMeal>((json) => DiningHallMeal.fromJson(json)).toList();
            diningMealList.addAll(addMealList);
          });
        });
        trace.stop();
      } catch(e) {
        log("[home_page] ${e.toString()}", LogLevel.error);
        Future.delayed(Duration.zero, () => AlertService.showErrorSnackbar(context, "Failed to fetch dining hours!"));
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
    return "Closed";
  }

  Future<void> getUpNextSubscriptions() async {
    if (!offlineMode) {
      if (upNextSubscriptions.isEmpty || DateTime.now().difference(lastUpNextFetch).inMinutes > 2) {
        try {
          setState(() => loadingUpNext = true);
          await AuthService.getAuthToken();
          var response = await httpClient.get(Uri.parse("$API_HOST/users/schedule/${currentUser.id}/next/subscribed"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"});
          setState(() {
            upNextSubscriptions = jsonDecode(response.body)["data"].map<SubscribedUpNext>((json) => SubscribedUpNext.fromJson(json)).toList();
            upNextUserIDs = upNextSubscriptions.map<String>((e) => e.subscribedUserID).toList();
          });
          for (int i = 0; i < upNextSubscriptions.length; i++) {
            if (friends.any((element) => element.user.id == upNextSubscriptions[i].subscribedUserID)) {
              setState(() {
                upNextSubscriptions[i].user = friends.firstWhere((element) => element.user.id == upNextSubscriptions[i].subscribedUserID).user;
              });
            } else if (upNextSubscriptions[i].subscribedUserID == currentUser.id) {
              setState(() {
                upNextSubscriptions[i].user = currentUser;
              });
            }
          }
          setState(() => loadingUpNext = false);
        } catch(err) {
          Future.delayed(Duration.zero, () => AlertService.showErrorSnackbar(context, "Failed to get UpNext subscriptions!"));
        }
      } else {
        log("[home_page] Using cached up next schedules, last fetch was ${DateTime.now().difference(lastUpNextFetch).inMinutes} minutes ago (minimum 2 minutes)");
      }
    } else {
      log("[home_page] Offline mode, not displaying up next schedules");
    }
  }

  Widget buildUpNextCard(SubscribedUpNext upNextSubscription) {
    upNextSubscription.upNextItems.sort((a, b) => a.startTime.compareTo(b.startTime));
    upNextSubscription.status = "Done for the day! 🎉";
    UpNextScheduleItem currentItem = UpNextScheduleItem();
    for (UpNextScheduleItem item in upNextSubscription.upNextItems) {
      if (item.startTime.toLocal().isAfter(DateTime.now())) {
        upNextSubscription.status = "Class at ${DateFormat("h:mm a").format(item.startTime.toLocal())}";
        currentItem = item;
        break;
      } else if (item.endTime.toLocal().isAfter(DateTime.now())) {
        upNextSubscription.status = "Class until ${DateFormat("h:mm a").format(item.endTime.toLocal())}";
        currentItem = item;
        break;
      }
    }
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: SizedBox(
        width: 175,
        child: Card(
          child: InkWell(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            onTap: () {
              if (upNextSubscription.user.id == currentUser.id && !upNextSubscription.status.contains("Done")) {
                router.navigateTo(context, "/schedule/view/${currentItem.title}", transition: TransitionType.native);
              } else {
                router.navigateTo(context, "/schedule/user/${upNextSubscription.user.id}", transition: TransitionType.native);
              }
            },
            child: Container(
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
                          upNextSubscription.user.profilePictureURL,
                          height: 30,
                        ),
                      ),
                      const Padding(padding: EdgeInsets.all(4)),
                      Text(
                        upNextSubscription.user.id == currentUser.id ?
                        "Me" : upNextSubscription.user.firstName,
                        style: const TextStyle(fontSize: 18),
                      )
                    ],
                  ),
                  const Padding(padding: EdgeInsets.all(4)),
                  upNextSubscription.status.contains("Done") ? const Text(
                      "Done for the day! 🎉",
                      style: TextStyle(color: Colors.green)
                  ) : Text(
                    currentItem.title,
                  ),
                  Visibility(
                    visible: !upNextSubscription.status.contains("Done"),
                    child: Text(
                      upNextSubscription.status,
                      style: TextStyle(color: upNextSubscription.status.contains("until") ? Colors.orangeAccent : ACTIVE_ACCENT_COLOR, fontSize: 12),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void showAddUpNextDialog() {
    if (friends.isEmpty) {
      AlertService.showWarningDialog(context, "No Friends!","You don't have any friends to add to your Up Next.", () {});
      return;
    }
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: const Text(
            "Add Friends to Up Next",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
          ),
          content: const AddUpNextDialog(),
          contentPadding: const EdgeInsets.only(right: 8),
          titlePadding: const EdgeInsets.only(left: 16, top: 16, right: 16),
          actions: [
            SizedBox(
              width: double.maxFinite,
              child: CupertinoButton(
                onPressed: () async {
                  lastUpNextFetch = DateTime.now().subtract(const Duration(minutes: 100));
                  if (!upNextUserIDs.contains(currentUser.id)) {
                    upNextUserIDs.insert(0, currentUser.id);
                  }
                  await httpClient.post(Uri.parse("$API_HOST/users/schedule/${currentUser.id}/next/subscribed"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}, body: jsonEncode(upNextUserIDs));
                  getUpNextSubscriptions();
                  Future.delayed(Duration.zero, () => router.pop(context));
                },
                color: ACTIVE_ACCENT_COLOR,
                child: const Text("Done"),
              ),
            )
          ],
        );
    });
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
            waitzBuildings.sort((a, b) => b.name.compareTo(a.name));
          });
          lastWaitzFetch = DateTime.now();
          trace.stop();
        } else {
          log("[home_page] Using cached waitz data, last fetch was ${DateTime.now().difference(lastWaitzFetch).inMinutes} minutes ago (minimum 60 minutes)");
        }
      } catch(e) {
        log("[home_page] ${e.toString()}", LogLevel.error);
        Future.delayed(Duration.zero, () => AlertService.showErrorSnackbar(context, "Failed to fetch waitz data!"));
      }
    } else {
      log("[home_page] Offline mode, no waitz data to display!", LogLevel.warn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    headlineArticle.id == "" ? const HeadlineArticlePlaceholder() : Container(
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
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                          Visibility(
                                            visible: !offlineMode,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                              children: [
                                                BoxedIcon(
                                                  WeatherIcons.fromString(weather.id != 0 ? "wi-${DateTime.now().hour > 6 && DateTime.now().hour < 20 ? "day" : "night"}-${weatherCodeToIcon[weather.id]}" : "wi-moon-new", fallback: WeatherIcons.day_sunny),
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                                const Padding(padding: EdgeInsets.all(2)),
                                                Text(
                                                  weather.temp != 0.0 ? "${((weather.temp - 273.15) * 9/5 + 32).toStringAsFixed(1)} °F" : "– °F",
                                                  style: const TextStyle(fontSize: 17, color: Colors.white)
                                                )
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(headlineArticle.title, style: const TextStyle(color: Colors.white, fontSize: 20)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 16.0, right: 16, top: 8, bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.fastfood),
                          Padding(padding: EdgeInsets.all(4)),
                          Text("Dining", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
                        ],
                      ),
                    ),
                    (diningHallList.isEmpty) ? const DiningPlaceholder() : SizedBox(
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
                                                  begin: FractionalOffset.center,
                                                  end: FractionalOffset.bottomCenter,
                                                  colors: [
                                                    Colors.black.withOpacity(0.0),
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
                                              Hero(
                                                tag: "${diningHallList[i].id}-status",
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: Text(diningHallList[i].status, style: TextStyle(color: diningHallList[i].status.contains("until") ? Colors.green : diningHallList[i].status.contains("at") ? Colors.orangeAccent : diningHallList[i].status.contains("Closed") ? Colors.red : Colors.grey, fontSize: 12))
                                                )
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
                    const Padding(
                      padding: EdgeInsets.only(left: 16.0, right: 16, top: 8, bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_view_day_rounded),
                          Padding(padding: EdgeInsets.all(4)),
                          Text("Up Next", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
                        ],
                      ),
                    ),
                    Visibility(
                      visible: true,
                      child: (loadingUpNext) ? const UpNextPlaceholder() : (upNextSubscriptions.isEmpty) ? SizedBox(
                        height: 100,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0, right: 8),
                          child: InkWell(
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                            onTap: () {
                              showAddUpNextDialog();
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0, right: 8),
                              child: Row(
                                children: [
                                  Image.asset("images/icons/new.png", height: 75, color: Colors.grey.withOpacity(0.6),),
                                  const Padding(padding: EdgeInsets.all(8)),
                                  const Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Click to add friends to your Up Next view.",
                                          style: TextStyle(fontSize: 18),
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ) : SizedBox(
                        height: 100,
                        child: ListView.builder(
                          itemCount: upNextSubscriptions.length + 1,
                          itemBuilder: (BuildContext context, int i) {
                            if (i == upNextSubscriptions.length) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: SizedBox(
                                  width: 100,
                                  child: InkWell(
                                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                                    onTap: () {
                                      showAddUpNextDialog();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      child: Center(
                                        child: Image.asset(
                                          "images/icons/new.png",
                                          color: Colors.grey.withOpacity(0.6),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              return buildUpNextCard(upNextSubscriptions[i]);
                            }
                          },
                          scrollDirection: Axis.horizontal,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 16.0, right: 16, top: 8, bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.menu_book_rounded),
                          Padding(padding: EdgeInsets.all(4)),
                          Text("Library", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
                        ],
                      ),
                    ),
                    (waitzBuildings.isEmpty) ? const WaitzPlaceholder() : Padding(
                      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                      child: Card(
                        child: Column(
                          children: waitzBuildings.map((b) => ExpansionTile(
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                            ),
                            textColor: ACTIVE_ACCENT_COLOR,
                            tilePadding: const EdgeInsets.all(8),
                            childrenPadding: const EdgeInsets.all(8),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
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
                                ),
                                const Padding(padding: EdgeInsets.all(4)),
                                Text(
                                  b.summary,
                                  style: TextStyle(fontSize: 18, color: b.summary.contains("Very Busy") || b.summary.contains("Closed") ? SB_RED : b.summary.contains("Not Busy") ? Colors.green : SB_AMBER),
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
                                        style: TextStyle(fontSize: 16, color: e.summary.contains("Very Busy") || b.summary.contains("Closed") ? SB_RED : e.summary.contains("Not Busy") ? Colors.green : SB_AMBER),
                                      )
                                    ],
                                  ),
                                  const Padding(padding: EdgeInsets.all(2)),
                                  ClipRRect(
                                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                                    child: LinearProgressIndicator(
                                      color: e.summary.contains("Very Busy") || b.summary.contains("Closed") ? SB_RED : e.summary.contains("Not Busy") ? Colors.green : SB_AMBER,
                                      value: e.busyness / 100,
                                    ),
                                  )
                                ],
                              ),
                            )).toList(),
                          )).toList()
                        ),
                      ),
                    ),
                    const SizedBox(height: 20)
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
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.white,),
                          Padding(padding: EdgeInsets.all(4)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Overdose Response", style: TextStyle(color: Colors.white, fontSize: 18),),
                                Padding(padding: EdgeInsets.all(2)),
                                Text("Stay safe out there! Check out the emergency response quick action guide.", style: TextStyle(color: Colors.white),)
                              ],
                            ),
                          ),
                          Padding(padding: EdgeInsets.all(4)),
                          Icon(Icons.arrow_forward_ios, color: Colors.white,),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
