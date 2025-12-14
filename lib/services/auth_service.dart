import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Update user info if user already exists (but don't create new user)
      await updateUserInfo();

      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  // Check if user exists in Firestore
  Future<bool> userExistsInFirestore() async {
    try {
      final user = currentUser;
      if (user == null) return false;

      final userDocRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userDocRef.get();
      return userDoc.exists;
    } catch (e) {
      print('Error checking user existence: $e');
      return false;
    }
  }

  // Check if user has dailyTarget set
  Future<bool> hasDailyTarget() async {
    try {
      final user = currentUser;
      if (user == null) return false;

      final userDocRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userDocRef.get();

      if (!userDoc.exists) return false;

      final data = userDoc.data();
      return data != null &&
          data.containsKey('dailyTarget') &&
          data['dailyTarget'] != null;
    } catch (e) {
      print('Error checking dailyTarget: $e');
      return false;
    }
  }

  // Update user info in Firestore (for existing users)
  Future<void> updateUserInfo() async {
    try {
      final user = currentUser;
      if (user == null) return;

      final userDocRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        // Update existing user document with latest info
        await userDocRef.update({
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating user document: $e');
      // Don't rethrow - we don't want to fail if Firestore fails
    }
  }

  // Sign out
  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }
}
