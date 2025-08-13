// services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> isTokenValid(String token) async {
    final doc = await _db.collection('tokens').doc(token).get();
    if (!doc.exists) return false;

    final data = doc.data()!;
    final createdAt = (data['createdAt'] as Timestamp).toDate();
    final now = DateTime.now();

    final isExpired = now.difference(createdAt).inDays > 3;
    return !isExpired && data['used'] == false;
  }

  Future<Map<String, dynamic>?> getTokenDetails(String token) async {
    final doc = await _db.collection('tokens').doc(token).get();
    return doc.exists ? doc.data() : null;
  }

  Future<void> markTokenAsUsed(String token) async {
    await _db.collection('tokens').doc(token).update({'used': true});
  }

  Future<bool> userExists(String email, String phone) async {
    final snapshot = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    if (snapshot.docs.isNotEmpty) return true;

    final phoneSnap = await _db
        .collection('users')
        .where('phone', isEqualTo: phone)
        .get();

    return phoneSnap.docs.isNotEmpty;
  }

  Future<int> getNextUserSequence(String rolePrefix) async {
    final now = DateTime.now();
    final monthYear = "${now.month.toString().padLeft(2, '0')}${now.year}";

    final query = await _db
        .collection('users')
        .where('userCode', isGreaterThanOrEqualTo: "$rolePrefix$monthYear")
        .get();

    return query.docs.length + 1;
  }
}
