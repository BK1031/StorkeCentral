import 'dart:async';

import 'package:cool_alert/cool_alert.dart';
import 'package:flutter/material.dart';
import 'package:storke_central/utils/config.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({Key? key}) : super(key: key);

  @override
  _MapsPageState createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {

  MapboxMapController? mapController;
  MyLocationTrackingMode myLocationTrackingMode = MyLocationTrackingMode.Tracking;

  StreamSubscription<Position>? positionStream;
  Position? position;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    super.dispose();
    positionStream?.cancel();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return CoolAlert.show(
          context: context,
          type: CoolAlertType.error,
          title: "Failed to retrieve location!",
          text: "We were unable to retrieve device location. Please verify that Location Services are enabled for this app in System Settings."
      );
    }
    positionStream = Geolocator.getPositionStream().listen((Position position) {
      // print(position == null ? 'Unknown' : position.latitude.toString() + ', ' + position.longitude.toString());
      if (mounted) {
        setState(() {
          this.position = position;
        });
        mapController!.animateCamera(CameraUpdate.newLatLngZoom(LatLng(position.latitude, position.longitude), 15));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Map", style: TextStyle(fontWeight: FontWeight.bold),),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(myLocationTrackingMode == MyLocationTrackingMode.Tracking ? Icons.gps_fixed : Icons.location_searching, color: Colors.white,),
          onPressed: () {
            setState(() {
              if (myLocationTrackingMode == MyLocationTrackingMode.None) {
                myLocationTrackingMode = MyLocationTrackingMode.Tracking;
                print("Tracking Mode: Tracking");
              }
              else {
                myLocationTrackingMode = MyLocationTrackingMode.None;
                print("Tracking Mode: None");
              }
            });
          },
        ),
        backgroundColor: Colors.greenAccent,
        body: MapboxMap(
          accessToken: MAPBOX_ACCESS_TOKEN,
          initialCameraPosition: const CameraPosition(target: LatLng(34.413563, -119.846482), zoom: 14),
          myLocationRenderMode: MyLocationRenderMode.COMPASS,
          onMapCreated: (controller) {
            mapController = controller;
            controller.animateCamera(CameraUpdate.newLatLngZoom(LatLng(position?.latitude ?? 34.413563, position?.longitude ?? -119.846482), 18));
          },
          myLocationEnabled: true,
        )
    );
  }
}
