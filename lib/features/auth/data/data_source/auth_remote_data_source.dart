import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../request/send_otp_request.dart';
import '../response/send_otp_response.dart';

class AuthRemoteDataSource {
  final String _apiKey = "c735413907079a974249eaa7fb107ebd";
  final String _sender = "TweetTest";
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<String, String> _otpStorage = {};
  final Map<String, DateTime> _lastSentTime = {};

  /// Send OTP using TweetSMS provider
  Future<SendOtpResponse> sendOtp(SendOtpRequest request) async {
    final now = DateTime.now();

    // Limit OTP sending to once per minute
    if (_lastSentTime.containsKey(request.phone)) {
      final diff = now.difference(_lastSentTime[request.phone]!);
      if (diff.inSeconds < 60) {
        return SendOtpResponse(
          success: false,
          message: "Please wait before sending another OTP.",
        );
      }
    }

    final otp = (100000 + Random().nextInt(900000)).toString();
    final hashedOtp = sha256.convert(utf8.encode(otp)).toString();

    final message = """
[Offline SMS]
رمز التحقق الخاص بك هو: $otp

لا تشارك هذا الرمز مع أي شخص.
""";
    final url = Uri.parse(
      "https://tweetsms.ps/api.php?comm=sendsms&api_key=$_apiKey&to=${request.phone}&message=$message&sender=$_sender",
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200 && response.body.contains("1")) {
        _otpStorage[request.phone] = hashedOtp;
        _lastSentTime[request.phone] = now;
        return SendOtpResponse(success: true, message: "OTP sent successfully");
      } else {
        return SendOtpResponse(
          success: false,
          message: "Failed to send OTP: ${response.body}",
        );
      }
    } catch (e) {
      return SendOtpResponse(success: false, message: e.toString());
    }
  }

  /// Verify OTP and handle user creation or login in Firestore
  Future<Map<String, dynamic>?> verifyOtp(String phone, String otp, String name) async {
    final hashedInput = sha256.convert(utf8.encode(otp)).toString();
    final storedOtp = _otpStorage[phone];

    if (storedOtp != hashedInput) return null;

    _otpStorage.remove(phone);

    // Canonical phone format
    final canonical = phone.replaceAll("+", "").replaceAll(RegExp(r'^0+'), "");
    final userRef = _firestore.collection("users").doc(canonical);
    final docSnapshot = await userRef.get();

    if (docSnapshot.exists) {
      return docSnapshot.data();
    }

    final newUser = {
      "name": name,
      "phone": "+$phone",
      "phoneCanon": canonical,
      "bio": "",
      "settings": {
        "autoDownloadMedia": true,
        "fontSize": 16,
        "notificationsEnabled": true,
        "groupNotifications": true,
        "readReceipts": true,
        "soundEnabled": true,
        "lastSeenPrivacy": "everyone",
        "profilePhotoPrivacy": "everyone",
      },
      "isVerified": true,
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    };

    await userRef.set(newUser);
    return newUser;
  }
}
