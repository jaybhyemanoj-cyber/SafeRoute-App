import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../config/safety_config.dart';
import '../models/destination.dart';
import '../models/hazard_report.dart';
import '../models/navigation_instruction.dart';
import '../models/navigation_state.dart';
import '../models/route_candidate.dart';
import '../models/route_model.dart';
import '../models/trip_summary.dart';
import '../models/user_preferences.dart';
import 'hazard_analysis_service.dart';
import 'report_service.dart';
import 'route_analysis_service.dart';
import 'routing_service.dart';
import 'safety_engine.dart';

/// Centralized state manager for Phase 4 Live Safety-Aware Walking Navigation.
class LiveNavigationService extends ChangeNotifier {
  static const Distance _distanceCalculator = Distance();

  // Core Navigation State
  NavigationState _state = NavigationState.routePreview;
  Destination? _destination;
  RouteCandidate? _activeCandidate;
  RouteModel? _currentRoute;
  LatLng? _currentLocation;
  double _currentGpsAccuracy = 0.0;

  // Polyline progress
  List<LatLng> _completedPoints = [];
  List<LatLng> _remainingPoints = [];
  double _remainingDistanceMeters = 0.0;
  double _remainingDurationSeconds = 0.0;

  // Turn-by-turn instruction state
  int _currentInstructionIndex = 0;
  NavigationInstruction? _currentInstruction;
  double _distanceToNextManeuverMeters = 0.0;

  // Nearby Hazards & Safety Signal Alerts
  List<HazardReport> _nearbyReports = [];
  HazardReport? _activeHazardAlert;
  final Set<String> _shownAlertIds = {};
  DateTime? _lastHazardFetchTime;
  LatLng? _lastHazardFetchLocation;

  // Off-route & Rerouting State
  DateTime? _lastRerouteTime;
  int _offRouteConfirmations = 0;
  int _reroutesCount = 0;

  // Trip Summary tracking metrics
  double _totalDistanceWalkedMeters = 0.0;
  LatLng? _lastWalkedPoint;
  DateTime? _startTime;
  int _initialSafetyScore = 100;
  TripSummary? _completedTripSummary;

  // Location Stream Subscription
  StreamSubscription<Position>? _positionSubscription;

  // Getters for UI binding
  NavigationState get state => _state;
  Destination? get destination => _destination;
  RouteCandidate? get activeCandidate => _activeCandidate;
  RouteModel? get currentRoute => _currentRoute;
  LatLng? get currentLocation => _currentLocation;
  List<LatLng> get completedPoints => List.unmodifiable(_completedPoints);
  List<LatLng> get remainingPoints => List.unmodifiable(_remainingPoints);
  double get remainingDistanceMeters => _remainingDistanceMeters;
  double get remainingDurationSeconds => _remainingDurationSeconds;
  NavigationInstruction? get currentInstruction => _currentInstruction;
  double get distanceToNextManeuverMeters => _distanceToNextManeuverMeters;
  HazardReport? get activeHazardAlert => _activeHazardAlert;
  List<HazardReport> get nearbyReports => List.unmodifiable(_nearbyReports);
  int get reroutesCount => _reroutesCount;
  TripSummary? get completedTripSummary => _completedTripSummary;

  UserPreferences? _userPreferences;

  /// Start live walking navigation session for a selected destination and route candidate.
  void startNavigation({
    required Destination destination,
    required RouteCandidate candidate,
    required LatLng initialUserLocation,
    required List<HazardReport> initialNearbyReports,
    UserPreferences? userPreferences,
  }) {
    _userPreferences = userPreferences;
    _destination = destination;
    _activeCandidate = candidate;
    _currentRoute = candidate.route;
    _currentLocation = initialUserLocation;
    _nearbyReports = List.from(initialNearbyReports);

    _initialSafetyScore = candidate.safetyScore.overallScore;
    _startTime = DateTime.now();
    _totalDistanceWalkedMeters = 0.0;
    _lastWalkedPoint = initialUserLocation;
    _reroutesCount = 0;
    _offRouteConfirmations = 0;
    _shownAlertIds.clear();
    _completedTripSummary = null;

    _remainingPoints = List.from(candidate.route.polylinePoints);
    _completedPoints = [initialUserLocation];
    _remainingDistanceMeters = candidate.route.distanceMeters;
    _remainingDurationSeconds = candidate.route.durationSeconds;

    _setupInstructions(candidate.route.instructions);

    _state = NavigationState.navigating;
    notifyListeners();

    _startLocationUpdates();
  }

