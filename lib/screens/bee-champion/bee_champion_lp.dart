/*
import 'package:flutter/material.dart';
import 'bee_champion_home.dart';
import 'bee_champion_products.dart';

class BeeChampionLandingPage extends StatefulWidget {
  const BeeChampionLandingPage({super.key});

  @override
  State<BeeChampionLandingPage> createState() => _BeeChampionLandingPageState();
}

class _BeeChampionLandingPageState extends State<BeeChampionLandingPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    BeeChampionHome(),
    BeeChampionProductsPage(),
  ];

  final List<String> _titles = const [
    'Bee Champion Home',
    'Products',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Bee Champion Page'), automaticallyImplyLeading: false,
        backgroundColor: Colors.amber[700],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Products',
          ),
        ],
      ),
    );
  }
}
*/
import 'package:flutter/material.dart';
import 'bee_champion_home.dart';
import 'bee_champion_products.dart';
import 'bee_champion_user_page.dart';

class BeeChampionLandingPage extends StatefulWidget {
  const BeeChampionLandingPage({super.key});

  @override
  State<BeeChampionLandingPage> createState() => _BeeChampionLandingPageState();
}

class _BeeChampionLandingPageState extends State<BeeChampionLandingPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    BeeChampionHome(),
    BeeChampionProductsPage(),
    BeeChampionUserPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Bee Champion Page'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.amber[700],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
