import 'dart:convert';

import 'package:extended_image/extended_image.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:storke_central/models/notification.dart' as sc;
import 'package:storke_central/utils/auth_service.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/logger.dart';
import 'package:storke_central/utils/theme.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {

  bool loading = false;

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      setState(() => loading = true);
      await AuthService.getAuthToken();
      await http.get(Uri.parse("$API_HOST/notifications/user/${currentUser.id}"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}).then((value) {
        setState(() {
          notifications = jsonDecode(utf8.decode(value.bodyBytes))["data"].map<sc.Notification>((json) => sc.Notification.fromJson(json)).toList();
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        });
      });
    } catch(err) {
      // TODO: Show error snackbar
      log(err.toString(), LogLevel.error);
    }
    setState(() => loading = false);
  }

  Future<void> markNotificationAsRead(sc.Notification notification) async {
    notification.read = true;
    setState(() {
      notifications.firstWhere((element) => element.id == notification.id).read = true;
    });
    try {
      await AuthService.getAuthToken();
      await http.post(Uri.parse("$API_HOST/notifications"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}, body: jsonEncode(notification));
    } catch(err) {
      // TODO: Show error snackbar
      log(err.toString(), LogLevel.error);
    }
  }

  Future<void> markAllAsRead() async {
    for (int i = 0; i < notifications.length; i++) {
      if (!notifications[i].read) {
        markNotificationAsRead(notifications[i]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: SB_NAVY,
        title: const Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("${notifications.where((element) => !element.read).length} unread notifications", style: TextStyle(fontSize: 16)),
                ),
                Visibility(
                  visible: notifications.any((element) => !element.read),
                  child: CupertinoButton(
                    padding: const EdgeInsets.all(0),
                    child: const Text("Mark all as read", style: TextStyle(fontSize: 16),),
                    onPressed: () {
                      markAllAsRead();
                    },
                  ),
                )
              ],
            ),
            Visibility(
              visible: loading,
              child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Center(
                      child: RefreshProgressIndicator(
                          color: Colors.white,
                          backgroundColor: SB_NAVY
                      )
                  )
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        if (!notifications[index].read) {
                          markNotificationAsRead(notifications[index]);
                        }
                        if (notifications[index].route != "") {
                          router.navigateTo(context, notifications[index].route, transition: TransitionType.native);
                        } else if (notifications[index].launchURL != "") {
                          launchUrl(Uri.parse(notifications[index].launchURL));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No action available for this notification")));
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            notifications[index].pictureURL != "" ? SizedBox(
                              height: 35,
                              width: 35,
                              child: ExtendedImage.network(
                                notifications[index].pictureURL,
                                fit: BoxFit.cover,
                                borderRadius: const BorderRadius.all(Radius.circular(125)),
                                shape: BoxShape.rectangle,
                              ),
                            ) : SizedBox(
                              height: 35,
                              width: 35,
                              child: Icon(
                                notifications[index].read ? Icons.notifications_rounded : Icons.notifications_active_rounded,
                                color: notifications[index].read ? Colors.grey : SB_NAVY,
                              ),
                            ),
                            const Padding(padding: EdgeInsets.all(4)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notifications[index].title,
                                    style: TextStyle(fontSize: 16, fontWeight: !notifications[index].read ? FontWeight.bold : FontWeight.normal)
                                  ),
                                  Text(
                                    notifications[index].body,
                                  )
                                ],
                              ),
                            ),
                            const Padding(padding: EdgeInsets.all(1)),
                            Text(
                                DateTime.now().difference(notifications[index].createdAt).inDays > 6 ? DateFormat("MMM d").format(notifications[index].createdAt) : timeago.format(notifications[index].createdAt, locale: "en_short"),
                                style: TextStyle(color: notifications[index].read ? Colors.grey : SB_NAVY,)
                            ),
                            Icon(
                              notifications[index].route != "" || notifications[index].launchURL != "" ? Icons.arrow_forward_ios_rounded : null,
                              color: notifications[index].read ? Colors.grey : SB_NAVY,
                            ),
                          ],
                        ),
                      ),
                    )
                  );
                },
              ),
            ),
          ],
        ),
      )
    );
  }
}
