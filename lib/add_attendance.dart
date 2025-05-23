import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'ble_controller.dart';

class AddAttendance extends StatefulWidget {
  const AddAttendance({Key? key}) : super(key: key);

  @override
  State<AddAttendance> createState() => _AddAttendanceState();
}

class _AddAttendanceState extends State<AddAttendance> {
  bool isBroadcasting = false;
  String? fcmToken;

  @override
  void initState() {
    super.initState();
    retrieveStudentInfo();
  }

  Future<void> retrieveStudentInfo() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      String? token = await messaging.getToken();

      setState(() {
        fcmToken = token;
      });

      await saveUuidToFirestore();

    } catch (error) {
      print('Error fetching user data or FCM token: $error');
    }
  }

  /// Generate UUID from UID and store it in Firestore
  Future<void> saveUuidToFirestore() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    String uuid = BleController().uidToUuid(uid);

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'uid': uid,
      'uuid': uuid,
    }, SetOptions(merge: true));

    print("UUID saved to Firestore: $uuid");
  }

  /// Start BLE broadcast using UUID
  void startBroadcasting() {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    if (!isBroadcasting) {
      BleController().startBroadcasting(uid);
      setState(() {
        isBroadcasting = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Broadcasting UID for attendance...'),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  /// Stop BLE broadcast
  void stopBroadcasting() {
    BleController().stopBroadcasting();
    setState(() {
      isBroadcasting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Stopped broadcasting.'),
      ),
    );
  }

  @override
  void dispose() {
    stopBroadcasting();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Attendance'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: isBroadcasting ? stopBroadcasting : startBroadcasting,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
          ),
          child: Text(
            isBroadcasting ? 'Stop Broadcasting' : '+ Attendance',
            style: TextStyle(fontSize: 30.0),
          ),
        ),
      ),
    );
  }
}
