import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // 1. Request Permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) print('User granted permission');
      
      // 2. Get the token and save it to Firestore
      await _saveTokenToFirestore();
    } else {
      if (kDebugMode) print('User declined or has not accepted permission');
    }
  }

  static Future<void> _saveTokenToFirestore() async {
    final user = AuthService.currentUser;
    if (user == null) return;

    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        if (kDebugMode) print('FCM Token saved successfully');
      }
    } catch (e) {
      if (kDebugMode) print('Error saving FCM token: $e');
    }
  }
}
