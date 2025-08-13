import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

//screens routing
import 'screens/landing_page_screen';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/admin/admin_lp_screen.dart';
import 'screens/bee-champion/bee_champion_lp.dart';
import 'screens/client/client_home_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Enable App Check in debug mode
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bees GH App',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingPageScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/admin': (context) => const AdminLandingPageScreen(),
        '/Bee Champion': (context) => const BeeChampionLandingPage(),
        '/client' : (context) => const ClientHomeScreen(firstName: '',),
      },
      theme: ThemeData(
        primarySwatch: Colors.amber,
        useMaterial3: true,
      ),
      //home: const LandingPageScreen(), // This becomes your default first screen
    );
  }
}
