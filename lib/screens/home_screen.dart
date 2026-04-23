import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../theme/app_theme.dart';
import '../services/foreground_service.dart';
import '../services/accessibility_service.dart';
import '../services/subscription_service.dart';
import '../widgets/app_logo.dart';
import 'subscription_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool isAutoAcceptOn = false;
  bool isSubscribed = false;
  String subscriptionStatus = "Checking...";
  RangeValues fareRange = const RangeValues(50, 500);
  List<String> systemLogs = [
    "Waiting for rides...",
    "[18:45] Last Captured Ride: ₹145.00"
  ];
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    // Enable Wakelock by default
    WakelockPlus.enable();
    _checkSubscription();
  }

  Future<void> _checkSubscription() async {
    final status = await SubscriptionService.isSubscribed();
    final expiry = await SubscriptionService.getExpiryStatus();
    setState(() {
      isSubscribed = status;
      subscriptionStatus = expiry;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleAutoAccept(bool value) {
    setState(() {
      isAutoAcceptOn = value;
      if (isAutoAcceptOn) {
        ForegroundService.start();
        systemLogs.insert(0, "[${DateTime.now().hour}:${DateTime.now().minute}] Auto-Accept Activated");
      } else {
        ForegroundService.stop();
        systemLogs.insert(0, "[${DateTime.now().hour}:${DateTime.now().minute}] Auto-Accept Deactivated");
      }
      _syncSettings();
    });
  }

  void _syncSettings() {
    AccessibilityService.updateSettings(
      minFare: fareRange.start,
      maxFare: fareRange.end,
      isEnabled: isAutoAcceptOn,
    );
  }

  Future<void> _launchMaps() async {
    const url = 'https://www.google.com/maps';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              border: isAutoAcceptOn
                  ? Border.all(
                      color: AppTheme.brightGreen.withOpacity(0.3 + (_pulseController.value * 0.4)),
                      width: 8,
                    )
                  : null,
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                const Center(child: AppLogo(size: 100)),
                const Center(
                  child: Text(
                    "VERSION 5.0 - PREMIUM",
                    style: TextStyle(color: AppTheme.safetyOrange, fontSize: 10),
                  ),
                ),
                const SizedBox(height: 20),
                _buildAutoAcceptToggle(),
                const SizedBox(height: 10),
                _buildSubscriptionBanner(),
                const SizedBox(height: 24),
                _buildFareControlCard(),
                const SizedBox(height: 10),
                _buildPermissionButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAutoAcceptToggle() {
    return GestureDetector(
      onTap: () {
        if (!isSubscribed) {
          _showUpgradePrompt();
          return;
        }
        _toggleAutoAccept(!isAutoAcceptOn);
      },
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: isSubscribed 
            ? (isAutoAcceptOn ? AppTheme.brightGreen.withOpacity(0.1) : AppTheme.darkGrey)
            : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSubscribed
              ? (isAutoAcceptOn ? AppTheme.brightGreen : Colors.grey[800]!)
              : Colors.white10,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isAutoAcceptOn ? "AUTO-ACCEPT: ON" : "AUTO-ACCEPT: OFF",
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isSubscribed
                        ? (isAutoAcceptOn ? AppTheme.brightGreen : Colors.grey[500])
                        : Colors.grey[700],
                    ),
                  ),
                  Text(
                    isAutoAcceptOn ? "स्वतः स्वीकार: चालू" : "स्वतः स्वीकार: बंद",
                    style: GoogleFonts.hind(
                      fontSize: 18,
                      color: isSubscribed
                        ? (isAutoAcceptOn ? AppTheme.brightGreen.withOpacity(0.8) : Colors.grey[600])
                        : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            if (!isSubscribed)
              const Positioned(
                top: 15,
                right: 15,
                child: Icon(Icons.lock_rounded, color: Colors.grey, size: 20),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionBanner() {
    return InkWell(
      onTap: _showUpgradePrompt,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSubscribed ? Icons.check_circle_rounded : Icons.info_outline_rounded,
              size: 14,
              color: isSubscribed ? AppTheme.brightGreen : AppTheme.safetyOrange,
            ),
            const SizedBox(width: 8),
            Text(
              subscriptionStatus,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: isSubscribed ? Colors.grey : AppTheme.safetyOrange,
                fontWeight: isSubscribed ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            if (!isSubscribed) ...[
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 10, color: AppTheme.safetyOrange),
            ],
          ],
        ),
      ),
    );
  }

  void _showUpgradePrompt() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
    );
    if (result == true) {
      _checkSubscription();
    }
  }

  Widget _buildFareControlCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "FARE CONTROL",
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    letterSpacing: 1.2,
                    color: AppTheme.safetyOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "किराया नियंत्रण",
                  style: GoogleFonts.hind(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                "₹${fareRange.start.round()} - ₹${fareRange.end.round()}",
                style: GoogleFonts.outfit(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            RangeSlider(
              values: fareRange,
              min: 20,
              max: 1000,
              divisions: 98,
              onChanged: (values) {
                setState(() => fareRange = values);
                _syncSettings();
              },
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [50, 100, 200].map((value) => _buildQuickSelectButton(value)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionButton() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: TextButton.icon(
        onPressed: AccessibilityService.openSettings,
        icon: const Icon(Icons.settings_accessibility, color: AppTheme.brightGreen, size: 22),
        label: Text(
          "GRANT ACCESSIBILITY PERMISSION\nअनुमति दें",
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: AppTheme.brightGreen,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: AppTheme.brightGreen.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppTheme.brightGreen.withOpacity(0.3)),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSelectButton(int value) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          fareRange = RangeValues(value.toDouble(), fareRange.end);
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.darkGrey,
        foregroundColor: AppTheme.safetyOrange,
        side: const BorderSide(color: AppTheme.safetyOrange),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text("₹$value"),
    );
  }
}
