import 'package:storke_central/models/dining_hall_menu_item.dart';
import 'package:intl/intl.dart';

class DiningHallMeal {
  String diningCommonCode = "";
  String mealCode = "";
  DateTime date = DateTime.now();
  DateTime open = DateTime.now();
  DateTime close = DateTime.now();

  List<DiningHallMenuItem> menuItems = [];

  DiningHallMeal();

  DiningHallMeal.fromJson(Map<String, dynamic> json) {
    diningCommonCode = json["diningCommonCode"] ?? "";
    mealCode = json["mealCode"] ?? "";
    date = DateTime.tryParse(json["date"]) ?? DateTime.now();
    open = DateTime.tryParse("${json["date"]} ${json["open"].toString().contains("AM") ? (int.parse(json["open"].toString().split(" AM")[0].toString().split(":")[0]) < 10 ? ("0" + json["open"].toString().split(" AM")[0]) : json["open"].toString().split(" AM")[0]) : (int.parse(json["open"].toString().split(" PM")[0].split(":")[0]) + 12).toString() + json["open"].toString().split(" PM")[0].split(":")[1]}:00") ?? DateTime.now();
    close = DateTime.tryParse("${json["date"]} ${json["close"].toString().contains("AM") ? (int.parse(json["close"].toString().split(" AM")[0].toString().split(":")[0]) < 10 ? ("0" + json["close"].toString().split(" AM")[0]) : json["close"].toString().split(" AM")[0]) : (int.parse(json["close"].toString().split(" PM")[0].split(":")[0]) + 12).toString() + json["close"].toString().split(" PM")[0].split(":")[1]}:00") ?? DateTime.now();
  }

  Map<String, dynamic> toJson() => {
    'diningCommonCode': diningCommonCode,
    'mealCode': mealCode,
    'date': DateFormat("yyyy-MM-dd").format(date),
    'open': DateFormat("jm").format(open),
    'close': DateFormat("jm").format(close),
  };
}

/*
{
    "diningCommonCode": "carrillo",
    "mealCode": "breakfast",
    "date": "2021-09-27",
    "open": "7:15 AM",
    "close": "10:00 AM"
}
 */