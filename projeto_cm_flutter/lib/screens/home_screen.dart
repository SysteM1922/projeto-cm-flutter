import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projeto_cm_flutter/screens/bus_tracking_screen.dart';
import 'package:projeto_cm_flutter/screens/login_screen.dart';
import 'package:projeto_cm_flutter/screens/nfc_screen.dart';
import 'package:projeto_cm_flutter/screens/scan_qr_code_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  
  final _storage = FlutterSecureStorage();

  // Method to sign out
  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    await _storage.delete(key: 'user_id');
    // Navigate back to the LoginScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the current user
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus App'),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Welcome message
            if (user != null)
              Text(
                'Welcome, ${user.displayName ?? user.email}',
                style: const TextStyle(fontSize: 20),
              ),
            const SizedBox(height: 20),
            // Buttons for the main features
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                children: [
                  // Real-time Bus Tracking
                  FeatureButton(
                    icon: Icons.directions_bus,
                    label: 'Real-time Bus Tracking',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const BusTrackingScreen()),
                      );
                    },
                  ),
                  // Scan QR Code
                  FeatureButton(
                    icon: Icons.qr_code_scanner,
                    label: 'Scan QR Code',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ScanQRCodeScreen()),
                      );
                    },
                  ),
                  // NFC Card Validation
                  FeatureButton(
                    icon: Icons.nfc,
                    label: 'NFC Validation',
                    onPressed: () {
                      // Navigate to NFC Validation screen (to be implemented)
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NFCScreen()),
                      );
                    },
                  ),
                  // Travel History
                  FeatureButton(
                    icon: Icons.history,
                    label: 'Travel History',
                    onPressed: () {
                      // Navigate to Travel History screen (to be implemented)
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom widget for feature buttons
class FeatureButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const FeatureButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onPressed,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 48,
                  color: Colors.blue[800],
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
