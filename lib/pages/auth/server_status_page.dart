import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storke_central/utils/auth_service.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/string_extension.dart';
import 'package:storke_central/utils/theme.dart';


class ServerStatusPage extends StatefulWidget {
  const ServerStatusPage({Key? key}) : super(key: key);

  @override
  State<ServerStatusPage> createState() => _ServerStatusPageState();
}

class _ServerStatusPageState extends State<ServerStatusPage> {

  Map<String, String> status = {};
  Timer? timer;
  bool criticalSystemsOnline = false;

  @override
  void initState() {
    getAllServiceStatuses();
    timer = Timer.periodic(const Duration(seconds: 10), (Timer t) => getAllServiceStatuses());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void getAllServiceStatuses() {
    getServiceStatus("montecito");
    getServiceStatus("rincon");
    getServiceStatus("lacumbre");
  }

  Future<void> getServiceStatus(String service) async {
    setState(() {
      status[service] = "LOADING";
    });
    try {
      var serviceStatus = await http.get(Uri.parse("$API_HOST/$service/ping"));
      print("$service: ${serviceStatus.statusCode}");
      setState(() {
        status[service] = serviceStatus.statusCode == 200 ? "ONLINE" : "OFFLINE";
      });
      // Critical system check
      if (status["montecito"] == "ONLINE" && status["rincon"] == "ONLINE" && status["lacumbre"] == "ONLINE") {
        setState(() {
          criticalSystemsOnline = true;
        });
      } else {
        setState(() {
          criticalSystemsOnline = false;
        });
      }
    } catch (err) {
      print("$service: $err");
      setState(() {
        status[service] = "OFFLINE";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Stack(
            alignment: Alignment.bottomLeft,
            children: [
              SizedBox(
                height: 250,
                width: MediaQuery.of(context).size.width,
                child: const Hero(
                  tag: "storke-banner",
                  child: Image(
                    image: AssetImage('images/storke.jpeg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Server Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 35, color: Colors.white)),
              )
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text("Critical Systems ${criticalSystemsOnline ? "Online" : "Offline"}!", style: TextStyle(color: criticalSystemsOnline ? SB_GREEN : SB_RED, fontSize: 22),),
                  const Padding(padding: EdgeInsets.all(4),),
                  Column(
                    children: status.entries.map((s) => Row(
                      children: [
                        s.value == "ONLINE" ?
                        Icon(Icons.check_circle, color: SB_GREEN, size: 40,)
                        : s.value == "OFFLINE" ?
                        Icon(Icons.cancel, color: SB_RED, size: 40,)
                        : const RefreshProgressIndicator(),
                        const Padding(padding: EdgeInsets.all(8)),
                        Text(s.key.capitalize(), style: const TextStyle(fontSize: 18),)
                      ],
                    )).toList(),
                  ),
                  const Padding(padding: EdgeInsets.all(8),),
                  Column(
                    children: [
                      const Text("This page will automatically refresh every 10 seconds"),
                      const Padding(padding: EdgeInsets.all(8),),
                      Visibility(
                        visible: criticalSystemsOnline,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: CupertinoButton.filled(
                            child: const Text("Back to Login"),
                            onPressed: () {
                              router.navigateTo(context, "/check-auth", transition: TransitionType.fadeIn, replace: true, clearStack: true);
                            },
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            )
          )
        ],
      ),
    );
  }
}
