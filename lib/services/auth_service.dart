// services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';
import 'package:intl/intl.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _fs = FirestoreService();

  Future<String?> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    String? token,
  }) async {
    if (await _fs.userExists(email, phone)) {
      return "User with this email or phone already exists.";
    }

    String role = "Client";
    String userCode = "";
    final username = "${firstName.toLowerCase()}.${lastName.toLowerCase()}";

    if (token != null && token.isNotEmpty) {
      if (!await _fs.isTokenValid(token)) {
        return "Token is invalid or expired.";
      }

      final tokenDetails = await _fs.getTokenDetails(token);
      role = tokenDetails!['role'];
      final prefix = role.startsWith("Bee") ? "BC" : role.startsWith("Trainer") ? "TB" : "LB";

      final now = DateTime.now();
      final monthYear = DateFormat('MMyyyy').format(now);
      final nextSeq = await _fs.getNextUserSequence(prefix);
      final sequence = nextSeq.toString().padLeft(4, '0');
      userCode = "$prefix$monthYear$sequence";

      await _fs.markTokenAsUsed(token);
    }

    // Create Firebase Auth User
    final userCred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final uid = userCred.user!.uid;

    // Save to Firestore
    final user = AppUser(
      uid: uid,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      email: email,
      role: role,
      username: username,
      userCode: userCode,
    );

    await FirebaseFirestore.instance.collection('users').doc(uid).set(user.toMap());

    return null; // Success
  }
}
