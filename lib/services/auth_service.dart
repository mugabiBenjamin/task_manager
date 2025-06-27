import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firebase_constants.dart';
import '../models/user_model.dart';
import 'user_service.dart';
import 'invitation_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();
  final InvitationService _invitationService = InvitationService();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
    String? invitationToken,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await result.user?.updateDisplayName(displayName);

      // Create user document in Firestore
      if (result.user != null) {
        await _createUserDocument(result.user!, displayName);
      }

      // Verify invitation token if provided
      if (invitationToken != null) {
        await verifyInvitationToken(invitationToken, displayName);
      }

      return result;
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle({String? invitationToken}) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result = await _auth.signInWithCredential(
        credential,
      );

      // Create user document if new user
      if (result.user != null) {
        await _createUserDocument(result.user!, result.user!.displayName ?? '');
        if (invitationToken != null) {
          await verifyInvitationToken(
            invitationToken,
            result.user!.displayName ?? '',
          );
        }
      }

      return result;
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      throw Exception('Failed to send verification email: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  // Get current user data from Firestore
  Future<UserModel?> getCurrentUserData() async {
    try {
      if (_auth.currentUser == null) return null;

      final doc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(_auth.currentUser!.uid)
          .get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(User user, String displayName) async {
    try {
      final userDoc = _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.uid);

      final docSnapshot = await userDoc.get();
      if (!docSnapshot.exists) {
        final userModel = UserModel(
          id: user.uid,
          email: user.email ?? '',
          displayName: displayName,
          createdAt: DateTime.now(),
          isEmailVerified: user.emailVerified,
          emailNotifications: true,
        );

        await userDoc.set(userModel.toMap());
      }
    } catch (e) {
      throw Exception('Failed to create user document: $e');
    }
  }

  // Verify invitation token
  Future<void> verifyInvitationToken(String token, String displayName) async {
    try {
      await _invitationService.acceptInvitation(token, displayName);
    } catch (e) {
      throw Exception('Failed to verify invitation token: $e');
    }
  }

  // Delete account
  Future<bool> deleteAccount() async {
    try {
      if (_auth.currentUser == null) return false;

      final userId = _auth.currentUser!.uid;

      // Delete user data using UserService
      await _userService.deleteUser(userId);

      // Delete Firebase Auth account
      await _auth.currentUser!.delete();

      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception('Please sign in again to delete your account');
      }
      throw Exception('Failed to delete account: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }
}
