import 'package:flutter/material.dart';

class DuoCard extends StatelessWidget {
  const DuoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset("images/icons/duo.png", width: 32, height: 32)
                )
            ),
            const Padding(padding: EdgeInsets.all(2)),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("TIME SENSITIVE", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                  Padding(padding: EdgeInsets.all(2)),
                  Text("Verify your identity", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Padding(padding: EdgeInsets.all(2)),
                  Text("Are you logging in to UCSB Single Sign-on?", style: TextStyle(fontSize: 14)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
