import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppUser {
  final String uid; // Maps to Firebase UID for migrated users, or Supabase UUID for new users
  final String id;  // Supabase Auth UUID
  final String? email;
  final String? displayName;
  final String? photoURL;

  AppUser({
    required this.uid,
    required this.id,
    this.email,
    this.displayName,
    this.photoURL,
  });

  factory AppUser.fromSupabase(User user) {
    final meta = user.userMetadata ?? {};
    final fbUid = meta['firebase_uid'] as String?;
    final name = meta['displayName'] as String? ??
        meta['display_name'] as String? ??
        meta['name'] as String?;
    final photo = meta['photoUrl'] as String? ??
        meta['photo_url'] as String? ??
        meta['avatar_url'] as String? ??
        meta['picture'] as String?;
    return AppUser(
      uid: (fbUid != null && fbUid.isNotEmpty) ? fbUid : user.id,
      id: user.id,
      email: user.email,
      displayName: name,
      photoURL: photo,
    );
  }
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AppUser? get currentUser {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return AppUser.fromSupabase(user);
  }

  String? get currentUid => currentUser?.uid;

  Stream<AppUser?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.map((data) {
      final user = data.session?.user ?? _supabase.auth.currentUser;
      if (user == null) return null;
      return AppUser.fromSupabase(user);
    });
  }

  Future<AppUser?> signInWithEmail(String email, String password) async {
    final res = await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    if (res.user != null) {
      await _syncUserToDirectory(res.user!);
      return AppUser.fromSupabase(res.user!);
    }
    return null;
  }

  Future<AppUser?> registerWithEmail(
      String email, String password, String name) async {
    final res = await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'displayName': name.trim(),
        'display_name': name.trim(),
      },
    );
    if (res.user != null) {
      await _syncUserToDirectory(res.user!, customName: name.trim());
      return AppUser.fromSupabase(res.user!);
    }
    return null;
  }

  Future<AppUser?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw Exception('Google Sign-In failed: No ID Token retrieved');
      }

      final res = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (res.user != null) {
        await _syncUserToDirectory(
          res.user!,
          customName: googleUser.displayName,
          customPhoto: googleUser.photoUrl,
        );
        return AppUser.fromSupabase(res.user!);
      }
      return null;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: 'io.supabase.nextmeet://reset-callback',
    );
  }

  Future<void> verifyRecoveryOtp({required String email, required String token}) async {
    await _supabase.auth.verifyOTP(
      type: OtpType.recovery,
      token: token.trim(),
      email: email.trim(),
    );
  }

  Future<void> setNewPassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<void> updateUserPassword(String oldPassword, String newPassword) async {
    final user = currentUser;
    if (user == null || user.email == null) {
      throw Exception('User not authenticated');
    }
    await _supabase.auth.signInWithPassword(
      email: user.email!,
      password: oldPassword,
    );
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _supabase.auth.signOut();
  }

  Future<void> _syncUserToDirectory(User user,
      {String? customName, String? customPhoto}) async {
    try {
      final meta = user.userMetadata ?? {};
      final name = customName ??
          meta['displayName'] ??
          meta['display_name'] ??
          'NextMeet Partner';
      final photo =
          customPhoto ?? meta['photoUrl'] ?? meta['avatar_url'] ?? '';
      final fbUid = meta['firebase_uid'] as String?;

      await _supabase.from('users').upsert({
        'id': user.id,
        'firebase_uid': fbUid,
        'email': user.email,
        'display_name': name,
        'photo_url': photo,
        'last_active': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Sync user to Supabase directory warning: $e');
    }
  }
}
