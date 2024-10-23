import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:projeto_cm_flutter/screens/login_screen.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({Key? key}) : super(key: key);

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final _storage = FlutterSecureStorage();

  String _userName = 'UserName';

  @override
  void initState() {
    super.initState();
    
    _storage.read(key: "user_name").then((value) {
      setState(() {
        _userName = value ?? 'UserName';
      });
    });
  }

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
    return Scaffold(
        body: Column(
      children: [
        SizedBox(height: 50),
        Row(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.center, children: [
          IconButton(
            padding: const EdgeInsets.only(right: 20),
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue,
                radius: 60,
                child: const Icon(Icons.person, size: 100),
              ),
              const SizedBox(width: 20),
              Expanded(child: Center(child: Text(_userName, style: const TextStyle(fontSize: 24)))),
            ],
          ),
        ),
        Expanded(child: Center(child: Text('Travel History'))),
      ],
    ));
  }
}
