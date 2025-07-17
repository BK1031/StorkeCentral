// ignore_for_file: no_logic_in_create_state, must_be_immutable

import 'dart:convert';
import 'dart:math';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:storke_central/models/building.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/logger.dart';
import 'package:storke_central/utils/theme.dart';

class BuildingDetailsPage extends StatefulWidget {
  String buildingID = "";
  BuildingDetailsPage({Key? key, required this.buildingID}) : super(key: key);

  @override
  State<BuildingDetailsPage> createState() => _BuildingDetailsPageState(buildingID);
}

class _BuildingDetailsPageState extends State<BuildingDetailsPage> {

  String buildingID = "";
  Building selectedBuilding = Building();

  MapboxMapController? mapController;
  final PageController _controller = PageController();
  int currPage = 0;

  String navType = "walking";
  Map geometry = {};
  double duration = 0.0;
  double distance = 0.0;

  _BuildingDetailsPageState(this.buildingID);

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    getBuilding();
    Future.delayed(Duration.zero, () {
      if (ModalRoute.of(context)!.settings.name!.contains("?cycling") || ModalRoute.of(context)!.settings.name!.contains("?walking")) {
        navType = ModalRoute.of(context)!.settings.name!.split("?")[1];
        currPage = 2;
        generateRoute();
        _controller.animateToPage(2, duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
      }
    });
  }

  void getBuilding() {
    setState(() {
      selectedBuilding = buildings.firstWhere((element) => element.id == buildingID);
    });
  }

  void _onMapCreated(MapboxMapController controller) {
    mapController = controller;
    generateRoute();
  }

  String getBuildingTypeIcon(String type) {
    switch (type) {
      case "Research Laboratory":
        return "images/markers/lab-marker.png";
      case "Trailer":
        return "images/markers/trailer-marker.png";
      case "Dining Hall":
        return "images/markers/dining-marker.png";
      case "Recreation":
        return "images/markers/recreation-marker.png";
      default:
        return "images/markers/building-marker.png";
    }
  }

  void generateRoute() {
    Future.delayed(const Duration(milliseconds: 400)).then((value) async {
      mapController?.addSymbol(SymbolOptions(
        geometry: LatLng(selectedBuilding.latitude, selectedBuilding.longitude),
        iconImage: getBuildingTypeIcon(selectedBuilding.type),
        iconSize: kIsWeb ? 0.5 : 1.5,
      ));
      await mapboxDirectionsRequest();
      animateCameraToBuilding();
      final fills = {
        "type": "FeatureCollection",
        "features": [
          {
            "type": "Feature",
            "id": 0,
            "properties": <String, dynamic>{},
            "geometry": geometry,
          },
        ],
      };
      await mapController!.removeLayer("lines");
      await mapController!.removeSource("fills");
      // Add new source and lineLayer
      await mapController!.addSource("fills", GeojsonSourceProperties(data: fills));
      await mapController!.addLineLayer(
        "fills",
        "lines",
        LineLayerProperties(
          lineColor: ACTIVE_ACCENT_COLOR.toHexStringRGB(),
          lineOpacity: 0.8,
          lineCap: "round",
          lineJoin: "round",
          lineWidth: 3,
        ),
      );
    });
  }

  Future<void> mapboxDirectionsRequest() async {
    String baseUrl = "https://api.mapbox.com/directions/v5/mapbox";
    String url = "$baseUrl/$navType/${currentPosition?.longitude},${currentPosition?.latitude};${selectedBuilding.longitude},${selectedBuilding.latitude}?alternatives=true&continue_straight=true&geometries=geojson&language=en&overview=full&steps=true&access_token=$MAPBOX_ACCESS_TOKEN";
    try {
      http.get(Uri.parse(url)).then((response) {
        Map<String, dynamic> responseJson = json.decode(response.body);
        setState(() {
          geometry = responseJson['routes'][0]['geometry'];
          duration = double.parse(responseJson['routes'][0]['duration'].toString());
          distance = double.parse(responseJson['routes'][0]['distance'].toString());
        });
      });
    } catch (e) {
      log("[building_details_page] ${e.toString()}", LogLevel.error);
    }
  }

