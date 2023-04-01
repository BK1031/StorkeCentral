import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:storke_central/models/dining_hall.dart';
import 'package:storke_central/models/dining_hall_meal.dart';
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
  PageController _controller = PageController();
  int currPage = 0;
  bool loading = false;

  _DiningHallPageState(this.diningHallID);

  @override
  void initState() {
    super.initState();
    getDining();
  }

  Future<void> getDining() async {
    setState(() => loading = true);
    if (!offlineMode) {
      try {
        await Future.delayed(const Duration(milliseconds: 100));
        await http.get(Uri.parse("$API_HOST/dining/$diningHallID"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}).then((value) {
          setState(() {
            selectedDiningHall = DiningHall.fromJson(jsonDecode(value.body)["data"]);
          });
        });
        await getDiningMenus();
        selectedDiningHall.status = getDiningStatus(selectedDiningHall.id);
      } catch(e) {
        log(e.toString(), LogLevel.error);
        // TODO: show error snackbar
      }
    } else {
      log("Offline mode, searching cache for dining...");
    }
  }

  Future<void> getDiningMenus() async {
    DateTime queryDate = DateTime.now();
    // DateTime queryDate = DateTime.parse("2023-03-23 08:00:00.000");
    if (!offlineMode) {
      try {
        await Future.delayed(const Duration(milliseconds: 100));
        await http.get(Uri.parse("$API_HOST/dining/meals/${DateFormat("yyyy-MM-dd").format(queryDate)}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}).then((value) {
          setState(() {
            selectedDiningHall.meals = jsonDecode(value.body)["data"].map<DiningHallMeal>((json) => DiningHallMeal.fromJson(json)).toList().where((element) => element.diningHallID == selectedDiningHall.id).toList();
          });
        });
        setState(() => loading = false);
      } catch(e) {
        log(e.toString(), LogLevel.error);
        // TODO: show error snackbar
      }
    } else {
      log("Offline mode, searching cache for dining...");
    }
  }

  String getDiningStatus(String diningHallID) {
    DateTime now = DateTime.now();
    // DateTime now = DateTime.parse("2023-03-23 11:00:00.100");
    selectedDiningHall.meals.sort((a, b) => a.open.compareTo(b.open));
    log("Current Time: $now - ${now.timeZoneName}");
    for (int j = 0; j < selectedDiningHall.meals.length; j++) {
      log("${selectedDiningHall.meals[j].name} from ${DateFormat("MM/dd h:mm a").format(selectedDiningHall.meals[j].open.toLocal())} to ${DateFormat("h:mm a").format(selectedDiningHall.meals[j].close.toLocal())}");
      if (now.isBefore(selectedDiningHall.meals[j].open.toLocal())) {
        setState(() {
          selectedMeal = selectedDiningHall.meals[j].name;
        });
        _controller.animateToPage(selectedDiningHall.meals.indexWhere((element) => element.name == selectedMeal), duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
        return "${selectedDiningHall.meals[j].name.capitalize()} at ${DateFormat("h:mm a").format(selectedDiningHall.meals[j].open.toLocal())}";
      } else if (now.isAfter(selectedDiningHall.meals[j].open.toLocal()) && now.isBefore(selectedDiningHall.meals[j].close.toLocal())) {
        setState(() {
          selectedMeal = selectedDiningHall.meals[j].name;
        });
        _controller.animateToPage(selectedDiningHall.meals.indexWhere((element) => element.name == selectedMeal), duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
        return "${selectedDiningHall.meals[j].name.capitalize()} until ${DateFormat("h:mm a").format(selectedDiningHall.meals[j].close.toLocal())}";
      }
    }
    // TODO: Get next days breakfast
    return "Closed Today";
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
                height: 125,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: FractionalOffset.topCenter,
                        end: FractionalOffset.bottomCenter,
                        colors: [
                          Colors.grey.withOpacity(0.0),
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
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 0.0, left: 8.0, right: 8.0),
                  child: loading ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: Center(
                          child: RefreshProgressIndicator(
                              color: Colors.white,
                              backgroundColor: SB_NAVY
                          )
                      )
                  ) : selectedDiningHall.meals.isEmpty ? Container(
                    height: 300,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        width: 250,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.no_food_rounded, size: 65, color: Theme.of(context).textTheme.caption!.color,),
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
                    physics: const NeverScrollableScrollPhysics(),
                    controller: _controller,
                    children: selectedDiningHall.meals.map((e) => GroupedListView<dynamic, String>(
                      elements: e.menuItems,
                      groupBy: (element) => element.station,
                      groupSeparatorBuilder: (String groupByValue) => Card(
                        color: SB_NAVY,
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
                              const Icon(Icons.fastfood_rounded),
                              const Padding(padding: EdgeInsets.all(4)),
                              Text(element.name, style: const TextStyle(fontSize: 16)),
                            ],
                          ),
                        )
                      ),
                      // itemComparator: (item1, item2) => item1['name'].compareTo(item2['name']), // optional
                      useStickyGroupSeparators: false, // optional
                      floatingHeader: true, // optional
                      order: GroupedListOrder.ASC, // optional
                    )).toList(),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(left: 8, top: 8, right: 8),
                  child: Card(
                    child: Row(
                      children: selectedDiningHall.meals.map((e) => Expanded(
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          color: selectedMeal == e.name ? SB_NAVY : null,
                          onPressed: () {
                            setState(() {
                              selectedMeal = e.name;
                            });
                            _controller.animateToPage(selectedDiningHall.meals.indexWhere((element) => element.name == selectedMeal), duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(e.name.capitalize(), style: TextStyle(color: selectedMeal == e.name ? Colors.white : Theme.of(context).textTheme.labelLarge!.color)),
                              Text("${DateFormat("jm").format(e.open.toLocal())} - ${DateFormat("jm").format(e.close.toLocal())}", style: TextStyle(fontSize: 13, color: selectedMeal == e.name ? Colors.white : SB_NAVY)),
                            ],
                          ),
                        ),
                      )).toList()
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
