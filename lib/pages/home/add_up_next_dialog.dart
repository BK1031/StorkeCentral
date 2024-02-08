import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/theme.dart';

class AddUpNextDialog extends StatefulWidget {
  const AddUpNextDialog({Key? key}) : super(key: key);

  @override
  State<AddUpNextDialog> createState() => _AddUpNextDialogState();
}

class _AddUpNextDialogState extends State<AddUpNextDialog> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      width: 300,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: friends.length,
        itemBuilder: (context, index) {
          return Card(
            child: InkWell(
              onTap: () {
                setState(() {
                  if (upNextUserIDs.contains(friends[index].user.id)) {
                    upNextUserIDs.remove(friends[index].user.id);
                  } else {
                    upNextUserIDs.add(friends[index].user.id);
                  }
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: ExtendedImage.network(
                      friends[index].user.profilePictureURL,
                      height: 45,
                      width: 45,
                      fit: BoxFit.cover,
                      borderRadius: const BorderRadius.all(Radius.circular(125)),
                      shape: BoxShape.rectangle,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${friends[index].user.firstName} ${friends[index].user.lastName}",
                          style: const TextStyle(fontSize: 18),
                        ),
                        Text(
                          "@${friends[index].user.userName}",
                          style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodySmall!.color),
                        )
                      ],
                    ),
                  ),
                  Icon(
                    upNextUserIDs.contains(friends[index].user.id) ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    color: upNextUserIDs.contains(friends[index].user.id) ? ACTIVE_ACCENT_COLOR : Colors.grey,
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
