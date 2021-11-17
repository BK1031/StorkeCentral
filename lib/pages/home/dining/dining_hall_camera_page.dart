import 'dart:convert';

import 'package:cool_alert/cool_alert.dart';
import 'package:easy_web_view2/easy_web_view2.dart';
import 'package:flutter/material.dart';
import 'package:storke_central/models/dining_hall.dart';
import 'package:storke_central/utils/config.dart';
import 'package:http/http.dart' as http;

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
                child: EasyWebView(
                  onLoaded: () {
                    print('$key: Loaded: $src');
                  },
                  key: key,
                  src: src,
                  isHtml: false, // Use Html syntax
                  isMarkdown: false, // Use markdown syntax
                  convertToWidgets: false, // Try to convert to flutter widgets
                  // width: 100,
                  // height: 100,
                ),
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
