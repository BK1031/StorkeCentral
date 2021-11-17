class DiningHallMenuItem {
  String name = "";
  String station = "";

  DiningHallMenuItem();

  DiningHallMenuItem.fromJson(Map<String, dynamic> json) {
    name = json["name"] ?? "";
    station = json["station"] ?? "";
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'station': station,
  };
}

/*
{
    "name": "Vegetarian Taco Salad (v)",
    "station": "Greens & Grains"
}
 */