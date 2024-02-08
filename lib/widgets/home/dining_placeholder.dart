import 'package:card_loading/card_loading.dart';
import 'package:flutter/material.dart';
import 'package:storke_central/utils/theme.dart';

class DiningPlaceholder extends StatelessWidget {
  const DiningPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        itemCount: 4,
        itemBuilder: (BuildContext context, int i) {
          return Padding(
            padding: EdgeInsets.only(right: 4, left: (i == 0) ? 8 : 0),
            child: SizedBox(
              width: 150,
              child: CardLoading(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                height: 150,
                margin: const EdgeInsets.all(8),
                cardLoadingTheme: getCardLoadingTheme(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: SizedBox(
                          height: 20,
                          width: 75,
                        ),
                      ),
                      Card(
                        child: SizedBox(
                          height: 20,
                          width: 150,
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
