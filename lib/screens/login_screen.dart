import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  String _verificationId = "";
  bool _isOTPSent = false;
  bool _isLoading = false;

  void _sendOTP() async {
    setState(() => _isLoading = true);
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showError("Please enter phone number");
      setState(() => _isLoading = false);
      return;
    }

    // Add +91 if missing
    final fullPhone = phone.startsWith("+") ? phone : "+91$phone";

    await AuthService.loginWithPhone(
      phone: fullPhone,
      onCodeSent: (id) {
        setState(() {
          _verificationId = id;
          _isOTPSent = true;
          _isLoading = false;
        });
      },
      onAutoVerify: (status) {
        // Auto-fill success! Navigation happens via main.dart
      },
      onError: (msg) {
        _showError(msg);
        setState(() => _isLoading = false);
      },
    );
  }

  void _verifyOTP() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.verifyOTP(
        verificationId: _verificationId,
        smsCode: _otpController.text.trim(),
      );
      // Navigation is handled by auth listener in main.dart
    } catch (e) {
      _showError("Invalid OTP. Try again.");
    }
    setState(() => _isLoading = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "WELCOME",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
              const Text("Login to Start Accepting Rides", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 50),
              
              if (!_isOTPSent) ...[
                _buildInput("Mobile Number", _phoneController, Icons.phone, prefix: "+91 "),
                const SizedBox(height: 20),
                _buildButton(_isLoading ? "SENDING..." : "GET OTP", _sendOTP),
              ] else ...[
                _buildInput("Enter 6-Digit OTP", _otpController, Icons.lock_outline),
                const SizedBox(height: 20),
                _buildButton(_isLoading ? "VERIFYING..." : "LOGIN NOW", _verifyOTP),
                TextButton(
                  onPressed: () => setState(() => _isOTPSent = false),
                  child: const Text("Edit Phone Number", style: TextStyle(color: Colors.grey)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, IconData icon, {String? prefix}) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.safetyOrange),
        prefixText: prefix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  Widget _buildButton(String label, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.safetyOrange,
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}
