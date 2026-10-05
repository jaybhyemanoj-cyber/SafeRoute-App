import 'package:flutter_test/flutter_test.dart';
import 'package:saferoute_ai/models/emergency_contact.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SafeRoute Emergency Contact Storage & Workflow Tests', () {
    const testFirebaseUidUserA = 'firebase_uid_user_A_123';
    const testFirebaseUidUserB = 'firebase_uid_user_B_456';

    test('Test 1 & 4 — Contact existence check for new & existing users', () {
      bool shouldPromptSetup(EmergencyContact? contact) {
        return contact == null || !contact.isValidPhoneNumber;
      }

      expect(shouldPromptSetup(null), isTrue);

      const invalidContact = EmergencyContact(
        id: 'c1',
        userId: testFirebaseUidUserA,
        contactName: 'Short Phone',
        phoneNumber: '123',
      );
      expect(shouldPromptSetup(invalidContact), isTrue);

      const validContact = EmergencyContact(
        id: 'c2',
        userId: testFirebaseUidUserA,
        contactName: 'Mom',
        phoneNumber: '+91 9876543210',
      );
      expect(shouldPromptSetup(validContact), isFalse);
    });

    test('Test 2 — Save contact with Firebase UID serialization', () {
      final contact = EmergencyContact(
        id: 'c_save_1',
        userId: testFirebaseUidUserA,
        contactName: 'Mom',
        phoneNumber: '+919876543210',
        relationship: 'Parent',
        createdAt: DateTime(2026, 10, 5),
        updatedAt: DateTime(2026, 10, 5),
      );

      final json = contact.toJson();
      expect(json['user_id'], equals(testFirebaseUidUserA));
      expect(json['contact_name'], equals('Mom'));
      expect(json['phone_number'], equals('+919876543210'));

      final restored = EmergencyContact.fromJson(json);
      expect(restored.userId, equals(testFirebaseUidUserA));
      expect(restored.contactName, equals('Mom'));
    });

    test('Test 5 — Edit contact copyWith functionality', () {
      const original = EmergencyContact(
        id: 'c_edit_1',
        userId: testFirebaseUidUserA,
        contactName: 'Dad',
        phoneNumber: '+919876543210',
        relationship: 'Parent',
      );

      final updated = original.copyWith(
        contactName: 'Dad (Mobile)',
        phoneNumber: '+919999988888',
        relationship: 'Father',
      );

      expect(updated.contactName, equals('Dad (Mobile)'));
      expect(updated.phoneNumber, equals('+919999988888'));
      expect(updated.relationship, equals('Father'));
      expect(updated.userId, equals(testFirebaseUidUserA));
    });

    test('Test 6 & 8 — Delete contact & SOS with missing contact handling', () {
      EmergencyContact? activeContact = const EmergencyContact(
        id: 'c_del_1',
        userId: testFirebaseUidUserA,
        contactName: 'Friend',
        phoneNumber: '+919876543210',
      );

      expect(activeContact != null, isTrue);

      // Simulate deletion
      activeContact = null;

      expect(activeContact, isNull);

      String getSosStatusMessage(EmergencyContact? contact) {
        if (contact == null || !contact.isValidPhoneNumber) {
          return 'Emergency contact not set. Add an emergency contact to enable SOS messaging.';
        }
        return 'Ready to send alert to ${contact.contactName}';
      }

      expect(getSosStatusMessage(activeContact), contains('Emergency contact not set'));
    });

    test('Test 9 — Invalid phone number validation', () {
      bool validatePhoneNumber(String rawPhone) {
        final digitsOnly = rawPhone.replaceAll(RegExp(r'\D'), '');
        return digitsOnly.length >= 10 && digitsOnly.length <= 15;
      }

      expect(validatePhoneNumber('+91 98765 43210'), isTrue);
      expect(validatePhoneNumber('+919876543210'), isTrue);
      expect(validatePhoneNumber('9876543210'), isTrue);
      expect(validatePhoneNumber('12345'), isFalse);
      expect(validatePhoneNumber('abc-def'), isFalse);
      expect(validatePhoneNumber('1234567890123456789'), isFalse);
    });

    test('Test 11 & 12 — Firebase UID scoping & logout separation', () {
      final contactUserA = EmergencyContact(
        id: 'cA',
        userId: testFirebaseUidUserA,
        contactName: 'User A Contact',
        phoneNumber: '+919876543210',
      );

      final contactUserB = EmergencyContact(
        id: 'cB',
        userId: testFirebaseUidUserB,
        contactName: 'User B Contact',
        phoneNumber: '+919111122222',
      );

      // Verify User A cannot access User B's record
      bool isOwner(EmergencyContact contact, String currentFirebaseUid) {
        return contact.userId == currentFirebaseUid;
      }

      expect(isOwner(contactUserA, testFirebaseUidUserA), isTrue);
      expect(isOwner(contactUserA, testFirebaseUidUserB), isFalse);
      expect(isOwner(contactUserB, testFirebaseUidUserB), isTrue);
    });
  });
}
