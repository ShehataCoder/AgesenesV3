import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Auth State Stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign Up
  Future<User?> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      final UserCredential credential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      // Update Display Name
      if (credential.user != null) {
        await credential.user!.updateDisplayName(name);
        await credential.user!.reload();
      }
      return _auth.currentUser;
    } on FirebaseAuthException catch (e) {
      debugPrint("SignUp Error: ${e.code}");
      throw _handleAuthException(e);
    } catch (e) {
      throw "An unknown error occurred.";
    }
  }

  // Sign In
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint("SignIn Error: ${e.code}");
      throw _handleAuthException(e);
    } catch (e) {
      throw "An unknown error occurred.";
    }
  }

  // Google Sign In
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // User canceled the sign-in flow
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint("Google SignIn Error: ${e.code}");
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint("Google SignIn Error: $e");
      throw "An unknown error occurred during Google Sign-In.";
    }
  }

  // Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint("Password Reset Error: ${e.code}");
      throw _handleAuthException(e);
    } catch (e) {
      throw "An unknown error occurred while sending reset email.";
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Delete Account
  Future<void> deleteUserAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw 'No user is currently signed in.';
    }

    try {
      await user.delete();
      debugPrint('Account deleted successfully.');
    } on FirebaseAuthException catch (e) {
      debugPrint('Delete error: ${e.code}');
      if (e.code == 'requires-recent-login') {
        final isGoogleUser = user.providerData.any(
          (provider) => provider.providerId == 'google.com',
        );

        if (isGoogleUser) {
          debugPrint('Google user detected. Attempting re-authentication...');
          await _reauthenticateWithGoogle(user);
          // Retry deletion after successful re-auth
          await user.delete();
          debugPrint('Account deleted after re-authentication.');
          return;
        }
        // Not a Google user (e.g., email/password)
        throw 'Please log out and log in again to delete your account.';
      }
      throw _handleAuthException(e);
    }
  }

  /// Re-authenticates a Google user.
  /// Throws a [String] error message on failure or cancellation.
  Future<void> _reauthenticateWithGoogle(User user) async {
    final googleSignIn = GoogleSignIn();

    // Try silent sign-in first for a smoother experience
    GoogleSignInAccount? googleUser = await googleSignIn.signInSilently();

    // If silent sign-in fails, prompt the user
    googleUser ??= await googleSignIn.signIn();

    if (googleUser == null) {
      throw 'Account deletion canceled.';
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await user.reauthenticateWithCredential(credential);
    debugPrint('Re-authentication with Google successful.');
  }

  // Current User
  User? get currentUser => _auth.currentUser;

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'invalid-email':
        return 'The email address is failing format validation.';
      case 'user-disabled':
        return 'This user has been disabled.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }
}
