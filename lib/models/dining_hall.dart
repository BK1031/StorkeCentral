import 'dining_hall_meal.dart';

class DiningHall {
  String id = "";
  String name = "";
  bool hasSackMeal = false;
  bool hasTakeOut = false;
  bool hasDiningCam = false;
  double latitude = 0.0;
  double longitude = 0.0;
  DateTime createdAt = DateTime.now().toUtc();

  String pictureUrl = "";
  double distanceFromUser = 0.0;
  String status = "Loading...";

  List<DiningHallMeal> meals = [];

  DiningHall();

  pictureFromId(String id) {
    if (id == "carrillo") return "images/carrillo.jpeg";
    else if (id == "de-la-guerra") return "images/de-la-guerra.jpeg";
    else if (id == "ortega") return "images/ortega.jpeg";
    else if (id == "portola") return "images/portola.jpeg";
  }

  DiningHall.fromJson(Map<String, dynamic> json) {
    id = json["id"] ?? "";
    name = json["name"] ?? "";
    hasSackMeal = json["hasSackMeal"] ?? false;
    hasTakeOut = json["hasTakeOut"] ?? false;
    hasDiningCam = json["hasDiningCam"] ?? false;
    latitude = json["latitude"] ?? 0.0;
    longitude = json["longitude"] ?? 0.0;
    createdAt = DateTime.tryParse(json["created_at"]) ?? DateTime.now().toUtc();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'hasSackMeal': hasSackMeal,
    'hasTakeOut': hasTakeOut,
    'hasDiningCam': hasDiningCam,
    'latitude': latitude,
    'longitude': longitude,
    "created_at": createdAt.toIso8601String()
  };
}

/*
{
    "name": "Carrillo",
    "code": "carrillo",
    "hasSackMeal": false,
    "hasTakeOutMeal": false,
    "hasDiningCam": true,
    "location": {
      "latitude": 34.409953,
      "longitude": -119.852770
    }
}
 */