import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> createAdminUser() async {
  try {
    // Check if admin already exists to avoid duplicate
    final existingAdmins = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .get();

    if (existingAdmins.docs.isNotEmpty) {
      print('⚠️ Admin user already exists. Skipping migration.');
      return;
    }

    UserCredential userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: 'admin@gmail.com',
      password: 'BuzzingStrong123!',
    );

    await FirebaseFirestore.instance.collection('users').doc(userCred.user!.uid).set({
      'uid': userCred.user!.uid,
      'email': 'admin@gmail.com',
      'first_name': 'Baron',
      'last_name': 'Okpoti-Abbans',
      'role': 'admin',
      'created_at': Timestamp.now(),
      'region': null,
      'town': null,
      'community': null,
    });

    print('✅ Admin user created successfully!');
  } catch (e) {
    print('❌ Failed to create admin user: $e');
  }
}
