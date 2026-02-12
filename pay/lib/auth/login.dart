
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'signup.dart';
import '/welcome/welcome.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import '/helpers/connection_status.dart';
import '/helpers/status.dart';
import '/secure_storage/secure_storage.dart';



// Color palette (Adjust as needed)
const Color kPrimary = Color(0xFF3949ab); // Indigo[600]
const Color kAccent = Color(0xFF90caf9); // Blue[200]
const Color kCardBg = Color(0xFFe3eafc); // Light blue tinted card
const Color kBg = Color(0xFFedf2fb); // Very light background
const Color kText = Color(0xFF283149); // Dark text

const API_URL = "https://aaraticosmetics.com.np/nonet/";

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool? _isOnline;
  late StreamSubscription<bool> _statusSubscription;

  @override
  void initState() {
    super.initState();
    // Listen to global online/offline status
    _isOnline = ConnectionStatus().isOnline;
    _statusSubscription = ConnectionStatus().statusStream.listen((online) {
      setState(() {
        _isOnline = online;
      });
    });
  }

  @override
  void dispose() {
    _statusSubscription.cancel();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> showDialogBox(String title, String content) {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, style: GoogleFonts.nunito(color: kPrimary)),
        content: Text(content, style: GoogleFonts.nunito()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      showDialogBox("Error", "Please enter all fields");
      return;
    }

    final hashedPassword = sha256.convert(utf8.encode(password)).toString();
    showLoadingDialog();

    // Check internet connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    print(connectivityResult);

    if (_isOnline == true) {
      // ONLINE LOGIN
      try {
        final response = await http.post(
          Uri.parse('${API_URL}login.php'),
          body: {"username": username, "password": hashedPassword},
        );
        Navigator.of(context).pop(); // Dismiss loading
        final result = response.body.trim();
        if (result == 'success') {
          // Store for offline login
          await user_secureStorage.write(key: 'username', value: username);
          await user_secureStorage.write(key: 'password_hash', value: hashedPassword);
          usernameController.clear();
          passwordController.clear();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => WelcomePage(username: username),
            ),
          );
        } else {
          showDialogBox("Login Failed", result);
        }
      } catch (e) {
        Navigator.of(context).pop();
        showDialogBox("Error", e.toString());
      }
    } else if (_isOnline == false) {
      // OFFLINE LOGIN
      try {
        final storedUsername = await user_secureStorage.read(key: 'username');
        final storedHash = await user_secureStorage.read(key: 'password_hash');

        Navigator.of(context).pop(); // Dismiss loading

        if (username == storedUsername && hashedPassword == storedHash) {
          usernameController.clear();
          passwordController.clear();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => WelcomePage(username: username),
            ),
          );
        } else {
          showDialogBox(
              "Offline Login Failed", "Invalid credentials (offline mode)");
        }
      } catch (e) {
        Navigator.of(context).pop();
        showDialogBox("Offline Login Error", e.toString());
      }
    } else {
      showDialogBox("Please wait...", "Checking connection status.");
    }
  }

  void goToSignup() {
    Navigator.of(context).push(_createRouteToSignup());
  }

  Route _createRouteToSignup() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const SignupPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // right to left
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        final tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(
          milliseconds: 350), // Optional, for more visible effect
    );
  }

  void showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Padding(
            padding: EdgeInsets.all(24.0),
            child: CircularProgressIndicator(color: kPrimary),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          ConnectionStatusDot(isOnline: _isOnline), // Always top right!
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "NONET",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      color: kPrimary,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 30),
                  LoginCard(
                    usernameController: usernameController,
                    passwordController: passwordController,
                    onLogin: login,
                    onGoToSignup: goToSignup,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginCard extends StatelessWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final VoidCallback onLogin;
  final VoidCallback onGoToSignup;
  const LoginCard({
    Key? key,
    required this.usernameController,
    required this.passwordController,
    required this.onLogin,
    required this.onGoToSignup,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Make sure you have kPrimary, kCardBg, kText, GoogleFonts defined/imported
    return Card(
      color: kCardBg,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded, color: kPrimary, size: 56),
            const SizedBox(height: 12),
            Text(
              "Sign In",
              style: GoogleFonts.nunito(
                color: kPrimary,
                fontSize: 30,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: usernameController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "Username",
                hintStyle: GoogleFonts.nunito(
                    fontSize: 18, color: kText.withAlpha(170)),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: kPrimary, width: 1.4)),
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
              ),
              style: GoogleFonts.nunito(fontSize: 20, color: kText),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: passwordController,
              obscureText: true,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "Password",
                hintStyle: GoogleFonts.nunito(
                    fontSize: 18, color: kText.withAlpha(170)),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: kPrimary, width: 1.4)),
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
              ),
              style: GoogleFonts.nunito(fontSize: 20, color: kText),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: onLogin,
                child: Text(
                  "Login",
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: onGoToSignup,
              child: Text(
                "Don't have an account? Sign Up",
                style: GoogleFonts.nunito(
                  color: kPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
