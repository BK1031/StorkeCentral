import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:storke_central/utils/config.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({Key? key}) : super(key: key);

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> with AutomaticKeepAliveClientMixin {

  bool _searching = false;
  FocusNode _searchFocus = FocusNode();
  TextEditingController _searchController = TextEditingController();

  // TODO: Replace these with building objects from maps service
  List<String> buildings = ["Storke Tower", "Broida Hall", "Buchanan Hall", "Elings Hall", "El Dorado Apartments", "Westgate Apartments", "Manzanita Village"];
  List<String> searchResults = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(_onSearchFocusChange);
  }

  @override
  void dispose() {
    _searchFocus.removeListener(_onSearchFocusChange);
    _searchFocus.dispose();
    super.dispose();
  }

  _onSearchFocusChange() {
    if (_searchFocus.hasFocus) {
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
          cutoff: 50
        ).map((e) => e.choice).toList();
      });
    } else {
      setState(() {
        searchResults.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Stack(
        children: [
          MapboxMap(
            accessToken: MAPBOX_ACCESS_TOKEN,
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
                    height: searchResults.isEmpty ? 45 : searchResults.length * 58 + 45,
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
                              hintText: "Search for building",
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

                                    },
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.all(Radius.circular(8)),
                                          child: ExtendedImage.network(
                                            "https://www.news.ucsb.edu/file/15062/download?token=3PaDYINg",
                                            fit: BoxFit.cover,
                                            height: 50,
                                            width: 50,
                                          ),
                                        ),
                                        const Padding(padding: EdgeInsets.all(4)),
                                        Expanded(
                                          child: Text(
                                            searchResults[index],
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                        Text(
                                          "32 m",
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
          Visibility(
            visible: !_searching,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: 162,
                  child: ListView.builder(
                    itemCount: 3,
                    itemBuilder: (BuildContext context, int i) {
                      return Padding(
                        padding: EdgeInsets.only(right: 4, left: (i == 0) ? 8 : 0, bottom: 12),
                        child: SizedBox(
                          width: 150,
                          child: Card(
                            child: GestureDetector(
                              onTap: () {

                              },
                              child: ClipRRect(
                                borderRadius: const BorderRadius.all(Radius.circular(8)),
                                child: Stack(
                                  children: [
                                    ExtendedImage.network(
                                      "https://www.news.ucsb.edu/file/15062/download?token=3PaDYINg",
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
                                                child: Hero(
                                                    tag: "Storke Tower",
                                                    child: Text("Storke Tower", style: const TextStyle(color: Colors.white),)
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text("123 m", style: const TextStyle(color: Colors.white, fontSize: 12),)
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
          ),
        ],
      ),
    );
  }
}
