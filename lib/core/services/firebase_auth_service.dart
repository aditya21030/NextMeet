import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Sign Up with Email & Password
  Future<User?> registerWithEmail(String email, String password, String name) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name immediately
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(name);
        await userCredential.user!.reload();
        await _syncUserToDirectory(_auth.currentUser!);
      }
      
      return _auth.currentUser;
    } catch (e) {
      print('Firebase Auth Register Error: $e');
      rethrow;
    }
  }

  // Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Firebase Auth Reset Error: $e');
      rethrow;
    }
  }

  // Sign In with Email & Password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        await _syncUserToDirectory(userCredential.user!);
      }
      return userCredential.user;
    } catch (e) {
      print('Firebase Auth Sign In Error: $e');
      rethrow;
    }
  }

  // Sign In with Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        await _syncUserToDirectory(userCredential.user!);
      }
      return userCredential.user;
    } catch (e) {
      print('Firebase Google Auth Error: $e');
      rethrow;
    }
  }

  // Sign in anonymously (Retained as fallback if needed)
  Future<User?> signInAnonymously() async {
    try {
      final UserCredential userCredential = await _auth.signInAnonymously();
      return userCredential.user;
    } catch (e) {
      print('Firebase Auth Error: $e');
      return null;
    }
  }

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Admin Dashboard Sync
  Future<void> _syncUserToDirectory(User user) async {
    try {
      await FirebaseFirestore.instance.collection('users_directory').doc(user.uid).set({
        'email': user.email ?? "No Email",
        'displayName': user.displayName ?? "Anonymous",
        'uid': user.uid,
        'photoUrl': user.photoURL ?? "",
        'lastLogin': FieldValue.serverTimestamp(),
        // Only set createdAt if the document doesn't exist to avoid overwriting
        'createdAt': user.metadata.creationTime != null ? Timestamp.fromDate(user.metadata.creationTime!) : FieldValue.serverTimestamp(),
        'syncedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Firebase Sync User Error: $e');
    }
  }
}
