import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Signs in with Google and creates a Firestore user document if the user is new.
  Future<User?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      // User canceled the sign-in flow
      return null;
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;

    // OPTIMIZATION: Check isNewUser instead of reading the doc from Firestore.
    // This avoids a database read operation on every Google sign-in.
    if (user != null && (userCredential.additionalUserInfo?.isNewUser ?? false)) {
      // For new users, create their document in Firestore.
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email,
        'displayName': user.displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'countryCode': 'IN', // Hardcoded as per your example
        'currency': 'INR',
      });
    }
    return user;
  }

  /// Signs up a new user with email and password.
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        // Update the user's display name in Firebase Auth
        await user.updateDisplayName(displayName);

        // Create the user document in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'displayName': displayName,
          'createdAt': FieldValue.serverTimestamp(),
          'countryCode': 'IN',
          'currency': 'INR',
        });
      }
      return user;
    } on FirebaseAuthException catch (e) {
      // Provide more user-friendly error messages
      if (e.code == 'weak-password') {
        throw Exception('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('An account already exists for that email.');
      }
      throw Exception(e.message ?? 'Sign up failed');
    }
  }

  /// Signs in an existing user with email and password.
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
         throw Exception('Incorrect email or password.');
      }
      throw Exception(e.message ?? 'Sign in failed');
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await GoogleSignIn().signOut(); // Sign out from Google
    await _auth.signOut();         // Sign out from Firebase
  }
}