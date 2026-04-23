package com.example.auto_rides_accept

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.provider.Settings

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.auto_rides_accept/settings"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateSettings" -> {
                    val min = call.argument<Double>("minFare") ?: 0.0
                    val max = call.argument<Double>("maxFare") ?: 1000.0
                    val enabled = call.argument<Boolean>("isEnabled") ?: false
                    
                    RideAcceptanceService.minFare = min
                    RideAcceptanceService.maxFare = max
                    RideAcceptanceService.isAutoAcceptEnabled = enabled
                    result.success(null)
                }
                "openAccessibilitySettings" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    startActivity(intent)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
