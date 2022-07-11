import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:storke_central/models/user.dart';
import 'package:storke_central/utils/theme.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({Key? key}) : super(key: key);

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {

  List<User> friends = [];

  @override
  void initState() {
    super.initState();

  }

  Future<void> getFriend() async {

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: SB_NAVY,
        title: const Text(
          "Friends",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(left: 8, top: 4, right: 8),
              child: Card(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: ExtendedImage.asset(
                        "images/storke.jpeg",
                        height: 60,
                        width: 60,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.all(Radius.circular(125)),
                        shape: BoxShape.rectangle,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Haarika Kathi",
                            style: TextStyle(fontSize: 18),
                          ),
                          Text(
                            "@haarika",
                            style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.caption!.color),
                          )
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.clear, color: Theme.of(context).textTheme.caption!.color),
                      onPressed: () {

                      },
                    )
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(left: 8, top: 4, right: 8),
              child: Card(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: ExtendedImage.asset(
                        "images/storke.jpeg",
                        height: 60,
                        width: 60,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.all(Radius.circular(125)),
                        shape: BoxShape.rectangle,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Haarika Kathi",
                            style: TextStyle(fontSize: 18),
                          ),
                          Text(
                            "@haarika",
                            style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.caption!.color),
                          )
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.cancel_outlined, color: Theme.of(context).textTheme.caption!.color),
                      onPressed: () {

                      },
                    )
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(left: 8, top: 4, right: 8),
              child: Card(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: ExtendedImage.asset(
                        "images/storke.jpeg",
                        height: 60,
                        width: 60,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.all(Radius.circular(125)),
                        shape: BoxShape.rectangle,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Haarika Kathi",
                            style: TextStyle(fontSize: 18),
                          ),
                          Text(
                            "@haarika",
                            style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.caption!.color),
                          )
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.cancel, color: Theme.of(context).textTheme.caption!.color),
                      onPressed: () {

                      },
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
