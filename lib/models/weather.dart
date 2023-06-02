class Weather {
  int id = 0;
  String main = "";
  String description = "";
  String icon = "";

  double temp = 0.0;
  double feelsLike = 0.0;
  double tempMin = 0.0;
  double tempMax = 0.0;
  int pressure = 0;
  int humidity = 0;

  int visibility = 0;

  double windSpeed = 0.0;
  int windDeg = 0;

  double longitude = 0.0;
  double latitude = 0.0;

  Weather();

  Weather.fromJson(Map<String, dynamic> json) {
    id = json["weather"][0]["id"];
    main = json["weather"][0]["main"];
    description = json["weather"][0]["description"];
    icon = json["weather"][0]["icon"];

    temp = json["main"]["temp"];
    feelsLike = json["main"]["feels_like"];
    tempMin = json["main"]["temp_min"];
    tempMax = json["main"]["temp_max"];
    pressure = json["main"]["pressure"];
    humidity = json["main"]["humidity"];

    visibility = json["visibility"];

    windSpeed = json["wind"]["speed"];
    windDeg = json["wind"]["deg"];

    longitude = json["coord"]["lon"];
    latitude = json["coord"]["lat"];
  }

}

/*
{
	"coord": {
		"lon": -119.8455,
		"lat": 34.4128
	},
	"weather": [
		{
			"id": 803,
			"main": "Clouds",
			"description": "broken clouds",
			"icon": "04d"
		}
	],
	"base": "stations",
	"main": {
		"temp": 292.22,
		"feels_like": 292.04,
		"temp_min": 290.07,
		"temp_max": 294.14,
		"pressure": 1013,
		"humidity": 71
	},
	"visibility": 10000,
	"wind": {
		"speed": 3.6,
		"deg": 230
	},
	"clouds": {
		"all": 75
	},
	"dt": 1685666988,
	"sys": {
		"type": 1,
		"id": 5773,
		"country": "US",
		"sunrise": 1685623703,
		"sunset": 1685675182
	},
	"timezone": -25200,
	"id": 5359864,
	"name": "Isla Vista",
	"cod": 200
}
 */