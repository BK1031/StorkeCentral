import 'package:storke_central/models/waitz_floor.dart';
import 'package:storke_central/utils/logger.dart';

class WaitzBuilding {

  String name = "";
  int busyness = 0;
  int people = 0;
  bool isAvailable = false;
  int capacity = 0;
  String hourSummary = "";
  bool isOpen = false;
  String bestLabel = "";
  double percentage = 0.0;
  String summary = "";

  List<WaitzFloor> floors = [];

  WaitzBuilding();

  WaitzBuilding.fromJson(Map<String, dynamic> json) {
    name = json["name"] ?? "";
    busyness = json["busyness"] ?? 0;
    people = json["people"] ?? 0;
    isAvailable = json["isAvailable"] ?? false;
    capacity = json["capacity"] ?? 0;
    hourSummary = json["hourSummary"] ?? "";
    isOpen = json["isOpen"] ?? false;
    bestLabel = json["bestLabel"] ?? "";
    percentage = json["percentage"] ?? 0.0;
    summary = json["locHtml"]["summary"] ?? "";
    try {
      for (int i = 0; i < json["subLocs"].length; i++) {
        floors.add(WaitzFloor.fromJson(json["subLocs"][i]));
      }
    } catch (err) {
      log("No subLocs for $name");
    }
  }

}