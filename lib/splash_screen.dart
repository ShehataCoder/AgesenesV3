import 'dart:async';
import 'package:flutter/material.dart';
import 'sign_in_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 10-second timer
    Timer(const Duration(seconds: 10), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignInScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Center(
          // <-- كل حاجة في النص
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // <-- يخلي العمود قد المحتوى فقط
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0xFF1F4E58), Color(0xFF111B29)],
                      stops: [0.3, 1.0],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.face_rounded,
                      color: Color(0xFF80DEEA),
                      size: 60,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Title
                const Text(
                  'AgeSense',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFFFFF),
                    letterSpacing: 1.0,
                    fontFamily: 'Poppins',
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  'Real-time Insights',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF9E9E9E),
                    fontFamily: 'Poppins',
                  ),
                ),

                const SizedBox(height: 32),

                // Progress Bar
                SizedBox(
                  width: size.width * 0.8,
                  height: 6,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: const LinearProgressIndicator(
                      backgroundColor: Color(0xFF333333),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF2962FF),
                      ),
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
