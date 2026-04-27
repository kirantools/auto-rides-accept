import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/accessibility_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'subscription_screen.dart';
import 'support_screen.dart';
import '../widgets/terms_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool isRunning = false;
  StreamSubscription? _userSubscription;
  bool isAccessibilityOn = false;
  bool isBatteryOptimized = false;
  bool isOverlayOn = false;
  bool isSubscribed = false;
  DateTime? expiryDate;
  RangeValues fareRange = const RangeValues(20, 1000);
  late AnimationController _pulseController;
  late TextEditingController _minController;
  late TextEditingController _maxController;
  String? _tutorialLink;
  bool _isSwitching = false;
  bool isTermsAccepted = true; // Default true to prevent flicker

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _minController = TextEditingController();
    _maxController = TextEditingController();
    
    WidgetsBinding.instance.addObserver(this);
    _loadAndRefresh();
    _initDeviceLockFlow();
    _checkForUpdates();
    _checkForAnnouncements();
    NotificationService.initialize();
  }

  void _initDeviceLockFlow() async {
    final hasConflict = await AuthService.hasDeviceConflict();
    if (hasConflict) {
      if (!mounted) return;
      _showSwitchDeviceDialog();
    } else {
      await AuthService.updateDeviceId();
      _startRealTimeListener();
    }
  }

  // 🎨 MATCHING SCREENSHOT: SWITCH DEVICE DIALOG
  void _showSwitchDeviceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: const Color(0xFF1E1E26),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Switch Device?", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 15),
                Text(
                  "This account is active on another device. Would you like to switch to this device? The other device will be logged out.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                ),
                const SizedBox(height: 30),
                if (_isSwitching) 
                  const CircularProgressIndicator(color: AppTheme.safetyOrange)
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () { AuthService.logout(); Navigator.pop(context); },
                        child: Text("CANCEL", style: TextStyle(color: Colors.purple[300], fontWeight: FontWeight.bold)),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          setDialogState(() => _isSwitching = true);
                          final success = await AuthService.updateDeviceId();
                          if (success && mounted) {
                            Navigator.pop(context);
                            _startRealTimeListener();
                            _refreshStatus();
                          } else {
                            if (mounted) setDialogState(() => _isSwitching = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.safetyOrange,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Text("SWITCH DEVICE", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startRealTimeListener() {
    _userSubscription = AuthService.userStream().listen((doc) async {
      if (!doc.exists) return;
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return;

      if (data['isBanned'] == true) { _showBannedDialog(); return; }

      // 🛡️ RE-VALIDATE IDENTITY
      final storedId = data['deviceId'] as String?;
      final currentId = await AuthService.getDeviceId();
      if (storedId != null && storedId != currentId) {
        _showLoggedOutDialog();
      }

      final expiry = data['expiry'] as Timestamp?;
      final date = expiry?.toDate();
      final active = date != null && date.isAfter(DateTime.now());

      setState(() {
        expiryDate = date;
        isSubscribed = active;
        isTermsAccepted = data['termsAccepted'] == true;
        if (!isSubscribed && isRunning) {
          isRunning = false;
          _saveSettings();
        }
      });
    });
  }

  // 🎨 MATCHING SCREENSHOT: LOGGED OUT DIALOG
  void _showLoggedOutDialog() {
    _userSubscription?.cancel(); // Stop listening
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E1E26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Logged Out", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 15),
              Text(
                "Your account is being used on another device. You have been logged out.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    AuthService.logout();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.safetyOrange,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBannedDialog() {
    showDialog(context: context, barrierDismissible: false, builder: (context) => AlertDialog(title: const Text("Suspended"), content: const Text("Account suspended."), actions: [ElevatedButton(onPressed: () { AuthService.logout(); Navigator.of(context).pop(); }, child: const Text("OK"))]));
  }

  Future<void> _loadAndRefresh() async {
    await _loadSettings();
    await _refreshStatus();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final min = prefs.getDouble('minFare') ?? 20.0;
      final max = prefs.getDouble('maxFare') ?? 1000.0;
      fareRange = RangeValues(min, max);
      isRunning = prefs.getBool('isRunning') ?? false;
      _minController.text = min.round().toString();
      _maxController.text = max.round().toString();
    });
    _sync();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('minFare', fareRange.start);
    await prefs.setDouble('maxFare', fareRange.end);
    await prefs.setBool('isRunning', isRunning);
    _sync();
  }

  Future<void> _refreshStatus() async {
    final acc = await AccessibilityService.isEnabled();
    final batt = await AccessibilityService.isIgnoringBatteryOptimizations();
    final over = await AccessibilityService.isOverlayPermissionGranted();
    
    final expiry = await AuthService.getSubscriptionExpiry();
    final active = expiry != null && expiry.isAfter(DateTime.now());

    final settingsSnap = await FirebaseFirestore.instance.collection('app_settings').doc('pricing').get();
    String? tutorial;
    if (settingsSnap.exists) tutorial = settingsSnap.data()?['tutorialLink'];

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(AuthService.currentUser?.uid).get();

    setState(() {
      isAccessibilityOn = acc;
      isBatteryOptimized = batt;
      isOverlayOn = over;
      expiryDate = expiry;
      isSubscribed = active;
      _tutorialLink = tutorial;
      isTermsAccepted = userDoc.data()?['termsAccepted'] == true;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshStatus();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _minController.dispose();
    _maxController.dispose();
    _userSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _toggleService(bool value) {
    setState(() => isRunning = value);
    _saveSettings();
  }

  void _sync() {
    AccessibilityService.updateSettings(
      minFare: fareRange.start,
      maxFare: fareRange.end,
      isEnabled: isRunning,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshStatus,
          color: AppTheme.safetyOrange,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 10),
                  const SizedBox(height: 20),
                  _buildMainToggle(),
                  const SizedBox(height: 30),
                  if (_tutorialLink != null && _tutorialLink!.isNotEmpty) ...[
                    _buildTutorialCard(),
                    const SizedBox(height: 30),
                  ],
                  _buildFareCard(),
                  const SizedBox(height: 30),
                  _buildPermissionSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    if (!isTermsAccepted) 
      TermsOverlay(onAccepted: () => setState(() => isTermsAccepted = true)),
  ],
);
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("SWAYAM", style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.safetyOrange, letterSpacing: 2)),
          const Text("UNIVERSAL ENGINE", style: TextStyle(fontSize: 10, letterSpacing: 3, color: Colors.grey, fontWeight: FontWeight.bold)),
        ]),
        Row(children: [
          IconButton(
            onPressed: () {
              Share.share(
                "🚀 Download Swayam Universal - The world's fastest ride-acceptance engine for drivers!\n\nGet it now at: https://swayamuniversal.netlify.app",
                subject: 'Swayam Universal App'
              );
            }, 
            icon: const Icon(Icons.share_rounded, color: AppTheme.safetyOrange)
          ),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SupportScreen())), 
            icon: const Icon(Icons.help_outline, color: AppTheme.safetyOrange)
          ),
          IconButton(onPressed: () => AuthService.logout(), icon: const Icon(Icons.logout, color: Colors.grey)),
        ]),
      ],
    );
  }

  void _showSupportDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Support"),
        content: TextField(controller: controller, maxLines: 4, decoration: InputDecoration(hintText: "Message...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              await AuthService.sendSupportTicket(controller.text.trim());
              if (mounted) Navigator.pop(context);
            },
            child: const Text("SEND"),
          ),
        ],
      ),
    );
  }

  Widget _buildMainToggle() {
    return GestureDetector(
      onTap: () async {
        if (!isSubscribed) { 
          final result = await Navigator.push(context, MaterialPageRoute(builder: (c) => const SubscriptionScreen())); 
          if (result == true) _refreshStatus();
          return; 
        }
        if (!isRunning && (!isAccessibilityOn || !isBatteryOptimized || !isOverlayOn)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("⚠️ PLEASE GRANT ALL PERMISSIONS BEFORE STARTING!"),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        _toggleService(!isRunning);
      },
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: !isSubscribed ? Colors.red.withOpacity(0.1) : (isRunning ? AppTheme.activeGreen.withOpacity(0.1) : AppTheme.darkCard),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: !isSubscribed ? Colors.red.withOpacity(0.5) : (isRunning ? AppTheme.activeGreen : Colors.white10), width: 3),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(!isSubscribed ? "RECHARGE NOW" : (isRunning ? "RUNNING" : "START"), style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: !isSubscribed ? Colors.red : (isRunning ? AppTheme.activeGreen : Colors.grey))),
              if (isSubscribed && expiryDate != null) Text("Expires: ${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFareCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("FARE CONTROL", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.safetyOrange)),
            Text("₹${fareRange.start.round()} - ₹${fareRange.end.round()}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildManualInput("Min", _minController, (v) {
              setState(() => fareRange = RangeValues(v, fareRange.end));
              _saveSettings();
            })),
            const SizedBox(width: 15),
            Expanded(child: _buildManualInput("Max", _maxController, (v) {
              setState(() => fareRange = RangeValues(fareRange.start, v));
              _saveSettings();
            })),
          ]),
          const SizedBox(height: 10),
          RangeSlider(
            values: fareRange, min: 0, max: 1000,
            activeColor: AppTheme.safetyOrange,
            onChanged: (v) {
              setState(() {
                fareRange = v;
                _minController.text = v.start.round().toString();
                _maxController.text = v.end.round().toString();
              });
              _saveSettings();
            },
          ),
        ]),
      ),
    );
  }

  Widget _buildManualInput(String label, TextEditingController controller, Function(double) onSubmitted) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.safetyOrange, fontSize: 12),
        prefixText: "₹",
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onSubmitted: (val) {
        final double? v = double.tryParse(val);
        if (v != null) onSubmitted(v);
      },
    );
  }

  Widget _buildPermissionSection() {
    return Column(children: [
      if (!isAccessibilityOn) _permButton("GRANT ACCESSIBILITY", AccessibilityService.openSettings),
      if (!isBatteryOptimized) _permButton("IGNORE BATTERY OPTIMIZATION", AccessibilityService.requestIgnoreBatteryOptimizations),
      if (!isOverlayOn) _permButton("GRANT OVERLAY PERMISSION", AccessibilityService.requestOverlayPermission),
    ]);
  }

  Widget _permButton(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton(
        onPressed: () async {
          onTap();
          await Future.delayed(const Duration(seconds: 2));
          _refreshStatus();
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.05), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTutorialCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: AppTheme.safetyOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: AppTheme.safetyOrange.withOpacity(0.3))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: AppTheme.safetyOrange, shape: BoxShape.circle), child: const Icon(Icons.play_arrow, color: Colors.black)),
        const SizedBox(width: 15),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("How to use the app?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text("Watch tutorial video.", style: TextStyle(color: Colors.grey, fontSize: 12))])),
        ElevatedButton(onPressed: _launchTutorial, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.safetyOrange, foregroundColor: Colors.black), child: const Text("WATCH")),
      ]),
    );
  }

  void _launchTutorial() async {
    if (_tutorialLink == null) return;
    final url = Uri.parse(_tutorialLink!);
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _checkForUpdates() async {
    final snap = await FirebaseFirestore.instance.collection('app_settings').doc('pricing').get();
    if (!snap.exists) return;
    final data = snap.data()!;
    final reqV = data['requiredVersion'];
    final link = data['updateLink'];
    final info = await PackageInfo.fromPlatform();
    if (info.version != reqV && link != null) _showUpdateDialog(link, reqV);
  }

  void _showUpdateDialog(String link, String v) {
    showDialog(context: context, barrierDismissible: false, builder: (context) => AlertDialog(title: const Text("Update Required"), content: Text("New version ($v) available."), actions: [ElevatedButton(onPressed: () => launchUrl(Uri.parse(link)), child: const Text("UPDATE"))]));
  }

  void _checkForAnnouncements() async {
    final snap = await FirebaseFirestore.instance.collection('app_settings').doc('announcement').get();
    if (snap.exists && snap.data()?['active'] == true) _showAnnouncementDialog(snap.data()?['message']);
  }

  void _showAnnouncementDialog(String msg) {
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text("Announcement"), content: Text(msg), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))]));
  }
}
