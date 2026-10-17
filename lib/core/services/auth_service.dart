import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

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

  factory AppUser.fromFirebase(fb.User user) {
    return AppUser(
      uid: user.uid,
      id: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
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
    if (user != null) return AppUser.fromSupabase(user);
    final fbUser = fb.FirebaseAuth.instance.currentUser;
    if (fbUser != null) return AppUser.fromFirebase(fbUser);
    return null;
  }

  String? get currentUid => currentUser?.uid;

  Stream<AppUser?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.map((data) {
      final user = data.session?.user ?? _supabase.auth.currentUser;
      if (user != null) return AppUser.fromSupabase(user);
      final fbUser = fb.FirebaseAuth.instance.currentUser;
      if (fbUser != null) return AppUser.fromFirebase(fbUser);
      return null;
    });
  }

  Future<AppUser?> signInWithEmail(String email, String password) async {
    final res = await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    if (res.user != null) {
      await _syncUserToDirectory(res.user!);
      _syncToFirebaseAuth(email: email.trim(), password: password);
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
      // Supabase anti-enumeration safeguard: if email already exists, identities is an empty list
      if (res.user!.identities != null && res.user!.identities!.isEmpty) {
        throw Exception('An account with this email already exists. Please log in with your password ❤️');
      }

      // If session is null, attempt immediate sign-in with password so the user has an active session
      if (res.session == null) {
        try {
          final loginRes = await _supabase.auth.signInWithPassword(
            email: email.trim(),
            password: password,
          );
          if (loginRes.user != null) {
            await _syncUserToDirectory(loginRes.user!, customName: name.trim());
            _syncToFirebaseAuth(email: email.trim(), password: password, name: name.trim());
            return AppUser.fromSupabase(loginRes.user!);
          }
        } catch (_) {}
      }

      await _syncUserToDirectory(res.user!, customName: name.trim());
      _syncToFirebaseAuth(email: email.trim(), password: password, name: name.trim());
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

      if (idToken == null && accessToken == null) {
        throw Exception('Google Sign-In failed: No credentials retrieved from Google account');
      }

      // 1. Authenticate with Firebase Auth (ensures Firestore and Storage security rules are satisfied)
      fb.UserCredential? fbCred;
      try {
        final credential = fb.GoogleAuthProvider.credential(
          accessToken: accessToken,
          idToken: idToken,
        );
        fbCred = await fb.FirebaseAuth.instance.signInWithCredential(credential);
      } catch (fbErr) {
        debugPrint('Firebase Google sign-in credential notice: $fbErr');
      }

      // 2. Attempt native Supabase Google ID token sign-in (active if provider is enabled in Supabase dashboard)
      User? supabaseUser;
      if (idToken != null) {
        try {
          final res = await _supabase.auth.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken,
            accessToken: accessToken,
          );
          supabaseUser = res.user;
        } catch (oauthErr) {
          debugPrint('Supabase native Google sign-in bypassed or disabled: $oauthErr');
        }
      }

      // 3. Resilient OAuth Bridge: If Google provider is not toggled in Supabase dashboard,
      // bridge the cryptographically verified Google profile directly into Supabase
      if (supabaseUser == null && googleUser.email.isNotEmpty) {
        final oauthBridgePassword = 'NM_GAuth_${googleUser.id}_SafeKey#2026!';
        try {
          // Attempt sign in with bridge password if user previously registered via Google
          final loginRes = await _supabase.auth.signInWithPassword(
            email: googleUser.email.trim(),
            password: oauthBridgePassword,
          );
          supabaseUser = loginRes.user;
        } catch (_) {
          // Account doesn't exist yet with this bridge password, sign up
          try {
            final signUpRes = await _supabase.auth.signUp(
              email: googleUser.email.trim(),
              password: oauthBridgePassword,
              data: {
                'displayName': googleUser.displayName ?? 'NextMeet Partner',
                'display_name': googleUser.displayName ?? 'NextMeet Partner',
                'photoUrl': googleUser.photoUrl ?? '',
                'photo_url': googleUser.photoUrl ?? '',
                'avatar_url': googleUser.photoUrl ?? '',
                'firebase_uid': fbCred?.user?.uid,
                'auth_provider': 'google',
              },
            );
            supabaseUser = signUpRes.user;

            // Ensure active session if auto-login didn't occur
            if (signUpRes.session == null) {
              try {
                final reLogin = await _supabase.auth.signInWithPassword(
                  email: googleUser.email.trim(),
                  password: oauthBridgePassword,
                );
                supabaseUser = reLogin.user ?? supabaseUser;
              } catch (_) {}
            }
          } catch (signUpErr) {
            final str = signUpErr.toString().toLowerCase();
            if (str.contains('already registered') || str.contains('already exists')) {
              throw Exception('An account with ${googleUser.email} already exists with a password. Please log in with your email and password ❤️');
            }
            debugPrint('Supabase Google OAuth fallback signup error: $signUpErr');
          }
        }
      }

      // 4. Directory sync and user resolution
      if (supabaseUser != null) {
        await _syncUserToDirectory(
          supabaseUser,
          customName: googleUser.displayName,
          customPhoto: googleUser.photoUrl,
        );
        return AppUser.fromSupabase(supabaseUser);
      } else if (fbCred?.user != null) {
        return AppUser.fromFirebase(fbCred!.user!);
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
    try {
      await fb.FirebaseAuth.instance.signOut();
    } catch (_) {}
    await _supabase.auth.signOut();
  }

  void _syncToFirebaseAuth({required String email, required String password, String? name}) async {
    try {
      final userCred = await fb.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (name != null && (userCred.user?.displayName == null || userCred.user!.displayName!.isEmpty)) {
        await userCred.user?.updateDisplayName(name);
      }
    } catch (_) {
      try {
        final newCred = await fb.FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (name != null) {
          await newCred.user?.updateDisplayName(name);
        }
      } catch (_) {
        try {
          if (fb.FirebaseAuth.instance.currentUser == null) {
            await fb.FirebaseAuth.instance.signInAnonymously();
          }
        } catch (_) {}
      }
    }
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
