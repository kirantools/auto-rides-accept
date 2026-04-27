import 'package:flutter/material.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../config/app_config.dart';

class PaymentService {
  static final _auth = FirebaseAuth.instance;
  static final _cfService = CFPaymentGatewayService();

  static Future<void> startPayment({
    required BuildContext context,
    required int amount,
    required int days,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw "User not logged in";


      // 1. Get Session ID from your RENDER BACKEND
      final response = await http.post(
        Uri.parse("${AppConfig.backendUrl}/create-order"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "amount": amount,
          "customerId": user.uid,
          "customerPhone": user.phoneNumber ?? "9999999999",
          "days": days
        }),
      );

      if (response.statusCode != 200) {
        throw "SERVER ERROR: ${response.body}";
      }
      
      final data = jsonDecode(response.body);
      if (data['payment_session_id'] == null) {
        throw "SERVER DATA ERROR: Session ID is missing.";
      }
      
      final String? paymentLink = data['payment_link'];
      
      if (paymentLink == null) throw "SERVER ERROR: No Payment Link received.";


      // 2. Launch Browser instead of SDK
      final Uri url = Uri.parse(paymentLink);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        onSuccess("Payment page opened. App will unlock once you pay!");
      } else {
        throw "Could not open browser. Please install Chrome.";
      }

    } catch (e) {
      onError("CRITICAL ERROR: ${e.toString()}");
    }
  }
}
