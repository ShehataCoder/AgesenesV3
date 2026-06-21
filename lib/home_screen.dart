import 'package:flutter/material.dart';
import 'camera_analysis_screen.dart';
import 'history_screen.dart';
import 'my_account_screen.dart';
import 'core/app_strings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeContent(),
    const HistoryScreen(),
    const MyAccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: IndexedStack(index: _currentIndex, children: _pages),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(
          context,
        ).bottomNavigationBarTheme.backgroundColor,
        selectedItemColor: Theme.of(
          context,
        ).bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor: Theme.of(
          context,
        ).bottomNavigationBarTheme.unselectedItemColor,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_filled),
            label: AppStrings.getText(context, 'nav_home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: AppStrings.getText(context, 'nav_history'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_circle_outlined),
            label: AppStrings.getText(context, 'nav_account'),
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Header
          Row(
            children: [
              const Icon(
                Icons.remove_red_eye_outlined,
                color: Color(0xFF2962FF),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                AppStrings.getText(context, 'app_name'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Main Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppStrings.getText(context, 'home_title'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.getText(context, 'home_subtitle'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF9E9E9E),
                ),
              ),
              const SizedBox(height: 50),

              // Action Button with Glow
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2962FF),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2962FF).withValues(alpha: 0.4),
                      blurRadius: 25,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      debugPrint('Camera Button Pressed');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CameraAnalysisScreen(),
                        ),
                      );
                    },
                    child: const Center(
                      child: Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                color: Color(0xFF757575),
                size: 14,
              ),
              const SizedBox(width: 4),
              RichText(
                text: TextSpan(
                  text: AppStrings.getText(context, 'privacy_intro'),
                  style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
                  children: [
                    TextSpan(
                      text: AppStrings.getText(context, 'privacy_policy'),
                      style: TextStyle(decoration: TextDecoration.underline),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
