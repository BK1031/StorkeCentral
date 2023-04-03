import 'package:flutter/material.dart';
import 'package:storke_central/utils/config.dart';
import 'package:url_launcher/url_launcher.dart';

import 'footer.dart';
import 'header.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({Key? key}) : super(key: key);

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {

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
                padding: MediaQuery.of(context).size.width > 800 ? const EdgeInsets.all(32) : const EdgeInsets.all(16),
                // color: Colors.greenAccent,
                width: MediaQuery.of(context).size.width > 1500 ? 1500 : MediaQuery.of(context).size.width,
                child: const Text("Download", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: MediaQuery.of(context).size.width > 800 ? const EdgeInsets.all(32) : const EdgeInsets.all(16),
                // color: Colors.greenAccent,
                width: MediaQuery.of(context).size.width > 1500 ? 1500 : MediaQuery.of(context).size.width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Get StorkeCentral from the App Store or Play Store below.", style: TextStyle(color: Colors.white, fontSize: 18)),
                    const Padding(padding: EdgeInsets.all(8)),
                    Wrap(
                      children: [
                        InkWell(
                          onTap: () => launchUrl(Uri.parse(APP_STORE_URL)),
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset("images/icons/download-app-store.png", width: 200)
                        ),
                        const Padding(padding: EdgeInsets.all(8)),
                        InkWell(
                            onTap: () => launchUrl(Uri.parse(PLAY_STORE_URL)),
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset("images/icons/download-play-store.png", width: 220)
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: MediaQuery.of(context).size.width > 800 ? const EdgeInsets.all(32) : const EdgeInsets.all(16),
                // color: Colors.greenAccent,
                width: MediaQuery.of(context).size.width > 1500 ? 1500 : MediaQuery.of(context).size.width,
                child: const Text("Web and desktop versions coming soon!", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
              const Footer(),
            ],
          ),
        )
    );
  }
}
