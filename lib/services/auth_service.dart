import 'package:firebase_auth/firebase_auth.dart';

/// Service wrapping Firebase Authentication for email/password auth.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Currently signed-in user, or null if not authenticated.
  User? get currentUser => _auth.currentUser;

  /// Stream that emits the current user on auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password.
  /// Throws [FirebaseAuthException] on failure.
  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Register a new user with email and password.
  /// Throws [FirebaseAuthException] on failure.
  Future<UserCredential> signUp(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Send a password reset email.
  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  /// Sign out the current user.
  Future<void> signOut() {
    return _auth.signOut();
  }
}
