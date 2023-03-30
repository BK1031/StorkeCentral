class DiningHallMenuItem {
  String mealID = "";
  String name = "";
  String station = "";
  DateTime createdAt = DateTime.now().toUtc();

  DiningHallMenuItem();

  DiningHallMenuItem.fromJson(Map<String, dynamic> json) {
    mealID = json["meal_id"] ?? "";
    name = json["name"] ?? "";
    station = json["station"] ?? "";
    createdAt = DateTime.tryParse(json["created_at"]) ?? DateTime.now().toUtc();
  }

  Map<String, dynamic> toJson() => {
    'meal_id': mealID,
    'name': name,
    'station': station,
    "created_at": createdAt.toIso8601String()
  };
}

/*
{
  "meal_id": "portola-lunch-2023-03-23",
  "name": "Strawberry Salad w/Poppyseed Dressing (v",
  "station": "Greens \u0026 Grains",
  "created_at": "2023-03-22T05:09:30.053008Z"
},
 */