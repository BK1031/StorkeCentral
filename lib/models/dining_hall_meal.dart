import 'dining_hall_menu_item.dart';

class DiningHallMeal {
  String id = "";
  String name = "";
  String diningHallID = "";
  DateTime open = DateTime.now().toUtc();
  DateTime close = DateTime.now().toUtc();
  DateTime createdAt = DateTime.now().toUtc();

  List<DiningHallMenuItem> menuItems = [];

  DiningHallMeal();

  DiningHallMeal.fromJson(Map<String, dynamic> json) {
    id = json["id"] ?? "";
    name = json["name"] ?? "";
    diningHallID = json["dining_hall_id"] ?? "";
    open = DateTime.tryParse(json["open"]) ?? DateTime.now().toUtc();
    close = DateTime.tryParse(json["close"]) ?? DateTime.now().toUtc();
    for (int i = 0; i < json["menu_items"].length; i++) {
      menuItems.add(DiningHallMenuItem.fromJson(json["menu_items"][i]));
    }
    createdAt = DateTime.tryParse(json["created_at"]) ?? DateTime.now().toUtc();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dining_hall_id': diningHallID,
    "open": open.toIso8601String(),
    "close": close.toIso8601String(),
    "created_at": createdAt.toIso8601String()
  };
}

/*
{
  "id": "portola-lunch-2023-03-23",
  "name": "lunch",
  "dining_hall_id": "portola",
  "open": "2023-03-23T11:00:00Z",
  "close": "2023-03-23T15:00:00Z",
  "menu_items": [
    {
      "meal_id": "portola-lunch-2023-03-23",
      "name": "Strawberry Salad w/Poppyseed Dressing (v",
      "station": "Greens \u0026 Grains",
      "created_at": "2023-03-22T05:09:30.053008Z"
    },
    ...
  ],
  "created_at": "2023-03-22T05:09:29.741477Z"
},

 */