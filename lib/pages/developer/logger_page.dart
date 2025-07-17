import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:storke_central/utils/logger.dart';
import 'package:storke_central/utils/theme.dart';

class LoggerPage extends StatefulWidget {
  const LoggerPage({Key? key}) : super(key: key);

  @override
  State<LoggerPage> createState() => _LoggerPageState();
}

class _LoggerPageState extends State<LoggerPage> {

  bool showTimestamps = true;
  ScrollController listScrollController = ScrollController();

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 200)).then((value) {
      listScrollController.animateTo(listScrollController.position.maxScrollExtent + 100, duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
            "Session Logs",
            style: TextStyle(fontWeight: FontWeight.bold)
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 8, right: 8),
        child: Row(
          children: [
            CupertinoButton(
              color: darkCardColor,
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Icon(showTimestamps ? Icons.visibility_off : Icons.visibility),
                  const Padding(padding: EdgeInsets.all(4)),
                  Text(showTimestamps ? "Hide Timestamps" : "Show Timestamps"),
                ],
              ),
              onPressed: () {
                setState(() {
                    showTimestamps = !showTimestamps;
                });
              },
            ),
            const Padding(padding: EdgeInsets.all(4)),
            CupertinoButton(
              color: darkCardColor,
              padding: const EdgeInsets.all(8),
              child: const Row(
                children: [],
              ),
              onPressed: () {},
            ),
          ],
        ),
      ),
      backgroundColor: darkBackgroundColor,
      body: ListView.builder(
        controller: listScrollController,
        itemCount: logs.length,
        itemBuilder: (context, index) => Container(
          padding: const EdgeInsets.all(2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: showTimestamps ? 72 : 0,
                child: Text(
                  showTimestamps ? DateFormat("Hms").format(logs[index].time.toLocal()).toString() : "",
                  style: const TextStyle(
                    fontFamily: "Courier New",
                    color: Colors.white60
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      logs[index].message,
                      style: TextStyle(
                        color: logs[index].level == LogLevel.error ? SB_RED : logs[index].level == LogLevel.warn ? SB_AMBER : Colors.white,
                        fontFamily: "Courier New"
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
