import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class SubscriptionService {
  static const String _keyExpiry = 'subscription_expiry';

  static Future<bool> isSubscribed() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryStr = prefs.getString(_keyExpiry);
    if (expiryStr == null) return false;

    final expiryDate = DateTime.parse(expiryStr);
    return DateTime.now().isBefore(expiryDate);
  }

  static Future<void> activateSubscription(int days) async {
    final prefs = await SharedPreferences.getInstance();
    final newExpiry = DateTime.now().add(Duration(days: days));
    await prefs.setString(_keyExpiry, newExpiry.toIso8601String());
  }

  static Future<String> getExpiryStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryStr = prefs.getString(_keyExpiry);
    if (expiryStr == null) return "No active plan";

    final expiryDate = DateTime.parse(expiryStr);
    if (DateTime.now().isAfter(expiryDate)) return "Plan expired";
    final formattedDate = DateFormat("dd/MM/yyyy 'at' hh:mm a").format(expiryDate);
    return "Expires on: $formattedDate";
  }
}
