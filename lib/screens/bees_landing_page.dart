
import 'package:flutter/material.dart';

void main() {
  runApp(BeesLandingApp());
}

class BeesLandingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bees For Development Ghana',
      home: BeesLandingPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class BeesLandingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const backgroundTop = Color(0xFFD6E106);
    const backgroundMid = Color(0xFFACBE04);
    const backgroundBottom = Color(0xFF789B04);

    const honeyOrange = Color(0xFFF38D00);
    const leafGreen = Color(0xFF139E42);
    const nearBlack = Color(0xFF0B0B0B);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [backgroundTop, backgroundMid, backgroundBottom],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.bug_report, color: nearBlack),
                    const SizedBox(width: 8),
                    Text(
                      'Bees For Development Ghana',
                      style: TextStyle(
                        color: nearBlack,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 2),
                Text(
                  'Join the Buzzing Family',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: nearBlack,
                    fontWeight: FontWeight.w700,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Learn, connect, and grow with beekeepers across Ghana.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: nearBlack.withOpacity(0.85),
                    fontSize: 16,
                  ),
                ),
                const Spacer(flex: 2),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: honeyOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () {},
                    child: const Text('Sign up'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: nearBlack,
                      side: BorderSide(color: leafGreen, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text('Login'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {},
                  child: const Text('Continue as guest'),
                ),
                const Spacer(flex: 3),
                Text(
                  'Supported by local beekeeping communities',
                  style: TextStyle(
                    color: nearBlack.withOpacity(0.7),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
