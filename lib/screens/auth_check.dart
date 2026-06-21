import 'dart:async'; // Import for TimeoutException
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../home_screen.dart';
import '../splash_screen.dart';
import 'onboarding_screen.dart';

class AuthCheck extends StatefulWidget {
  final User user;

  const AuthCheck({super.key, required this.user});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    try {
      // 1. Try: Reload with timeout
      await widget.user.reload().timeout(const Duration(seconds: 3));
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        final String uid = widget.user.uid;
        final bool hasSeenOnboarding =
            prefs.getBool('onboarding_seen_$uid') ?? false;

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => hasSeenOnboarding
                  ? const HomeScreen()
                  : OnboardingScreen(uid: uid),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      // 2. Catch FirebaseAuthException (Priority 1)
      if (e.code == 'user-not-found' || e.code == 'user-disabled') {
        // CRITICAL: User is deleted or disabled -> Sign out
        await FirebaseAuth.instance.signOut();
        // StreamBuilder in main.dart will handle navigation to SignInScreen
      } else {
        // Other Firebase errors (e.g., network) -> Go to Home (Optimistic)
        // Note: Ideally we should duplicate checks here or just let it go to Home for now
        // But for consistency let's stick to Home if reload fails
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
    } on TimeoutException catch (_) {
      // 3. Catch TimeoutException (Priority 2) -> Go to Home (Optimistic)
      debugPrint("Reload timed out");
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      // 4. Catch Generic Exception (Priority 3) -> Go to Home (Optimistic)
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Return SplashScreen instead of CircularProgressIndicator
    return const SplashScreen();
  }
}
