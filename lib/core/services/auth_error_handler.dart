/// Centralized friendly error translator for NextMeet authentication & onboarding.
/// Converts cryptic Firebase/Supabase error codes and raw exceptions into warm,
/// human-friendly couple-centric messages without technical jargon.
class AuthErrorHandler {
  /// Friendly message for login attempts
  static String getLoginErrorMessage(dynamic error) {
    if (error == null) return 'Could not sign in. Please verify your credentials ❤️';
    final str = error.toString().toLowerCase();

    if (str.contains('sign_in_canceled') ||
        str.contains('sign_in_failed: null') ||
        str.contains('canceled') ||
        str.contains('cancelled')) {
      return 'Google sign-in was cancelled. Tap again whenever you are ready ✨';
    }

    if (str.contains('provider_disabled') ||
        str.contains('provider is not enabled') ||
        str.contains('provider (issuer')) {
      return 'Google sign-in is syncing. Please log in with your email or try again shortly ❤️';
    }

    if (str.contains('account-exists-with-different-credential') ||
        str.contains('already exists with a password')) {
      return 'An account with this email was created with a password. Please log in using your password ❤️';
    }

    if (str.contains('network') ||
        str.contains('socketexception') ||
        str.contains('failed host lookup') ||
        str.contains('clientoffline') ||
        str.contains('connection refused') ||
        str.contains('timed out')) {
      return 'Unable to connect to NextMeet. Please check your internet connection 📶';
    }

    if (str.contains('invalid login credentials') ||
        str.contains('invalid_credentials') ||
        str.contains('invalid-credential') ||
        str.contains('wrong-password') ||
        str.contains('invalid_grant')) {
      return 'Incorrect email or password. Please check your spelling and try again ❤️';
    }

    if (str.contains('user-not-found') || str.contains('no user found')) {
      return 'No account found with this email. Please check your spelling or create an account below ✨';
    }

    if (str.contains('invalid-email') || str.contains('invalid email')) {
      return 'Please enter a valid email address (e.g. name@example.com) 📧';
    }

    if (str.contains('email not confirmed') || str.contains('email_not_confirmed')) {
      return 'Please verify your email address by tapping the link sent to your inbox 💌';
    }

    if (str.contains('too-many-requests') ||
        str.contains('over_email_send_rate_limit') ||
        str.contains('rate limit')) {
      return 'Too many attempts. Please take a deep breath and wait a moment before trying again ⏳';
    }

    return 'Incorrect email or password. Please try again or tap "Forgot Password?" to reset it ❤️';
  }

  /// Friendly message for registration / account creation
  static String getRegistrationErrorMessage(dynamic error) {
    if (error == null) return 'Could not create account. Please check your details ❤️';
    final str = error.toString().toLowerCase();

    if (str.contains('user already registered') ||
        str.contains('already registered') ||
        str.contains('email-already-in-use') ||
        str.contains('already in use') ||
        str.contains('already exists')) {
      return 'An account with this email already exists. Please log in with your password ❤️';
    }

    if (str.contains('invalid-email') || str.contains('invalid email')) {
      return 'Please enter a valid email address (e.g. name@example.com) 📧';
    }

    if (str.contains('weak-password') ||
        str.contains('password should be at least') ||
        str.contains('password is too short')) {
      return 'Please choose a password with at least 6 characters 🔒';
    }

    if (str.contains('network') ||
        str.contains('socketexception') ||
        str.contains('failed host lookup') ||
        str.contains('clientoffline') ||
        str.contains('timed out')) {
      return 'Unable to connect to NextMeet. Please check your internet connection 📶';
    }

    if (str.contains('too-many-requests') || str.contains('rate limit')) {
      return 'Too many attempts. Please wait a moment and try again ⏳';
    }

    return 'Could not complete registration. Please check your details and try again ❤️';
  }

  /// Friendly message for couple journey creation / joining
  static String getJourneyErrorMessage(dynamic error) {
    if (error == null) return 'Could not start your couple journey. Please try again ❤️';
    final str = error.toString().toLowerCase();

    if (str.contains('network') ||
        str.contains('socketexception') ||
        str.contains('connection') ||
        str.contains('timed out')) {
      return 'Unable to connect to NextMeet. Please check your internet connection 📶';
    }

    if (str.contains('permission-denied') || str.contains('permission_denied')) {
      return 'Could not complete sync. Please ensure you are logged in and try again ❤️';
    }

    return 'Could not start your couple journey right now. Please check your connection and try again ❤️';
  }
}
