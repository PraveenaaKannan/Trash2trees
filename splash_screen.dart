import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Setup animation
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3), // Truck runs for 3 seconds
    );

    // We'll animate truck across the whole screen width
    // Begin from -150px (off screen left), end at screen width
    // But since we need screen width, we'll initialize animation later in build()

    _controller.forward();

    // Redirect after 3.2s
    Timer(Duration(milliseconds: 3200), () {
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Define animation based on screen width
    _animation = Tween<double>(begin: -150, end: screenWidth).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    return Scaffold(
      backgroundColor: Color(0xFFE8F5E9),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset("assets/logo.png", width: 100),
            SizedBox(height: 15),
            Text(
              "Smart Waste, Smart Future ♻",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            // Truck animation
            SizedBox(height: 30),
            SizedBox(
              height: 100,
              width: screenWidth,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_animation.value, 0),
                    child: child,
                  );
                },
                child: Image.asset("assets/truck.png", width: 120),
              ),
            ),

            SizedBox(height: 20),
            Text(
              "Loading your smart city...",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}