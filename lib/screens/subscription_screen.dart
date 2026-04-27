import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/payment_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isLoading = false;
  Map<String, dynamic> _pricing = {'plan1': 10, 'plan15': 49, 'plan30': 99};
  bool _fetchingPrices = true;

  @override
  void initState() {
    super.initState();
    _fetchPricing();
  }

  Future<void> _fetchPricing() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('app_settings').doc('pricing').get();
      if (snap.exists) setState(() => _pricing = snap.data()!);
    } finally {
      setState(() => _fetchingPrices = false);
    }
  }

  Future<void> _manualSync() async {
    setState(() => _isLoading = true);
    try {
      final expiry = await AuthService.getSubscriptionExpiry();
      if (expiry != null && expiry.isAfter(DateTime.now())) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Subscription Activated!"), backgroundColor: AppTheme.activeGreen));
          Navigator.pop(context, true);
          return;
        }
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Not activated yet. Please wait 1 minute.")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _buyPlan(int days, dynamic price) async {
    final intPrice = int.tryParse(price.toString()) ?? 10;
    setState(() => _isLoading = true);
    await PaymentService.startPayment(
      context: context, amount: intPrice, days: days,
      onSuccess: (msg) { if (mounted) { setState(() => _isLoading = false); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Check status after paying."))); } },
      onError: (err) { if (mounted) { setState(() => _isLoading = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red)); } },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_fetchingPrices) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.safetyOrange)));
    return Scaffold(
      appBar: AppBar(title: Text("CHOOSE YOUR PLAN", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)), centerTitle: true, backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _buildPlanCard("STARTER", "1 DAY", "₹${_pricing['plan1']}", Colors.blueGrey, () => _buyPlan(1, _pricing['plan1'])),
              const SizedBox(height: 15),
              _buildPlanCard("PRO", "15 DAYS", "₹${_pricing['plan15']}", AppTheme.safetyOrange, () => _buyPlan(15, _pricing['plan15']), isBest: true),
              const SizedBox(height: 15),
              _buildPlanCard("ELITE", "30 DAYS", "₹${_pricing['plan30']}", Colors.purpleAccent, () => _buyPlan(30, _pricing['plan30'])),
              const SizedBox(height: 30),
              ElevatedButton.icon(onPressed: _isLoading ? null : _manualSync, icon: const Icon(Icons.sync), label: const Text("CHECK STATUS"), style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, minimumSize: const Size(double.infinity, 50))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(String name, String duration, String price, Color color, VoidCallback onTap, {bool isBest = false}) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(25), border: Border.all(color: isBest ? color : color.withOpacity(0.3), width: isBest ? 3 : 1)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (isBest) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)), child: const Text("BEST VALUE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black))),
            const SizedBox(height: 5),
            Text(name, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(duration, style: const TextStyle(color: Colors.white70)),
          ]),
          Text(price, style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900)),
        ]),
      ),
    );
  }
}
