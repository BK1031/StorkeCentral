import 'package:flutter/material.dart';

import 'footer.dart';
import 'header.dart';

class FeaturesPage extends StatefulWidget {
  const FeaturesPage({Key? key}) : super(key: key);

  @override
  State<FeaturesPage> createState() => _FeaturesPageState();
}

class _FeaturesPageState extends State<FeaturesPage> {

  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              const Header(),
              Container(
                padding: MediaQuery.of(context).size.width > 800 ? const EdgeInsets.all(32) : const EdgeInsets.all(8),
                // color: Colors.greenAccent,
                width: MediaQuery.of(context).size.width > 1500 ? 1500 : MediaQuery.of(context).size.width,
                child: const Text("Features", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: MediaQuery.of(context).size.width > 800 ? const EdgeInsets.all(32) : const EdgeInsets.all(16),
                // color: Colors.greenAccent,
                width: MediaQuery.of(context).size.width > 1500 ? 1500 : MediaQuery.of(context).size.width,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Here's a full breakdown of everything you can do with StorkeCentral.", style: TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
              ),
              const Footer(),
            ],
          ),
        )
    );
  }
}
