/// Human-readable Firebase Authentication errors shared by Android and iOS.
///
/// Do not pass passwords, OAuth ID tokens or user credentials into [details].
/// Diagnostic details are only intended for local debug builds.
String safeAuthDiagnostic(String? details) {
  final sanitized = (details ?? '')
      .replaceAll(RegExp(r'[\r\n\t]+'), ' ')
      .replaceAll(
        RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'),
        '[email]',
      )
      .replaceAll(RegExp(r'AIza[\w-]{20,}'), '[api-key]')
      .replaceAll(
        RegExp(r'Bearer\s+[\w.\-]+', caseSensitive: false),
        'Bearer [redacted]',
      )
      .trim();
  return sanitized.length > 240
      ? '${sanitized.substring(0, 240)}…'
      : sanitized;
}

String firebaseAuthErrorText(
  String code, {
  String? details,
  bool includeDiagnostics = false,
}) {
  final normalizedCode = code.trim().toLowerCase();

  final explanation = switch (normalizedCode) {
    'invalid-email' => 'Please enter a valid email address.',
    'invalid-credential' || 'invalid-login-credentials' ||
    'wrong-password' || 'user-not-found' =>
      'Incorrect email or password. Try again or reset your password.',
    'email-already-in-use' => 'An account already exists with that email.',
    'weak-password' => 'Password must contain at least 6 characters.',
    'user-disabled' => 'This account has been disabled.',
    'too-many-requests' =>
      'Too many attempts. Wait a little while and try again.',
    'network-request-failed' =>
      'Network error. Check the emulator internet connection and retry.',
    'operation-not-allowed' =>
      'This sign-in method is disabled in Firebase Authentication.',
    'invalid-api-key' || 'app-not-authorized' ||
    'invalid-app-credential' || 'configuration-not-found' =>
      'Firebase configuration needs attention. Contact the developer.',
    'requires-recent-login' => 'Please sign in again to continue.',
    'unknown' || 'internal-error' =>
      'Firebase could not complete authentication. Please try again.',
    _ => 'Could not authenticate. Please try again.',
  };

  if (!includeDiagnostics) return explanation;

  // Redact potentially sensitive IDs from SDK messages in screenshots.
  final clippedDetails = safeAuthDiagnostic(details);

  return '$explanation\nDebug: ${normalizedCode.isEmpty ? 'no-code' : normalizedCode}'
      '${clippedDetails.isEmpty ? '' : '\n$clippedDetails'}';
}
