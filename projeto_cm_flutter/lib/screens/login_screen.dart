import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:projeto_cm_flutter/screens/home_screen.dart';
import 'package:projeto_cm_flutter/screens/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _storage = FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _visibility = false;
  bool biometrics = false;

  Future<bool> _authenticate() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your credentials',
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  void _bioAuth(String email, String password) async {
    bool biometricsCapable = await _localAuth.canCheckBiometrics;

    if (!biometricsCapable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Biometrics are not available on this device.')),
      );
      return;
    }

    bool authenticated = await _authenticate();
    if (authenticated) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setBool('biometrics', true);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  void _bioLogin() async {
    bool authenticated = await _authenticate();

    if (authenticated) {
      try {
        String? email = await _storage.read(key: 'email');
        String? password = await _storage.read(key: 'password');

        if (email != null && password != null) {
          bool connection = await InternetConnectionChecker().hasConnection;
          if (!connection) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else {
            _login(email: email, password: password);
          }
        }
      } catch (e) {
        log('Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred. Please try again.')),
        );
      }
    }
  }

  void _login({String email = "", String password = ""}) async {
    try {
      bool _withBiometrics = false;
      if (email.isEmpty || password.isEmpty) {
        email = _emailController.text;
        password = _passwordController.text;
      } else {
        _withBiometrics = true;
      }

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _storage.write(key: 'email', value: email);
      await _storage.write(key: 'password', value: password);

      log('$userCredential');

      if (!_withBiometrics) {
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Biometric Login'),
              content: const Text(
                  'Do you want to enable biometric login for future logins?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HomeScreen()),
                    );
                  },
                  child: Text('No', style: TextStyle(color: Colors.blue[800])),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                    _bioAuth(email, password);
                  },
                  child: Text(
                    'Yes',
                    style: TextStyle(color: Colors.blue[800]),
                  ),
                ),
              ],
            );
          },
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = '';
      log('Error: ${e.code}');
      if (e.code == 'invalid-credential') {
        message = 'Invalid credentials. Please try again.';
      } else if (e.code == 'network-request-failed') {
        String? email = await _storage.read(key: 'email');
        String? password = await _storage.read(key: 'password');

        if (email != null && password != null) {
          if (email == _emailController.text &&
              password == _passwordController.text) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
            return;
          } else {
            message = 'You are offline and the credentials do not match.';
          }
        }

        message = 'Check your internet connection and try again.';
      } else {
        message = 'An unknown error occurred.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
  }

  void _checkBiometrics() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      biometrics = prefs.getBool('biometrics')!;
    });

    if (biometrics) {
      _bioLogin();
    }
  }

  @override
  void initState() {
    super.initState();

    _checkBiometrics();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Title or Logo
                Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                AutofillGroup(
                  child: Column(
                    children: [
                      // Email Input Field
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Password Input Field with show/hide password functionality
                      TextField(
                        controller: _passwordController,
                        autofillHints: const [AutofillHints.password],
                        obscureText: !_visibility,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () {
                              setState(() {
                                _visibility = !_visibility;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Login Button
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                if (biometrics)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    child: ElevatedButton(
                      onPressed: _bioLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Use Biometrics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                // Forgot Password Text
                TextButton(
                  onPressed: () {
                    // Handle forgot password action
                    // You can implement password reset functionality here
                  },
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(color: Colors.blue[800]),
                  ),
                ),

                const SizedBox(height: 20),

                // Sign Up Button
                TextButton(
                  onPressed: () {
                    // Navigate to the SignUpScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SignupScreen()),
                    );
                  },
                  child: Text(
                    "Don't have an account? Sign Up",
                    style: TextStyle(
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