  void animateCameraToBuilding() {
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng((currentPosition!.latitude + selectedBuilding.latitude) / 2, (currentPosition!.longitude + selectedBuilding.longitude) / 2),
          zoom: Geolocator.distanceBetween(currentPosition!.latitude, currentPosition!.longitude, selectedBuilding.latitude, selectedBuilding.longitude) < 500 ? 15.5 : 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Hero(
                tag: "${selectedBuilding.id}-image",
                child: ExtendedImage.network(
                  selectedBuilding.pictureURL,
                  fit: BoxFit.cover,
                  height: 250,
                  width: double.infinity,
                ),
              ),
              Container(
                height: 125,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: FractionalOffset.topCenter,
                        end: FractionalOffset.bottomCenter,
                        colors: [
                          Colors.grey.withOpacity(0.0),
                          Colors.black,
                        ],
                        stops: const [0, 1]
                    )
                ),
              ),
              Container(
                height: 250,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Hero(
                      tag: "${selectedBuilding.id}-title",
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          selectedBuilding.name,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: Stack(
              children: [
                PageView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: _controller,
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(padding: EdgeInsets.all(32),),
                          selectedBuilding.number != "0" ? Text("Building ${selectedBuilding.number}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)) : Container(),
                          const Padding(padding: EdgeInsets.all(8),),
                          Text(selectedBuilding.description, style: const TextStyle(fontSize: 16)),
                          const Padding(padding: EdgeInsets.all(8),),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(padding: EdgeInsets.all(32),),
                          Text("Coming Soon!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Stack(
                      children: [
                        MapboxMap(
                          styleString: AdaptiveTheme.of(context).brightness == Brightness.light ? MAPBOX_LIGHT_THEME : MAPBOX_DARK_THEME,
                          accessToken: kIsWeb ? MAPBOX_PUBLIC_TOKEN : MAPBOX_ACCESS_TOKEN,
                          onMapCreated: _onMapCreated,
                          initialCameraPosition: const CameraPosition(
                            target: LatLng(34.412278, -119.847787),
                            zoom: 14.0,
                          ),
                          attributionButtonMargins: const Point(-32, -32),
                          myLocationEnabled: true,
                          dragEnabled: true,
                        ),
                        Visibility(
                          visible: distance != 0.0,
                          child: SafeArea(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              width: double.infinity,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Card(
                                    elevation: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 45,
                                            child: CupertinoButton(
                                              padding: EdgeInsets.zero,
                                              color: navType == "walking" ? ACTIVE_ACCENT_COLOR : null,
                                              onPressed: () {
                                                setState(() {
                                                  navType = "walking";
                                                });
                                                generateRoute();
                                              },
                                              child: Icon(Icons.directions_walk_rounded, color: navType == "walking" ? Colors.white : null),
                                            ),
                                          ),
                                          const Padding(padding: EdgeInsets.all(4)),
                                          SizedBox(
                                            width: 45,
                                            child: CupertinoButton(
                                              padding: EdgeInsets.zero,
                                              color: navType == "cycling" ? ACTIVE_ACCENT_COLOR : null,
                                              onPressed: () {
                                                setState(() {
                                                  navType = "cycling";
                                                });
                                                generateRoute();
                                              },
                                              child: Icon(Icons.directions_bike_rounded, color: navType == "cycling" ? Colors.white : null),
                                            ),
                                          ),
                                          const Padding(padding: EdgeInsets.all(4)),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text("${(distance * UNITS_CONVERSION[PREF_UNITS]!).round()} ${PREF_UNITS.toLowerCase()}", style: const TextStyle(fontSize: 18),),
                                              const Text("Distance"),
                                            ],
                                          ),
                                          const Padding(padding: EdgeInsets.all(4),),
                                          Container(
                                            width: 1, // Thickness
                                            height: 35,
                                            color: Colors.grey,
                                          ),
                                          const Padding(padding: EdgeInsets.all(4),),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text("${(duration / 60).round()} min", style: const TextStyle(fontSize: 18),),
                                              const Text("Time"),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
                Container(
                  padding: const EdgeInsets.only(left: 8, top: 8, right: 8),
                  child: Card(
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            color: currPage == 0 ? ACTIVE_ACCENT_COLOR : null,
                            onPressed: () {
                              setState(() {
                                currPage = 0;
                              });
                              _controller.animateToPage(0, duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
                            },
                            child: Text("Overview", style: TextStyle(color: currPage == 0 ? Colors.white : Theme.of(context).textTheme.labelLarge!.color)),
                          ),
                        ),
                        Expanded(
                          child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              color: currPage == 1 ? ACTIVE_ACCENT_COLOR : null,
                              onPressed: () {
                                setState(() {
                                  currPage = 1;
                                });
                                _controller.animateToPage(1, duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
                              },
                              child: Text("Floor plan", style: TextStyle(color: currPage == 1 ? Colors.white : Theme.of(context).textTheme.labelLarge!.color))
                          ),
                        ),
                        Expanded(
                          child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              color: currPage == 2 ? ACTIVE_ACCENT_COLOR : null,
                              onPressed: () {
                                setState(() {
                                  currPage = 2;
                                });
                                _controller.animateToPage(2, duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
                              },
                              child: Text("Maps", style: TextStyle(color: currPage == 2 ? Colors.white : Theme.of(context).textTheme.labelLarge!.color))
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}