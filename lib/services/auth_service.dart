import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;

  static Future<void> loginWithPhone({
    required String phone,
    required Function(String) onCodeSent,
    required Function(String) onAutoVerify,
    required Function(String) onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        onAutoVerify("Success");
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? "Verification failed");
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  static Future<void> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await _auth.signInWithCredential(credential);
    await updateDeviceId();
  }

  static Future<void> logout() async => await _auth.signOut();

  // --- UNIQUE DIGITAL FINGERPRINT ---

  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('unique_device_id');
    
    if (deviceId == null) {
      // Generate a new unique ID only once
      deviceId = const Uuid().v4();
      await prefs.setString('unique_device_id', deviceId);
    }
    
    return deviceId;
  }

  static Future<bool> hasDeviceConflict() async {
    if (currentUser == null) return false;
    try {
      final doc = await _db.collection('users').doc(currentUser!.uid).get(const GetOptions(source: Source.server));
      if (!doc.exists) return false;

      final storedDeviceId = doc.data()?['deviceId'] as String?;
      if (storedDeviceId == null) return false;

      final currentDeviceId = await getDeviceId();
      return storedDeviceId != currentDeviceId;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateDeviceId() async {
    if (currentUser == null) return false;
    try {
      final id = await getDeviceId();
      await _db.collection('users').doc(currentUser!.uid).set({
        'deviceId': id,
        'phone': currentUser!.phoneNumber,
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isUserBanned() async {
    if (currentUser == null) return false;
    final doc = await _db.collection('users').doc(currentUser!.uid).get(const GetOptions(source: Source.server));
    return doc.data()?['isBanned'] == true;
  }

  static Stream<DocumentSnapshot> userStream() {
    if (currentUser == null) return const Stream.empty();
    return _db.collection('users').doc(currentUser!.uid).snapshots();
  }

  static Future<void> acceptTerms() async {
    if (currentUser == null) return;
    await _db.collection('users').doc(currentUser!.uid).set({
      'termsAccepted': true,
      'termsAcceptedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> sendDetailedSupportTicket(String category, String message) async {
    if (currentUser == null) return;
    await _db.collection('support_tickets').add({
      'userId': currentUser!.uid,
      'userPhone': currentUser!.phoneNumber,
      'category': category,
      'message': message,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'messages': [
        {
          'text': message,
          'sender': 'user',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }
      ],
    });
  }

  static Future<void> addMessageToTicket(String ticketId, String text) async {
    await _db.collection('support_tickets').doc(ticketId).update({
      'messages': FieldValue.arrayUnion([
        {
          'text': text,
          'sender': 'user',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }
      ]),
      'status': 'pending',
    });
  }

  static Stream<QuerySnapshot> getMyTickets() {
    if (currentUser == null) return const Stream.empty();
    return _db.collection('support_tickets')
        .where('userId', isEqualTo: currentUser!.uid)
        .snapshots();
  }

  static Future<void> sendSupportTicket(String message) async {
    await sendDetailedSupportTicket("Other", message);
  }

  static Future<DateTime?> getSubscriptionExpiry() async {
    if (currentUser == null) return null;
    final doc = await _db.collection('users').doc(currentUser!.uid).get(const GetOptions(source: Source.server));
    if (!doc.exists) return null;
    final expiry = doc.data()?['expiry'] as Timestamp?;
    return expiry?.toDate();
  }
}
