import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Communication channel between Flutter Dart and Native Android SmsManager & Volume Listener
class NativeEmergencyChannel {
  static final NativeEmergencyChannel instance = NativeEmergencyChannel._internal();
  factory NativeEmergencyChannel() => instance;

  NativeEmergencyChannel._internal() {
    try {
      _channel.setMethodCallHandler(_handleMethodCall);
    } catch (e) {
      debugPrint('[NativeEmergencyChannel] Channel setup warning: $e');
    }
  }


  static const MethodChannel _channel = MethodChannel('com.saferoute.ai/emergency');

  final StreamController<void> _volumeTriggerController = StreamController<void>.broadcast();
  Stream<void> get onVolumeTrigger => _volumeTriggerController.stream;

  final StreamController<Map<String, dynamic>> _smsStatusController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onSmsStatusUpdate => _smsStatusController.stream;

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onVolumeEmergencyTriggered':
        debugPrint('[NativeEmergencyChannel] Volume button emergency trigger received');
        _volumeTriggerController.add(null);
        break;
      case 'onSmsStatusUpdated':
        if (call.arguments is Map) {
          final map = Map<String, dynamic>.from(call.arguments as Map);
          debugPrint('[NativeEmergencyChannel] SMS status update: $map');
          _smsStatusController.add(map);
        }
        break;
      default:
        debugPrint('[NativeEmergencyChannel] Unhandled native method: ${call.method}');
    }
  }

  /// Check if SEND_SMS permission is granted
  Future<bool> checkSmsPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      final bool granted = await _channel.invokeMethod('checkSmsPermission') ?? false;
      return granted;
    } on PlatformException catch (e) {
      debugPrint('[NativeEmergencyChannel] Error checking SMS permission: $e');
      return false;
    }
  }

  /// Request SEND_SMS permission from Android
  Future<bool> requestSmsPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      final bool granted = await _channel.invokeMethod('requestSmsPermission') ?? false;
      return granted;
    } on PlatformException catch (e) {
      debugPrint('[NativeEmergencyChannel] Error requesting SMS permission: $e');
      return false;
    }
  }

  /// Send emergency SMS natively via Android SmsManager
  Future<Map<String, dynamic>> sendEmergencySms({
    required String phoneNumber,
    required String message,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      debugPrint('[NativeEmergencyChannel] Non-Android platform fallback SMS trigger for: $phoneNumber');
      return {'status': 'SENT', 'message': 'Simulated send on non-Android platform'};
    }

    try {
      final res = await _channel.invokeMethod('sendEmergencySms', {
        'phoneNumber': phoneNumber,
        'message': message,
      });
      if (res is Map) {
        return Map<String, dynamic>.from(res);
      }
      return {'status': 'SENT'};
    } on PlatformException catch (e) {
      debugPrint('[NativeEmergencyChannel] Exception during sendEmergencySms: $e');
      return {'status': 'SEND_FAILED', 'error': e.message ?? e.code};
    }
  }

  /// Open App Settings if permission permanently denied
  Future<void> openAppSettings() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('openAppSettings');
    } catch (e) {
      debugPrint('[NativeEmergencyChannel] Error opening app settings: $e');
    }
  }
}
