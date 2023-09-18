import 'package:card_loading/card_loading.dart';
import 'package:flutter/material.dart';

class HeadlineArticlePlaceholder extends StatelessWidget {
  const HeadlineArticlePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return CardLoading(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      height: 175,
      margin: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Card(
                  child: SizedBox(
                    height: 20,
                    width: 30,
                  ),
                ),
                Padding(padding: EdgeInsets.all(4)),
                Card(
                  child: SizedBox(
                    height: 20,
                    width: 100,
                  ),
                ),
              ],
            ),
            Padding(padding: EdgeInsets.all(8)),
            Card(
              child: SizedBox(
                height: 20,
                width: 500,
              ),
            ),
            Card(
              child: SizedBox(
                height: 20,
                width: 200,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
