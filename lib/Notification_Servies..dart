// import 'dart:async';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:provider/provider.dart';
// import 'login_page.dart';
//
// class Notification_Servies extends StatefulWidget {
//
//   @override
//   State<Notification_Servies> createState() => _Notification_ServiesState();
// }
//
// class _Notification_ServiesState extends State<Notification_Servies> {
//
//
//
//     // Fluttertoast.showToast(
//     //     msg: "${msg}",
//     //     toastLength: Toast.LENGTH_LONG,
//     //     gravity: ToastGravity.BOTTOM,
//     //     backgroundColor:  StyleResource.theme_Green
//     // );
//
//
//
//   final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();
//
//   Future showNotification({int id = 0, String? title, String? body, String? image, String? payLoad}) async {
//     // notificationCount++;
//
//
//
//     if(image==null){
//       return notificationsPlugin.show(
//           id,
//           title,
//           body,
//           await NotificationDetails(
//             android: AndroidNotificationDetails(
//               'channelId',
//               'channelName',
//               // category: AndroidNotificationCategory.message,
//               importance: Importance.max,
//
//             ),
//             iOS: DarwinNotificationDetails(),
//           ),
//
//           payload: payLoad
//
//       );
//     }
//     else {
//
//       // final http.Response response = await http.get(Uri.parse(URL));
//       final http.Response response = await http.get(Uri.parse(image.toString()));
//
//       return notificationsPlugin.show(
//           id,
//           title,
//           body,
//           await NotificationDetails(
//             android: AndroidNotificationDetails(
//                 'channelId',
//                 'channelName',
//                 // category: AndroidNotificationCategory.message,
//                 importance: Importance.max,
//                 largeIcon: ByteArrayAndroidBitmap.fromBase64String(base64Encode(response.bodyBytes)),
//                 fullScreenIntent: true,
//
//                 styleInformation: BigPictureStyleInformation(
//                   ByteArrayAndroidBitmap.fromBase64String(base64Encode(response.bodyBytes)),
//                   largeIcon: ByteArrayAndroidBitmap.fromBase64String(base64Encode(response.bodyBytes)),
//                   hideExpandedLargeIcon: true,
//                 )
//             ),
//             iOS: DarwinNotificationDetails(),
//           ),
//           payload: payLoad
//
//       );
//     }
//
//   }
//
//   Notification_Listener() async {
//     print("HomeScreen-Notification_Listener");
//
//
//     FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) async {
//       if (message != null) {
//
//         print('(HomeScreen-instance) A new  event was published!');
//         print("(HomeScreen-instance) title : " + message.notification!.title.toString());
//         print("(HomeScreen-instance) body : " + message.notification!.body.toString());
//         print("(HomeScreen-instance) image : " + message.notification!.android!.imageUrl.toString());
//
//       }
//     });
//
//
//     FirebaseMessaging.onMessage.listen((message) async {
//       // RemoteNotification notification = message.notification!;
//       if (message != null) {
//
//
//
//         print('(HomeScreen-onMessage) A new  event was published!');
//         print("(HomeScreen-onMessage) title : " + message.notification!.title.toString());
//         print("(HomeScreen-onMessage) body : " + message.notification!.body.toString());
//         print("(HomeScreen-onMessage) image : " + message.notification!.android!.imageUrl.toString());
//
//       }
//     });
//
//
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? message) async {
//       if (message != null) {
//
//         print('(HomeScreen-onMessageOpenedApp) A new  event was published!');
//         print("(HomeScreen-onMessageOpenedApp) title : " + message.notification!.title.toString());
//         print("(HomeScreen-onMessageOpenedApp) body : " + message.notification!.body.toString());
//         print("(HomeScreen-onMessageOpenedApp) image : " + message.notification!.android!.imageUrl.toString());
//
//       }
//     });
//
//
//
//     await notificationsPlugin.initialize(
//         InitializationSettings(
//             android: const AndroidInitializationSettings('logo'),
//             iOS: DarwinInitializationSettings(
//                 requestAlertPermission: true,
//                 requestBadgePermission: true,
//                 requestSoundPermission: true,
//                 // onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {}
//             )
//         ),
//         onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
//
//           // **NOTIFICATION REDIRECTION**
//
//           if (notificationResponse != null) {
//
//             Map<String, dynamic> jsonNoti = jsonDecode(notificationResponse.payload!);
//
//             String? title = jsonNoti.values.elementAtOrNull(0).toString();
//             String? body = jsonNoti.values.elementAtOrNull(1).toString();
//             String? image = jsonNoti.values.elementAtOrNull(2).toString();
//
//             print('(HomeScreen-actionStream) A new  event was published!');
//             print("(HomeScreen-actionStream) title : " + title);
//             print("(HomeScreen-actionStream) body : " + body);
//             print("(HomeScreen-actionStream) image : " + image);
//
//           }
//
//         }
//     );
//
//   }
//
//   InitList() async {
//     print("Notification Servies Start");
//     await Notification_Listener();
//     Navigator.of(context).pushAndRemoveUntil(
//         MaterialPageRoute(builder: (context) => LoginPage()),
//             (route) => false
//     );
//   }
//
//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     InitList();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//     );
//   }
// }
