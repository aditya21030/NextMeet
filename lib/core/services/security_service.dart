import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class SecurityService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isBiometricAvailable() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();
      final List<BiometricType> available = await _auth.getAvailableBiometrics();
      return (canCheck || isSupported) && (available.isNotEmpty || isSupported);
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  Future<bool> authenticate({String reason = 'Authenticate to access Couple Sanctuary'}) async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allows Fingerprint, Face ID, and Face Camera unlock
          useErrorDialogs: true,
          sensitiveTransaction: false,
        ),
      );
      return didAuthenticate;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
