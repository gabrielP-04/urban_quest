import 'package:firebase_auth/firebase_auth.dart';
import 'package:urban_quest/services/visited_poi_storage.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentUserEmail => _auth.currentUser?.email;

  
  bool get isSignedIn => _auth.currentUser != null;

  
  Future<UserCredential> signUp({
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
    } catch (e) {
      throw 'Something went wrong $e';
    }
  }

  
  Future<UserCredential> signIn({
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
    } catch (e) {
      throw 'Something went wrong: $e';
    }
  }

  
  Future<void> signOut() async {
    try {
      await VisitedPoiStorage.clearVisitedPoiIds(userId: currentUserId);
      await _auth.signOut();
    } catch (e) {
      throw 'Could not sign out: $e';
    }
  }

  
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Could not send password reset email: $e';
    }
  }

  
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Could not delete account: $e';
    }
  }

  
  Future<void> changeEmail({
    required String newEmail,
    required String password,
  }) async {
    final user = _auth.currentUser;

    if (user == null || user.email == null) {
      throw 'User not authenticated';
    }

    try {
      
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      
      
      await user.verifyBeforeUpdateEmail(newEmail);

    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Unexpected error. Please try again.';
    }
  }

  
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;

    if (user == null || user.email == null) {
      throw 'User not authenticated';
    }

    try {
      
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      
      await user.updatePassword(newPassword);

    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Unexpected error. Please try again.';
    }
  }

  
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters long.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed at the moment.';
      case 'invalid-credential':
        return 'The email or password is incorrect. Please try again.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'requires-recent-login':
        return 'For security reasons, please sign in again to continue.';
      default:
        return 'Authentication error: ${e.message ?? e.code}';
    }
  }
}