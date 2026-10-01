import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/destination.dart';
import '../models/hazard_report.dart';
import '../models/navigation_state.dart';
import '../models/route_candidate.dart';
import '../models/route_model.dart';
import '../models/user_preferences.dart';
import '../services/live_navigation_service.dart';
import '../services/map_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/constants.dart';
import '../widgets/ai_question_dialog.dart';
import '../widgets/destination_marker.dart';
import '../widgets/hazard_alert_banner.dart';
import '../widgets/hazard_explanation_sheet.dart';
import '../widgets/hazard_marker.dart';
import '../widgets/maneuver_card.dart';
import '../widgets/navigation_safety_panel.dart';
import '../widgets/primary_button.dart';
import '../widgets/safety_score_badge.dart';
import '../widgets/trip_summary_sheet.dart';

/// Phase 4 & Phase 5 Live Safety-Aware Walking Navigation Screen with AI Guidance.
class NavigationScreen extends StatefulWidget {
  final Destination destination;
  final RouteModel route;
  final LatLng userLocation;
  final RouteCandidate? activeCandidate;
  final List<HazardReport> initialNearbyReports;
  final UserPreferences? userPreferences;

  const NavigationScreen({
    super.key,
    required this.destination,
    required this.route,
    required this.userLocation,
    this.activeCandidate,
    this.initialNearbyReports = const [],
    this.userPreferences,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final MapController _mapController = MapController();
  final MapService _mapService = MapService();
  late final LiveNavigationService _navService;

  @override
  void initState() {
    super.initState();
    _navService = LiveNavigationService();

    // Attach listener for map updates and arrival sheet trigger
    _navService.addListener(_onNavigationStateChanged);

    // Initialize live walking navigation
    if (widget.activeCandidate != null) {
      _navService.startNavigation(
        destination: widget.destination,
        candidate: widget.activeCandidate!,
        initialUserLocation: widget.userLocation,
        initialNearbyReports: widget.initialNearbyReports,
        userPreferences: widget.userPreferences,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.route.polylinePoints.isNotEmpty) {
        final bounds = _mapService.calculateBounds(widget.route.polylinePoints);
        _mapService.fitBounds(_mapController, bounds);
      }
    });
  }

  void _onNavigationStateChanged() {
    if (!mounted) return;

    // Recenter map on user location during active navigation
    if (_navService.state == NavigationState.navigating && _navService.currentLocation != null) {
      _mapController.move(_navService.currentLocation!, AppConstants.detailZoom);
    }

    // Show Trip Summary Modal Sheet upon arrival
    if (_navService.state == NavigationState.arrived && _navService.completedTripSummary != null) {
      _showArrivalSummarySheet();
    }
  }

  void _showArrivalSummarySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TripSummarySheet(
        summary: _navService.completedTripSummary!,
        onFinish: () {
          _navService.stopNavigation();
          Navigator.of(context).pop(); // pop sheet
          Navigator.of(context).pop(); // pop navigation screen to home
        },
      ),
    );
  }

  void _showHazardDetails(HazardReport report) {
    final userPos = _navService.currentLocation ?? widget.userLocation;
    final dist = const Distance().as(
      LengthUnit.Meter,
      userPos,
      LatLng(report.latitude, report.longitude),
    );

    HazardExplanationSheet.show(
      context,
      hazard: report,
      distanceMeters: dist,
    );
  }

  void _openAiQuestions() {
    final candidate = _navService.activeCandidate ?? widget.activeCandidate;
    final navStateData = {
      'destination': widget.destination.title,
      'safety_score': candidate?.safetyScore.overallScore ?? 100,
      'remaining_distance': _formatRemainingDistance(_navService.remainingDistanceMeters),
      'remaining_duration': _formatRemainingDuration(_navService.remainingDurationSeconds),
      'nearby_hazard_count': _navService.nearbyReports.length,
      'signals': candidate?.safetyScore.signals.map((s) => s.label).toList() ?? [],
    };

    AiQuestionDialog.show(
      context,
      navigationState: navStateData,
    );
  }

  @override
  void dispose() {
    _navService.removeListener(_onNavigationStateChanged);
    _navService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final userPos = _navService.currentLocation ?? widget.userLocation;
    final candidate = _navService.activeCandidate ?? widget.activeCandidate;
    final scoreColor = candidate?.safetyScore.badgeColor ?? AppColors.primary;

    return ListenableBuilder(
      listenable: _navService,
      builder: (context, _) {
        return Scaffold(
          body: Stack(
            children: [
              // 1. Interactive OpenStreetMap Canvas
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: widget.userLocation,
                  initialZoom: AppConstants.detailZoom,
                  minZoom: 5.0,
                  maxZoom: 18.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: AppConstants.mapTileUrl,
                    userAgentPackageName: AppConstants.mapPackageName,
                  ),

                  // Route Polyline Progress Layer
                  PolylineLayer(
                    polylines: [
                      // De-emphasized completed route segment (behind)
                      if (_navService.completedPoints.isNotEmpty)
                        Polyline(
                          points: _navService.completedPoints,
                          strokeWidth: 4.0,
                          color: AppColors.textMuted.withAlpha(120),
                          borderColor: AppColors.border,
                          borderStrokeWidth: 1.0,
                        ),
                      // Prominent active remaining route segment (on top)
                      if (_navService.remainingPoints.isNotEmpty)
                        Polyline(
                          points: _navService.remainingPoints,
                          strokeWidth: 6.0,
                          color: scoreColor,
                          borderColor: AppColors.primaryDark,
                          borderStrokeWidth: 1.5,
                        ),
                    ],
                  ),

                  // Markers Layer (User Location + Destination + Nearby Hazards)
                  MarkerLayer(
                    markers: [
                      // Dynamic Current User Position Marker
                      Marker(
                        point: userPos,
                        width: 34,
                        height: 34,
                        child: const CurrentLocationMarkerWidget(),
                      ),

                      // Destination Marker
                      Marker(
                        point: widget.destination.toLatLng(),
                        width: 120,
                        height: 70,
                        alignment: Alignment.topCenter,
                        child: DestinationMarkerWidget(
                          label: widget.destination.title,
                        ),
                      ),

                      // Nearby Hazard Markers
                      ..._navService.nearbyReports.map(
                        (report) => HazardMarkerWidget.buildMarker(
                          report: report,
                          onTap: () => _showHazardDetails(report),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // 2. Top Maneuver Card & Header Overlay
              Positioned(
                top: mediaQuery.padding.top + AppSpacing.md,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Turn-by-turn maneuver card
                    ManeuverCard(
                      instruction: _navService.currentInstruction,
                      distanceToNextManeuverMeters: _navService.distanceToNextManeuverMeters,
                      destinationTitle: widget.destination.title,
                    ),

                    // Status banner when recalculating route
                    if (_navService.state == NavigationState.rerouting) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs + 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppColors.softShadow,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Recalculating safety-aware route...',
                              style: AppTypography.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 3. Non-blocking Contextual Hazard Warning Alert Banner
              if (_navService.activeHazardAlert != null)
                Positioned(
                  top: mediaQuery.padding.top + AppSpacing.md + 90,
                  left: 0,
                  right: 0,
                  child: HazardAlertBanner(
                    report: _navService.activeHazardAlert!,
                    onDismiss: _navService.dismissHazardAlert,
                    onViewDetails: () {
                      _showHazardDetails(_navService.activeHazardAlert!);
                      _navService.dismissHazardAlert();
                    },
                  ),
                ),

              // 4. Expandable Safety Signals Panel Drawer
              Positioned(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: 230,
                child: NavigationSafetyPanel(
                  nearbyReports: _navService.nearbyReports,
                  onReportTap: _showHazardDetails,
                ),
              ),

              // 5. Bottom Live Navigation Controls Card
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppSpacing.roundedSheet,
                    boxShadow: AppColors.floatingShadow,
                  ),
                  padding: EdgeInsets.only(
                    left: AppSpacing.xl,
                    right: AppSpacing.xl,
                    top: AppSpacing.lg,
                    bottom: mediaQuery.padding.bottom + AppSpacing.lg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Route Progress & Safety Score Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatRemainingDistance(_navService.remainingDistanceMeters),
                                style: AppTypography.appTitle.copyWith(
                                  fontSize: 30,
                                  color: scoreColor,
                                ),
                              ),
                              Text(
                                candidate?.safetyScore.safetyLabel ?? 'Safety-aware route',
                                style: AppTypography.caption.copyWith(
                                  color: scoreColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _openAiQuestions,
                                tooltip: 'Ask AI',
                                icon: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome,
                                    color: AppColors.primaryDark,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              if (candidate != null)
                                SafetyScoreBadge(
                                  safetyScore: candidate.safetyScore,
                                  isCompact: true,
                                ),
                              const SizedBox(width: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs + 2,
                                ),
                                decoration: BoxDecoration(
                                  color: scoreColor.withAlpha(20),
                                  borderRadius: AppSpacing.roundedMd,
                                ),
                                child: Text(
                                  _formatRemainingDuration(_navService.remainingDurationSeconds),
                                  style: AppTypography.headingSmall.copyWith(
                                    color: scoreColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // End Navigation Action Button
                      PrimaryButton(
                        text: 'End Navigation',
                        icon: Icons.close_rounded,
                        onPressed: () {
                          _navService.stopNavigation();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatRemainingDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }

  String _formatRemainingDuration(double seconds) {
    final mins = (seconds / 60).round();
    if (mins >= 60) {
      final hrs = mins ~/ 60;
      final rem = mins % 60;
      return rem > 0 ? '~$hrs hr $rem min' : '~$hrs hr';
    }
    return '~$mins min';
  }
}
