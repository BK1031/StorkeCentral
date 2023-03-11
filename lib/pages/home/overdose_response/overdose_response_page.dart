import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class OverdoseResponsePage extends StatefulWidget {
  const OverdoseResponsePage({Key? key}) : super(key: key);

  @override
  _OverdoseResponsePageState createState() => _OverdoseResponsePageState();
}

class _OverdoseResponsePageState extends State<OverdoseResponsePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Overdose Response", style: TextStyle(fontWeight: FontWeight.bold),),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Card(
              color: Colors.redAccent,
              child: InkWell(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                onTap: () {
                  launch("tel:911");
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: const [
                      Text(
                        "Not sure if it’s alcohol poisoning or a drug overdose?",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          "Just Call 911",
                          style: TextStyle(fontSize: 35, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        "If someone has any warning signs, call 911.",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              child: Text(
                "Stay calm and know that you are doing the right thing. One call could be the one that saves someone's life. The UCSB Responsible Action Protocol, is similar to the California Good Samaritan Law and protects students who make a call on behalf of themselves or someone needing assistance.",
                style: TextStyle(),
              ),
            )
          ],
        ),
      ),
    );
  }
}
