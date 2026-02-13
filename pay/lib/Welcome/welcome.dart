import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/dashboard/dashboard.dart';


class WelcomePage extends StatefulWidget {
  final String username;

  const WelcomePage({super.key, required this.username});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
  with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _welcomeOffset;
  late Animation<Offset> _dashboardOffset;
  var balance = null;
  


  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _welcomeOffset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1), // Slide up
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _dashboardOffset = Tween<Offset>(
      begin: const Offset(0, 1), // Start offscreen bottom
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Start animation after short delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 206, 214, 223),
      body: Stack(
        children: [
          SlideTransition(
            position: _dashboardOffset,
            child: DashboardPage(username: widget.username),
          ),
          SlideTransition(
            position: _welcomeOffset,
            child: Center(
              child: Text(
                'Welcome ${widget.username.toUpperCase()}',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[700],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}