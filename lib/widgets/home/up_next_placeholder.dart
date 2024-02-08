import 'package:card_loading/card_loading.dart';
import 'package:flutter/material.dart';
import 'package:storke_central/utils/theme.dart';

class UpNextPlaceholder extends StatelessWidget {
  const UpNextPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        itemCount: 4,
        itemBuilder: (BuildContext context, int i) {
          return Padding(
            padding: EdgeInsets.only(right: 4, left: (i == 0) ? 8 : 0),
            child: SizedBox(
              width: 175,
              child: CardLoading(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                height: 150,
                margin: const EdgeInsets.all(8),
                cardLoadingTheme: getCardLoadingTheme(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Card(
                            shape: CircleBorder(),
                            child: SizedBox(
                              height: 25,
                              width: 25,
                            ),
                          ),
                          Padding(padding: EdgeInsets.all(4)),
                          Card(
                            child: SizedBox(
                              height: 20,
                              width: 75,
                            ),
                          ),
                        ],
                      ),
                      Padding(padding: EdgeInsets.all(2)),
                      Card(
                        child: SizedBox(
                          height: 20,
                          width: 75,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        scrollDirection: Axis.horizontal,
      ),
    );
  }
}
