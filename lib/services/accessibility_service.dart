import 'package:flutter/services.dart';

class AccessibilityService {
  static const _channel = MethodChannel('com.swayam.swayam_universal/settings');

  static Future<void> updateSettings({
    required double minFare,
    required double maxFare,
    required bool isEnabled,
  }) async {
    try {
      await _channel.invokeMethod('updateSettings', {
        'minFare': minFare,
        'maxFare': maxFare,
        'isEnabled': isEnabled,
      });
    } on PlatformException catch (e) {
      print("Sync Error: ${e.message}");
    }
  }

  static Future<void> openSettings() async => await _channel.invokeMethod('openAccessibilitySettings');
  
  static Future<bool> isEnabled() async => await _channel.invokeMethod('isAccessibilityEnabled');

  static Future<bool> isIgnoringBatteryOptimizations() async => await _channel.invokeMethod('isIgnoringBatteryOptimizations');

  static Future<void> requestIgnoreBatteryOptimizations() async => await _channel.invokeMethod('requestIgnoreBatteryOptimizations');

  static Future<bool> isOverlayPermissionGranted() async => await _channel.invokeMethod('checkOverlayPermission');

  static Future<void> requestOverlayPermission() async => await _channel.invokeMethod('requestOverlayPermission');
}
