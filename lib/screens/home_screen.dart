import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../config/safety_config.dart';
import '../models/destination.dart';
import '../models/hazard_report.dart';
import '../models/location_model.dart';
import '../models/route_candidate.dart';
import '../models/route_model.dart';
import '../services/location_service.dart';
import '../services/map_service.dart';
import '../services/preferences_service.dart';
import '../services/report_service.dart';
import '../services/route_analysis_service.dart';
import '../services/routing_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/constants.dart';
import '../widgets/cluster_marker.dart';
import '../widgets/destination_marker.dart';
import '../widgets/error_banner.dart';
import '../widgets/hazard_filter.dart';
import '../widgets/hazard_marker.dart';
import '../widgets/location_button.dart';
import '../widgets/permission_dialog.dart';
import '../widgets/primary_button.dart';
import '../widgets/report_details_sheet.dart';
import '../widgets/report_form.dart';
import '../widgets/route_comparison_card.dart';
import '../widgets/route_info_sheet.dart';
import '../widgets/safety_breakdown_sheet.dart';

import '../widgets/search_bar_widget.dart';
import '../services/emergency_service.dart';
import '../widgets/sos_button.dart';
import '../widgets/emergency_cancellation_dialog.dart';
import '../widgets/emergency_status_sheet.dart';
import '../models/emergency_contact.dart';
import '../services/auth_service.dart';
import '../services/emergency_contact_service.dart';
import '../widgets/emergency_contact_dialog.dart';
import 'navigation_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static bool _hasPromptedEmergencySetupInSession = false;

  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final RoutingService _routingService = RoutingService();
  final MapService _mapService = MapService();
  final FocusNode _searchFocusNode = FocusNode();

  LatLng _currentCenter = AppConstants.defaultLocation;
  LocationModel? _currentLocation;
  Destination? _selectedDestination;
  RouteModel? _activeRoute;

  // Phase 2: Hazard Reports State
  List<HazardReport> _nearbyReports = [];
  String _selectedHazardFilter = 'all';
  bool _isLoadingReports = false;

  // Phase 3: Route Candidates & Safety Analysis State
  List<RouteCandidate> _routeCandidates = [];
  RouteCandidate? _activeCandidate;

  bool _isLocating = false;
  bool _isCalculatingRoute = false;
  bool _hasPermission = false;
  bool _isCancellationDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _checkInitialPermissionAndLocation();
    _fetchNearbyHazards();
    EmergencyService.instance.addListener(_onEmergencyStateChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstTimeEmergencyContactSetup();
    });
  }

  Future<void> _checkFirstTimeEmergencyContactSetup() async {
    if (_hasPromptedEmergencySetupInSession) return;

    final user = AuthService().currentUser;
    if (user == null || !user.emailVerified) return;

    final contact = await EmergencyContactService.getPrimaryContact(user.uid);
    if (contact == null && mounted && !_hasPromptedEmergencySetupInSession) {
      _hasPromptedEmergencySetupInSession = true;
      final result = await showDialog<EmergencyContact?>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const EmergencyContactDialog(isFirstTimeSetup: true),
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency contact saved successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    EmergencyService.instance.removeListener(_onEmergencyStateChanged);
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onEmergencyStateChanged() {
    final service = EmergencyService.instance;
    if (!mounted) return;

    setState(() {});

    if (service.isPreparing && !_isCancellationDialogOpen) {
      _isCancellationDialogOpen = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const EmergencyCancellationDialog(),
      ).then((_) {
        _isCancellationDialogOpen = false;
      });
    } else if (!service.isPreparing && _isCancellationDialogOpen) {
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (_) {}
      _isCancellationDialogOpen = false;
    }
  }


  void _safeMove(LatLng center, double zoom) {
    try {
      _mapController.move(center, zoom);
    } catch (e) {
      debugPrint('[HomeScreen] MapController not ready for move: $e');
    }
  }

  void _safeFitBounds(LatLngBounds bounds) {
    try {
      _mapService.fitBounds(_mapController, bounds);
    } catch (e) {
      debugPrint('[HomeScreen] MapController not ready for fitBounds: $e');
    }
  }

  Future<void> _checkInitialPermissionAndLocation() async {
    final status = await _locationService.checkPermission();
    if (status == LocationPermission.always ||
        status == LocationPermission.whileInUse) {
      _hasPermission = true;
      _locateUser(showError: false);
    }
  }

  Future<void> _fetchNearbyHazards() async {
    if (_isLoadingReports) return;
    setState(() => _isLoadingReports = true);

    final reports = await ReportService.fetchNearbyReports();

    if (mounted) {
      setState(() {
        _nearbyReports = reports;
        _isLoadingReports = false;
      });

      // Fit map camera to show all hazard markers across Nagpur
      if (reports.isNotEmpty && _selectedDestination == null) {
        final points = reports.map((r) => LatLng(r.latitude, r.longitude)).toList();
        final bounds = _mapService.calculateBounds(points);
        _safeFitBounds(bounds);
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LocationPermissionDialog(
        onAllow: () async {
          Navigator.of(context).pop();
          final permission = await _locationService.requestPermission();
          if (permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse) {
            setState(() => _hasPermission = true);
            _locateUser(showError: true);
          } else if (context.mounted) {
            ErrorBanner.show(
              context: context,
              title: 'Location permission denied',
              message:
                  'Defaulting to Nagpur map area. You can search destinations manually.',
              icon: Icons.location_off_rounded,
            );
          }
        },
        onDeny: () {
          Navigator.of(context).pop();
          ErrorBanner.show(
            context: context,
            title: 'Location permission skipped',
            message: 'Using Nagpur, Maharashtra as your default map location.',
            icon: Icons.map_rounded,
          );
        },
      ),
    );
  }

  Future<void> _locateUser({bool showError = true}) async {
    if (!_hasPermission) {
      _requestLocationPermission();
      return;
    }

    setState(() => _isLocating = true);
    final loc = await _locationService.getCurrentLocation();
    setState(() => _isLocating = false);

    if (loc != null) {
      setState(() {
        _currentLocation = loc;
        _currentCenter = loc.toLatLng();
      });
      _safeMove(_currentCenter, AppConstants.detailZoom);
      _fetchNearbyHazards();
    } else if (showError && mounted) {
      ErrorBanner.show(
        context: context,
        title: 'Location unavailable',
        message: 'Unable to get GPS coordinates. Check location settings.',
        icon: Icons.gps_off_rounded,
        onRetry: () => _locateUser(showError: true),
      );
    }
  }

  void _onDestinationSelected(Destination dest) {
    setState(() {
      _selectedDestination = dest;
      _activeRoute = null;
      _routeCandidates = [];
      _activeCandidate = null;
    });

    _safeMove(dest.toLatLng(), AppConstants.detailZoom);
  }

  Future<void> _calculateRoute() async {
    if (_selectedDestination == null) return;

    if (_currentLocation == null) {
      final loc = await _locationService.getCurrentLocation();
      if (loc != null) {
        setState(() => _currentLocation = loc);
      } else {
        if (mounted) {
          ErrorBanner.show(
            context: context,
            title: 'Location required',
            message: 'Unable to get valid GPS position for routing. Please check location settings.',
            icon: Icons.gps_off_rounded,
            onRetry: _calculateRoute,
          );
        }
        return;
      }
    }

    final LatLng origin = _currentLocation!.toLatLng();
    final LatLng destination = _selectedDestination!.toLatLng();

    setState(() => _isCalculatingRoute = true);

    // Phase 3: Obtain route alternatives from OSRM
    final routes = await _routingService.getWalkingRouteAlternatives(
      originLat: origin.latitude,
      originLon: origin.longitude,
      destLat: destination.latitude,
      destLon: destination.longitude,
    );

    setState(() => _isCalculatingRoute = false);

    if (routes.isNotEmpty) {
      // Phase 6: Fetch user safety preferences
      final userPrefs = await PreferencesService.getPreferences();

      // Phase 3 & Phase 6: Evaluate candidates using SafetyEngine with personalized preferences
      final candidates = RouteAnalysisService.analyzeRouteCandidates(
        routes: routes,
        nearbyReports: _filteredReports,
        preferences: userPrefs,
      );

      final primaryCandidate = candidates.first;

      setState(() {
        _routeCandidates = candidates;
        _activeCandidate = primaryCandidate;
        _activeRoute = primaryCandidate.route;
      });

      // Fit map camera to enclose origin and destination points
      final bounds = _mapService.calculateBounds(primaryCandidate.route.polylinePoints);
      _safeFitBounds(bounds);
    } else if (mounted) {
      ErrorBanner.show(
        context: context,
        title: 'Walking route unavailable',
        message: 'Could not calculate walking path to destination.',
        icon: Icons.alt_route_rounded,
        onRetry: _calculateRoute,
      );
    }
  }

  void _selectRouteCandidate(RouteCandidate candidate) {
    setState(() {
      _activeCandidate = candidate;
      _activeRoute = candidate.route;
    });

    final bounds = _mapService.calculateBounds(candidate.route.polylinePoints);
    _safeFitBounds(bounds);
  }

  void _showSafetyBreakdown(RouteCandidate candidate) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafetyBreakdownSheet(
        safetyScore: candidate.safetyScore,
        candidate: candidate,
      ),
    );
  }

  Future<void> _startNavigation() async {
    if (_selectedDestination == null || _activeRoute == null) return;

    // Log route history to Supabase (non-blocking)
    final LatLng origin = _currentLocation?.toLatLng() ?? AppConstants.defaultLocation;
    ReportService.saveRouteHistory(
      startLat: origin.latitude,
      startLon: origin.longitude,
      endLat: _selectedDestination!.latitude,
      endLon: _selectedDestination!.longitude,
      distanceMeters: _activeRoute!.distanceMeters,
      durationSeconds: _activeRoute!.durationSeconds.round(),
      safetyScore: _activeCandidate?.safetyScore.overallScore,
      hazardCount: _activeCandidate?.hazardCount,
      analysisVersion: SafetyConfig.analysisVersion,
    );

    final userPrefs = await PreferencesService.getPreferences();
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NavigationScreen(
          destination: _selectedDestination!,
          route: _activeRoute!,
          userLocation: origin,
          activeCandidate: _activeCandidate,
          initialNearbyReports: _nearbyReports,
          userPreferences: userPrefs,
        ),
      ),
    );
  }

  void _clearRouteAndSelection() {
    setState(() {
      _selectedDestination = null;
      _activeRoute = null;
      _routeCandidates = [];
      _activeCandidate = null;
    });
  }

  void _openReportForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReportFormSheet(
        currentLocation: _currentLocation?.toLatLng(),
        onReportSubmitted: () {
          _fetchNearbyHazards();
        },
      ),
    );
  }

  void _showHazardDetails(HazardReport report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReportDetailsSheet(report: report),
    );
  }

  /// Filter hazard reports based on selected category pill
  List<HazardReport> get _filteredReports {
    if (_selectedHazardFilter == 'all') {
      return _nearbyReports;
    }
    return _nearbyReports
        .where((r) => r.hazardType == _selectedHazardFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    // Safely acquire map camera (which is null before FlutterMap renders its first frame)
    MapCamera? camera;
    try {
      camera = _mapController.camera;
    } catch (_) {
      camera = null;
    }

    // Build hazard clusters based on filtered reports and map camera zoom/projection
    final clusters = ClusterHelper.buildClusters(
      reports: _filteredReports,
      camera: camera,
    );

    return Scaffold(
      body: Stack(
        children: [
          // 1. Immersive OpenStreetMap Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: AppConstants.defaultLocation,
              initialZoom: AppConstants.defaultZoom,
              minZoom: 4.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onMapReady: () {
                if (mounted) setState(() {});
              },
              onPositionChanged: (position, hasGesture) {
                setState(() {});
              },
            ),
            children: [
              TileLayer(
                urlTemplate: AppConstants.mapTileUrl,
                userAgentPackageName: AppConstants.mapPackageName,
              ),

              // Route Polyline Layer
              if (_routeCandidates.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    // Unselected route candidates (drawn behind)
                    ..._routeCandidates
                        .where((c) => c.id != _activeCandidate?.id)
                        .map(
                          (c) => Polyline(
                            points: c.route.polylinePoints,
                            strokeWidth: 4.0,
                            color: AppColors.textMuted.withAlpha(120),
                            borderColor: AppColors.border,
                            borderStrokeWidth: 1.0,
                          ),
                        ),
                    // Active selected candidate (drawn on top)
                    if (_activeCandidate != null)
                      Polyline(
                        points: _activeCandidate!.route.polylinePoints,
                        strokeWidth: 6.0,
                        color: _activeCandidate!.safetyScore.badgeColor,
                        borderColor: AppColors.primaryDark,
                        borderStrokeWidth: 1.5,
                      ),
                  ],
                ),

              // Markers Layer (Clusters & Individual Hazard Markers + Destination + User Location)
              MarkerLayer(
                markers: [
                  // 1. Hazard Clusters & Hazard Markers
                  ...clusters.map((cluster) {
                    if (cluster.count > 1) {
                      return Marker(
                        point: cluster.center,
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        child: ClusterMarkerWidget(
                          count: cluster.count,
                          onTap: () {
                            double currentZoom = 13.0;
                            try {
                              currentZoom = _mapController.camera.zoom;
                            } catch (_) {}
                            final targetZoom = (currentZoom + 2.5).clamp(4.0, 18.0);
                            _mapController.move(cluster.center, targetZoom);
                          },
                        ),
                      );
                    } else {
                      final report = cluster.reports.first;
                      return HazardMarkerWidget.buildMarker(
                        report: report,
                        onTap: () => _showHazardDetails(report),
                      );
                    }
                  }),

                  // 2. Destination Marker
                  if (_selectedDestination != null)
                    Marker(
                      point: _selectedDestination!.toLatLng(),
                      width: 140,
                      height: 80,
                      alignment: Alignment.topCenter,
                      child: DestinationMarkerWidget(
                        label: _selectedDestination!.title,
                      ),
                    ),

                  // 3. User Live Location Marker (Drawn LAST to sit on top of hazards and clusters)
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!.toLatLng(),
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      child: const CurrentLocationMarkerWidget(),
                    ),
                ],
              ),
            ],
          ),

          // 2. Floating Top Header & Search Bar & Hazard Filter Overlay
          Positioned(
            top: mediaQuery.padding.top + AppSpacing.md,
            left: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top App Branding Pill
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs + 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppColors.softShadow,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'SafeRoute AI',
                              style: AppTypography.headingSmall
                                  .copyWith(fontSize: 13),
                            ),
                             const SizedBox(width: AppSpacing.xs),
                            Text(
                              '• Phase 6',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SosButton(),
                          const SizedBox(width: AppSpacing.xs + 2),
                          if (_isLoadingReports)
                            Container(
                              margin: const EdgeInsets.only(right: AppSpacing.xs),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: AppColors.softShadow,
                              ),
                              child: const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          Material(
                            color: AppColors.surface,
                            shape: const CircleBorder(),
                            elevation: 2,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const ProfileScreen(),
                                  ),
                                );
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(AppSpacing.xs + 2),
                                child: Icon(
                                  Icons.person_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // Floating Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: FloatingSearchBar(
                    focusNode: _searchFocusNode,
                    onDestinationSelected: _onDestinationSelected,
                    onClear: _clearRouteAndSelection,
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // Phase 2: Hazard Filter Bar
                HazardFilterBar(
                  selectedCategory: _selectedHazardFilter,
                  onCategorySelected: (category) {
                    setState(() {
                      _selectedHazardFilter = category;
                    });
                  },
                ),
              ],
            ),
          ),

          // 3. Floating Action Buttons (Location Button & Report Hazard FAB)
          Positioned(
            right: AppSpacing.lg,
            bottom: _activeRoute != null
                ? (_routeCandidates.length > 1 ? 330 : 250)
                : 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Report Hazard FAB
                FloatingActionButton.extended(
                  heroTag: 'report_hazard_fab',
                  onPressed: _openReportForm,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  icon: const Icon(Icons.add_location_alt_rounded, size: 20),
                  label: Text(
                    'Report Hazard',
                    style: AppTypography.button.copyWith(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Current Location Button
                FloatingLocationButton(
                  onPressed: () => _locateUser(showError: true),
                  isLocating: _isLocating,
                ),
              ],
            ),
          ),

          // 4. "Find Route" Floating CTA Button
          if (_activeRoute == null)
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.xxl,
              child: PrimaryButton(
                text: 'Find Route',
                icon: Icons.alt_route_rounded,
                isLoading: _isCalculatingRoute,
                onPressed: () {
                  if (_selectedDestination == null) {
                    _searchFocusNode.requestFocus();
                  } else {
                    _calculateRoute();
                  }
                },
              ),
            ),

          // 5. Phase 3: Route Candidate Selector & Route Info Bottom Sheet
          if (_selectedDestination != null && _activeRoute != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_routeCandidates.length > 1 && _activeCandidate != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: RouteComparisonSelector(
                        candidates: _routeCandidates,
                        selectedCandidate: _activeCandidate!,
                        onCandidateSelected: _selectRouteCandidate,
                        onShowBreakdown: _showSafetyBreakdown,
                      ),
                    ),
                  RouteInfoSheet(
                    destination: _selectedDestination!,
                    route: _activeRoute!,
                    activeCandidate: _activeCandidate,
                    onStartNavigation: _startNavigation,
                    onClose: _clearRouteAndSelection,
                    onShowSafetyBreakdown: _activeCandidate != null
                        ? () => _showSafetyBreakdown(_activeCandidate!)
                        : null,
                  ),
                ],
              ),
            ),

          // 6. Emergency Status Sheet Overlay
          if (EmergencyService.instance.isEmergencyActive &&
              !EmergencyService.instance.isPreparing)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: EmergencyStatusSheet(),
            ),
        ],
      ),
    );
  }
}

