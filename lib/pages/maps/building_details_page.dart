import 'package:flutter/material.dart';
import 'package:storke_central/models/building.dart';
import 'package:storke_central/utils/config.dart';

class BuildingDetailsPage extends StatefulWidget {
  String buildingID = "";
  BuildingDetailsPage({Key? key, required this.buildingID}) : super(key: key);

  @override
  State<BuildingDetailsPage> createState() => _BuildingDetailsPageState(buildingID);
}

class _BuildingDetailsPageState extends State<BuildingDetailsPage> {

  String buildingID = "";
  Building selectedBuilding = Building();

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
      appBar: AppBar(
        title: Text(
          selectedBuilding.name,
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
      ),
    );
  }
}
