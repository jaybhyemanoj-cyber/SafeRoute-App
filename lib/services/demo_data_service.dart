import '../models/hazard_report.dart';

/// Embedded Nagpur Demo Reports Dataset for offline testing, local seeding, & verification.
class DemoDataService {
  /// Raw Nagpur synthetic test reports dataset (15 items).
  static final List<Map<String, dynamic>> nagpurDemoReportsRaw = [
    {
      "id": "d0000000-0000-0000-0000-000000000001",
      "latitude": 21.14841,
      "longitude": 79.08405,
      "hazard_type": "broken_footpath",
      "description": "[DEMO DATA — NOT A REAL INCIDENT] Broken/uneven footpath reported for route-testing near Sitabuldi Fort area.",
      "status": "active",
      "confidence": 0.85,
      "area": "Sitabuldi",
      "created_at": "2026-10-01T07:00:00Z",
      "demo_only": true,
      "city": "Nagpur",
      "state": "Maharashtra"
    },
    {
      "id": "d0000000-0000-0000-0000-000000000002",
      "latitude": 21.1443,
      "longitude": 79.08034,
      "hazard_type": "heavy_traffic",
      "description": "[DEMO DATA — NOT A REAL INCIDENT] Simulated heavy-traffic crossing; use to test route safety scoring near Sitabuldi junction.",
      "status": "active",
      "confidence": 0.8,
      "area": "Sitabuldi",
      "created_at": "2026-10-01T05:00:00Z",
      "demo_only": true,
      "city": "Nagpur",
      "state": "Maharashtra"
    },
    {
      "id": "d0000000-0000-0000-0000-000000000003",
      "latitude": 21.14097,
      "longitude": 79.06243,
      "hazard_type": "poor_lighting",
      "description": "[DEMO DATA — NOT A REAL INCIDENT] Simulated poorly lit stretch for testing evening-route alerts in Dharampeth.",
      "status": "active",
      "confidence": 0.75,
      "area": "Dharampeth",
      "created_at": "2026-09-30T22:00:00Z",
      "demo_only": true,
      "city": "Nagpur",
      "state": "Maharashtra"
    },
    {
      "id": "d0000000-0000-0000-0000-000000000004",
      "latitude": 21.1462,
      "longitude": 79.0678,
      "hazard_type": "construction",
      "description": "[DEMO DATA — NOT A REAL INCIDENT] Simulated footpath construction obstruction for route comparison tests.",
      "status": "active",
      "confidence": 0.82,
      "area": "Civil Lines",
      "created_at": "2026-10-01T02:00:00Z",
      "demo_only": true,
      "city": "Nagpur",
      "state": "Maharashtra"
    },
    {
      "id": "d0000000-0000-0000-0000-000000000005",
      "latitude": 21.151,
      "longitude": 79.0712,
      "hazard_type": "unsafe_crossing",
      "description": "[DEMO DATA — NOT A REAL INCIDENT] Simulated difficult pedestrian crossing; test whether candidate routes avoid this point.",
      "status": "active",
      "confidence": 0.78,
      "area": "Civil Lines",
      "created_at": "2026-10-01T08:00:00Z",
      "demo_only": true,
      "city": "Nagpur",
      "state": "Maharashtra"
    },
    {
      "id": "d0000000-0000-0000-0000-000000000006",
      "latitude": 21.1369,
      "longitude": 79.0795,
      "hazard_type": "road_damage",
      "description": "[DEMO DATA — NOT A REAL INCIDENT] Simulated damaged road edge near Dhantoli for testing hazard proximity penalties.",
      "status": "active",
      "confidence": 0.72,
      "area": "Dhantoli",
      "created_at": "2026-09-30T16:00:00Z",
      "demo_only": true,
      "city": "Nagpur",
      "state": "Maharashtra"
    },
    {
      "id": "d0000000-0000-0000-0000-000000000007",
      "latitude": 21.1338,
      "longitude": 79.0858,
      "hazard_type": "waterlogging",
      "description": "[DEMO DATA — NOT A REAL INCIDENT] Simulated waterlogging point for testing route scoring; not a current observation.",
      "status": "active",
      "confidence": 0.8,
      "area": "Ramdaspeth",
      "created_at": "2026-10-01T03:00:00Z",
      "demo_only": true,
      "city": "Nagpur",
      "state": "Maharashtra"
    },
    {
      "id": "d0000000-0000-0000-0000-000000000008",
      "latitude": 21.1428,
      "longitude": 79.0906,
      "hazard_type": "stray_animals",
      "description": "[DEMO DATA — NOT A REAL INCIDENT] Simulated stray-animal report for testing the hazard marker and scoring flow.",
      "status": "active",
      "confidence": 0.65,
      "area": "Maharajbagh",
      "created_at": "2026-09-30T10:00:00Z",
      "demo_only": true,
      "city": "Nagpur",
      "state": "Maharashtra"
    },
    {
      "id": "d0000000-0000-0000-0000-000000000009",
      "latitude": 21.1551,
      "longitude": 79.0882,
      "hazard_type": "broken_footpath",
      "description": "[DEMO DATA — NOT A REAL INCIDENT] Simulated uneven footpath near the central railway approach area.",
      "status": "active",
      "confidence": 0.78,
      "area": "Railway Station area",
      "created_at": "2026-10-01T00:00:00Z",
      "demo_only": true,
      "city": "Nagpur",
      "state": "Maharashtra"
    },
    {
      "id": "d0000000-0000-0000-0000-000000000010",
      "latitude": 21.1501,
      "longitude": 79.0962,
      "hazard_type": "heavy_traffic",
      "description": "[DEMO DATA — NOT A REAL INCIDENT] Simulated busy traffic segment for comparing alternate walking routes.",
      "status": "active",
      "confidence": 0.88,
      "area": "Gandhibagh side",
      "created_at": "2026-10-01T09:00:00Z",
      "demo_only": true,
      "city": "Nagpur",
      "state": "Maharashtra"
    },
    {
      "id": "d0000000-0000-0000-0000-000000000011",
      "latitude": 21.1533,
      "longitude": 79.0789,
      "hazard_type": "construction",
      "description": "[DEMO DATA — NOT A REAL INCIDENT] Simulated construction zone close to Sadar-side streets.",
      "status": "active",
      "confidence": 0.76,
      "area": "Sadar",
      "created_at": "2026-09-30T18:00:00Z",
      "demo_only": true,
      "city": "Nagpur",
      "state": "Maharashtra"
    },
    {
      "id": "d0000000-0000-0000-0000-000000000012",
      "latitude": 21.1375,
      "longitude": 79.0599,
      "hazard_type": "poor_lighting",
      "description": "[DEMO DATA — NOT A REAL INCIDENT] Simulated low-light report for testing personalized alerts after dark.",
      "status": "active",
      "confidence": 0.7,
      "area": "Dharampeth",
      "created_at": "2026-09-30T04:00:00Z",
      "demo_only": true,
      "city": "Nagpur",
      "state": "Maharashtra"
    },
    {
      "id": "d0000000-0000-0000-0000-000000000013",
      "latitude": 21.1308,
      "longitude": 79.0735,
      "hazard_type": "unsafe_crossing",
      "description": "[DEMO DATA — NOT A REAL INCIDENT] Simulated crossing risk near the west-central area for route candidate testing.",
      "status": "active",
      "confidence": 0.83,
      "area": "Ramdaspeth/Dhantoli",
      "created_at": "2026-10-01T06:00:00Z",
      "demo_only": true,
      "city": "Nagpur",
      "state": "Maharashtra"
    },
    {
      "id": "d0000000-0000-0000-0000-000000000014",
      "latitude": 21.158,
      "longitude": 79.0948,
      "hazard_type": "road_damage",
      "description": "[DEMO DATA — NOT A REAL INCIDENT] Simulated road-edge damage for checking nearby-report retrieval radius.",
      "status": "active",
      "confidence": 0.68,
      "area": "Mahal side",
      "created_at": "2026-09-29T10:00:00Z",
      "demo_only": true,
      "city": "Nagpur",
      "state": "Maharashtra"
    },
    {
      "id": "d0000000-0000-0000-0000-000000000015",
      "latitude": 21.1452,
      "longitude": 79.0732,
      "hazard_type": "other",
      "description": "[DEMO DATA — NOT A REAL INCIDENT] Generic test report to verify handling of the 'other' hazard category.",
      "status": "active",
      "confidence": 0.6,
      "area": "Civil Lines/Dharampeth",
      "created_at": "2026-09-28T10:00:00Z",
      "demo_only": true,
      "city": "Nagpur",
      "state": "Maharashtra"
    }
  ];

  /// Get list of HazardReport instances parsed from dataset.
  static List<HazardReport> get nagpurDemoReports => getNagpurDemoReports();

  static List<HazardReport> getNagpurDemoReports() {
    return nagpurDemoReportsRaw
        .map((map) => HazardReport.fromJson(map))
        .toList();
  }
}
