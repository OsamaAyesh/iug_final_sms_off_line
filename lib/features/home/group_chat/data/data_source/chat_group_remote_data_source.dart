import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../../../../core/util/snack_bar.dart';
import '../request/send_message_request.dart';
import '../response/message_response.dart';

class ChatGroupRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ Stream messages in real time
  Stream<List<MessageResponse>> getMessages(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => MessageResponse.fromJson(doc.data(), doc.id)).toList());
  }

  /// ✅ Send a new message with initial status for all members
  Future<void> sendMessage(SendMessageRequest request) async {
    try {
      final groupDoc = await _firestore.collection('groups').doc(request.groupId).get();
      if (!groupDoc.exists) throw Exception('المجموعة غير موجودة');

      final members = List<String>.from(groupDoc.data()?['members'] ?? []);
      final Map<String, String> initialStatus = {};
      for (var memberId in members) {
        if (memberId != request.senderId) {
          initialStatus[memberId] = 'pending';
        }
      }

      final messageData = request.toJson();
      messageData['status'] = initialStatus;

      await _firestore
          .collection('groups')
          .doc(request.groupId)
          .collection('messages')
          .add(messageData);
    } catch (e) {
      AppSnackbar.error('حدث خطأ أثناء إرسال الرسالة', englishMessage: 'Error sending message');
      rethrow;
    }
  }

  /// ✅ Update message status
  Future<void> updateMessageStatus({
    required String groupId,
    required String messageId,
    required String userId,
    required String status,
  }) async {
    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .update({'status.$userId': status});
    } catch (e) {
      AppSnackbar.error('فشل تحديث حالة الرسالة', englishMessage: 'Error updating status');
      rethrow;
    }
  }

  /// ✅ Batch update message status
  Future<void> batchUpdateMessageStatus({
    required String groupId,
    required List<String> messageIds,
    required String userId,
    required String status,
  }) async {
    try {
      final batch = _firestore.batch();
      for (var messageId in messageIds) {
        final ref = _firestore
            .collection('groups')
            .doc(groupId)
            .collection('messages')
            .doc(messageId);
        batch.update(ref, {'status.$userId': status});
      }
      await batch.commit();
    } catch (e) {
      AppSnackbar.error('فشل في تحديث حالات متعددة', englishMessage: 'Batch update failed');
      rethrow;
    }
  }

  /// ✅ Get group members
  Future<List<Map<String, dynamic>>> getGroupMembers(String groupId) async {
    try {
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) return [];

      final memberIds = List<String>.from(groupDoc.data()?['members'] ?? []);
      final List<Map<String, dynamic>> members = [];
      for (var memberId in memberIds) {
        final userDoc = await _firestore.collection('users').doc(memberId).get();
        if (userDoc.exists) {
          final userData = Map<String, dynamic>.from(userDoc.data()!);
          userData['userId'] = memberId;
          members.add(userData);
        }
      }
      return members;
    } catch (e) {
      AppSnackbar.error('فشل في تحميل بيانات الأعضاء', englishMessage: 'Error loading members');
      return [];
    }
  }

  /// ✅ Mark messages as seen
  Future<void> markMessagesAsSeen({
    required String groupId,
    required String userId,
  }) async {
    try {
      final snap = await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .where('status.$userId', whereIn: ['pending', 'delivered'])
          .get();

      if (snap.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (var doc in snap.docs) {
        batch.update(doc.reference, {'status.$userId': 'seen'});
      }
      await batch.commit();
    } catch (e) {
      AppSnackbar.warning('حدث خطأ أثناء تحديث حالة القراءة', englishMessage: 'Error marking seen');
    }
  }

  /// ✅ Mark message as delivered
  Future<void> markMessageAsDelivered({
    required String groupId,
    required String messageId,
    required String userId,
  }) async {
    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .update({'status.$userId': 'delivered'});
    } catch (e) {
      AppSnackbar.warning('تعذر تحديث حالة التسليم', englishMessage: 'Error marking delivered');
    }
  }

  /// ✅ Normalize number
  String _normalizePalestinianNumber(String number) {
    number = number.replaceAll('+', '').replaceAll(' ', '');
    if (number.startsWith('970') || number.startsWith('972')) {
      number = '0${number.substring(3)}';
    } else if (!number.startsWith('0')) {
      number = '0$number';
    }
    return number;
  }

  /// ✅ Send SMS using TweetSMS API (updates status only when success)
  // Future<void> sendSmsToUsers(List<String> numbers, String text) async {
  //   const String apiKey = "c735413907079a974249eaa7fb107ebd";
  //   const String senderName = "TweetTest";
  //
  //   if (numbers.isEmpty || text.trim().isEmpty) {
  //     AppSnackbar.warning('قائمة الأرقام فارغة أو الرسالة فارغة', englishMessage: 'Empty numbers or message');
  //     return;
  //   }
  //
  //   AppSnackbar.loading('جارٍ إرسال الرسائل...', englishMessage: 'Sending SMS...');
  //
  //   for (final rawNumber in numbers) {
  //     final number = _normalizePalestinianNumber(rawNumber);
  //
  //     try {
  //       final encodedMessage = Uri.encodeComponent(text);
  //       final url = Uri.parse(
  //         "https://tweetsms.ps/api.php?comm=sendsms"
  //             "&api_key=$apiKey"
  //             "&to=$number"
  //             "&message=$encodedMessage"
  //             "&sender=$senderName",
  //       );
  //
  //       final response = await http.get(url);
  //       final result = response.body.trim();
  //
  //       if (response.statusCode == 200 && result.startsWith("1")) {
  //         AppSnackbar.success('تم إرسال الرسالة إلى $number', englishMessage: 'SMS sent to $number');
  //       } else {
  //         String errorMessage = _mapTweetSmsError(result, number);
  //         AppSnackbar.error(errorMessage, englishMessage: 'Failed to send SMS to $number');
  //       }
  //     } catch (e) {
  //       AppSnackbar.error('حدث خطأ أثناء الإرسال إلى $rawNumber', englishMessage: 'Error sending to $rawNumber');
  //     }
  //   }
  //
  //   AppSnackbar.success('انتهى إرسال جميع الرسائل', englishMessage: 'Finished sending all SMS');
  // }
  Future<Map<String, int>> sendSmsToUsers(String groupId, List<String> numbers, String text) async {
    int successCount = 0;
    int failCount = 0;

    const apiKey = "c735413907079a974249eaa7fb107ebd";
    const senderName = "TweetTest";

    for (final rawNumber in numbers) {
      final number = _normalizePalestinianNumber(rawNumber);

      try {
        final url = Uri.parse(
          "https://tweetsms.ps/api.php?comm=sendsms"
              "&api_key=$apiKey&to=$number&message=${Uri.encodeComponent(text)}&sender=$senderName",
        );

        final response = await http.get(url);
        final result = response.body.trim();

        final isSuccess = response.statusCode == 200 && result.startsWith("1");
        await _firestore
            .collection("groups")
            .doc(groupId)
            .collection("sms_logs")
            .add({
          "phone": number,
          "status": isSuccess ? "success" : "failed",
          "message": isSuccess ? "تم الإرسال بنجاح" : _mapTweetSmsError(result, number),
          "timestamp": FieldValue.serverTimestamp(),
        });

        if (isSuccess) {
          successCount++;
        } else {
          failCount++;
        }
      } catch (e) {
        await _firestore
            .collection("groups")
            .doc(groupId)
            .collection("sms_logs")
            .add({
          "phone": rawNumber,
          "status": "failed",
          "message": e.toString(),
          "timestamp": FieldValue.serverTimestamp(),
        });
        failCount++;
      }
    }

    return {"success": successCount, "failed": failCount};
  }

  /// ✅ Map TweetSMS error codes to readable messages
  String _mapTweetSmsError(String result, String number) {
    if (result.contains("-113")) {
      return "الرصيد غير كافٍ لإرسال الرسالة إلى $number";
    } else if (result.contains("-115")) {
      return "المرسل غير مفعّل (TweetTest)";
    } else if (result.contains("-2")) {
      return "الرقم غير صالح أو غير مدعوم: $number";
    } else if (result.contains("-110")) {
      return "مفتاح API غير صالح أو خطأ في الإعدادات";
    } else if (result.contains("-999")) {
      return "فشل الإرسال من مزود الخدمة إلى $number";
    }
    return "فشل غير معروف أثناء إرسال الرسالة إلى $number";
  }

  /// ✅ Check SMS balance
  Future<void> checkSmsBalance() async {
    const String apiKey = "c735413907079a974249eaa7fb107ebd";
    final url = Uri.parse("https://tweetsms.ps/api.php?comm=chk_balance&api_key=$apiKey");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        AppSnackbar.success("الرصيد المتبقي: ${response.body}", englishMessage: "Balance: ${response.body}");
      } else {
        AppSnackbar.error('فشل في جلب الرصيد', englishMessage: 'Failed to check balance');
      }
    } catch (e) {
      AppSnackbar.error('حدث خطأ أثناء التحقق من الرصيد', englishMessage: 'Error checking balance');
    }
  }
}
