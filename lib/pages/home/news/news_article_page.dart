import 'package:flutter/material.dart';
import 'package:storke_central/utils/config.dart';
import 'package:url_launcher/url_launcher.dart';


class NewsArticlePage extends StatefulWidget {
  const NewsArticlePage({Key? key}) : super(key: key);

  @override
  _NewsArticlePageState createState() => _NewsArticlePageState();
}

class _NewsArticlePageState extends State<NewsArticlePage> {

  static ValueKey key = const ValueKey('key_0');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Daily Nexus"),
          actions: [
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                PopupMenuItem<int>(
                  value: 0,
                  child: Row(
                    children: [
                      Icon(Icons.language, color: Theme.of(context).dividerColor,),
                      const Padding(padding: EdgeInsets.all(4),),
                      const Text("Open in browser"),
                    ],
                  ),
                ),
                PopupMenuItem<int>(
                  value: 1,
                  child: Row(
                    children: [
                      Icon(Icons.ios_share, color: Theme.of(context).dividerColor,),
                      const Padding(padding: EdgeInsets.all(4),),
                      const Text("Share"),
                    ],
                  ),
                ),
              ],
              onSelected: (item) {
                    launch(selectedArticle.articleUrl);
              },
            ),
          ],
        ),
        body: Container(color: Colors.greenAccent)
    );
  }
}
