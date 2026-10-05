import 'package:flutter_test/flutter_test.dart';
import 'package:saferoute_ai/models/emergency_contact.dart';
import 'package:saferoute_ai/services/emergency_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Emergency SOS Unit & Integration Tests', () {

    test('EmergencyContact phone validation & masking', () {
      const contact = EmergencyContact(
        id: 'c1',
        userId: 'u1',
        contactName: 'Mom',
        phoneNumber: '+91 9876543210',
        relationship: 'Parent',
        isPrimary: true,
      );

      expect(contact.isValidPhoneNumber, true);
      expect(contact.maskedPhoneNumber.contains('3210'), true);
      expect(contact.maskedPhoneNumber.contains('98765'), false); // Sensitive digits masked
    });

    test('EmergencyContact invalid phone detection', () {
      const contact = EmergencyContact(
        id: 'c2',
        userId: 'u1',
        contactName: 'Invalid',
        phoneNumber: '1234',
        relationship: 'Parent',
        isPrimary: true,
      );

      expect(contact.isValidPhoneNumber, false);
    });

    test('buildEmergencySms with valid coordinates', () {
      final now = DateTime(2026, 10, 5, 13, 35);
      final sms = EmergencyService.buildEmergencySms(
        userName: 'Manoj',
        timestamp: now,
        latitude: 21.1458,
        longitude: 79.0882,
      );

      expect(sms, contains('🚨 SafeRoute Emergency Alert'));
      expect(sms, contains('Name: Manoj'));
      expect(sms, contains('Time: 1:35 PM'));
      expect(sms, contains('https://maps.google.com/?q=21.1458,79.0882'));
      expect(sms, contains('SafeRoute is not a replacement for emergency services.'));
    });

    test('buildEmergencySms with unavailable location', () {
      final now = DateTime(2026, 10, 5, 13, 35);
      final sms = EmergencyService.buildEmergencySms(
        userName: 'Manoj',
        timestamp: now,
        latitude: null,
        longitude: null,
      );

      expect(sms, contains('🚨 SafeRoute Emergency Alert'));
      expect(sms, contains('Name: Manoj'));
      expect(sms, contains('Time: 1:35 PM'));
      expect(sms, contains('Location:\nUnavailable'));
      expect(sms, contains('SafeRoute is not a replacement for emergency services.'));
    });

    test('EmergencyService initial state & 5s cancellation behavior', () async {
      final service = EmergencyService.instance;
      expect(service.status, EmergencyStatus.idle);
      expect(service.isEmergencyActive, false);

      // Trigger primary SOS button
      service.triggerEmergency(triggerType: EmergencyTriggerType.primarySosButton);

      expect(service.isEmergencyActive, true);
      expect(service.isPreparing, true);
      expect(service.cancellationSecondsLeft, 5);

      // Cancel emergency alert before 5s expires
      service.cancelEmergency();

      expect(service.status, EmergencyStatus.cancelled);
      expect(service.statusMessage, contains('cancelled'));
    });
  });
}
