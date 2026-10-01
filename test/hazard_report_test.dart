import 'package:flutter_test/flutter_test.dart';
import 'package:saferoute_ai/models/hazard_report.dart';

void main() {
  group('HazardReport Model Tests', () {
    test('HazardReport fromJson & toJson serialization', () {
      final json = {
        'id': 'rep_123',
        'user_id': 'user_456',
        'latitude': 21.1458,
        'longitude': 79.0882,
        'hazard_type': 'poor_lighting',
        'description': 'Street lights broken near junction',
        'photo_url': 'https://example.com/photo.jpg',
        'created_at': '2026-10-01T02:00:00.000Z',
        'status': 'active',
        'confidence': 0.8,
      };

      final report = HazardReport.fromJson(json);

      expect(report.id, 'rep_123');
      expect(report.userId, 'user_456');
      expect(report.latitude, 21.1458);
      expect(report.longitude, 79.0882);
      expect(report.hazardType, 'poor_lighting');
      expect(report.displayLabel, 'Poor Lighting');
      expect(report.emoji, '💡');
      expect(report.description, 'Street lights broken near junction');
      expect(report.photoUrl, 'https://example.com/photo.jpg');
      expect(report.status, 'active');
      expect(report.confidence, 0.8);

      final convertedJson = report.toJson();
      expect(convertedJson['id'], 'rep_123');
      expect(convertedJson['hazard_type'], 'poor_lighting');
      expect(convertedJson['latitude'], 21.1458);
    });

    test('HazardReport defaults for optional fields', () {
      final json = {
        'id': 'rep_999',
        'latitude': 21.1,
        'longitude': 79.1,
        'hazard_type': 'waterlogging',
      };

      final report = HazardReport.fromJson(json);

      expect(report.id, 'rep_999');
      expect(report.userId, isNull);
      expect(report.description, isNull);
      expect(report.photoUrl, isNull);
      expect(report.status, 'active');
      expect(report.confidence, 0.5);
      expect(report.displayLabel, 'Waterlogging');
      expect(report.emoji, '💧');
    });

    test('All 10 hazard categories supported', () {
      expect(HazardReport.hazardCategories.length, 10);
      final keys = HazardReport.hazardCategories.map((c) => c['key']).toList();

      expect(keys, containsAll([
        'poor_lighting',
        'broken_footpath',
        'road_damage',
        'construction',
        'unsafe_crossing',
        'heavy_traffic',
        'waterlogging',
        'suspicious_activity',
        'stray_animals',
        'other',
      ]));
    });
  });
}
