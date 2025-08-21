import 'package:flutter/material.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Admin Home Page",
          style: TextStyle(
            color: Color(0xFFFFD54F),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.brown[800],
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFFFD54F)),
      ),
      body:
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [
                Colors.amber.shade50,
                Colors.amber.shade100,
              ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        ),
        child:
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
            Text(
              'Welcome to the Admin Dashboard! 🐝',
              style: TextStyle(
                fontSize: 22,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Coming in Phase 2',
              style: TextStyle(
                fontSize: 14,
              ),
            ),
              
            ],

        ),

      ),
      )
    );
  }
}

