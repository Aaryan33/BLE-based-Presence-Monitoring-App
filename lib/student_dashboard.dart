import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ble_controller.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class StudentDashboardPage extends StatefulWidget {
  @override
  _StudentDashboardPageState createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _studentName = '';
  String _rollNo = '';
  String _email = '';
  bool _isLoading = true;
  bool isBroadcasting = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();

        if (userDoc.exists) {
          setState(() {
            _studentName = userDoc['name'] ?? 'Student';
            _rollNo = userDoc['rollNo'] ?? '';
            _email = userDoc['email'] ?? '';
          });

          await _saveUuidToFirestore();
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Save UUID to Firestore if missing
  Future<void> _saveUuidToFirestore() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    String uuid = BleController().uidToUuid(uid);

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'uid': uid,
      'uuid': uuid,
    }, SetOptions(merge: true));

    print("UUID saved to Firestore: $uuid");
  }

  void _startBroadcasting() {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    if (!isBroadcasting) {
      BleController().startBroadcasting(uid);
      setState(() {
        isBroadcasting = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('📡 Broadcasting started')),
      );
    }
  }

  void _stopBroadcasting() {
    if (isBroadcasting) {
      BleController().stopBroadcasting();
      setState(() {
        isBroadcasting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Broadcasting stopped')),
      );
    }
  }

  void _toggleBroadcasting() {
    if (isBroadcasting) {
      _stopBroadcasting();
    } else {
      _startBroadcasting();
    }
  }

  @override
  void dispose() {
    _stopBroadcasting();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading ? _buildLoadingView() : _buildDashboardView(),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: CircularProgressIndicator(
        color: Colors.deepPurple,
      ),
    );
  }

  Widget _buildDashboardView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade100,
            Colors.deepPurple.shade50,
            Colors.white,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            _buildHeader(),
            _buildStudentInfoCard(),
            const Spacer(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Text(
      'Welcome, $_studentName',
      style: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: Colors.deepPurple.shade700,
      ),
    );
  }

  Widget _buildStudentInfoCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade400,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Text(
              _studentName.isNotEmpty ? _studentName[0].toUpperCase() : 'S',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _studentName,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.badge_outlined, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text(
                'Roll No: $_rollNo',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.email_outlined, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text(
                _email,
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: _toggleBroadcasting,
            borderRadius: BorderRadius.circular(20),
            child: Chip(
              label: Text(isBroadcasting ? 'Stop' : 'Mark Attendance'),
              avatar: Icon(
                isBroadcasting ? Icons.stop_circle : Icons.broadcast_on_home,
                color: isBroadcasting ? Colors.red : Colors.green,
                size: 18,
              ),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(
        'Smart Attendance System',
        style: TextStyle(fontSize: 12, color: Colors.deepPurple),
      ),
    );
  }
}
