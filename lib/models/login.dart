class Login {
  String id = "";
  String userID = "";
  double latitude = 0.0;
  double longitude = 0.0;
  String appVersion = "";
  String deviceName = "";
  String deviceVersion = "";
  String connectionType = "";
  String connectionSSID = "";
  String connectionIP = "";
  DateTime createdAt = DateTime.now().toUtc();

  Login();

  Login.fromJson(Map<String, dynamic> json) {
    id = json["id"] ?? "";
    userID = json["user_id"] ?? "";
    latitude = json["latitude"] ?? 0.0;
    longitude = json["longitude"] ?? 0.0;
    appVersion = json["app_version"] ?? "";
    deviceName = json["device_name"] ?? "";
    deviceVersion = json["device_version"] ?? "";
    connectionType = json["connection_type"] ?? "";
    connectionSSID = json["connection_ssid"] ?? "";
    connectionIP = json["connection_ip"] ?? "";
    createdAt = DateTime.tryParse(json["created_at"]) ?? DateTime.now().toUtc();
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "user_id": userID,
      "latitude": latitude,
      "longitude": longitude,
      "app_version": appVersion,
      "device_name": deviceName,
      "device_version": deviceVersion,
      "connection_type": connectionType,
      "connection_ssid": connectionSSID,
      "connection_ip": connectionIP,
      "created_at": createdAt.toIso8601String()
    };
  }
}

/*
{
  "id": "140de00a-48e4-422d-8554-c46971dddc42",
  "user_id": "hi",
  "latitude": 34.4092574,
  "longitude": -119.8515887,
  "agent": "StorkeCentral iOS v1.0.2",
  "connection_type": "",
  "connection_ssid": "",
  "connection_ip": "",
  "created_at": "2022-05-27T05:10:41.721892Z"
}
 */