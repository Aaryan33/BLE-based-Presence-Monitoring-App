import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:overlay_support/overlay_support.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'student_dashboard.dart';
import 'faculty_dashboard.dart';
import 'admin_dashboard.dart';


Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("✅ Handling a background message: ${message.messageId}");
}

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(OverlaySupport.global(child: MyApp()));
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      themeMode: ThemeMode.light,
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {

    await Future.delayed(Duration(seconds: 1));

    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      try {

        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userSnapshot.exists) {

          String? role = userSnapshot.get('role');

          if (role == 'student') {
            String? token = await FirebaseMessaging.instance.getToken();

            if (token != null) {
              await FirebaseFirestore.instance.collection('users')
                  .doc(currentUser.uid)
                  .update({'fcmToken': token});
              print("✅ FCM token updated on auto-login: $token");
            }
          }

          _navigateToRoleDashboard(role);
        }
        else {
          await FirebaseAuth.instance.signOut();
          _navigateToLogin();
        }
      }
      catch (e) {
        print("Error checking user role: $e");
        _navigateToLogin();
      }
    }
    else {
      _navigateToLogin();
    }
  }

  void _navigateToRoleDashboard(String? role) {

    Widget destination;

    switch (role) {
      case 'student':
        destination = StudentDashboardPage();
        break;
      case 'faculty':
        destination = FacultyDashboardPage();
        break;
      case 'admin':
        destination = AdminDashboardPage();
        break;

      default:
        destination = LoginPage();
        break;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => NotificationWrapper(child: destination)),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => NotificationWrapper(child: LoginPage())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade100,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 100,
              color: Colors.deepPurple,
            ),
            SizedBox(height: 24),
            Text(
              'Smart Attendance',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(
              color: Colors.deepPurple,
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationWrapper extends StatefulWidget {
  final Widget child;
  const NotificationWrapper({required this.child});

  @override
  State<NotificationWrapper> createState() => _NotificationWrapperState();
}

class _NotificationWrapperState extends State<NotificationWrapper> {
  @override
  void initState() {
    super.initState();
    _initFCM();
  }

  Future<void> _initFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Notification permission granted');

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          showSimpleNotification(
            Text(message.notification!.title ?? 'No Title'),
            subtitle: Text(message.notification!.body ?? 'No Body'),
            background: Colors.deepPurple,
          );
        }
      });

      // When app opened by clicking on the notification (terminated)
      messaging.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          _handleNotificationTap(message);
        }
      });

      // When app opened from background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap(message);
      });
    } else {
      print('❌ Notification permission denied');
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Custom behavior when clicking on notification
    print('🔔 Notification Clicked: ${message.notification?.title}');
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}



///
///
///


// admin@gmail.com, admin123

// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
// import 'login_page.dart';
// import 'register_admin.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//
//   runApp(MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       theme: ThemeData(primarySwatch: Colors.deepPurple),
//       themeMode: ThemeMode.light,
//       home: LoginPage(),
//       home: RegisterAdminPage(),
//     );
//   }
// }