import 'dart:async';

import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/logger.dart';
import 'package:storke_central/utils/string_extension.dart';
import 'package:storke_central/utils/theme.dart';


class ServerStatusPage extends StatefulWidget {
  const ServerStatusPage({Key? key}) : super(key: key);

  @override
  State<ServerStatusPage> createState() => _ServerStatusPageState();
}

class _ServerStatusPageState extends State<ServerStatusPage> {

  Map<String, String> status = {
    "montecito": "OFFLINE",
    "rincon": "OFFLINE",
    "lacumbre": "OFFLINE",
    "gaviota": "OFFLINE",
    "tepusquet": "OFFLINE",
    "arguello": "OFFLINE",
    "miranda": "OFFLINE",
    "jalama": "OFFLINE",
  };
  Timer? timer;

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    getAllServiceStatuses();
    timer = Timer.periodic(const Duration(seconds: 5), (Timer t) => getAllServiceStatuses());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void getAllServiceStatuses() {
    List<String> services = status.keys.toList();
    for (var s in services) {
      if (status[s] == "OFFLINE") {
        setState(() {
          status[s] = "LOADING";
        });
      }
      getServiceStatus(s);
    }
  }

  Future<void> getServiceStatus(String service) async {
    try {
      var serviceStatus = await http.get(Uri.parse("$API_HOST/$service/ping"));
      log("[server_status_page] $service: ${serviceStatus.statusCode}");
      if (mounted) {
        setState(() {
          status[service] = serviceStatus.statusCode == 200 ? "ONLINE" : "OFFLINE";
        });
      }
    } catch (err) {
      log("[server_status_page] $service: $err");
      setState(() {
        status[service] = "OFFLINE";
      });
    }
  }

  bool allSystemsOnline() {
    return status.values.every((element) => element == "ONLINE");
  }

  bool criticalSystemsOnline() {
    return status["montecito"] == "ONLINE" && status["rincon"] == "ONLINE" && status["lacumbre"] == "ONLINE";
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
                  allSystemsOnline() ? Text("All Systems Online!", style: TextStyle(color: SB_GREEN, fontSize: 22),) : criticalSystemsOnline() ? Text("Critical Systems Online!", style: TextStyle(color: SB_GREEN, fontSize: 22),) : Text("Critical Systems Offline!", style: TextStyle(color: SB_RED, fontSize: 22),),
                  const Padding(padding: EdgeInsets.all(4),),
                  Column(
                    children: status.keys.map((s) => Row(
                      children: [
                        status[s] == "ONLINE" ?
                        Icon(Icons.check_circle, color: SB_GREEN, size: 40,)
                        : status[s] == "OFFLINE" ?
                        Icon(Icons.cancel, color: SB_RED, size: 40,)
                        : const RefreshProgressIndicator(),
                        const Padding(padding: EdgeInsets.all(8)),
                        Text(s.capitalize(), style: const TextStyle(fontSize: 18),)
                      ],
                    )).toList(),
                  ),
                  const Padding(padding: EdgeInsets.all(8),),
                  Column(
                    children: [
                      const Text("This page will automatically refresh every 5 seconds"),
                      const Padding(padding: EdgeInsets.all(8),),
                      Visibility(
                        visible: criticalSystemsOnline(),
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
