import 'package:flutter/material.dart';
import 'client_accounts_screen.dart';
import 'client_home_screen.dart';
import 'client_shopping_cart_screen.dart';

class ClientLandingPage extends StatefulWidget {
  final String firstName;

  const ClientLandingPage({super.key, required this.firstName});

  @override
  State<ClientLandingPage> createState() => _ClientLandingPageState();
}

class _ClientLandingPageState extends State<ClientLandingPage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      ClientHomeScreen(firstName: widget.firstName),
      const ShoppingCartScreen(),
      const UserAccountsScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}
