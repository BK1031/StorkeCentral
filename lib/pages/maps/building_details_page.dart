import 'package:flutter/material.dart';
import 'package:storke_central/models/building.dart';
import 'package:storke_central/utils/config.dart';
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

  PageController _controller = PageController();
  int currPage = 0;

  _BuildingDetailsPageState(this.buildingID);

  @override
  void initState() {
    super.initState();
    getBuilding();
  }

  void getBuilding() {
    setState(() {
      selectedBuilding = buildings.firstWhere((element) => element.id == buildingID);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: 4,
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                elevation: 0,
                expandedHeight: 200.0,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                  title: Hero(
                    tag: "${selectedBuilding.id}-title",
                    child: Text(
                      selectedBuilding.name,
                      style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  background: Hero(
                    tag: "${selectedBuilding.id}-image",
                    child: Image.network(
                      selectedBuilding.pictureURL,
                      fit: BoxFit.cover,
                    ),
                  )),
              ),
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  const TabBar(
                    tabs: [
                      Tab(text: "OVERVIEW"),
                      Tab(text: "WALKING"),
                      Tab(text: "BIKING"),
                    ],
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: Container(
              child: TabBarView(
                children: [
                  Placeholder(),
                  Placeholder(),
                  Placeholder(),
                ],
              )
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      padding: const EdgeInsets.only(left: 4, top: 4, right: 4),
      child: Card(
        color: SB_NAVY,
        child: _tabBar,
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}