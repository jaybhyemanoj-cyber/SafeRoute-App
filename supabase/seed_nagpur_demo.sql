-- ========================================================
-- SAFEROUTE AI — NAGPUR DEMO HAZARD REPORTS SEED DATA
-- All 15 records are SYNTHETIC demo data for testing.
-- Uses deterministic UUIDs (d0000000-0000-0000-0000-000000000001..15)
-- with ON CONFLICT DO UPDATE for safe idempotency.
-- ========================================================

INSERT INTO public.reports (id, latitude, longitude, hazard_type, description, status, confidence, created_at)
VALUES
  ('d0000000-0000-0000-0000-000000000001', 21.14841, 79.08405, 'broken_footpath', '[DEMO DATA — NOT A REAL INCIDENT] Broken/uneven footpath reported for route-testing near Sitabuldi Fort area.', 'active', 0.85, '2026-10-01T07:00:00Z'),
  ('d0000000-0000-0000-0000-000000000002', 21.14430, 79.08034, 'heavy_traffic', '[DEMO DATA — NOT A REAL INCIDENT] Simulated heavy-traffic crossing; use to test route safety scoring near Sitabuldi junction.', 'active', 0.80, '2026-10-01T05:00:00Z'),
  ('d0000000-0000-0000-0000-000000000003', 21.14097, 79.06243, 'poor_lighting', '[DEMO DATA — NOT A REAL INCIDENT] Simulated poorly lit stretch for testing evening-route alerts in Dharampeth.', 'active', 0.75, '2026-09-30T22:00:00Z'),
  ('d0000000-0000-0000-0000-000000000004', 21.14620, 79.06780, 'construction', '[DEMO DATA — NOT A REAL INCIDENT] Simulated footpath construction obstruction for route comparison tests.', 'active', 0.82, '2026-10-01T02:00:00Z'),
  ('d0000000-0000-0000-0000-000000000005', 21.15100, 79.07120, 'unsafe_crossing', '[DEMO DATA — NOT A REAL INCIDENT] Simulated difficult pedestrian crossing; test whether candidate routes avoid this point.', 'active', 0.78, '2026-10-01T08:00:00Z'),
  ('d0000000-0000-0000-0000-000000000006', 21.13690, 79.07950, 'road_damage', '[DEMO DATA — NOT A REAL INCIDENT] Simulated damaged road edge near Dhantoli for testing hazard proximity penalties.', 'active', 0.72, '2026-09-30T16:00:00Z'),
  ('d0000000-0000-0000-0000-000000000007', 21.13380, 79.08580, 'waterlogging', '[DEMO DATA — NOT A REAL INCIDENT] Simulated waterlogging point for testing route scoring; not a current observation.', 'active', 0.80, '2026-10-01T03:00:00Z'),
  ('d0000000-0000-0000-0000-000000000008', 21.14280, 79.09060, 'stray_animals', '[DEMO DATA — NOT A REAL INCIDENT] Simulated stray-animal report for testing the hazard marker and scoring flow.', 'active', 0.65, '2026-09-30T10:00:00Z'),
  ('d0000000-0000-0000-0000-000000000009', 21.15510, 79.08820, 'broken_footpath', '[DEMO DATA — NOT A REAL INCIDENT] Simulated uneven footpath near the central railway approach area.', 'active', 0.78, '2026-10-01T00:00:00Z'),
  ('d0000000-0000-0000-0000-000000000010', 21.15010, 79.09620, 'heavy_traffic', '[DEMO DATA — NOT A REAL INCIDENT] Simulated busy traffic segment for comparing alternate walking routes.', 'active', 0.88, '2026-10-01T09:00:00Z'),
  ('d0000000-0000-0000-0000-000000000011', 21.15330, 79.07890, 'construction', '[DEMO DATA — NOT A REAL INCIDENT] Simulated construction zone close to Sadar-side streets.', 'active', 0.76, '2026-09-30T18:00:00Z'),
  ('d0000000-0000-0000-0000-000000000012', 21.13750, 79.05990, 'poor_lighting', '[DEMO DATA — NOT A REAL INCIDENT] Simulated low-light report for testing personalized alerts after dark.', 'active', 0.70, '2026-09-30T04:00:00Z'),
  ('d0000000-0000-0000-0000-000000000013', 21.13080, 79.07350, 'unsafe_crossing', '[DEMO DATA — NOT A REAL INCIDENT] Simulated crossing risk near the west-central area for route candidate testing.', 'active', 0.83, '2026-10-01T06:00:00Z'),
  ('d0000000-0000-0000-0000-000000000014', 21.15800, 79.09480, 'road_damage', '[DEMO DATA — NOT A REAL INCIDENT] Simulated road-edge damage for checking nearby-report retrieval radius.', 'active', 0.68, '2026-09-29T10:00:00Z'),
  ('d0000000-0000-0000-0000-000000000015', 21.14520, 79.07320, 'other', '[DEMO DATA — NOT A REAL INCIDENT] Generic test report to verify handling of the ''other'' hazard category.', 'active', 0.60, '2026-09-28T10:00:00Z')
ON CONFLICT (id) DO UPDATE SET
  latitude = EXCLUDED.latitude,
  longitude = EXCLUDED.longitude,
  hazard_type = EXCLUDED.hazard_type,
  description = EXCLUDED.description,
  status = EXCLUDED.status,
  confidence = EXCLUDED.confidence,
  created_at = EXCLUDED.created_at;
