import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class TermsOverlay extends StatelessWidget {
  final VoidCallback onAccepted;

  const TermsOverlay({super.key, required this.onAccepted});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.9),
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E26),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppTheme.safetyOrange.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  children: [
                    const Icon(Icons.gavel_rounded, color: AppTheme.safetyOrange, size: 40),
                    const SizedBox(height: 10),
                    Text(
                      "Terms & Conditions",
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "Please read and accept to continue using Swayam",
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _section("1. Automation Disclosure", 
                        "Swayam Universal uses Android Accessibility Services to automate ride acceptance on third-party apps like Uber, Ola, and Rapido. By using this app, you understand that automation is running on your behalf."),
                      _section("2. Data & Privacy", 
                        "The app reads screen content solely to detect fare amounts and accept buttons. We do NOT store, upload, or share any personal data, messages, or sensitive information from other apps."),
                      _section("3. Subscriptions", 
                        "Payments are processed via Cashfree. Subscriptions are non-refundable. Each plan (Starter, Daily, Monthly) provides access for the specified duration from the time of purchase."),
                      _section("4. Liability", 
                        "Swayam is a tool for driver convenience. We are not responsible for any account suspensions or technical issues on external ride-hailing platforms resulting from the use of automation."),
                      _section("5. Battery & Performance", 
                        "Running background automation requires significant battery power. We recommend keeping your device charged while using the active engine."),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(25.0),
                child: ElevatedButton(
                  onPressed: () async {
                    await AuthService.acceptTerms();
                    onAccepted();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.safetyOrange,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text("I AGREE & CONTINUE", 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.safetyOrange, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 5),
          Text(content, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}
