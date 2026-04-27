package com.swayam.swayam_universal

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.provider.Settings
import android.net.Uri
import android.os.PowerManager
import android.content.Context
import android.view.accessibility.AccessibilityManager
import android.accessibilityservice.AccessibilityServiceInfo

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.swayam.swayam_universal/settings"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateSettings" -> {
                    val min = (call.argument<Any>("minFare") as? Number)?.toDouble() ?: 0.0
                    val max = (call.argument<Any>("maxFare") as? Number)?.toDouble() ?: 1000.0
                    val enabled = call.argument<Boolean>("isEnabled") ?: false
                    RideAcceptanceService.minFare = min
                    RideAcceptanceService.maxFare = max
                    RideAcceptanceService.isAutoAcceptEnabled = enabled
                    result.success(null)
                }
                "openAccessibilitySettings" -> {
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(null)
                }
                "isAccessibilityEnabled" -> {
                    val am = getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
                    val enabledServices = am.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_GENERIC)
                    val isEnabled = enabledServices.any { it.resolveInfo.serviceInfo.packageName == packageName }
                    result.success(isEnabled)
                }
                "isIgnoringBatteryOptimizations" -> {
                    val pm = getSystemService(POWER_SERVICE) as PowerManager
                    result.success(pm.isIgnoringBatteryOptimizations(packageName))
                }
                "requestIgnoreBatteryOptimizations" -> {
                    val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                    intent.data = Uri.parse("package:$packageName")
                    startActivity(intent)
                    result.success(null)
                }
                "checkOverlayPermission" -> {
                    result.success(Settings.canDrawOverlays(this))
                }
                "requestOverlayPermission" -> {
                    val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
                    intent.data = Uri.parse("package:$packageName")
                    startActivity(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
