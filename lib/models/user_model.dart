// models/user_model.dart
class AppUser {
  final String uid;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String role;
  final String username;
  final String userCode;

  AppUser({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.role,
    required this.username,
    required this.userCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'email': email,
      'role': role,
      'username': username,
      'userCode': userCode,
      'createdAt': DateTime.now(),
    };
  }
}
