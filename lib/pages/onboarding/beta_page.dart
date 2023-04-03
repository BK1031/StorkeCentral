import 'package:flutter/material.dart';

import 'footer.dart';
import 'header.dart';

class BetaPage extends StatefulWidget {
  const BetaPage({Key? key}) : super(key: key);

  @override
  State<BetaPage> createState() => _BetaPageState();
}

class _BetaPageState extends State<BetaPage> {

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
                child: const Text("Join our public beta!", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              ),
              const Footer(),
            ],
          ),
        )
    );
  }
}
