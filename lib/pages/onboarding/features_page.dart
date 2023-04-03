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
                padding: MediaQuery.of(context).size.width > 800 ? const EdgeInsets.all(32) : const EdgeInsets.only(bottom: 32),
                // color: Colors.greenAccent,
                width: MediaQuery.of(context).size.width > 1500 ? 1500 : MediaQuery.of(context).size.width,
                child: const Text("Download Page", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              ),
              const Footer(),
            ],
          ),
        )
    );
  }
}
