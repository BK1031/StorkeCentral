import 'package:flutter/material.dart';
import 'package:storke_central/utils/config.dart';

class DiningHallCameraPage extends StatefulWidget {
  String id;
  DiningHallCameraPage(this.id, {Key? key}) : super(key: key);
  @override
  _DiningHallCameraPageState createState() => _DiningHallCameraPageState(id);
}

class _DiningHallCameraPageState extends State<DiningHallCameraPage> {

  static ValueKey key = const ValueKey('key_0');
  String src = "https://api.ucsb.edu/dining/cams/v2/stream/${selectedDiningHall.code}?ucsb-api-key=$UCSB_DINING_CAM_KEY";

  _DiningHallCameraPageState(String id) {
    selectedDiningHall.code = id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text("Dining Cam"),
      // ),
        body: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(color: Colors.greenAccent,)
              ),
            ),
            Padding(
                padding: const EdgeInsets.all(8),
                child: Text("LIVE: ${selectedDiningHall.name} Dining Commons")
            )
          ],
        )
    );
  }
}
