// المسار: lib/features/home/group_chat/data/data_source/chat_group_remote_data_source.dart

import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../../../../constants/constants/constants.dart';
import '../../../../../core/util/snack_bar.dart';
import '../request/send_message_request.dart';
import '../response/message_response.dart';

class ChatGroupRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ================================
  // ✅ 1. STREAM MESSAGES (مع معالجة الأخطاء)
  // ================================
  Stream<List<MessageResponse>> getMessages(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
      final messages = <MessageResponse>[];

      for (var doc in snapshot.docs) {
        try {
          final message = MessageResponse.fromJson(doc.data(), doc.id);
          messages.add(message);
        } catch (e) {
          print('❌ Error parsing message ${doc.id}: $e');
          print('❌ Message data: ${doc.data()}');
          // ✅ نستمر في تحميل الرسائل الأخرى رغم الخطأ
        }
      }

      return messages;
    }).handleError((error) {
      print('❌ Error in messages stream: $error');
      // ✅ إرجاع قائمة فارغة بدلاً من إلقاء الخطأ
      return <MessageResponse>[];
    });
  }

  // ================================
  // ✅ 2. SEND MESSAGE (مع تحسين معالجة البيانات)
  // ================================
  Future<void> sendMessage(SendMessageRequest request) async {
    try {
      final groupDoc =
      await _firestore.collection('groups').doc(request.groupId).get();

      if (!groupDoc.exists) {
        throw Exception('المجموعة غير موجودة');
      }

      final members = List<String>.from(groupDoc.data()?['participants'] ?? []);

      // ✅ بناء حالة أولية للرسالة بشكل آمن
      final Map<String, dynamic> initialStatus = {};
      for (var memberId in members) {
        if (memberId != request.senderId) {
          initialStatus[memberId] = 'pending';
        } else {
          initialStatus[memberId] = 'sent';
        }
      }

      final messageData = request.toJson();

      // ✅ التأكد من أن الحقول بالأنواع الصحيحة
      messageData['status'] = initialStatus;
      messageData['reactions'] = messageData['reactions'] ?? {};
      messageData['isDeleted'] = messageData['isDeleted'] ?? false;
      messageData['deletedBy'] = messageData['deletedBy'];
      messageData['mentions'] = messageData['mentions'] ?? [];
      messageData['isGroup'] = messageData['isGroup'] ?? true;

      // ✅ إضافة الرسالة
      await _firestore
          .collection('groups')
          .doc(request.groupId)
          .collection('messages')
          .add(messageData);

      // ✅ تحديث آخر رسالة في المجموعة
      await _firestore.collection('groups').doc(request.groupId).update({
        'lastMessage': request.content,
        'lastMessageSender': request.senderId,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      print('❌ Error sending message: $e');
      AppSnackbar.error('حدث خطأ أثناء إرسال الرسالة',
          englishMessage: 'Error sending message: $e');
      rethrow;
    }
  }

  // ================================
  // ✅ 3. GET GROUP MEMBERS (مع معالجة الأخطاء)
  // ================================
  Future<List<Map<String, dynamic>>> getGroupMembers(String groupId) async {
    try {
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) {
        print('❌ Group $groupId does not exist');
        return [];
      }

      final memberIds =
      List<String>.from(groupDoc.data()?['participants'] ?? []);
      final admins = List<String>.from(groupDoc.data()?['admins'] ?? []);

      final List<Map<String, dynamic>> members = [];

      for (var memberId in memberIds) {
        try {
          final userDoc = await _firestore.collection('users').doc(memberId).get();
          if (userDoc.exists) {
            final userData = Map<String, dynamic>.from(userDoc.data()!);

            // ✅ تنظيف البيانات والتأكد من الأنواع
            final cleanUserData = {
              'userId': memberId,
              'name': _safeString(userData['name']) ?? 'مستخدم',
              'imageUrl': _safeString(userData['imageUrl']) ?? '',
              'phone': _safeString(userData['phone']),
              'phoneCanon': _safeString(userData['phoneCanon']),
              'isOnline': userData['isOnline'] ?? false,
              'lastSeen': userData['lastSeen'],
              'isAdmin': admins.contains(memberId),
            };

            members.add(cleanUserData);
          } else {
            print('⚠️ User $memberId not found, using default data');
            members.add({
              'userId': memberId,
              'name': 'مستخدم',
              'imageUrl': '',
              'isAdmin': admins.contains(memberId),
              'isOnline': false,
            });
          }
        } catch (e) {
          print('❌ Error loading user $memberId: $e');
          // ✅ نستمر في تحميل الأعضاء الآخرين
          members.add({
            'userId': memberId,
            'name': 'مستخدم',
            'imageUrl': '',
            'isAdmin': admins.contains(memberId),
            'isOnline': false,
          });
        }
      }

      return members;
    } catch (e) {
      print('❌ Error loading group members: $e');
      return [];
    }
  }

  // ✅ دالة مساعدة للتحقق من String
  String? _safeString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  // ================================
  // ✅ 4. UPDATE MESSAGE STATUS (مع معالجة الأخطاء)
  // ================================
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
      print('❌ Error updating status: $e');
      // لا نعيد throw الخطأ لأنها عملية ثانوية
    }
  }

  // ================================
  // ✅ 5. BATCH UPDATE (مع معالجة الأخطاء)
  // ================================
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
      print('❌ Batch update error: $e');
    }
  }

  // ================================
  // ✅ 6. MARK AS DELIVERED (مع معالجة الأخطاء)
  // ================================
  Future<void> markMessagesAsDelivered({
    required String groupId,
    required String userId,
  }) async {
    try {
      final snap = await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .where('status.$userId', isEqualTo: 'pending')
          .get();

      if (snap.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (var doc in snap.docs) {
        try {
          batch.update(doc.reference, {'status.$userId': 'delivered'});
        } catch (e) {
          print('❌ Error updating message ${doc.id}: $e');
        }
      }
      await batch.commit();
    } catch (e) {
      print('❌ Error marking delivered: $e');
    }
  }

  // ================================
  // ✅ 7. MARK AS SEEN
  // ================================
  Future<void> markMessagesAsSeen({
    required String groupId,
    required String userId,
  }) async {
    try {
      final snap = await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .where('status.$userId', whereIn: ['pending', 'delivered']).get();

      if (snap.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (var doc in snap.docs) {
        batch.update(doc.reference, {'status.$userId': 'seen'});
      }
      await batch.commit();
    } catch (e) {
      print('❌ Error marking seen: $e');
    }
  }

  // ================================
  // ✅ 8. ADD/UPDATE REACTION
  // ================================
  Future<void> addOrUpdateReaction({
    required String groupId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .update({'reactions.$userId': emoji});
    } catch (e) {
      AppSnackbar.error('فشل إضافة التفاعل');
    }
  }

  // ================================
  // ✅ 9. REMOVE REACTION
  // ================================
  Future<void> removeReaction({
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
          .update({'reactions.$userId': FieldValue.delete()});
    } catch (e) {
      AppSnackbar.error('فشل حذف التفاعل');
    }
  }

  // ================================
  // ✅ 10. DELETE MESSAGE
  // ================================
  Future<void> deleteMessage({
    required String groupId,
    required String messageId,
    required String deletedBy,
  }) async {
    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .update({
        'isDeleted': true,
        'deletedBy': deletedBy,
        'content': 'تم حذف هذه الرسالة',
      });
    } catch (e) {
      AppSnackbar.error('فشل حذف الرسالة');
      rethrow;
    }
  }

  // ================================
  // ✅ 11. SMS SENDING
  // ================================
  String _normalizePalestinianNumber(String number) {
    number = number.replaceAll('+', '').replaceAll(' ', '');
    if (number.startsWith('970') || number.startsWith('972')) {
      number = '0${number.substring(3)}';
    } else if (!number.startsWith('0')) {
      number = '0$number';
    }
    return number;
  }

  Future<Map<String, int>> sendSmsToUsers(
      String groupId, List<String> numbers, String text) async {
    int successCount = 0;
    int failCount = 0;

    const apiKey = "c735413907079a974249eaa7fb107ebd";
    const senderName = Constants.senderName;

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
          "message": isSuccess
              ? "تم الإرسال بنجاح"
              : _mapTweetSmsError(result, number),
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

  String _mapTweetSmsError(String result, String number) {
    if (result.contains("-113")) {
      return "الرصيد غير كافٍ لإرسال الرسالة إلى $number";
    } else if (result.contains("-115")) {
      return "المرسل غير مفعّل (${Constants.senderName})";
    } else if (result.contains("-2")) {
      return "الرقم غير صالح أو غير مدعوم: $number";
    } else if (result.contains("-110")) {
      return "مفتاح API غير صالح أو خطأ في الإعدادات";
    } else if (result.contains("-999")) {
      return "فشل الإرسال من مزود الخدمة إلى $number";
    }
    return "فشل غير معروف أثناء إرسال الرسالة إلى $number";
  }
}