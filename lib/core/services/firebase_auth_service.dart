import 'auth_service.dart';

/// Legacy adapter maintaining seamless backward compatibility for existing screens
/// while routing 100% of authentication operations through Supabase Auth.
class FirebaseAuthService {
  final AuthService _auth = AuthService();

  Future<AppUser?> registerWithEmail(
          String email, String password, String name) =>
      _auth.registerWithEmail(email, password, name);

  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email);

  Future<void> verifyRecoveryOtp(
          {required String email, required String token}) =>
      _auth.verifyRecoveryOtp(email: email, token: token);

  Future<void> setNewPassword(String newPassword) =>
      _auth.setNewPassword(newPassword);

  Future<AppUser?> signInWithEmail(String email, String password) =>
      _auth.signInWithEmail(email, password);

  Future<AppUser?> signInWithGoogle() => _auth.signInWithGoogle();

  AppUser? get currentUser => _auth.currentUser;

  Stream<AppUser?> get authStateChanges => _auth.authStateChanges;

  Future<void> signOut() => _auth.signOut();
}
