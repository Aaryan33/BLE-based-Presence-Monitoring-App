import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartattendancebeacon/class_dropdown.dart';

class FetchAttendance extends StatefulWidget {
  @override
  _FetchAttendanceState createState() => _FetchAttendanceState();
}

class _FetchAttendanceState extends State<FetchAttendance> {
  String? selectedClass;
  String? selectedMacAddress;
  TextEditingController _dateController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int presentStudentsCount = 0;
  int absentStudentsCount = 0;

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Class:',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            classDropdown(
              onChanged: (String? selectedValue, String? macAddress) {
                setState(() {
                  selectedClass = selectedValue;
                  selectedMacAddress = macAddress;
                  print(macAddress);
                });
              },
            ),
            SizedBox(height: 10),
            Text(
              'Select Date:',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _dateController,
              readOnly: true,
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null && pickedDate != _selectedDate) {
                  setState(() {
                    _selectedDate = pickedDate;
                    _dateController.text =
                        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
                  });
                }
              },
              decoration: InputDecoration(
                labelText: 'Date',
                suffixIcon: Icon(Icons.calendar_today),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                if (selectedClass != null) {
                  // Fetch attendance data for the selected class and date
                  fetchAttendance(selectedClass!, _selectedDate);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please select a class.'),
                    ),
                  );
                }
              },
              child: Center(
                child: Text(
                  'Fetch Attendance',
                ),
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('Present Students: $presentStudentsCount'),
                Text('Absent Students: $absentStudentsCount'),
              ],
            ),
            SizedBox(height: 10),
            Text(
              'Attendance List:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: attendanceData.length,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    child: ListTile(
                      title: Text(
                        attendanceData[index]['name'],
                        style: TextStyle(color: Colors.black),
                      ),
                      subtitle: Text(attendanceData[index]['email']),
                      trailing: Text(
                        attendanceData[index]['present'] ? 'Present' : 'Absent',
                        style: TextStyle(
                          color: attendanceData[index]['present']
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> attendanceData = [];

  Future<void> fetchAttendance(
      String selectedClass, DateTime selectedDate) async {
    String dateString =
        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    print(dateString);
    try {
      // Fetch all users of the selected class
      QuerySnapshot<Map<String, dynamic>> usersSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('macAddress', isEqualTo: selectedClass)
              .get();

      List<String> studentUIDs = [];
      Map<String, bool> attendanceMap = {};

      usersSnapshot.docs.forEach((userDoc) {
        String uid = userDoc.id;
        String name = userDoc.data()['name'];
        String email = userDoc.data()['email'];

        // Add student UID to the list
        studentUIDs.add(uid);
        print(studentUIDs);

        attendanceMap["$uid _ $dateString"] = false;

        // Print student name and email for debug
        print('Student Name: $name, Email: $email');
      });

      QuerySnapshot<Map<String, dynamic>> attendanceQuerySnapshot =
          await FirebaseFirestore.instance
              .collection('attendance')
              .where('date', isEqualTo: dateString)
              .where('status', isEqualTo: 'present')
              .get();

      attendanceQuerySnapshot.docs.forEach((attendanceDoc) {
        String reluid = attendanceDoc.id;

        // Mark student as present
        attendanceMap[reluid] = true;
      });

      List<String> absentStudents = [];
      studentUIDs.forEach((uid) {
        if (!attendanceMap.containsKey("$uid _ $dateString") ||
            attendanceMap["$uid _ $dateString"] == false) {
          absentStudents.add(uid);
        }
      });

      // Display the attendance status
      int totalStudentsCount = studentUIDs.length;
      presentStudentsCount = totalStudentsCount - absentStudents.length;
      absentStudentsCount = absentStudents.length;
      print('Total Students: $totalStudentsCount');
      print('Present Students: $presentStudentsCount');
      print('Absent Students: ${absentStudents.length}');
      print('List of absent students: $absentStudents');

      attendanceData.clear();
      await Future.forEach(studentUIDs, (uid) async {
        DocumentSnapshot userSnapshot =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (userSnapshot.exists) {
          Map<String, dynamic>? userData =
              userSnapshot.data() as Map<String, dynamic>?;
          if (userData != null) {
            String name = userData['name'] ?? '';
            String email = userData['email'] ?? '';
            print('Name: $name, Email: $email'); // Debugging
            if (attendanceMap.containsKey("$uid _ $dateString")) {
              // Student present
              attendanceData.add({
                'name': name,
                'email': email,
                'present': attendanceMap["$uid _ $dateString"],
              });
            } else {
              // No attendance data for the student
              attendanceData.add({
                'name': name,
                'email': email,
                'present': false,
              });
            }
          }
        } else {
          print('User not found for UID: $uid');
        }
      });

      setState(() {});
    } catch (error) {
      print('Error fetching attendance data: $error');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching attendance data.'),
        ),
      );
    }
  }
}
