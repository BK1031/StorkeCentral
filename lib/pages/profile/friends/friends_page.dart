import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:storke_central/models/user.dart';
import 'package:storke_central/utils/auth_service.dart';
import 'package:storke_central/utils/theme.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({Key? key}) : super(key: key);

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {

  List<User> friends = [];

  int currPage = 0;
  PageController pageController = PageController();

  @override
  void initState() {
    super.initState();

  }

  Future<void> getFriend() async {
    await AuthService.getAuthToken();
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
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(left: 8, top: 8, right: 8),
            child: Card(
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      color: currPage == 0 ? SB_NAVY : null,
                      onPressed: () {
                        setState(() {
                          currPage = 0;
                        });
                      },
                      child: Text("My Friends", style: TextStyle(color: currPage == 0 ? Colors.white : Theme.of(context).textTheme.button!.color)),
                    ),
                  ),
                  Expanded(
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      color: currPage == 1 ? SB_NAVY : null,
                      onPressed: () {
                        setState(() {
                          currPage = 1;
                        });
                      },
                      child: Text("Requests", style: TextStyle(color: currPage == 1 ? Colors.white : Theme.of(context).textTheme.button!.color)),
                    ),
                  )
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              child: PageView(
                controller: pageController,
                children: [
                  ListView.builder(
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      return Container(
                        padding: const EdgeInsets.only(left: 8, top: 4, right: 8),
                        child: Card(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                child: ExtendedImage.network(
                                  friends[index].profilePictureURL,
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
                      );
                    },
                  ),
                  ListView.builder(
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      return Container(
                        padding: const EdgeInsets.only(left: 8, top: 4, right: 8),
                        child: Card(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                child: ExtendedImage.network(
                                  friends[index].profilePictureURL,
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
                      );
                    },
                  ),
                ],
              )
            ),
          ),
        ],
      ),
    );
  }
}
