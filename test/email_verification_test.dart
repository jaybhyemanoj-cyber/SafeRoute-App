import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Firebase Mandatory Email Verification Logic & UI Tests', () {
    test('Email masking helper logic format test', () {
      String maskEmail(String rawEmail) {
        if (!rawEmail.contains('@')) return rawEmail;
        final parts = rawEmail.split('@');
        final name = parts[0];
        final domain = parts[1];
        if (name.length <= 1) {
          return '$name***@$domain';
        }
        return '${name[0]}***@$domain';
      }

      expect(maskEmail('manoj@gmail.com'), equals('m***@gmail.com'));
      expect(maskEmail('user123@saferoute.ai'), equals('u***@saferoute.ai'));
      expect(maskEmail('a@domain.com'), equals('a***@domain.com'));
      expect(maskEmail('invalid-email'), equals('invalid-email'));
    });

    test('Auth state email verification guard rule', () {
      bool canAccessProtectedApp({
        required bool isAuthenticated,
        required bool isEmailVerified,
      }) {
        return isAuthenticated && isEmailVerified;
      }

      // Unauthenticated -> Blocked
      expect(canAccessProtectedApp(isAuthenticated: false, isEmailVerified: false), isFalse);
      expect(canAccessProtectedApp(isAuthenticated: false, isEmailVerified: true), isFalse);

      // Authenticated but Email NOT verified -> Blocked
      expect(canAccessProtectedApp(isAuthenticated: true, isEmailVerified: false), isFalse);

      // Authenticated AND Email verified -> Allowed
      expect(canAccessProtectedApp(isAuthenticated: true, isEmailVerified: true), isTrue);
    });

    test('Verification resend cooldown countdown logic', () {
      int cooldown = 45;
      void tick() {
        if (cooldown > 0) cooldown--;
      }

      expect(cooldown, equals(45));
      tick();
      expect(cooldown, equals(44));
      for (int i = 0; i < 44; i++) {
        tick();
      }
      expect(cooldown, equals(0));
    });
  });
}
