import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/theme.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SettingsAboutPage extends StatefulWidget {
  const SettingsAboutPage({Key? key}) : super(key: key);

  @override
  State<SettingsAboutPage> createState() => _SettingsAboutPageState();
}

class _SettingsAboutPageState extends State<SettingsAboutPage> {

  String version = "";
  String deviceName = "";
  String deviceVersion = "";

  String connectionType = "";
  String connectionSSID = "";
  String connectionIP = "";

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    queryDeviceInfo();
    queryNetworkInfo();
  }

  Future<void> queryDeviceInfo() async {
    setState(() {
      if (Platform.isIOS) version = "StorkeCentral iOS v${appVersion.toString()}";
      if (Platform.isAndroid) version = "StorkeCentral Android v${appVersion.toString()}";
      if (kIsWeb) version = "StorkeCentral Web v${appVersion.toString()}";
      deviceName = Platform.localHostname;
      deviceVersion = "${Platform.operatingSystem.toUpperCase()} ${Platform.operatingSystemVersion}";
    });
  }

  Future<void> queryNetworkInfo() async {
    final info = NetworkInfo();
    var wifiName = await info.getWifiName(); // FooNetwor
    var wifiIP = await info.getWifiIP(); // 192.168.1.43
    var connectivityResult = await (Connectivity().checkConnectivity());
    setState(() {
      if (connectivityResult == ConnectivityResult.wifi) connectionType = "WiFi";
      if (connectivityResult == ConnectivityResult.mobile) connectionType = "Cellular";
      connectionSSID = wifiName ?? "Error";
      connectionIP = wifiIP ?? "Error";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "About",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(left: 8, top: 8, right: 8),
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
                      child: Text(
                        "Device",
                        // "Developer".toUpperCase(),
                        style: TextStyle(color: ACTIVE_ACCENT_COLOR, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ListTile(
                      title: const Text("App Version"),
                      trailing: Text(
                        version,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    ListTile(
                      title: const Text("Device Name"),
                      trailing: Text(
                        deviceName,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    ListTile(
                      title: const Text("Device Version"),
                      trailing: Text(
                        deviceVersion,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(left: 8, top: 8, right: 8),
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
                      child: Text(
                        "Network",
                        // "Developer".toUpperCase(),
                        style: TextStyle(color: ACTIVE_ACCENT_COLOR, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ListTile(
                      title: const Text("Connection Type"),
                      trailing: Text(
                        connectionType,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    ListTile(
                      title: const Text("Network SSID"),
                      trailing: Text(
                        connectionSSID,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    ListTile(
                      title: const Text("Network IP"),
                      trailing: Text(
                        connectionIP,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(left: 8, top: 8, right: 8),
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
                      child: Text(
                        "Contributors",
                        // "Developer".toUpperCase(),
                        style: TextStyle(color: ACTIVE_ACCENT_COLOR, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ListTile(
                      title: const Text("Bharat Kathi"),
                      onTap: () {
                        launchUrlString("https://www.instagram.com/bk1031_official/");
                      },
                    ),
                    ListTile(
                      title: const Text("Neel Tripathi"),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(left: 8, top: 8, right: 8),
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
                      child: Text(
                        "Supporters",
                        // "Developer".toUpperCase(),
                        style: TextStyle(color: ACTIVE_ACCENT_COLOR, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Column(
                      children: [
                        "Adam Tatarkhanov",
                        "Adrian Vu",
                        "Alex Lopes",
                        "Anthony Galvan",
                        "Camron Hosseini",
                        "Jake Schultz",
                        "Jose Saavedra",
                        "Zeke Feinglass"
                      ].map((name) => ListTile(
                        title: Text(name),
                        onTap: () {},
                      )).toList(),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
