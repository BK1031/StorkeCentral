import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:storke_central/utils/config.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({Key? key}) : super(key: key);

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MapboxMap(
        accessToken: MAPBOX_ACCESS_TOKEN,
        initialCameraPosition: const CameraPosition(
          target: LatLng(34.412278, -119.847787),
          zoom: 14.0,
        ),
        dragEnabled: true,
      ),
    );
  }
}
