import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_profile_screen.dart';
import 'settings/settings_screen.dart';
import 'core/app_strings.dart';

class UserProfile {
  final String name;
  final String email;
  final String? profileImageUrl;

  UserProfile({required this.name, required this.email, this.profileImageUrl});
}

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  String _userName = 'User';
  String _userEmail = 'No Email';
  String? _localImagePath;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Reload Firebase user to get latest display name
    await user.reload();
    final refreshedUser = FirebaseAuth.instance.currentUser;

    // Load local image path from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_pic_${user.uid}');

    if (mounted) {
      setState(() {
        _userName = refreshedUser?.displayName ?? 'User';
        _userEmail = refreshedUser?.email ?? 'No Email';
        // Only set path if file exists
        if (imagePath != null && File(imagePath).existsSync()) {
          _localImagePath = imagePath;
        } else {
          _localImagePath = null;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Create UserProfile from current state to pass to EditProfileScreen
    final UserProfile userProfile = UserProfile(
      name: _userName,
      email: _userEmail,
      profileImageUrl: _localImagePath,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          AppStrings.getText(context, 'nav_account'),
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Profile Avatar Section
            Stack(
              children: [
                Builder(
                  builder: (context) {
                    // Image hierarchy: 1) Local image, 2) Google photo URL, 3) Placeholder
                    final user = FirebaseAuth.instance.currentUser;
                    ImageProvider? imageProvider;
                    if (_localImagePath != null) {
                      imageProvider = FileImage(File(_localImagePath!));
                    } else if (user?.photoURL != null) {
                      imageProvider = NetworkImage(user!.photoURL!);
                    }

                    return Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFDBB5),
                        image: imageProvider != null
                            ? DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: imageProvider == null
                          ? const Icon(
                              Icons.person_outline,
                              size: 60,
                              color: Colors.black54,
                            )
                          : null,
                    );
                  },
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2962FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Edit Profile Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditProfileScreen(userProfile: userProfile),
                    ),
                  );
                  // Refresh data immediately when returning from EditProfileScreen
                  await _loadUserData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2962FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppStrings.getText(context, 'edit_profile_btn'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Info Container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildProfileInfoTile(
                    context,
                    icon: Icons.person,
                    label: AppStrings.getText(context, 'label_name'),
                    value: _userName,
                    hasDivider: true,
                  ),
                  _buildProfileInfoTile(
                    context,
                    icon: Icons.email,
                    label: AppStrings.getText(context, 'label_email'),
                    value: _userEmail,
                    hasDivider: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool hasDivider,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFFB0B0B0)),
          ),
          title: Text(
            label,
            style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
          ),
          subtitle: Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (hasDivider)
          const Divider(color: Color(0xFF333333), height: 1, thickness: 1),
      ],
    );
  }
}
