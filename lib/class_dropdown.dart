import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class classDropdown extends StatelessWidget {
  final Function(String?, String?)? onChanged;

  const classDropdown({Key? key, this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('class').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }

        List<QueryDocumentSnapshot> classDocs = snapshot.data!.docs;
        List<DropdownMenuItem<String>> dropdownItems = [];

        for (var doc in classDocs) {
          String name = doc['name'];
          String macAddress = doc['macAddress'];
          dropdownItems.add(
            DropdownMenuItem(
              child: Text(name),
              value: macAddress, // Using MAC address as value
            ),
          );
        }

        return DropdownButton<String>(
          items: dropdownItems,
          onChanged: (
            String? selectedValue,
          ) {
            onChanged?.call(selectedValue, '');
          },
          hint: Text('Select a class'),
        );
      },
    );
  }
}
