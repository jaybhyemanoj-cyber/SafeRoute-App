import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../models/emergency_contact.dart';
import '../models/location_model.dart';
import 'auth_service.dart';
import 'emergency_contact_service.dart';
import 'location_service.dart';
import 'native_emergency_channel.dart';
import 'profile_service.dart';

enum EmergencyTriggerType { primarySosButton, secondaryVolume }

enum EmergencyStatus {
  idle,
  preparing, // 5-second silent cancellation period
  locationPending,
  sendingSms,
  smsSent,
  smsDelivered,
  smsFailed,
  cancelled,
}

class EmergencyService extends ChangeNotifier {
  static final EmergencyService instance = EmergencyService._internal();
  factory EmergencyService() => instance;

  EmergencyService._internal() {
    _initNativeListeners();
  }

  final NativeEmergencyChannel _nativeChannel = NativeEmergencyChannel.instance;
  final LocationService _locationService = LocationService();
  final AuthService _authService = AuthService();

  StreamSubscription? _volumeSub;
  StreamSubscription? _smsStatusSub;
  Timer? _cancellationTimer;
  Timer? _countdownTimer;

  EmergencyStatus _status = EmergencyStatus.idle;
  EmergencyTriggerType? _lastTriggerType;
  EmergencyContact? _currentContact;
  LocationModel? _currentLocation;
  DateTime? _triggerTime;

  int _cancellationSecondsLeft = 5;
  String _statusMessage = '';
  String _smsSendStatusText = '';
  String _locationStatusText = '';

  // Getters
  EmergencyStatus get status => _status;
  bool get isEmergencyActive => _status != EmergencyStatus.idle && _status != EmergencyStatus.cancelled;
  bool get isPreparing => _status == EmergencyStatus.preparing;
  int get cancellationSecondsLeft => _cancellationSecondsLeft;
  EmergencyTriggerType? get lastTriggerType => _lastTriggerType;
  EmergencyContact? get currentContact => _currentContact;
  LocationModel? get currentLocation => _currentLocation;
  DateTime? get triggerTime => _triggerTime;
  String get statusMessage => _statusMessage;
  String get smsSendStatusText => _smsSendStatusText;
  String get locationStatusText => _locationStatusText;

  void _initNativeListeners() {
    // Listen for Secondary Volume-Button trigger
    _volumeSub?.cancel();
    _volumeSub = _nativeChannel.onVolumeTrigger.listen((_) {
      debugPrint('[EmergencyService] Received volume button emergency trigger');
      triggerEmergency(triggerType: EmergencyTriggerType.secondaryVolume);
    });

    // Listen for SMS status updates from native BroadcastReceiver
    _smsStatusSub?.cancel();
    _smsStatusSub = _nativeChannel.onSmsStatusUpdate.listen((data) {
      final statusStr = data['status']?.toString();
      final error = data['error']?.toString() ?? data['details']?.toString();

      if (statusStr == 'SENT') {
        _status = EmergencyStatus.smsSent;
        _smsSendStatusText = 'Emergency SMS sent.';
        _statusMessage = 'Emergency SMS sent to contact.';
        notifyListeners();
      } else if (statusStr == 'DELIVERED') {
        _status = EmergencyStatus.smsDelivered;
        _smsSendStatusText = 'Emergency SMS delivered.';
        _statusMessage = 'Emergency SMS delivered successfully.';
        notifyListeners();
      } else if (statusStr == 'SEND_FAILED') {
        _status = EmergencyStatus.smsFailed;
        _smsSendStatusText = 'Emergency SMS could not be sent.';
        _statusMessage = error != null && error.isNotEmpty
            ? 'Send failed: $error'
            : 'Emergency SMS could not be sent.';
        notifyListeners();
      } else if (statusStr == 'DELIVERY_UNAVAILABLE') {
        // SMS sent but delivery tracking unavailable by carrier
        _smsSendStatusText = 'SMS sent, but delivery status is unavailable.';
        notifyListeners();
      }
    });
  }

