import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> addFacultyMember(String name, String subject, String email, String password) async {
  try {

    UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .set({
      'uid': userCredential.user!.uid,
      'name': name,
      'email': email,
      'role': 'faculty',
      'subject': subject,
    });

    print('Faculty member added successfully!');
  }
  catch (e) {
    print('Error adding faculty member: $e');
  }
}
