// ignore_for_file: no_logic_in_create_state, must_be_immutable

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';
import 'package:storke_central/models/dining_hall.dart';
import 'package:storke_central/models/dining_hall_meal.dart';
import 'package:storke_central/models/dining_hall_menu_item.dart';
import 'package:storke_central/utils/alert_service.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/logger.dart';
import 'package:storke_central/utils/string_extension.dart';
import 'package:storke_central/utils/theme.dart';

class DiningHallPage extends StatefulWidget {
  String diningHallID = "";
  DiningHallPage({Key? key, required this.diningHallID}) : super(key: key);

  @override
  State<DiningHallPage> createState() => _DiningHallPageState(diningHallID);
}

class _DiningHallPageState extends State<DiningHallPage> {

  String diningHallID = "";
  String selectedMeal = "breakfast";
  final PageController _controller = PageController();
  bool loading = false;

  DateTime nextMealDate = DateTime.now();
  DateTime selectedDate = DateTime.now();
  List<DateTime> dates = [];

  _DiningHallPageState(this.diningHallID);

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    getDates();
    getDining().then((value) => getDiningStatus(diningHallID));
  }

  Future<void> getDates() async {
    DateTime now = DateTime.now();
    dates.add(now);
    for (int i = 1; i < 3; i++) {
      dates.add(now.add(Duration(days: i)));
    }
    for (int i = 1; i < 3; i++) {
      dates.add(now.subtract(Duration(days: i)));
    }
    dates.sort((a, b) => a.compareTo(b));
  }

  Future<void> getDining() async {
    setState(() => loading = true);
    if (!offlineMode) {
      try {
        await Future.delayed(const Duration(milliseconds: 100));
        await httpClient.get(Uri.parse("$API_HOST/dining/$diningHallID"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}).then((value) {
          setState(() {
            selectedDiningHall = DiningHall.fromJson(jsonDecode(utf8.decode(value.bodyBytes))["data"]);
          });
        });
        await getDiningMenus();
      } catch(e) {
        log("[dining_hall_page] ${e.toString()}", LogLevel.error);
        Future.delayed(Duration.zero, () => AlertService.showErrorSnackbar(context, "Failed to fetch dining hall!"));
      }
    } else {
      log("[dining_hall_page] Offline mode, searching cache for dining...");
    }
  }

  Future<void> getDiningMenus() async {
    // DateTime queryDate = DateTime.parse("2023-03-23 08:00:00.000");
    if (!offlineMode) {
      setState(() => loading = true);
      try {
        await Future.delayed(const Duration(milliseconds: 100));
        await httpClient.get(Uri.parse("$API_HOST/dining/meals/${DateFormat("MM-dd-yyyy").format(selectedDate)}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}).then((value) {
          setState(() {
            selectedDiningHall.meals = jsonDecode(utf8.decode(value.bodyBytes))["data"].map<DiningHallMeal>((json) => DiningHallMeal.fromJson(json)).toList().where((element) => element.diningHallID == selectedDiningHall.id).toList();
            selectedDiningHall.meals.sort((a, b) => a.open.compareTo(b.open));
          });
          if (selectedDiningHall.meals.isNotEmpty) {
            setState(() {
              selectedMeal = selectedDiningHall.meals[0].name;
            });
          }
        });
        setState(() => loading = false);
      } catch(e) {
        log("[dining_hall_page] ${e.toString()}", LogLevel.error);
        Future.delayed(Duration.zero, () => AlertService.showErrorSnackbar(context, "Failed to fetch dining menu!"));
      }
    } else {
      log("[dining_hall_page] Offline mode, searching cache for dining...");
    }
  }

  Future<void> getDiningStatus(String diningHallID) async {
    DateTime now = DateTime.now();
    selectedDiningHall.meals.sort((a, b) => a.open.compareTo(b.open));
    log("[dining_hall_page] Current Time: $now - ${now.timeZoneName}");
    for (int j = 0; j < selectedDiningHall.meals.length; j++) {
      log("[dining_hall_page] ${selectedDiningHall.meals[j].name} from ${DateFormat("MM/dd h:mm a").format(selectedDiningHall.meals[j].open.toLocal())} to ${DateFormat("h:mm a").format(selectedDiningHall.meals[j].close.toLocal())}");
      if (now.isBefore(selectedDiningHall.meals[j].open.toLocal())) {
        Future.delayed(const Duration(milliseconds: 25), () {
          setState(() {
            nextMealDate = selectedDiningHall.meals[j].open.toLocal();
            selectedDiningHall.status = "${selectedDiningHall.meals[j].name.capitalize()} at ${DateFormat("h:mm a").format(selectedDiningHall.meals[j].open.toLocal())}";
            selectedMeal = selectedDiningHall.meals[j].name;
          });
          _controller.animateToPage(selectedDiningHall.meals.indexWhere((element) => element.name == selectedMeal), duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
        });
        return;
      } else if (now.isAfter(selectedDiningHall.meals[j].open.toLocal()) && now.isBefore(selectedDiningHall.meals[j].close.toLocal())) {
        Future.delayed(const Duration(milliseconds: 25), () {
          setState(() {
            nextMealDate = selectedDiningHall.meals[j].open.toLocal();
            selectedDiningHall.status = "${selectedDiningHall.meals[j].name.capitalize()} until ${DateFormat("h:mm a").format(selectedDiningHall.meals[j].close.toLocal())}";
            selectedMeal = selectedDiningHall.meals[j].name;
          });
          _controller.animateToPage(selectedDiningHall.meals.indexWhere((element) => element.name == selectedMeal), duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
        });
        return;
      }
    }
    setState(() {
      selectedDiningHall.status = "Closed Today";
    });
    if (selectedDate.day == now.day) {
      // Only check one next day if closed on current day
      setState(() {
        selectedDate = now.add(const Duration(days: 1));
      });
      await getDiningMenus();
      return getDiningStatus(diningHallID);
    }
  }

  Icon getMenuItemIcon(DiningHallMenuItem item) {
    switch (item.station) {
      case "Breakfast":
        return const Icon(Icons.breakfast_dining_rounded);
      default:
        return const Icon(Icons.fastfood_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Hero(
                tag: "${selectedDiningHall.id}-image",
                child: Image.asset(
                  "images/${selectedDiningHall.id}.jpeg",
                  fit: BoxFit.cover,
                  height: 250,
                  width: double.infinity,
                ),
              ),
              Container(
                height: 250,
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
                height: 250,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Hero(
                      tag: "${selectedDiningHall.id}-title",
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          selectedDiningHall.name,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    const Padding(padding: EdgeInsets.all(4)),
                    Hero(
                      tag: "${selectedDiningHall.id}-status",
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          "${selectedDiningHall.status} on ${DateFormat("M/dd").format(nextMealDate)}",
                          style: TextStyle(fontSize: 16, color: selectedDiningHall.status.contains("until") ? Colors.green : selectedDiningHall.status.contains("at") ? Colors.orangeAccent : selectedDiningHall.status.contains("Closed") ? Colors.red : Colors.grey,),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.only(left: 8, top: 8, right: 8),
            child: Card(
              child: Row(
                  children: selectedDiningHall.meals.map((e) => Expanded(
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      color: selectedMeal == e.name ? ACTIVE_ACCENT_COLOR : null,
                      onPressed: () {
                        _controller.animateToPage(selectedDiningHall.meals.indexWhere((element) => element.name == e.name), duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(e.name.capitalize(), style: TextStyle(color: selectedMeal == e.name ? Colors.white : Theme.of(context).textTheme.labelLarge!.color)),
                          Text("${DateFormat("jm").format(e.open.toLocal())} - ${DateFormat("jm").format(e.close.toLocal())}", style: TextStyle(fontSize: 13, color: selectedMeal == e.name ? Colors.white : ACTIVE_ACCENT_COLOR)),
                        ],
                      ),
                    ),
                  )).toList()
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 0.0, left: 8.0, right: 8.0),
              child: loading ? Padding(
                  padding: const EdgeInsets.all(8),
                  child: Center(
                      child: RefreshProgressIndicator(
                          color: Colors.white,
                          backgroundColor: ACTIVE_ACCENT_COLOR
                      )
                  )
              ) : selectedDiningHall.meals.isEmpty ? SizedBox(
                height: 300,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    width: 250,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.no_food_rounded, size: 65, color: Theme.of(context).textTheme.bodySmall!.color,),
                        const Padding(padding: EdgeInsets.all(4),),
                        const Text(
                          "No Menu Found",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Padding(padding: EdgeInsets.all(4),),
                        Text(
                            "We couldn't find a menu listed for this dining hall today, ${selectedDiningHall.name} may be closed today."
                        ),
                        const Padding(padding: EdgeInsets.all(8),),
                      ],
                    ),
                  ),
                )
              ) : PageView(
                controller: _controller,
                onPageChanged: (int page) {
                  setState(() {
                    selectedMeal = selectedDiningHall.meals[page].name;
                  });
                },
                children: selectedDiningHall.meals.map((e) => GroupedListView<dynamic, String>(
                  padding: EdgeInsets.zero,
                  elements: e.menuItems,
                  groupBy: (element) => element.station,
                  groupSeparatorBuilder: (String groupByValue) => Card(
                    color: ACTIVE_ACCENT_COLOR,
                    child: Container(
                      height: 35,
                      padding: const EdgeInsets.all(8),
                      child: Center(child: Text(groupByValue, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)))
                    )
                  ),
                  itemBuilder: (context, dynamic element) => Card(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          getMenuItemIcon(element),
                          const Padding(padding: EdgeInsets.all(4)),
                          Text(element.name, style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    )
                  ),
                  useStickyGroupSeparators: false, // optional
                  floatingHeader: true, // optional
                  order: GroupedListOrder.ASC, // optional
                )).toList()
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: dates.map((e) => SizedBox(
                    width: 45,
                    child: CupertinoButton(
                      color: e.day == selectedDate.day ? ACTIVE_ACCENT_COLOR : null,
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          selectedDate = e;
                        });
                        getDiningMenus();
                      },
                      child: Column(
                        children: [
                          Text(DateFormat("d").format(e), style: TextStyle(fontSize: 17, color: e.day == selectedDate.day ? Colors.white : Theme.of(context).textTheme.labelLarge!.color),),
                          Text(DateFormat("MMM").format(e), style: TextStyle(fontSize: 13, color: e.day == selectedDate.day ? Colors.white : ACTIVE_ACCENT_COLOR)),
                        ],
                      ),
                    ),
                  )).toList()
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
