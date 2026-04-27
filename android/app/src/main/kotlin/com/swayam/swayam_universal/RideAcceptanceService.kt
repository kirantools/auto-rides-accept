package com.swayam.swayam_universal

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.util.Log

class RideAcceptanceService : AccessibilityService() {

    companion object {
        var minFare: Double = 0.0
        var maxFare: Double = 1000.0
        var isAutoAcceptEnabled: Boolean = false
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (!isAutoAcceptEnabled) return
        
        // 1. Scan the main active window
        rootInActiveWindow?.let { 
            processWindow(it)
            it.recycle()
        }

        // 2. Scan all other windows (popups/overlays)
        val currentWindows = windows
        for (window in currentWindows) {
            window.root?.let {
                processWindow(it)
                it.recycle()
            }
        }
    }

    private fun processWindow(root: AccessibilityNodeInfo) {
        if (hasValidFare(root)) {
            Log.d("SwayamUniversal", "Valid Fare Found! Striking Window...")
            findAndClickUniversalAccept(root)
        }
    }

    private fun hasValidFare(node: AccessibilityNodeInfo): Boolean {
        val text = (node.text?.toString() ?: "") + (node.contentDescription?.toString() ?: "")
        
        if (text.contains("₹") || text.contains("Rs")) {
            val fareValue = extractFare(text)
            if (fareValue != null) {
                val isWithinMax = (maxFare >= 1000.0) || (fareValue <= maxFare)
                if (fareValue >= minFare && isWithinMax) {
                    Log.d("SwayamUniversal", "HIT: ₹$fareValue (Min: $minFare, Max: $maxFare)")
                    return true
                }
            }
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            if (child != null) {
                if (hasValidFare(child)) return true
            }
        }
        return false
    }

    private fun extractFare(text: String): Double? {
        return try {
            val regex = Regex("(?:₹|Rs)\\s?([\\d,]+\\.?\\d*)")
            val match = regex.find(text)
            match?.groupValues?.get(1)?.replace(",", "")?.toDouble()
        } catch (e: Exception) { null }
    }

    private fun findAndClickUniversalAccept(node: AccessibilityNodeInfo?) {
        if (node == null) return
        val text = node.text?.toString()?.lowercase() ?: ""
        val desc = node.contentDescription?.toString()?.lowercase() ?: ""

        // 🌍 EXTENDED UNIVERSAL DICTIONARY
        val keywords = listOf(
            "accept", "confirm", "match", "book", "go", "take", "yes",
            "అంగీకరించండి", "అంగీకరించు", "తీసుకోండి", // Telugu
            "स्वीकार", "हाँ", "पुष्टि", "स्वीकारें", // Hindi
            "ஏற்றுக்கொள்", "உறுதிப்படுத்து", "சரி", // Tamil
            "ಒಪ್ಪಿಕೊಳ್ಳಿ", "ಖಚಿತಪಡಿಸಿ", "ಸರಿ" // Kannada
        )

        val isNegative = text.contains("cancel") || text.contains("reject") || 
                         text.contains("decline") || text.contains("no") || text == "-"
        
        val isMatch = keywords.any { text.contains(it) || desc.contains(it) }

        if (isMatch && !isNegative) {
            var target = node
            while (target != null) {
                if (target.isClickable) {
                    target.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                    Log.d("SwayamUniversal", "STRIKE SUCCESS on: ${target.className}")
                    return
                }
                target = target.parent
            }
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            if (child != null) findAndClickUniversalAccept(child)
        }
    }

    override fun onInterrupt() {}
}
