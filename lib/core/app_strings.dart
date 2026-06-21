import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../settings/locale_manager.dart';

class AppStrings {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'settings_title': 'Settings',
      'appearance': 'APPEARANCE',
      'theme': 'Theme',
      'light': 'Light',
      'dark': 'Dark',
      'system': 'System',
      'data': 'DATA',
      'auto_save': 'Auto-save results',
      'auto_save_sub': 'Automatically save analysis to history.',
      'general': 'GENERAL',
      'language': 'Language',
      'account': 'ACCOUNT',
      'delete_account': 'Delete Account',
      // Bottom Navigation
      'nav_home': 'Home',
      'nav_history': 'History',
      'nav_account': 'My Account',
      // My Account Screen
      'edit_profile_btn': 'Edit Profile',
      'label_name': 'Name',
      'label_email': 'Email',
      // History Screen
      'search_hint': 'Search by age, gender or date',
      'no_history': 'No history found',
      // Edit Profile Screen
      'edit_profile_title': 'Edit Profile',
      'change_photo': 'Change Photo',
      'full_name': 'Full Name',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'save_changes': 'Save Changes',
      'cancel': 'Cancel',
      // Camera Screen
      'mode_on_device': 'On-Device',
      'mode_cloud': 'Cloud',
      'detecting': 'Detecting...',
      // Home Screen Content
      'app_name': 'AgeSense',
      'home_title': 'Live Age & Gender Estimation',
      'home_subtitle': 'Tap the camera to begin your analysis',
      'privacy_intro': 'Your privacy is important. ',
      'privacy_policy': 'Read our Privacy Policy.',
      // Auth Screens
      'sign_in_title': 'Sign In',
      'sign_up_title': 'Create Your Account',
      'sign_up_subtitle': 'Get started with AgeSense today.',
      'email_hint': 'Email',
      'username_hint': 'Email or Username',
      'forgot_password': 'Forgot Password?',
      'sign_in_btn': 'Sign In',
      'sign_up_btn': 'Sign Up',
      'or_divider': 'OR',
      'sign_in_google': 'Sign In with Google',
      'sign_up_google': 'Sign Up with Google',
      'already_have_account': 'Already have an account? Sign In',
      'dont_have_account': 'Don\'t have an account? Sign Up',
      'delete_account_title': 'Delete Account',
      'delete_account_content':
          'Are you sure? This will permanently delete your account and all your history data. This action cannot be undone.',
      'delete': 'Delete',
      'delete_error_login': 'Please log in again to delete your account.',
      'account_deleted_title': 'Account Deleted',
      'account_deleted_content':
          'We are sad to see you go. Your account and history have been deleted.',
      'ok': 'OK',
    },
    'ar': {
      'settings_title': 'الإعدادات',
      'appearance': 'المظهر',
      'theme': 'السمة',
      'light': 'فاتح',
      'dark': 'داكن',
      'system': 'النظام',
      'data': 'البيانات',
      'auto_save': 'حفظ النتائج تلقائياً',
      'auto_save_sub': 'حفظ التحليل في السجل تلقائياً',
      'general': 'عام',
      'language': 'اللغة',
      'account': 'الحساب',
      'delete_account': 'حذف الحساب',
      // Bottom Navigation
      'nav_home': 'الرئيسية',
      'nav_history': 'السجل',
      'nav_account': 'حسابي',
      // My Account Screen
      'edit_profile_btn': 'تعديل الملف الشخصي',
      'label_name': 'الاسم',
      'label_email': 'البريد الإلكتروني',
      // History Screen
      'search_hint': 'بحث بالعمر، النوع أو التاريخ',
      'no_history': 'لا يوجد سجلات',
      // Edit Profile Screen
      'edit_profile_title': 'تعديل الملف الشخصي',
      'change_photo': 'تغيير الصورة',
      'full_name': 'الاسم الكامل',
      'password': 'كلمة المرور',
      'confirm_password': 'تأكيد كلمة المرور',
      'save_changes': 'حفظ التغييرات',
      'cancel': 'إلغاء',
      // Camera Screen
      'mode_on_device': 'على الجهاز',
      'mode_cloud': 'سحابي',
      'detecting': 'جاري الكشف...',
      // Home Screen Content
      'app_name': 'AgeSense',
      'home_title': 'تقدير العمر والنوع مباشرة',
      'home_subtitle': 'اضغط على الكاميرا لبدء التحليل',
      'privacy_intro': 'خصوصيتك تهمنا. ',
      'privacy_policy': 'اقرأ سياسة الخصوصية.',
      // Auth Screens
      'sign_in_title': 'تسجيل الدخول',
      'sign_up_title': 'إنشاء حسابك',
      'sign_up_subtitle': 'ابدأ مع AgeSense اليوم.',
      'email_hint': 'البريد الإلكتروني',
      'username_hint': 'البريد الإلكتروني أو اسم المستخدم',
      'forgot_password': 'هل نسيت كلمة المرور؟',
      'sign_in_btn': 'تسجيل الدخول',
      'sign_up_btn': 'إنشاء حساب',
      'or_divider': 'أو',
      'sign_in_google': 'تسجيل الدخول عبر Google',
      'sign_up_google': 'التسجيل عبر Google',
      'already_have_account': 'لديك حساب بالفعل؟ تسجيل الدخول',
      'dont_have_account': 'ليس لديك حساب؟ إنشاء حساب',
      'delete_account_title': 'حذف الحساب',
      'delete_account_content':
          'هل أنت متأكد؟ سيؤدي هذا إلى حذف حسابك وجميع سجلاتك نهائياً. لا يمكن التراجع عن هذا الإجراء.',
      'delete': 'حذف',
      'delete_error_login': 'يرجى تسجيل الدخول مرة أخرى لحذف الحساب.',
      'account_deleted_title': 'تم حذف الحساب',
      'account_deleted_content':
          'نحن حزينون لرؤيتك تغادر. تم حذف حسابك وسجلاتك.',
      'ok': 'موافق',
    },
  };

  static String getText(
    BuildContext context,
    String key, {
    bool listen = true,
  }) {
    final localeManager = Provider.of<LocaleManager>(context, listen: listen);
    String languageCode = localeManager.locale.languageCode;
    return _localizedValues[languageCode]?[key] ?? key;
  }
}
