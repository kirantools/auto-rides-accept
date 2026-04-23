import 'package:flutter/services.dart';

class AccessibilityService {
  static const _channel = MethodChannel('com.example.auto_rides_accept/settings');

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
      print("Failed to update settings: ${e.message}");
    }
  }

  static Future<void> openSettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } on PlatformException catch (e) {
      print("Failed to open settings: ${e.message}");
    }
  }
}
