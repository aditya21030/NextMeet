import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricAuthResult {
  final bool success;
  final String? errorMessage;
  final String? errorCode;

  const BiometricAuthResult({
    required this.success,
    this.errorMessage,
    this.errorCode,
  });
}

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  static const String _keyBiometricsEnabled = 'nextmeet_biometrics_enabled';
  static const String _keyFingerprintEnabled = 'nextmeet_fingerprint_enabled';

  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
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

  Future<bool> supportsFingerprint() async {
    try {
      final available = await _auth.getAvailableBiometrics();
      if (available.contains(BiometricType.fingerprint) || available.contains(BiometricType.strong)) {
        return true;
      }
      final supported = await _auth.isDeviceSupported();
      return supported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> supportsIris() async {
    try {
      final available = await _auth.getAvailableBiometrics();
      return available.contains(BiometricType.iris);
    } catch (_) {
      return false;
    }
  }

  Future<String> getHardwareStatusDescription() async {
    try {
      final available = await _auth.getAvailableBiometrics();
      final bool isSupported = await _auth.isDeviceSupported();

      final bool hasFingerprint = available.contains(BiometricType.fingerprint) || available.contains(BiometricType.strong);

      if (hasFingerprint) {
        return 'Fingerprint Sensor Ready';
      } else if (isSupported || available.isNotEmpty) {
        return 'Device Biometrics Ready';
      } else {
        return 'Not configured in phone settings';
      }
    } catch (_) {
      return 'Biometric status unavailable';
    }
  }

  Future<BiometricAuthResult> authenticateWithDetails({
    String reason = 'Scan your fingerprint on the sensor to unlock',
    bool biometricOnly = true,
  }) async {
    try {
      final bool available = await isBiometricAvailable();
      if (!available) {
        return const BiometricAuthResult(
          success: false,
          errorCode: 'NotAvailable',
          errorMessage: 'Biometric authentication is not supported or not set up on this device.',
        );
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );

      return BiometricAuthResult(
        success: didAuthenticate,
        errorMessage: didAuthenticate ? null : 'Authentication was cancelled or not recognized.',
      );
    } on PlatformException catch (e) {
      String message;
      switch (e.code) {
        case 'NotAvailable':
          message = 'Biometric sensors are currently unavailable on this device.';
          break;
        case 'NotEnrolled':
          message = 'No fingerprint enrolled. Please register in phone Settings.';
          break;
        case 'LockedOut':
          message = 'Too many failed attempts. Biometrics temporarily locked.';
          break;
        case 'PermanentlyLockedOut':
          message = 'Biometrics permanently locked. Unlock your phone using PIN or password.';
          break;
        case 'PasscodeNotSet':
          message = 'Device security PIN/passcode is required to use biometrics.';
          break;
        default:
          message = e.message ?? 'Biometric authentication failed (${e.code}).';
          break;
      }
      return BiometricAuthResult(
        success: false,
        errorCode: e.code,
        errorMessage: message,
      );
    } catch (e) {
      return BiometricAuthResult(
        success: false,
        errorMessage: 'An unexpected biometric error occurred: $e',
      );
    }
  }

  Future<bool> authenticate({
    String reason = 'Authenticate to access Couple Sanctuary',
    bool biometricOnly = false,
  }) async {
    final result = await authenticateWithDetails(reason: reason, biometricOnly: biometricOnly);
    return result.success;
  }

  // Local device preferences
  Future<bool> isLocalBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBiometricsEnabled) ?? true;
  }

  Future<void> setLocalBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricsEnabled, enabled);
  }

  Future<bool> isFingerprintEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFingerprintEnabled) ?? true;
  }

  Future<void> setFingerprintEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFingerprintEnabled, enabled);
  }
}
