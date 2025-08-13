/*
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'client/client_landing_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;

  void _loginUser() async {
    setState(() => _isLoading = true);

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      // Step 1: Sign in
      UserCredential userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCred.user!.uid;

      // Step 2: Get user details from Firestore
      final userDocRef = _firestore.collection('users').doc(uid);
      final userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        throw Exception("User data not found in Firestore.");
      }

      final userData = userDoc.data()!;
      final firstName = userData['first_name'] ?? 'Buzz';
      final lastName = userData['last_name'] ?? 'User';
      final role = userData['role'] ?? 'client';

      // ✅ Step 3: Ensure user_id is stored in user doc
      if (userData['user_id'] != uid) {
        await userDocRef.update({'user_id': uid});
      }

      // ✅ Step 4: Find and update generated_ids document where assigned_to == uid
      try {
        final genIdSnapshot = await _firestore
            .collection('generated_ids')
            .where('assigned_to', isEqualTo: uid)
            .limit(1)
            .get();

        if (genIdSnapshot.docs.isNotEmpty) {
          await genIdSnapshot.docs.first.reference.update({'online': true});
          print("✅ Online status updated for generated_id doc.");
        } else {
          print("⚠️ No generated_id document found for this user.");
        }
      } catch (e) {
        print("⚠️ Could not update generated_ids status: $e");
      }

      // 🎉 Step 5: Print welcome
      print("🎉 Welcome $firstName $lastName!");

      // Step 6: Navigate based on role
      switch (role) {
        case 'admin':
          Navigator.pushReplacementNamed(context, '/admin');
          break;
        case 'Bee Champion':
          Navigator.pushReplacementNamed(context, '/Bee Champion');
          break;
        case 'trainer':
          Navigator.pushReplacementNamed(context, '/trainer');
          break;
        case 'learner':
          Navigator.pushReplacementNamed(context, '/learner');
          break;
        case 'client':
        default:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ClientLandingPage(firstName: firstName),
            ),
          );
          break;
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Login failed");
    } catch (e) {
      _showError("Login failed: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("🚫 $message")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // TODO: Navigate to Forgot Password screen
                },
                child: const Text('Forgot Password?'),
              ),
            ),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _loginUser,
              child: const Text("Login"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signup');
              },
              child: const Text("Don't have an account? Sign up"),
            )
          ],
        ),
      ),
    );
  }
}

*/
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'client/client_landing_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;

  void _loginUser() async {
    setState(() => _isLoading = true);

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      // Step 1: Sign in
      UserCredential userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCred.user!.uid;

      // Step 2: Get user details from Firestore
      final userDocRef = _firestore.collection('users').doc(uid);
      final userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        throw Exception("User data not found in Firestore.");
      }

      final userData = userDoc.data()!;
      final firstName = userData['first_name'] ?? 'Buzz';
      final lastName = userData['last_name'] ?? 'User';
      final role = userData['role'] ?? 'client';

      // Ensure user_id is stored in user doc
      if (userData['user_id'] != uid) {
        await userDocRef.update({'user_id': uid});
      }

      // Find and update generated_ids document
      try {
        final genIdSnapshot = await _firestore
            .collection('generated_ids')
            .where('assigned_to', isEqualTo: uid)
            .limit(1)
            .get();

        if (genIdSnapshot.docs.isNotEmpty) {
          await genIdSnapshot.docs.first.reference.update({'online': true});
        }
      } catch (e) {
        print("⚠️ Could not update generated_ids status: $e");
      }

      // Navigate
      switch (role) {
        case 'admin':
          Navigator.pushReplacementNamed(context, '/admin');
          break;
        case 'Bee Champion':
          Navigator.pushReplacementNamed(context, '/Bee Champion');
          break;
        case 'trainer':
          Navigator.pushReplacementNamed(context, '/trainer');
          break;
        case 'learner':
          Navigator.pushReplacementNamed(context, '/learner');
          break;
        default:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ClientLandingPage(firstName: firstName),
            ),
          );
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Login failed");
    } catch (e) {
      _showError("Login failed: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("🚫 $message")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFC107), Color(0xFFFFA000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 10,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_rounded, size: 60, color: Colors.amber),
                    const SizedBox(height: 12),
                    Text(
                      "Welcome Back",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[800],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // TODO: Forgot password navigation
                        },
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          //backgroundColor: Colors.brown[800],
                          backgroundColor: const Color(0xFF8B4513),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _loginUser,
                        child: const Text(
                          "Login",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      child: const Text(
                        "Don't have an account? Sign up",
                        style: TextStyle(color: Colors.brown),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
