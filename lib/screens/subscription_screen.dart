import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';
import '../theme/app_theme.dart';
import '../services/subscription_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final List<Map<String, dynamic>> plans = [
    {
      'name': 'STARTER PLAN (1 Day)',
      'hindi': 'स्टार्टर प्लान (1 दिन)',
      'price': '₹20',
      'days': 1,
      'isPopular': false,
    },
    {
      'name': 'ECONOMY PLAN (15 Days)',
      'hindi': 'इकोनॉमी प्लान (15 दिन)',
      'price': '₹99',
      'days': 15,
      'isPopular': false,
    },
    {
      'name': 'PREMIUM MONTHLY (30 Days)',
      'hindi': 'प्रीमियम मंथली (30 दिन)',
      'price': '₹199',
      'days': 30,
      'isPopular': true,
    },
  ];

  Future<Map<String, dynamic>?> _fetchPaymentSession(String amount) async {
    try {
      // Clean the amount string (remove ₹)
      final cleanAmount = amount.replaceAll('₹', '').trim();
      
      // --- PRODUCTION SETUP ---
      // 1. Host your 'backend' folder on Render.com or Railway.app
      // 2. Paste the URL they give you here:
      final String cloudUrl = "https://auto-rides-accept.onrender.com"; 
      
      final response = await http.post(
        Uri.parse("$cloudUrl/create-order"), 
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "amount": double.parse(cleanAmount).toStringAsFixed(2),
          "customerId": "driver_${DateTime.now().millisecondsSinceEpoch}",
          "customerPhone": "9999999999"
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Backend Response Data: $data");
        return {
          "payment_session_id": data["payment_session_id"],
          "order_id": data["order_id"]
        };
      } else {
        print("Backend Error Code: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Backend Error: ${response.statusCode}. Please check Render logs.")),
        );
      }
    } catch (e) {
      print("Connection Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connection Failed: $e")),
      );
    }
    return null; 
  }

  void _handlePayment(int days, String amount) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.safetyOrange)),
    );

    // 1. Get the session details from your server
    Map<String, dynamic>? sessionData = await _fetchPaymentSession(amount);
    Navigator.pop(context); // Close loading

    if (sessionData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment Server is waking up... Please try again in 30 seconds.")),
      );
      return;
    }

    // 2. Start Real Cashfree Checkout
    try {
      var session = CFSessionBuilder()
          .setEnvironment(CFEnvironment.SANDBOX)
          .setPaymentSessionId(sessionData["payment_session_id"])
          .setOrderId(sessionData["order_id"])
          .build();

      var paymentGatewayService = CFPaymentGatewayService();
      
      paymentGatewayService.setCallback((String orderId) async {
          // PAYMENT SUCCESS!
          await SubscriptionService.activateSubscription(days);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Payment Successful! Plan Active."), backgroundColor: AppTheme.brightGreen),
            );
            Navigator.pop(context, true);
          }
      }, (CFErrorResponse errorResponse, String orderId) {
          // PAYMENT FAILED
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Payment Failed: ${errorResponse.getMessage()}"), backgroundColor: Colors.red),
          );
      });

      var webCheckoutPayment = CFWebCheckoutPaymentBuilder()
          .setSession(session)
          .build();
      paymentGatewayService.doPayment(webCheckoutPayment);
    } catch (e) {
      print("Cashfree Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.oledBlack,
      appBar: AppBar(
        title: Text("UPGRADE / अपग्रेड", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.stars_rounded, size: 80, color: AppTheme.safetyOrange),
            const SizedBox(height: 20),
            Text(
              "UNLOCK ALL FEATURES",
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              "सभी सुविधाओं को अनलॉक करें",
              style: GoogleFonts.hind(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ...plans.map((plan) => _buildPlanCard(plan)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.darkGrey,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: plan['isPopular'] ? AppTheme.safetyOrange : Colors.white10,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan['name'],
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    plan['hindi'],
                    style: GoogleFonts.hind(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    plan['price'],
                    style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.safetyOrange),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _handlePayment(plan['days'], plan['price']),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.safetyOrange,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text("BUY / खरीदें", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
