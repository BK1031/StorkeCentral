import 'package:storke_central/models/dining_hall_meal.dart';

class DiningHall {
  String name = "";
  String code = "";
  bool hasSackMeal = false;
  bool hasTakeOut = false;
  bool hasDiningCam = false;
  double latitude = 0.0;
  double longitude = 0.0;

  double distanceFromUser = 0.0;
  String status = "Loading...";

  List<DiningHallMeal> meals = [];

  DiningHall();

  DiningHall.fromJson(Map<String, dynamic> json) {
    name = json["name"] ?? "";
    code = json["code"] ?? "";
    hasSackMeal = json["hasSackMeal"] ?? false;
    hasTakeOut = json["hasTakeOut"] ?? false;
    hasDiningCam = json["hasDiningCam"] ?? false;
    latitude = json["location"]["latitude"] ?? 0.0;
    longitude = json["location"]["longitude"] ?? 0.0;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'code': code,
    'hasSackMeal': hasSackMeal,
    'hasTakeOut': hasTakeOut,
    'hasDiningCam': hasDiningCam,
    'latitude': latitude,
    'longitude': longitude,
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