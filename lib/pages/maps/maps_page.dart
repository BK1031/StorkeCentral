import 'package:extended_image/extended_image.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:storke_central/models/building.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/logger.dart';
import 'package:storke_central/utils/theme.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({Key? key}) : super(key: key);

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> with RouteAware, AutomaticKeepAliveClientMixin {

  MapboxMapController? mapController;
  bool _searching = false;
  bool _buildingSelected = false;
  FocusNode _searchFocus = FocusNode();
  TextEditingController _searchController = TextEditingController();

  List<Building> searchResults = [];

  @override
  bool get wantKeepAlive => false;

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(_onSearchFocusChange);
    orderBuildingsByDistance();
  }

  @override
  void dispose() {
    _searchFocus.removeListener(_onSearchFocusChange);
    _searchFocus.dispose();
    super.dispose();
  }

  _onSearchFocusChange() {
    if (_searchFocus.hasFocus) {
      cancelBuildingSelection();
      setState(() {
        _searching = true;
      });
    } else {
      setState(() {
        _searching = false;
      });
    }
  }

  buildingSearch(String input) {
    if (input.isNotEmpty) {
      setState(() {
        searchResults = extractTop(
          query: input,
          choices: buildings,
          limit: 5,
          cutoff: 50,
          getter: (Building b) => "${b.id.replaceAll("-", " ")} ${b.name} ${b.number}",
        ).map((e) => e.choice).toList();
      });
    } else {
      setState(() {
        searchResults.clear();
      });
    }
  }

  void orderBuildingsByDistance() {
    for (int i = 0; i < buildings.length; i++) {
      buildings[i].distanceFromUser = distanceFromUser(buildings[i].latitude, buildings[i].longitude);
    }
    setState(() {
      buildings.sort((a, b) => a.distanceFromUser.compareTo(b.distanceFromUser));
    });
  }

  double distanceFromUser(double lat, double long) {
    double distance = 0.0;
    try {
      distance = Geolocator.distanceBetween(currentPosition!.latitude, currentPosition!.longitude, lat, long);
      return distance;
    } catch(err) {
      // TODO: Show error snackbar
      log(err.toString(), LogLevel.error);
    }
    return distance;
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

  void _onMapCreated(MapboxMapController controller) {
    mapController = controller;
  }
  
  void selectBuilding(Building building) {
    mapController?.removeSymbols(mapController!.symbols);
    log("Selected building ${building.name}", LogLevel.info);
    setState(() {
      selectedBuilding = building;
      _buildingSelected = true;
      _searching = false;
      _searchController.clear();
      _searchFocus.unfocus();
      searchResults.clear();
    });
    mapController?.addSymbol(SymbolOptions(
      geometry: LatLng(building.latitude, building.longitude),
      iconSize: kIsWeb ? 0.5 : 1.5,
      iconOffset: const Offset(0, -10),
      iconImage: getBuildingTypeIcon(building.type),
    ));
    mapController?.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: LatLng(building.latitude - 0.0010, building.longitude),
        zoom: 16,
      ),
    ));
  }

  void cancelBuildingSelection() {
    mapController?.removeSymbols(mapController!.symbols);
    setState(() {
      selectedBuilding = Building();
      _buildingSelected = false;
    });
    mapController?.animateCamera(CameraUpdate.newCameraPosition(const CameraPosition(
        target: LatLng(34.412278, -119.847787),
        zoom: 14.0,
    )));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Stack(
        children: [
          MapboxMap(
            accessToken: kIsWeb ? MAPBOX_PUBLIC_TOKEN : MAPBOX_ACCESS_TOKEN,
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(34.412278, -119.847787),
              zoom: 14.0,
            ),
            myLocationEnabled: true,
            dragEnabled: true,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                child: Card(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    height: searchResults.isEmpty ? 45 : searchResults.length * 58 + 50,
                    padding: const EdgeInsets.only(left: 8, right: 8),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 45,
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocus,
                            decoration: const InputDecoration(
                              icon: Icon(Icons.search_rounded),
                              border: InputBorder.none,
                              hintText: "Search for building name",
                            ),
                            textCapitalization: TextCapitalization.words,
                            keyboardType: TextInputType.name,
                            // style: const TextStyle(fontSize: 14),
                            onChanged: buildingSearch,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            child: ListView.builder(
                              itemCount: searchResults.length,
                              itemBuilder: (context, index) {
                                return Card(
                                  child: InkWell(
                                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                                    onTap: () {
                                      selectBuilding(searchResults[index]);
                                    },
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.all(Radius.circular(8)),
                                          child: ExtendedImage.network(
                                            searchResults[index].pictureURL,
                                            fit: BoxFit.cover,
                                            height: 50,
                                            width: 50,
                                          ),
                                        ),
                                        const Padding(padding: EdgeInsets.all(4)),
                                        Expanded(
                                          child: Text(
                                            searchResults[index].name,
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                        Text(
                                          "${(buildings[index].distanceFromUser * UNITS_CONVERSION[PREF_UNITS]!).round()} ${PREF_UNITS.toLowerCase()}",
                                          style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.caption!.color),
                                        ),
                                        Icon(Icons.arrow_forward_ios_rounded, color: Theme.of(context).textTheme.caption!.color),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                height: _searching || _buildingSelected ? 0 : 162,
                child: ListView.builder(
                  itemCount: buildings.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Padding(
                      padding: EdgeInsets.only(right: 4, left: (index == 0) ? 8 : 0, bottom: 12),
                      child: SizedBox(
                        width: 150,
                        child: Card(
                          child: GestureDetector(
                            onTap: () {
                              selectBuilding(buildings[index]);
                            },
                            child: ClipRRect(
                              borderRadius: const BorderRadius.all(Radius.circular(8)),
                              child: Stack(
                                children: [
                                  ExtendedImage.network(
                                    buildings[index].pictureURL,
                                    fit: BoxFit.cover,
                                    height: 150,
                                    width: 150,
                                  ),
                                  Container(
                                    height: 350.0,
                                    decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                            begin: FractionalOffset.topCenter,
                                            end: FractionalOffset.bottomCenter,
                                            colors: [
                                              // Colors.grey.withOpacity(1.0),
                                              Colors.grey.withOpacity(0.0),
                                              Colors.black,
                                            ],
                                            stops: const [0, 1]
                                        )
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(buildings[index].name, style: const TextStyle(color: Colors.white),),
                                            ),
                                          ],
                                        ),
                                        Text("${(buildings[index].distanceFromUser * UNITS_CONVERSION[PREF_UNITS]!).round()} ${PREF_UNITS.toLowerCase()}", style: TextStyle(color: Colors.grey, fontSize: 12),)
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  scrollDirection: Axis.horizontal,
                ),
              )
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                height: !_searching && _buildingSelected ? 350 : 0,
                padding: const EdgeInsets.all(8),
                child: Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          router.navigateTo(context, "/maps/buildings/${selectedBuilding.id}", transition: TransitionType.native);
                        },
                        child: ClipRRect(
                          borderRadius: const BorderRadius.all(Radius.circular(8)),
                          child: Stack(
                            children: [
                              Hero(
                                tag: "${selectedBuilding.id}-image",
                                child: ExtendedImage.network(
                                  selectedBuilding.pictureURL,
                                  fit: BoxFit.cover,
                                  height: 125,
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
                                          // Colors.grey.withOpacity(1.0),
                                          Colors.grey.withOpacity(0.0),
                                          Colors.black,
                                        ],
                                        stops: const [0, 1]
                                    )
                                ),
                              ),
                              Container(
                                height: 125,
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.close, color: Colors.white,),
                                          padding: EdgeInsets.zero,
                                          onPressed: () {
                                            cancelBuildingSelection();
                                          },
                                        )
                                      ],
                                    ),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Expanded(
                                          child: Hero(
                                            tag: "${selectedBuilding.id}-title",
                                            child: Material(
                                              color: Colors.transparent,
                                              child: Text(
                                                selectedBuilding.name,
                                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                            ),
                                          )
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          child: SingleChildScrollView(
                            child: Text(
                              selectedBuilding.description,
                              // style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
                        child: Row(
                          children: [
                            Text("Navigate me here (${(selectedBuilding.distanceFromUser * UNITS_CONVERSION[PREF_UNITS]!).round()} ${PREF_UNITS.toLowerCase()})", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const Padding(padding: EdgeInsets.all(4)),
                            Expanded(
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                color: SB_NAVY,
                                onPressed: () {
                                  // navigateToBuilding(selectedBuilding, MapBoxNavigationMode.cycling);
                                  router.navigateTo(context, "/maps/buildings/${selectedBuilding.id}?navigate", transition: TransitionType.native);
                                },
                                child: const Icon(Icons.directions_walk_rounded, color: Colors.white,),
                              ),
                            ),
                            const Padding(padding: EdgeInsets.all(4)),
                            Expanded(
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                color: SB_NAVY,
                                onPressed: () {
                                  // navigateToBuilding(selectedBuilding, MapBoxNavigationMode.cycling);
                                  router.navigateTo(context, "/maps/buildings/${selectedBuilding.id}?navigate", transition: TransitionType.native);
                                },
                                child: const Icon(Icons.directions_bike_rounded, color: Colors.white,),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                )
              )
            ],
          ),
        ],
      ),
    );
  }
}
