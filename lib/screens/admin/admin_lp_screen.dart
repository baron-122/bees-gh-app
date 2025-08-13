import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'admin_home_screen.dart';
import 'admin_settings_screen.dart';
import 'id_generator_screen.dart';
import 'admin_products_screen.dart';
import 'admin_honeyStore_screen.dart';

class AdminLandingPageScreen extends StatefulWidget {
  const AdminLandingPageScreen({super.key});

  @override
  State<AdminLandingPageScreen> createState() => _AdminLandingPageScreenState();
}

class _AdminLandingPageScreenState extends State<AdminLandingPageScreen> {
  int _currentIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Widget> _screens = const [
    AdminHomeScreen(),
    AdminSettingsScreen(),
    IdGeneratorScreen(),
    AdminProductsPage(),
    AdminHoneyStoreScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  Future<void> _showLogoutDialog() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Do you want to logout and return to the login screen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      await _firestore.collection('generated_ids').doc(uid).update({'online': false});
  }}

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // prevent default pop
      onPopInvoked: (didPop) {
        if (!didPop) _showLogoutDialog();
      },
      child: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          selectedItemColor: Colors.amber[800],
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_outlined),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shop),
              label: 'Products',
            ),
            BottomNavigationBarItem(
                icon: Icon(Icons.cabin_outlined),
              label: 'Honey Store',
            )
          ],
        ),
      ),
    );
  }
}