  /// Update location stream subscription using Geolocator settings.
  void _startLocationUpdates() {
    _positionSubscription?.cancel();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3, // Update every 3 meters
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (position) => _onPositionUpdated(position),
      onError: (e) {
        debugPrint('[LiveNavigationService] GPS stream error: $e');
      },
    );
  }

  /// Process incoming GPS position update during active navigation.
  void _onPositionUpdated(Position position) {
    if (_state != NavigationState.navigating && _state != NavigationState.rerouting) return;

    final LatLng newPos = LatLng(position.latitude, position.longitude);
    _currentGpsAccuracy = position.accuracy;

    // Ignore noisy location jumps exceeding configured GPS accuracy threshold
    if (_currentGpsAccuracy > SafetyConfig.gpsAccuracyThresholdMeters && position.accuracy > 0) {
      debugPrint('[LiveNavigationService] High GPS jitter (${position.accuracy}m). Ignoring position jump.');
      return;
    }

    _currentLocation = newPos;

    // Track total distance walked
    if (_lastWalkedPoint != null) {
      final stepDist = _distanceCalculator.as(LengthUnit.Meter, _lastWalkedPoint!, newPos);
      if (stepDist > 1.0 && stepDist < 50.0) {
        _totalDistanceWalkedMeters += stepDist;
      }
    }
    _lastWalkedPoint = newPos;

    // 1. Update polyline progress & remaining distance
    _updatePolylineProgress(newPos);

    // 2. Check destination arrival
    if (_destination != null) {
      final distToDest = _distanceCalculator.as(
        LengthUnit.Meter,
        newPos,
        _destination!.toLatLng(),
      );

      if (distToDest <= SafetyConfig.arrivalRadiusMeters) {
        _onArrivalReached();
        return;
      }
    }

    // 3. Update turn-by-turn maneuver progress
    _updateInstructionProgress(newPos);

    // 4. Off-route detection & rerouting
    _checkOffRoute(newPos);

    // 5. Periodic nearby hazard refresh & proximity alerts
    _checkHazardAlerts(newPos);

    notifyListeners();
  }

  /// Split polyline into completed and remaining segments based on current GPS position.
  void _updatePolylineProgress(LatLng userPos) {
    if (_currentRoute == null || _currentRoute!.polylinePoints.isEmpty) return;

    final points = _currentRoute!.polylinePoints;
    int closestIndex = 0;
    double minDistance = double.infinity;

    for (int i = 0; i < points.length; i++) {
      final dist = _distanceCalculator.as(LengthUnit.Meter, userPos, points[i]);
      if (dist < minDistance) {
        minDistance = dist;
        closestIndex = i;
      }
    }

    // Build completed points
    _completedPoints = points.sublist(0, closestIndex + 1);
    if (_completedPoints.isEmpty || _completedPoints.last != userPos) {
      _completedPoints.add(userPos);
    }

    // Build remaining points
    _remainingPoints = [userPos, ...points.sublist(closestIndex)];

    // Re-calculate remaining distance in meters
    double remDist = 0.0;
    for (int i = 0; i < _remainingPoints.length - 1; i++) {
      remDist += _distanceCalculator.as(
        LengthUnit.Meter,
        _remainingPoints[i],
        _remainingPoints[i + 1],
      );
    }
    _remainingDistanceMeters = remDist;

    // Estimate remaining walking duration at average walking speed (1.25 m/s)
    _remainingDurationSeconds = remDist / 1.25;
  }

  /// Setup turn-by-turn instructions from route model.
  void _setupInstructions(List<NavigationInstruction> instructions) {
    if (instructions.isNotEmpty) {
      _currentInstructionIndex = 0;
      _currentInstruction = instructions.first;
    } else {
      _currentInstruction = null;
    }
  }

  /// Update instruction maneuver distance & transition to next maneuver step.
  void _updateInstructionProgress(LatLng userPos) {
    if (_currentRoute == null || _currentRoute!.instructions.isEmpty) return;

    final instructions = _currentRoute!.instructions;
    if (_currentInstructionIndex < instructions.length) {
      final target = instructions[_currentInstructionIndex];
      final distToStep = _distanceCalculator.as(LengthUnit.Meter, userPos, target.location);
      _distanceToNextManeuverMeters = distToStep;

      // Advance to next step when within 15 meters of maneuver point
      if (distToStep < 15.0 && _currentInstructionIndex < instructions.length - 1) {
        _currentInstructionIndex++;
        _currentInstruction = instructions[_currentInstructionIndex];
      }
    }
  }

  /// Evaluate off-route deviation against remaining polyline geometry.
  void _checkOffRoute(LatLng userPos) {
    if (_currentRoute == null || _remainingPoints.isEmpty) return;

    // Minimum distance from current GPS position to remaining polyline
    final distToPolyline = HazardAnalysisService.getMinimumDistanceToRoute(
      userPos,
      _remainingPoints,
    );

    if (distToPolyline > SafetyConfig.offRouteThresholdMeters) {
      _offRouteConfirmations++;
    } else {
      _offRouteConfirmations = 0;
    }

    // Require sustained deviation (2 consecutive checks) and respect reroute cooldown
    if (_offRouteConfirmations >= 2) {
      final now = DateTime.now();
      if (_lastRerouteTime == null ||
          now.difference(_lastRerouteTime!).inSeconds >= SafetyConfig.rerouteCooldownSeconds) {
        _performReroute(userPos);
      }
    }
  }

  /// Execute automatic safety-aware rerouting from current position to destination.
  Future<void> _performReroute(LatLng currentPos) async {
    if (_destination == null) return;

    _state = NavigationState.rerouting;
    _lastRerouteTime = DateTime.now();
    _reroutesCount++;
    _offRouteConfirmations = 0;
    notifyListeners();

    debugPrint('[LiveNavigationService] Off-route detected! Recalculating safety-aware routes...');

    try {
      final routes = await RoutingService().getWalkingRouteAlternatives(
        originLat: currentPos.latitude,
        originLon: currentPos.longitude,
        destLat: _destination!.latitude,
        destLon: _destination!.longitude,
      );

      if (routes.isNotEmpty) {
        final candidateRanked = RouteAnalysisService.analyzeRouteCandidates(
          routes: routes,
          nearbyReports: _nearbyReports,
        );

        final newCandidate = candidateRanked.first;

        _activeCandidate = newCandidate;
        _currentRoute = newCandidate.route;
        _remainingPoints = List.from(newCandidate.route.polylinePoints);
        _completedPoints = [currentPos];
        _remainingDistanceMeters = newCandidate.route.distanceMeters;
        _remainingDurationSeconds = newCandidate.route.durationSeconds;

        _setupInstructions(newCandidate.route.instructions);

        _state = NavigationState.navigating;
        HapticFeedback.mediumImpact();
        debugPrint('[LiveNavigationService] Rerouting complete. New Safety Score: ${newCandidate.safetyScore.overallScore}');
      } else {
        _state = NavigationState.navigating;
      }
    } catch (e) {
      debugPrint('[LiveNavigationService] Rerouting error: $e');
      _state = NavigationState.navigating;
    }

    notifyListeners();
  }

  /// Check nearby hazard proximity & show contextual non-blocking alerts.
  Future<void> _checkHazardAlerts(LatLng userPos) async {
    final now = DateTime.now();

    // Throttle hazard query refreshes by time and distance
    final shouldFetch = _lastHazardFetchTime == null ||
        now.difference(_lastHazardFetchTime!).inSeconds >= SafetyConfig.hazardRefreshIntervalSeconds ||
        (_lastHazardFetchLocation != null &&
            _distanceCalculator.as(LengthUnit.Meter, _lastHazardFetchLocation!, userPos) >=
                SafetyConfig.hazardRefreshDistanceMeters);

    if (shouldFetch) {
      _lastHazardFetchTime = now;
      _lastHazardFetchLocation = userPos;

      final fetchedReports = await ReportService.fetchNearbyReports(
        latitude: userPos.latitude,
        longitude: userPos.longitude,
        radiusKm: 2.0,
      );

      if (fetchedReports.isNotEmpty) {
        _nearbyReports = fetchedReports;

        // Re-evaluate safety score of active candidate with fresh report data
        if (_currentRoute != null) {
          final updatedScore = SafetyEngine.calculateScore(
            route: _currentRoute!,
            nearbyReports: _nearbyReports,
          );

          if (_activeCandidate != null &&
              updatedScore.overallScore != _activeCandidate!.safetyScore.overallScore) {
            _activeCandidate = RouteCandidate(
              id: _activeCandidate!.id,
              title: _activeCandidate!.title,
              route: _currentRoute!,
              safetyScore: updatedScore,
              hazardCount: updatedScore.signals.length,
              riskSignals: updatedScore.signals,
              isRecommended: _activeCandidate!.isRecommended,
            );
          }
        }
      }
    }

    // Determine alert distance & confidence cutoff from user preferences sensitivity
    double maxAlertDist = SafetyConfig.hazardAlertDistanceMeters;
    double minConfidence = 0.5;

    if (_userPreferences != null) {
      if (_userPreferences!.alertSensitivity == 'high') {
        maxAlertDist = 200.0;
        minConfidence = 0.3;
      } else if (_userPreferences!.alertSensitivity == 'low') {
        maxAlertDist = 100.0;
        minConfidence = 0.7;
      }
    }

    HazardReport? upcomingAlert;
    double minAlertDist = maxAlertDist;

    for (final report in _nearbyReports) {
      if (_shownAlertIds.contains(report.id)) continue;
      if (report.confidence < minConfidence) continue;

      final repPos = LatLng(report.latitude, report.longitude);
      final distToUser = _distanceCalculator.as(LengthUnit.Meter, userPos, repPos);

      // Check if report is within alert distance and close to remaining route
      if (distToUser <= minAlertDist) {
        final distToRoute = HazardAnalysisService.getMinimumDistanceToRoute(repPos, _remainingPoints);
        if (distToRoute <= 80.0) {
          minAlertDist = distToUser;
          upcomingAlert = report;
        }
      }
    }

    if (upcomingAlert != null) {
      _activeHazardAlert = upcomingAlert;
      _shownAlertIds.add(upcomingAlert.id);
      HapticFeedback.mediumImpact();
      debugPrint('[LiveNavigationService] Triggered hazard alert: ${upcomingAlert.displayLabel}');
    }
  }

  /// Dismiss currently active hazard alert card.
  void dismissHazardAlert() {
    _activeHazardAlert = null;
    notifyListeners();
  }

  /// Handle destination arrival event.
  void _onArrivalReached() {
    _positionSubscription?.cancel();
    _state = NavigationState.arrived;
    HapticFeedback.heavyImpact();

    final finalScore = _activeCandidate?.safetyScore.overallScore ?? _initialSafetyScore;

    _completedTripSummary = TripSummary(
      destinationTitle: _destination?.title ?? 'Destination',
      totalDistanceMeters: _totalDistanceWalkedMeters > 0
          ? _totalDistanceWalkedMeters
          : (_currentRoute?.distanceMeters ?? 0.0),
      totalDurationSeconds: _startTime != null
          ? DateTime.now().difference(_startTime!).inSeconds.toDouble()
          : (_currentRoute?.durationSeconds ?? 0.0),
      routeTitle: _activeCandidate?.title ?? 'Walking Path',
      initialSafetyScore: _initialSafetyScore,
      finalSafetyScore: finalScore,
      hazardSignalsCount: _shownAlertIds.length,
      reroutesCount: _reroutesCount,
      timestamp: DateTime.now(),
    );

    // Save completed route history to Supabase (non-blocking)
    if (_destination != null && _currentLocation != null) {
      ReportService.saveRouteHistory(
        startLat: _completedPoints.first.latitude,
        startLon: _completedPoints.first.longitude,
        endLat: _destination!.latitude,
        endLon: _destination!.longitude,
        distanceMeters: _completedTripSummary!.totalDistanceMeters,
        durationSeconds: _completedTripSummary!.totalDurationSeconds.round(),
        safetyScore: finalScore,
        hazardCount: _shownAlertIds.length,
        analysisVersion: SafetyConfig.analysisVersion,
      );
    }

    notifyListeners();
  }

  /// End navigation session manually and cleanup stream subscriptions.
  void stopNavigation() {
    _positionSubscription?.cancel();
    _state = NavigationState.navigationFinished;
    _activeHazardAlert = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}
