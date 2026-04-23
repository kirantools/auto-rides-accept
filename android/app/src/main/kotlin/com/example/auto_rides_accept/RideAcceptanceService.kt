package com.example.auto_rides_accept

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

        val rootNode = rootInActiveWindow ?: return
        findFareAndAccept(rootNode)
    }

    private fun findFareAndAccept(node: AccessibilityNodeInfo) {
        val text = node.text?.toString() ?: ""
        
        // Look for Rupee symbol and numbers
        if (text.contains("₹")) {
            val fareValue = extractFare(text)
            if (fareValue != null && fareValue >= minFare && fareValue <= maxFare) {
                Log.d("RideAcceptance", "Fare matched: ₹$fareValue. Looking for Accept button...")
                findAndClickAcceptButton(rootInActiveWindow)
            }
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            if (child != null) {
                findFareAndAccept(child)
            }
        }
    }

    private fun extractFare(text: String): Double? {
        return try {
            val regex = Regex("₹\\s?(\\d+)")
            val match = regex.find(text)
            match?.groupValues?.get(1)?.toDouble()
        } catch (e: Exception) {
            null
        }
    }

    private fun findAndClickAcceptButton(node: AccessibilityNodeInfo?) {
        if (node == null) return

        val text = node.text?.toString()?.lowercase() ?: ""
        val contentDesc = node.contentDescription?.toString()?.lowercase() ?: ""

        // Common button labels in ride apps
        if (text.contains("accept") || text.contains("confirm") || text.contains("स्वीकार") ||
            contentDesc.contains("accept") || contentDesc.contains("confirm")) {
            
            if (node.isClickable) {
                node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                Log.d("RideAcceptance", "Clicked Accept button!")
            } else {
                // Try parent if button is not clickable but label is
                var parent = node.parent
                while (parent != null) {
                    if (parent.isClickable) {
                        parent.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                        Log.d("RideAcceptance", "Clicked Parent Accept button!")
                        break
                    }
                    parent = parent.parent
                }
            }
        }

        for (i in 0 until node.childCount) {
            findAndClickAcceptButton(node.getChild(i))
        }
    }

    override fun onInterrupt() {}
}
