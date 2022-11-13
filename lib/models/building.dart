class Building {
  String id = "";
  String number = "";
  String name = "";
  String description = "";
  String type = "";
  String pictureURL = "";
  double latitude = 0.0;
  double longitude = 0.0;
  double distanceFromUser = 0.0;
  DateTime updatedAt = DateTime.now().toUtc();
  DateTime createdAt = DateTime.now().toUtc();

  Building();

  Building.fromJson(Map<String, dynamic> json) {
    id = json["id"] ?? "";
    number = json["number"] ?? "";
    name = json["name"] ?? "";
    description = json["description"] ?? "";
    type = json["type"] ?? "";
    pictureURL = json["picture_url"] ?? "";
    latitude = json["latitude"] ?? 0.0;
    longitude = json["longitude"] ?? 0.0;
    updatedAt = DateTime.tryParse(json["updated_at"]) ?? DateTime.now().toUtc();
    createdAt = DateTime.tryParse(json["created_at"]) ?? DateTime.now().toUtc();
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "number": number,
      "name": name,
      "description": description,
      "type": type,
      "picture_url": pictureURL,
      "latitude": latitude,
      "longitude": longitude,
      "updated_at": updatedAt.toIso8601String(),
      "created_at": createdAt.toIso8601String()
    };
  }
}