import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartattendancebeacon/add_attendance.dart';
import 'package:smartattendancebeacon/add_student.dart';
import 'package:smartattendancebeacon/bluetooth_scan.dart';
import 'package:smartattendancebeacon/add_student_excel.dart';
import 'package:smartattendancebeacon/get_attendance.dart';
import 'package:smartattendancebeacon/login_page.dart';

class FacultyDashboardPage extends StatefulWidget {

  // final String facultyEmail;
  // final String facultyPassword;
  //
  // FacultyDashboardPage({
  //   required this.facultyEmail,
  //   required this.facultyPassword,
  // });

  @override
  _FacultyDashboardPageState createState() => _FacultyDashboardPageState();
}

class _FacultyDashboardPageState extends State<FacultyDashboardPage> {
  int _selectedIndex = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      BluetoothScanPage(),
      AddStudent(
        // facultyEmail: widget.facultyEmail,
        // facultyPassword: widget.facultyPassword,
      ),
      // AddStudentExcel(),
      // FetchAttendance(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          unselectedItemColor: Colors.grey,
          selectedItemColor: Color.fromARGB(255, 140, 65, 153),
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.bluetooth),
              label: 'Bluetooth',
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.add),
              label: 'Add Students',
            ),
            // BottomNavigationBarItem(
            //   icon: Icon(Icons.list),
            //   label: 'Auto',
            // ),

            // BottomNavigationBarItem(
            //   icon: Icon(Icons.download),
            //   label: "Get Attendance",
            // ),
          ],
        ),
      ),
    );
  }
}