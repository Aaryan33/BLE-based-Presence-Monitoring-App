import 'dart:convert';
import 'package:get/get.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartattendancebeacon/attendance_excel_service.dart';
import 'package:lottie/lottie.dart';
import 'ble_controller.dart';

class BluetoothScanPage extends StatefulWidget {
  const BluetoothScanPage({Key? key}) : super(key: key);

  @override
  State createState() => _BluetoothScanPageState();
}

class _BluetoothScanPageState extends State<BluetoothScanPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, Map<String, dynamic>> _uuidToStudentMap = {};
  bool _isScanning = false;
  int _studentsFound = 0;
  late AnimationController _animationController;
  final Set<String> _markedStudents = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String uidToUuid(String uid) {
    var bytes = utf8.encode(uid);
    var digest = sha1.convert(bytes).bytes.sublist(0, 16);
    return [
      _bytesToHex(digest.sublist(0, 4)),
      _bytesToHex(digest.sublist(4, 6)),
      _bytesToHex(digest.sublist(6, 8)),
      _bytesToHex(digest.sublist(8, 10)),
      _bytesToHex(digest.sublist(10, 16)),
    ].join("-");
  }

  String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  String _extractTokenFromAdvertisingData(Map<int, List<int>> manufacturerData) {
    try {
      for (var entry in manufacturerData.entries) {
        if (entry.value.length >= 18) {
          return extractUuidFromAltBeacon(entry.value);
        }
      }
      return '';
    }
    catch (e) {
      print("Error extracting UUID from advertisement: $e");
      return '';
    }
  }

  String extractUuidFromAltBeacon(List<int> data) {
    if (data.length < 18) return 'Invalid';
    final uuidBytes = data.sublist(2, 18);
    final parts = [
      _bytesToHex(uuidBytes.sublist(0, 4)),
      _bytesToHex(uuidBytes.sublist(4, 6)),
      _bytesToHex(uuidBytes.sublist(6, 8)),
      _bytesToHex(uuidBytes.sublist(8, 10)),
      _bytesToHex(uuidBytes.sublist(10, 16)),
    ];
    return parts.join('-');
  }

  Future<Map<String, dynamic>?> _getStudentByUuid(String uuid) async {
    if (_uuidToStudentMap.containsKey(uuid)) return _uuidToStudentMap[uuid];
    try {
      final querySnapshot = await _firestore.collection('users').get();
      for (var doc in querySnapshot.docs) {
        final uid = doc['uid'];
        final expectedUuid = BleController().uidToUuid(uid);
        print('uuid : ${uuid}');
        if (expectedUuid.toLowerCase() == uuid.toLowerCase()) {
          final student = {
            'name': (doc['name'] ?? '').toString(),
            'rollNo': (doc['rollNo'] ?? '').toString(),
            'email': (doc['email'] ?? '').toString(),
          };
          _uuidToStudentMap[uuid] = student;
          return student;
        }
      }
    }
    catch (e) {
      print("Error fetching student for UUID $uuid: $e");
    }
    return null;
  }

  /// This function checks in Excel
  Future<bool> _isStudentMarkedPresentToday(Map<String, dynamic> student) async {
    try {
      final today = DateTime.now();
      return await AttendanceExcelService.isStudentMarkedPresent(
        email: student['email'],
        rollNo: student['rollNo'],
        date: today,
      );
    }
    catch (e) {
      print("Error checking attendance in Excel for student: $e");
      return false;
    }
  }

  Future<void> _markStudentPresent(String receivedUuid, Map<String, dynamic> studentData) async {

    if (await _isStudentMarkedPresentToday(studentData)) {
      _showSnackBar('Already marked present today.', icon: Icons.info, color: Colors.orange);
      setState(() {
        _markedStudents.add(receivedUuid);
      });
      return;
    }
    try {
      final name = studentData['name'] ?? '';
      final email = studentData['email'] ?? '';
      final rollNo = studentData['rollNo'] ?? '';
      await AttendanceExcelService.markStudentPresent(
        name: name,
        email: email,
        rollNo: rollNo,
      );
      setState(() {
        _markedStudents.add(receivedUuid);
      });
      _showSnackBar(
        '${studentData['name']} has been marked present!',
        icon: Icons.check_circle,
        color: Colors.green.shade700,
      );
    }
    catch (e) {
      print("Error marking student present: $e");
      _showSnackBar(
        'Failed to mark attendance. Please try again.',
        icon: Icons.error_outline,
        color: Colors.red.shade700,
      );
    }
  }

  void _showSnackBar(String message, {IconData icon = Icons.info_outline, Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color ?? Colors.blueGrey.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(12),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
    });
    _animationController.repeat();
    await Get.find<BleController>().scanDevices();
  }

  Future<void> _stopScan() async {
    setState(() {
      _isScanning = false;
    });
    _animationController.stop();
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      print("Error stopping scan: $e");
    }
  }

  Widget _buildInfoCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade300, Colors.deepPurple.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attendance Status',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isScanning ? Colors.green.shade400 : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isScanning)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    SizedBox(width: 5),
                    Text(
                      _isScanning ? 'Active' : 'Idle',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white70),
              SizedBox(width: 8),
              Text(
                'Marked Present:',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
              SizedBox(width: 5),
              Text(
                '${_markedStudents.length}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Scan Attendance"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('How to Take Attendance'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple.shade100,
                          child: Text('1', style: TextStyle(color: Colors.deepPurple)),
                        ),
                        title: Text('Tap "SCAN" to start searching for nearby student beacons'),
                      ),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple.shade100,
                          child: Text('2', style: TextStyle(color: Colors.deepPurple)),
                        ),
                        title: Text('Wait for students to appear in the list'),
                      ),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple.shade100,
                          child: Text('3', style: TextStyle(color: Colors.deepPurple)),
                        ),
                        title: Text('Tap the check button to mark a student present'),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('GOT IT', style: TextStyle(color: Colors.deepPurple)),
                    ),
                  ],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade100,
              Colors.deepPurple.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            _buildInfoCard(),
            if (_isScanning)
              Container(
                height: 120,
                width: 120,
                child: RotationTransition(
                  turns: _animationController,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          Colors.deepPurple.withOpacity(0.0),
                          Colors.deepPurple.withOpacity(0.5),
                        ],
                        stops: [0.0, 1.0],
                        startAngle: 0.0,
                        endAngle: 3.14 * 2,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.bluetooth_searching,
                            size: 40,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isScanning ? _stopScan : _startScan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isScanning ? Colors.red.shade600 : Colors.deepPurple,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_isScanning ? Icons.stop : Icons.bluetooth_searching),
                      SizedBox(width: 10),
                      Text(
                        _isScanning ? 'STOP SCAN' : 'START SCAN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'NEARBY STUDENTS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GetBuilder<BleController>(
                init: BleController(),
                builder: (BleController controller) {
                  return StreamBuilder<List<ScanResult>>(
                    stream: controller.scanResults,
                    builder: (context, snapshot) {
                      if (!_isScanning && (snapshot.data == null || snapshot.data!.isEmpty)) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bluetooth_disabled,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No devices found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap "START SCAN" to begin',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (_isScanning && (snapshot.data == null || snapshot.data!.isEmpty)) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation(Colors.deepPurple),
                                  strokeWidth: 3,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Scanning for students...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      List<MapEntry<ScanResult, String>> validStudents = [];
                      if (snapshot.hasData) {
                        for (var result in snapshot.data!) {
                          final uuid = _extractTokenFromAdvertisingData(result.advertisementData.manufacturerData);
                          if (uuid.isNotEmpty) {
                            validStudents.add(MapEntry(result, uuid));
                          }
                        }
                        if (_studentsFound != validStudents.length) {
                          Future.microtask(() {
                            setState(() {
                              _studentsFound = validStudents.length;
                            });
                          });
                        }
                      }

                      return AnimatedSwitcher(
                        duration: Duration(milliseconds: 300),
                        child: validStudents.isEmpty
                            ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_search,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No students detected',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                            : ListView.builder(
                          padding: EdgeInsets.all(8),
                          itemCount: validStudents.length,
                          itemBuilder: (context, index) {
                            final entry = validStudents[index];
                            final result = entry.key;
                            final uuid = entry.value;

                            return FutureBuilder<Map<String, dynamic>?>(
                              future: _getStudentByUuid(uuid),
                              builder: (context, snapshot) {
                                final student = snapshot.data;
                                if (student == null) return SizedBox.shrink();

                                return FutureBuilder<bool>(
                                  future: _isStudentMarkedPresentToday(student),
                                  builder: (context, attendanceSnapshot) {
                                    final isMarked = attendanceSnapshot.data == true;

                                    final signalStrength = result.rssi;
                                    int bars = 0;
                                    if (signalStrength > -60) bars = 4;
                                    else if (signalStrength > -70) bars = 3;
                                    else if (signalStrength > -80) bars = 2;
                                    else if (signalStrength > -90) bars = 1;

                                    return Card(
                                      elevation: 2,
                                      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: isMarked
                                            ? BorderSide(color: Colors.green.shade300, width: 2)
                                            : BorderSide.none,
                                      ),
                                      child: ListTile(
                                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        leading: CircleAvatar(
                                          backgroundColor: isMarked
                                              ? Colors.green.shade100
                                              : Colors.deepPurple.shade100,
                                          child: Text(
                                            student['name']?.substring(0, 1) ?? '',
                                            style: TextStyle(
                                              color: isMarked
                                                  ? Colors.green.shade700
                                                  : Colors.deepPurple.shade700,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          '${student['name'] ?? 'Unknown'}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isMarked
                                                ? Colors.green.shade700
                                                : Colors.black87,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Roll: ${student['rollNo'] ?? 'N/A'}'),
                                          ],
                                        ),
                                        trailing: isMarked
                                            ? Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade100,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.check,
                                            color: Colors.green.shade700,
                                          ),
                                        )
                                            : ElevatedButton(
                                          onPressed: () => _markStudentPresent(uuid, student),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.deepPurple.shade100,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            padding: EdgeInsets.symmetric(horizontal: 12),
                                          ),
                                          child: Text('Mark'),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
