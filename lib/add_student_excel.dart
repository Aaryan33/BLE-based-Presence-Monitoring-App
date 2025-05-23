import 'package:flutter/material.dart';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:smartattendancebeacon/class_dropdown.dart';

class AddStudentExcel extends StatefulWidget {
  @override
  _AddStudentExcelState createState() => _AddStudentExcelState();
}

class _AddStudentExcelState extends State<AddStudentExcel> {
  Future<void> _addStudentsFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xls', 'xlsx'],
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        List<int>? bytes = file.bytes;
        if (bytes != null) {
          var excel = Excel.decodeBytes(bytes);
          var table = excel.tables[excel.tables.keys.first];

          for (var row in table!.rows) {}

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Students added successfully!'),
            ),
          );
        } else {
          print('Error: No bytes found in the selected file.');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: No bytes found in the selected file.'),
            ),
          );
        }
      }
    } catch (error) {
      print('Error adding students from Excel: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add students from Excel.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Students from Excel'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            classDropdown(
              onChanged: (String? className, String? macAddress) {
                setState(() {});
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addStudentsFromExcel,
              child: Text('Add Students from Excel'),
            ),
          ],
        ),
      ),
    );
  }
}
