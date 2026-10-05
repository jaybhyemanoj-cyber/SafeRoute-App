/// Internal model representing a historical accident-prone location record.
/// Keeps dataset private and structured for backend/scoring engine use only.
class HistoricalAccidentLocation {
  final String id;
  final String name;
  final double? latitude;
  final double? longitude;
  final String type;
  final int? seriousAccidents;
  final String? source;
  final int? sourceYear;
  final String verificationStatus;
  final String? notes;

  const HistoricalAccidentLocation({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
    required this.type,
    this.seriousAccidents,
    this.source,
    this.sourceYear,
    required this.verificationStatus,
    this.notes,
  });

  /// Location is eligible for geographic scoring ONLY IF:
  /// 1. Latitude and longitude are present (non-null valid numbers).
  /// 2. Serious accident count is valid and known (non-null, > 0).
  /// 3. Verification status is explicitly 'verified' (unverified coordinates are never used).
  bool get isEligibleForScoring {
    if (latitude == null || longitude == null) return false;
    if (seriousAccidents == null || seriousAccidents! <= 0) return false;
    final status = verificationStatus.toLowerCase().trim();
    if (status.contains('unverified') || status != 'verified') return false;
    return true;
  }
}