  /// Trigger emergency pipeline (Centralized entrance for Primary and Secondary triggers)
  Future<void> triggerEmergency({
    EmergencyTriggerType triggerType = EmergencyTriggerType.primarySosButton,
  }) async {
    // 1. Prevent duplicate simultaneous emergency requests
    if (isEmergencyActive) {
      debugPrint('[EmergencyService] Emergency already active. Request ignored.');
      return;
    }

    _lastTriggerType = triggerType;
    _triggerTime = DateTime.now();
    _status = EmergencyStatus.preparing;
    _cancellationSecondsLeft = 5;
    _statusMessage = 'Emergency alert preparing...';
    _smsSendStatusText = 'Preparing SMS...';
    _locationStatusText = 'Acquiring location...';

    notifyListeners();

    // 2. Light vibration feedback
    try {
      await HapticFeedback.vibrate();
    } catch (e) {
      debugPrint('[EmergencyService] Haptic feedback error: $e');
    }

    // 3. Start 5-second silent cancellation countdown
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cancellationSecondsLeft > 1) {
        _cancellationSecondsLeft--;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });

    _cancellationTimer?.cancel();
    _cancellationTimer = Timer(const Duration(seconds: 5), () {
      _countdownTimer?.cancel();
      if (_status == EmergencyStatus.preparing) {
        _executeEmergencyPipeline();
      }
    });
  }

  /// Cancel emergency during the 5-second silent cancellation window
  void cancelEmergency() {
    if (_status == EmergencyStatus.preparing) {
      _cancellationTimer?.cancel();
      _countdownTimer?.cancel();
      _status = EmergencyStatus.cancelled;
      _statusMessage = 'Emergency alert cancelled.';
      notifyListeners();

      // Reset to idle after a brief message display
      Timer(const Duration(seconds: 2), () {
        if (_status == EmergencyStatus.cancelled) {
          _status = EmergencyStatus.idle;
          notifyListeners();
        }
      });
    }
  }

  /// Execute the post-cancellation emergency pipeline
  Future<void> _executeEmergencyPipeline() async {
    _status = EmergencyStatus.locationPending;
    _statusMessage = 'Fetching user profile & emergency contact...';
    notifyListeners();

    // A. Get User Display Name
    String userName = 'SafeRoute User';
    final user = _authService.currentUser;
    if (user != null) {
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        userName = user.displayName!;
      } else if (user.email != null && user.email!.isNotEmpty) {
        userName = user.email!.split('@').first;
      }
      try {
        final profile = await ProfileService.getProfile(user.uid);
        if (profile != null && profile.displayName.isNotEmpty) {
          userName = profile.displayName;
        }
      } catch (e) {
        debugPrint('[EmergencyService] Profile name fetch error: $e');
      }
    }

    // B. Get Primary Emergency Contact
    final contact = await EmergencyContactService.getPrimaryContact(user?.uid);
    _currentContact = contact;

    if (contact == null || !contact.isValidPhoneNumber) {
      _status = EmergencyStatus.smsFailed;
      _statusMessage = 'No valid primary emergency contact configured.';
      _smsSendStatusText = 'Contact missing or invalid phone number.';
      notifyListeners();
      return;
    }

    // C. Get GPS Location with 10-second timeout & fallback to last known
    _statusMessage = 'Acquiring GPS location...';
    notifyListeners();

    LocationModel? loc = await _fetchEmergencyLocationWithTimeout();
    _currentLocation = loc;
    _locationStatusText = loc != null ? 'Shared ✓' : 'Unavailable';

    // D. Build Emergency SMS Content
    final smsText = buildEmergencySms(
      userName: userName,
      timestamp: _triggerTime ?? DateTime.now(),
      latitude: loc?.latitude,
      longitude: loc?.longitude,
    );

    // E. Check & Request Android SMS Permission
    _status = EmergencyStatus.sendingSms;
    _smsSendStatusText = 'Sending emergency SMS...';
    _statusMessage = 'Sending SMS to ${contact.name}...';
    notifyListeners();

    bool hasSmsPerm = await _nativeChannel.checkSmsPermission();
    if (!hasSmsPerm) {
      hasSmsPerm = await _nativeChannel.requestSmsPermission();
    }

    if (!hasSmsPerm) {
      _status = EmergencyStatus.smsFailed;
      _smsSendStatusText = 'Emergency SMS permission denied.';
      _statusMessage = 'Emergency SMS permission is required to send alerts directly from this phone.';
      notifyListeners();
      return;
    }

    // F. Send SMS via Native Android SmsManager
    final result = await _nativeChannel.sendEmergencySms(
      phoneNumber: contact.phoneNumber,
      message: smsText,
    );

    final resultStatus = result['status']?.toString();
    if (resultStatus == 'SENT') {
      _status = EmergencyStatus.smsSent;
      _smsSendStatusText = 'Emergency SMS sent.';
      _statusMessage = 'Emergency SMS sent to ${contact.name}.';
    } else if (resultStatus == 'SEND_FAILED') {
      _status = EmergencyStatus.smsFailed;
      final err = result['error']?.toString() ?? 'SMS send failed.';
      _smsSendStatusText = 'Emergency SMS could not be sent.';
      _statusMessage = 'Failed: $err';
    }

    notifyListeners();
  }

  /// Helper to fetch location within 10 seconds timeout, falling back to last known position
  Future<LocationModel?> _fetchEmergencyLocationWithTimeout() async {
    try {
      bool serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) return await _getLastKnownLocation();

      LocationPermission perm = await _locationService.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await _locationService.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        return await _getLastKnownLocation();
      }

      // Try fetching fresh location with 10s maximum timeout
      Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return LocationModel(
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
        heading: pos.heading,
      );
    } catch (e) {
      debugPrint('[EmergencyService] Fresh location failed or timed out ($e). Trying last known location...');
      return await _getLastKnownLocation();
    }
  }

  Future<LocationModel?> _getLastKnownLocation() async {
    try {
      Position? lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null) {
        return LocationModel(
          latitude: lastPos.latitude,
          longitude: lastPos.longitude,
          accuracy: lastPos.accuracy,
          heading: lastPos.heading,
        );
      }
    } catch (e) {
      debugPrint('[EmergencyService] Last known location failed: $e');
    }
    return null; // Location unavailable (NEVER invent or use Nagpur fallback)
  }

  /// Dedicated function to construct emergency SMS text
  static String buildEmergencySms({
    required String userName,
    required DateTime timestamp,
    double? latitude,
    double? longitude,
  }) {
    final formattedTime = DateFormat('h:mm a').format(timestamp);
    final String locationText;

    if (latitude != null && longitude != null) {
      // Construct Google Maps URL (No API key needed)
      locationText = 'https://maps.google.com/?q=$latitude,$longitude';
    } else {
      locationText = 'Unavailable';
    }

    return '🚨 SafeRoute Emergency Alert\n\n'
        'Name: $userName\n'
        'Time: $formattedTime\n\n'
        'Location:\n$locationText\n\n'
        'Please contact them immediately.\n\n'
        'SafeRoute is not a replacement for emergency services.';
  }

  /// Stop active emergency session and reset UI state
  void stopEmergencySession() {
    _cancellationTimer?.cancel();
    _countdownTimer?.cancel();
    _status = EmergencyStatus.idle;
    _currentContact = null;
    _currentLocation = null;
    _statusMessage = '';
    _smsSendStatusText = '';
    _locationStatusText = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _volumeSub?.cancel();
    _smsStatusSub?.cancel();
    _cancellationTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }
}
