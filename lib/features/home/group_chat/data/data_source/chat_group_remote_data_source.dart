import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../../../../core/util/snack_bar.dart';
import '../request/send_message_request.dart';
import '../response/message_response.dart';

class ChatGroupRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();

// أصلح دالة getMessages
  Stream<List<MessageResponse>> getMessages(String groupId, String currentUserId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
      // تحديث الحالات عند جلب الرسائل
      await _updateMessageStatusesOnReceive(snapshot, groupId, currentUserId);

      // معالجة آمنة للبيانات
      final messages = <MessageResponse>[];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final message = MessageResponse.fromJson(_safeCastMap(data), doc.id);
          messages.add(message);
        } catch (e) {
          print('❌ Error parsing message ${doc.id}: $e');
          print('📄 Message data: ${doc.data()}');
        }
      }
      return messages;
    });
  }

// دالة مساعدة للتحويل الآمن
  Map<String, dynamic> _safeCastMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is Map<dynamic, dynamic>) {
      return data.cast<String, dynamic>();
    } else {
      print('⚠️ Unexpected data type: ${data.runtimeType}');
      return {};
    }
  }

// أصلح دالة تحديث الحالات
  Future<void> _updateMessageStatusesOnReceive(
      QuerySnapshot snapshot, String groupId, String currentUserId) async {
    try {
      final batch = _firestore.batch();
      bool hasConnection = await _checkInternetConnection();
      bool hasUpdates = false;

      for (var doc in snapshot.docs) {
        try {
          final data = _safeCastMap(doc.data());
          final status = data['status'];

          // معالجة آمنة للحالة
          Map<String, dynamic> statusMap = {};
          if (status is Map<String, dynamic>) {
            statusMap = status;
          } else if (status is Map<dynamic, dynamic>) {
            statusMap = status.cast<String, dynamic>();
          }

          final userStatus = statusMap[currentUserId]?.toString();

          // إذا كانت الرسالة من مستخدم آخر ولم تكن مقروءة
          if (data['senderId'] != currentUserId && userStatus != 'seen') {
            final newStatus = hasConnection ? 'delivered' : 'pending';
            if (userStatus != newStatus) {
              final ref = _firestore
                  .collection('groups')
                  .doc(groupId)
                  .collection('messages')
                  .doc(doc.id);
              batch.update(ref, {'status.$currentUserId': newStatus});
              hasUpdates = true;
            }
          }
        } catch (e) {
          print('❌ Error updating status for message ${doc.id}: $e');
        }
      }

      if (hasUpdates) {
        await batch.commit();
        print('✅ Updated message statuses');
      }
    } catch (e) {
      print('❌ Error in _updateMessageStatusesOnReceive: $e');
    }
  }
  // /// ✅ تحديث حالات الرسائل عند الاستلام
  // Future<void> _updateMessageStatusesOnReceive(
  //     QuerySnapshot snapshot, String groupId, String currentUserId) async {
  //   try {
  //     final batch = _firestore.batch();
  //     bool hasConnection = await _checkInternetConnection();
  //     bool hasUpdates = false;
  //
  //     for (var doc in snapshot.docs) {
  //       final message = doc.data() as Map<String, dynamic>;
  //       final status = message['status'] as Map<String, dynamic>? ?? {};
  //       final userStatus = status[currentUserId]?.toString();
  //
  //       // إذا كانت الرسالة من مستخدم آخر ولم تكن مقروءة
  //       if (message['senderId'] != currentUserId && userStatus != 'seen') {
  //         final newStatus = hasConnection ? 'delivered' : 'pending';
  //         if (userStatus != newStatus) {
  //           final ref = _firestore
  //               .collection('groups')
  //               .doc(groupId)
  //               .collection('messages')
  //               .doc(doc.id);
  //           batch.update(ref, {'status.$currentUserId': newStatus});
  //           hasUpdates = true;
  //         }
  //       }
  //     }
  //
  //     if (hasUpdates) {
  //       await batch.commit();
  //     }
  //   } catch (e) {
  //     print('Error updating message statuses: $e');
  //   }
  // }

  /// ✅ التحقق من الاتصال بالإنترنت
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  /// ✅ إرسال رسالة مع تحسين الحالات الأولية
  Future<void> sendMessage(SendMessageRequest request) async {
    try {
      final groupDoc = await _firestore.collection('groups').doc(request.groupId).get();
      if (!groupDoc.exists) throw Exception('المجموعة غير موجودة');

      final members = List<String>.from(groupDoc.data()?['members'] ?? []);
      final Map<String, String> initialStatus = {};

      bool hasConnection = await _checkInternetConnection();

      for (var memberId in members) {
        if (memberId != request.senderId) {
          initialStatus[memberId] = hasConnection ? 'pending' : 'failed';
        } else {
          initialStatus[memberId] = 'sent';
        }
      }

      final messageData = request.toJson();
      messageData['status'] = initialStatus;
      messageData['reactions'] = {}; // إضافة التفاعلات
      messageData['mentions'] = request.mentions;

      await _firestore
          .collection('groups')
          .doc(request.groupId)
          .collection('messages')
          .add(messageData);

      // تحديث آخر رسالة في المجموعة
      await _firestore.collection('groups').doc(request.groupId).update({
        'lastMessage': request.content,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': request.senderId,
      });

    } catch (e) {
      AppSnackbar.error('حدث خطأ أثناء إرسال الرسالة', englishMessage: 'Error sending message');
      rethrow;
    }
  }

  /// ✅ إضافة التفاعلات على الرسائل
  Future<void> toggleMessageReaction({
    required String groupId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      final messageRef = _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .doc(messageId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(messageRef);
        if (!snapshot.exists) return;

        final reactions = Map<String, dynamic>.from(snapshot.get('reactions') ?? {});
        final userReactions = List<String>.from(reactions[userId] ?? []);

        if (userReactions.contains(emoji)) {
          userReactions.remove(emoji);
        } else {
          userReactions.add(emoji);
        }

        if (userReactions.isEmpty) {
          reactions.remove(userId);
        } else {
          reactions[userId] = userReactions;
        }

        transaction.update(messageRef, {'reactions': reactions});
      });
    } catch (e) {
      AppSnackbar.error('فشل في إضافة التفاعل', englishMessage: 'Error adding reaction');
      rethrow;
    }
  }

  /// ✅ حذف الرسالة مع التحقق من الصلاحيات
  Future<void> deleteMessage({
    required String groupId,
    required String messageId,
    required String userId,
    required bool isAdmin,
  }) async {
    try {
      final messageDoc = await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .get();

      if (!messageDoc.exists) throw Exception('الرسالة غير موجودة');

      final messageData = messageDoc.data()!;
      final senderId = messageData['senderId'] as String;

      // التحقق من الصلاحيات: يمكن للمرسل أو الأدمن فقط الحذف
      if (senderId != userId && !isAdmin) {
        throw Exception('ليس لديك صلاحية لحذف هذه الرسالة');
      }

      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .delete();

    } catch (e) {
      AppSnackbar.error('فشل في حذف الرسالة', englishMessage: 'Error deleting message');
      rethrow;
    }
  }

  /// ✅ مراقبة حالة الاتصال للمستخدمين
  Stream<Map<String, dynamic>> getUserConnectionStatus(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return {'isOnline': false, 'lastSeen': DateTime.now()};

      final data = snapshot.data()!;
      return {
        'isOnline': data['isOnline'] ?? false,
        'lastSeen': (data['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
      };
    });
  }

  /// ✅ تحديث حالة الاتصال للمستخدم
  Future<void> updateUserConnectionStatus(String userId, bool isOnline) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating user status: $e');
    }
  }

  /// ✅ تحديث حالة الرسالة
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

  /// ✅ Send SMS using TweetSMS API
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