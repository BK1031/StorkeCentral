import 'package:card_loading/card_loading.dart';
import 'package:flutter/material.dart';
import 'package:storke_central/utils/theme.dart';

class WaitzPlaceholder extends StatelessWidget {
  const WaitzPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
      child: Column(
          children: [0,1,2].map((e) => CardLoading(
            margin: const EdgeInsets.all(8),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            height: 150,
            cardLoadingTheme: getCardLoadingTheme(context),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Card(
                            child: SizedBox(
                              height: 25,
                              width: 200,
                            ),
                          ),
                          Card(
                            child: SizedBox(
                              height: 15,
                              width: 200,
                            ),
                          ),
                        ],
                      ),
                      Card(
                        child: SizedBox(
                          height: 30,
                          width: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )).toList()
      ),
    );
  }
}
