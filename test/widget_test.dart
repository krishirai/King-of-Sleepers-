import 'package:flutter_test/flutter_test.dart';
import 'package:sleeping_king/auth_error_messages.dart';
import 'package:sleeping_king/firebase_options.dart';

void main() {
  group('Firebase sign-in errors', () {
    test('invalid credentials have useful guidance', () {
      expect(
        firebaseAuthErrorText('invalid-credential'),
        contains('Incorrect email or password'),
      );
    });

    test('network and disabled-provider errors are actionable', () {
      expect(
        firebaseAuthErrorText('network-request-failed'),
        contains('internet connection'),
      );
      expect(
        firebaseAuthErrorText('operation-not-allowed'),
        contains('disabled'),
      );
    });

    test('unknown Firebase error shows redacted diagnostic in debug', () {
      final result = firebaseAuthErrorText(
        'unknown',
        details: 'Request for student@example.com, key '
            'AIzaSyExampleLongFakeKeyString0987654321 failed',
        includeDiagnostics: true,
      );
      expect(result, contains('Debug: unknown'));
      expect(result, contains('[email]'));
      expect(result, contains('[api-key]'));
      expect(result, isNot(contains('student@example.com')));
    });

    test('release error hides technical details', () {
      final result = firebaseAuthErrorText(
        'unknown',
        details: 'something technical',
      );
      expect(result, isNot(contains('something technical')));
      expect(result, isNot(contains('Debug:')));
    });
  });

  test('Android and iOS both point to the intended Firebase project', () {
    expect(
      DefaultFirebaseOptions.android.projectId,
      'king-of-sleepers-c221d',
    );
    expect(
      DefaultFirebaseOptions.ios.projectId,
      'king-of-sleepers-c221d',
    );
  });
}
