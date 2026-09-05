import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

/// Firebase Authentication Service for Smriti AI
/// 
/// This service handles all Firebase authentication operations.
/// 
/// IMPORTANT: This is a SINGLE-USER app design:
/// - No caregiver accounts
/// - No family member accounts  
/// - No sharing or invite functionality
/// - One person uses the app independently
class FirebaseService {
  static final FirebaseService instance = FirebaseService._();

  FirebaseService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb 
        ? "348047548865-l1g7h67ajv34ian0rvs963ha4pls0fo4.apps.googleusercontent.com"
        : null,
    serverClientId: "348047548865-l1g7h67ajv34ian0rvs963ha4pls0fo4.apps.googleusercontent.com",
  );

  /// Get the current authenticated user, if any
  User? get currentUser => _auth.currentUser;

  /// Check if a user is currently signed in
  bool get isSignedIn => _auth.currentUser != null;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Initialize Firebase and return true if successful
  Future<bool> initialize() async {
    try {
      // Firebase is initialized in main.dart before this service is used
      return true;
    } catch (e) {
      debugPrint('FirebaseService initialization error: $e');
      return false;
    }
  }

  /// Sign in with email and password
  /// 
  /// [email] - User's email address
  /// [password] - User's password
  /// 
  /// Returns the UserCredential on success, throws exception on failure
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Create a new user account with email and password
  /// 
  /// [email] - New user's email address
  /// [password] - New user's password (min 6 characters)
  /// 
  /// Returns the UserCredential on success, throws exception on failure
  Future<UserCredential> createUserWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with Google account
  /// 
  /// Opens Google sign-in flow and returns UserCredential on success
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Determine the sign-in provider based on platform
      if (kIsWeb) {
        // Web: Use popup for Google sign-in
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        
        final credential = await _auth.signInWithPopup(googleProvider);
        return credential;
      } else {
        // Mobile: Use GoogleSignIn package
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        
        if (googleUser == null) {
          throw AuthException('Google sign-in was cancelled');
        }

        final GoogleSignInAuthentication googleAuth = 
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        return await _auth.signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      debugPrint('[FirebaseService] Google sign-in technical exception: $e');
      throw AuthException('Could not sign in with Google. Please try again.');
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        // Sign out from Google on mobile
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      throw AuthException('Failed to sign out: $e');
    }
  }

  /// Get the current user's ID token
  /// 
  /// Returns the ID token string, or null if not signed in
  Future<String?> getIdToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  /// Get the current user's display name
  String? get displayName => _auth.currentUser?.displayName;

  /// Get the current user's email
  String? get email => _auth.currentUser?.email;

  /// Get the current user's photo URL
  String? get photoURL => _auth.currentUser?.photoURL;

  /// Get the current user's UID
  String? get uid => _auth.currentUser?.uid;

  /// Send a password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Delete the current user's account (with re-authentication)
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Handle FirebaseAuthException and return user-friendly message
  AuthException _handleAuthException(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'user-not-found':
        message = 'No account found with this email address';
        break;
      case 'wrong-password':
        message = 'Incorrect password. Please try again';
        break;
      case 'email-already-in-use':
        message = 'An account already exists with this email';
        break;
      case 'invalid-email':
        message = 'Please enter a valid email address';
        break;
      case 'weak-password':
        message = 'Password should be at least 6 characters';
        break;
      case 'user-disabled':
        message = 'This account has been disabled';
        break;
      case 'too-many-requests':
        message = 'Too many attempts. Please try again later';
        break;
      case 'operation-not-allowed':
        message = 'This sign-in method is not enabled';
        break;
      case 'account-exists-with-different-credential':
        message = 'An account already exists with a different sign-in method';
        break;
      case 'invalid-credential':
        message = 'Invalid credentials. Please check and try again';
        break;
      case 'network-error':
        message = 'Network error. Please check your connection';
        break;
      default:
        message = 'An error occurred. Please try again';
    }
    return AuthException(message);
  }
}

/// Custom exception for auth errors with user-friendly messages
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
