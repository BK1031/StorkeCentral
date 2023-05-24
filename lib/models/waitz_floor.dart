class WaitzFloor {

  int id = 0;
  String name = "";
  int busyness = 0;
  int people = 0;
  int capacity = 0;
  bool isAvailable = false;
  String hourSummary = "";
  bool isOpen = false;
  double percentage = 0.0;
  String summary = "";

  WaitzFloor();

  WaitzFloor.fromJson(Map<String, dynamic> json) {
    id = json["id"] ?? "";
    name = json["name"] ?? "";
    busyness = json["busyness"] ?? 0;
    people = json["people"] ?? 0;
    capacity = json["capacity"] ?? 0;
    isAvailable = json["isAvailable"] ?? false;
    hourSummary = json["hourSummary"] ?? "";
    isOpen = json["isOpen"] ?? false;
    percentage = json["percentage"] ?? 0.0;
    summary = json["subLocHtml"]["summary"] ?? "";
  }

}