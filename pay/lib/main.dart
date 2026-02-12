
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const AuthApp());

const API_URL = "https://aaraticosmetics.com.np/api/";

class AuthApp extends StatelessWidget {
  const AuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nonet Auth',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

Future<void> showDialogBox(String title, String content) {
  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(content),
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

    try {
      final response = await http.post(
        Uri.parse('${API_URL}login.php'),
        body: {
          "username": username,
          "password": hashedPassword,
        },
      );

      final result = response.body.trim();

      if (result == 'success') {
        showDialogBox("Login Success", "Welcome $username");
        usernameController.clear();
        passwordController.clear();
      } else {
        showDialogBox("Login Failed", result);
      }
    } catch (e) {
      showDialogBox("Error", e.toString());
    }
  }

  void goToSignup() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: usernameController, decoration: const InputDecoration(labelText: "Username")),
            TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Password")),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: login, child: const Text("Login")),
            TextButton(onPressed: goToSignup, child: const Text("Don't have an account? Sign Up"))
          ],
        ),
      ),
    );
  }
}

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final otpController = TextEditingController();

Future<void> showDialogBox(String title, String content) {
  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("OK"),
        ),
      ],
    ),
  );
}

  Future<void> sendOtp() async {
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      showDialogBox("Error", "Please fill all fields");
      return;
    }

    final hashedPassword = sha256.convert(utf8.encode(password)).toString();

    try {
      final response = await http.post(
        Uri.parse('${API_URL}signup.php'),
        body: {
          "username": username,
          "email": email,
          "password": hashedPassword,
        },
      );

      final result = response.body.trim();

      if (result == 'otp_sent') {
        showDialogBox("OTP Sent", "Check your email for the OTP");
      } else {
        showDialogBox("Error", result);
      }
    } catch (e) {
      showDialogBox("Error", e.toString());
    }
  }

  Future<void> verifySignup() async {
    final username = usernameController.text.trim();
    final otp = otpController.text.trim();

    if (otp.isEmpty) {
      showDialogBox("Error", "Enter OTP to verify");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${API_URL}verify_otp.php'),
        body: {
          "username": username,
          "otp": otp,
        },
      );

      final result = response.body.trim();

      if (result == 'success') {
        await showDialogBox("Signup Success", "You can now login");
        emailController.clear();
        passwordController.clear();
        otpController.clear();
        Navigator.pop(context);
      } else {
        showDialogBox("Error", result);
      }
    } catch (e) {
      showDialogBox("Error", e.toString());
    }
  }

  void goBackToLogin() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: usernameController, decoration: const InputDecoration(labelText: "Username")),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Password")),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: sendOtp, child: const Text("Send OTP")),
            TextField(controller: otpController, decoration: const InputDecoration(labelText: "Enter OTP")),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: verifySignup, child: const Text("Register")),
            TextButton(onPressed: goBackToLogin, child: const Text("Back to Login"))
          ],
        ),
      ),
    );
  }
}
