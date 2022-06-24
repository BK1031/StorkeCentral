import 'package:flutter/material.dart';
import 'package:storke_central/utils/logger.dart';
import 'package:storke_central/utils/theme.dart';

class LoggerPage extends StatefulWidget {
  const LoggerPage({Key? key}) : super(key: key);

  @override
  State<LoggerPage> createState() => _LoggerPageState();
}

class _LoggerPageState extends State<LoggerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
            "Session Logs",
            style: TextStyle(fontWeight: FontWeight.bold)
        ),
      ),
      backgroundColor: darkBackgroundColor,
      body: ListView.builder(
        itemBuilder: (context, index) => Container(
          child: Row(
            children: [
              Text(
                logs[index].time.toLocal().toString(),
                style: TextStyle(
                  fontFamily: "Courier New",
                  color: Colors.white60
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    logs[index].message,
                    style: TextStyle(
                      color: logs[index].level == LogLevel.error ? SB_RED : logs[index].level == LogLevel.warn ? SB_AMBER : Colors.white,
                      fontFamily: "Courier New"
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
