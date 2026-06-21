import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme_manager.dart';
import 'locale_manager.dart';
import '../core/app_strings.dart';
import '../services/auth_service.dart';
import '../core/database_helper.dart';
import '../sign_in_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final localeManager = Provider.of<LocaleManager>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppStrings.getText(context, 'settings_title'),
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
      ),
      body: Stack(
        children: [
          // Layer 1: Main Settings Content
          ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- APPEARANCE Section ---
              _buildSectionHeader(AppStrings.getText(context, 'appearance')),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10.0),
                  leading: _buildIcon(
                    Icons.palette,
                    const Color(0xFF0D47A1),
                    const Color(0xFF42A5F5),
                  ),
                  title: Text(
                    AppStrings.getText(context, 'theme'),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: ToggleButtons(
                    isSelected: [
                      themeManager.themeMode == ThemeMode.light,
                      themeManager.themeMode == ThemeMode.dark,
                      themeManager.themeMode == ThemeMode.system,
                    ],
                    onPressed: (int index) {
                      if (index == 0) themeManager.toggleTheme(ThemeMode.light);
                      if (index == 1) themeManager.toggleTheme(ThemeMode.dark);
                      if (index == 2)
                        themeManager.toggleTheme(ThemeMode.system);
                    },
                    color: Colors.grey,
                    selectedColor: Colors.white,
                    fillColor: const Color(0xFF2962FF),
                    borderRadius: BorderRadius.circular(8),
                    constraints: const BoxConstraints(
                      minHeight: 36,
                      minWidth: 48,
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          AppStrings.getText(context, 'light'),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          AppStrings.getText(context, 'dark'),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          AppStrings.getText(context, 'system'),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- DATA Section ---
              _buildSectionHeader(AppStrings.getText(context, 'data')),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: ListTile(
                  leading: _buildIcon(
                    Icons.save,
                    const Color(0xFF0D47A1),
                    const Color(0xFF42A5F5),
                  ),
                  title: Text(
                    AppStrings.getText(context, 'auto_save'),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  subtitle: Text(
                    AppStrings.getText(context, 'auto_save_sub'),
                    style: const TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 12,
                    ),
                  ),
                  trailing: Switch(
                    value: true, // Dummy value
                    onChanged: (val) {},
                    activeThumbColor: const Color(0xFF2962FF),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- GENERAL Section ---
              _buildSectionHeader(AppStrings.getText(context, 'general')),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: ListTile(
                  leading: _buildIcon(
                    Icons.language,
                    const Color(0xFF0D47A1),
                    const Color(0xFF42A5F5),
                  ),
                  title: Text(
                    AppStrings.getText(context, 'language'),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  trailing: DropdownButton<String>(
                    value: localeManager.locale.languageCode == 'ar'
                        ? 'العربية'
                        : 'English',
                    dropdownColor: Theme.of(context).cardColor,
                    style: Theme.of(context).textTheme.bodyLarge,
                    underline: Container(),
                    icon: Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    items: ['English', 'العربية'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue == 'English') {
                        localeManager.setLocale(const Locale('en'));
                      } else if (newValue == 'العربية') {
                        localeManager.setLocale(const Locale('ar'));
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- ACCOUNT Section ---
              _buildSectionHeader(AppStrings.getText(context, 'account')),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: _buildIcon(
                        Icons.logout,
                        const Color(0xFFB71C1C),
                        const Color(0xFFFF5252),
                      ),
                      title: const Text(
                        'Log Out',
                        style: TextStyle(color: Color(0xFFFF5252)),
                      ),
                      onTap: () {
                        _showLogoutConfirmationDialog(context);
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: _buildIcon(
                        Icons.delete,
                        const Color(0xFFB71C1C),
                        const Color(0xFFFF5252),
                      ),
                      title: Text(
                        AppStrings.getText(context, 'delete_account'),
                        style: const TextStyle(color: Color(0xFFFF5252)),
                      ),
                      onTap: () {
                        _showDeleteConfirmationDialog(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Layer 2: Loading Overlay (only visible when _isLoading is true)
          Visibility(
            visible: _isLoading,
            child: Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.all(24.0),
          title: Text(
            'Log Out',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF424242)
                        : Colors.grey[300],
                    foregroundColor: isDark ? Colors.white : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(AppStrings.getText(dialogContext, 'cancel')),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop(); // Close dialog
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const SignInScreen()),
                        (route) => false,
                      );
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Log Out'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.all(24.0),
          title: Text(
            AppStrings.getText(dialogContext, 'delete_account_title'),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            AppStrings.getText(dialogContext, 'delete_account_content'),
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF424242)
                        : Colors.grey[300],
                    foregroundColor: isDark ? Colors.white : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(AppStrings.getText(dialogContext, 'cancel')),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop(); // Close confirmation dialog
                    _handleDeleteAccount(); // Start deletion process
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(AppStrings.getText(dialogContext, 'delete')),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleDeleteAccount() async {
    // Get references before async gap
    final authService = Provider.of<AuthService>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Show inline loading overlay
    setState(() {
      _isLoading = true;
    });

    try {
      // Step 1: Clear local history
      await DatabaseHelper.instance.clearAllHistory();

      // Step 2: Delete Firebase account
      await authService.deleteUserAccount();

      // Step 3: Dismiss loading and show Goodbye Dialog
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSuccessDialog();
      }
    } catch (e) {
      // ERROR: Remove overlay and show error
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User MUST click OK
      builder: (BuildContext dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.all(24.0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sad Face Icon
              Icon(
                Icons.sentiment_dissatisfied,
                size: 64,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                AppStrings.getText(dialogContext, 'account_deleted_title'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Content
              Text(
                AppStrings.getText(dialogContext, 'account_deleted_content'),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const SignInScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2962FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  AppStrings.getText(dialogContext, 'ok'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF9E9E9E),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildIcon(IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }
}
