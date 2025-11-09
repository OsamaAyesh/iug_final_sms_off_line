// المسار: lib/features/home/single_chat/data/data_source/single_chat_remote_data_source.dart

import 'dart:async';
import 'dart:convert';
import 'package:app_mobile/constants/constants/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../../../../core/util/snack_bar.dart';
import '../request/send_message_request.dart';
import '../response/message_response.dart';

class SingleChatRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ================================
  // ✅ 1. CREATE OR GET CHAT ID
  // ================================
// ✅ الإصدار المعدل - يمنع إنشاء شات مكرر
  Future<String> getOrCreateChatId(String user1Id, String user2Id) async {
    try {
      // إنشاء ID موحد دائمًا
      final participants = [user1Id, user2Id]..sort();
      final chatId = 'individual_${participants[0]}_${participants[1]}'; // ✅ prefix ثابت

      final chatDoc = await _firestore.collection('chats').doc(chatId).get();

      // إنشاء الوثيقة فقط إن لم تكن موجودة
      if (!chatDoc.exists) {
        await _firestore.collection('chats').doc(chatId).set({
          'id': chatId,
          'type': 'individual',
          'participants': participants,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastMessage': '',
          'lastMessageSender': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unreadCount': {
            participants[0]: 0,
            participants[1]: 0,
          },
        });

        print('✅ تم إنشاء محادثة جديدة: $chatId');
      } else {
        print('⚠️ تم العثور على محادثة موجودة مسبقًا: $chatId');
      }

      return chatId;
    } catch (e) {
      print('❌ خطأ في getOrCreateChatId: $e');
      throw Exception('فشل في إنشاء/جلب المحادثة: $e');
    }
  }

  // ================================
  // ✅ 2. STREAM MESSAGES (Real-time)
  // ================================
  Stream<List<SingleMessageResponse>> getMessages(String chatId) {
    try {
      return _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          // ✅ fallback لتجنب null
          if (!data.containsKey('timestamp')) {
            data['timestamp'] = Timestamp.now();
          }
          return SingleMessageResponse.fromJson(data, doc.id);
        }).toList();
      });
    } catch (e) {
      print('❌ Error in getMessages: $e');
      rethrow;
    }
  }


  // ================================
  // ✅ 3. SEND MESSAGE (Optimistic UI)
  // ================================
  Future<void> sendMessage(SendSingleMessageRequest request) async {
    try {
      final messageData = request.toJson();

      // ✅ إضافة الرسالة
      await _firestore
          .collection('chats')
          .doc(request.chatId)
          .collection('messages')
          .add(messageData);

      // ✅ تحديث آخر رسالة في المحادثة
      await _firestore.collection('chats').doc(request.chatId).update({
        'lastMessage': request.content,
        'lastMessageSender': request.senderId,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ✅ إنشاء/تحديث محادثة للمستخدمين
      await _updateUserChats(request);

    } catch (e) {
      AppSnackbar.error('حدث خطأ أثناء إرسال الرسالة',
          englishMessage: 'Error sending message: $e');
      rethrow;
    }
  }

  // ================================
  // ✅ 4. UPDATE USER CHATS
  // ================================
  Future<void> _updateUserChats(SendSingleMessageRequest request) async {
    final batch = _firestore.batch();

    // تحديث محادثة المرسل
    final senderChatRef = _firestore
        .collection('users')
        .doc(request.senderId)
        .collection('chats')
        .doc(request.receiverId);

    batch.set(senderChatRef, {
      'chatId': request.chatId,
      'userId': request.receiverId,
      'lastMessage': request.content,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': 0, // المرسل لا يوجد لديه رسائل غير مقروءة
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // تحديث محادثة المستقبل
    final receiverChatRef = _firestore
        .collection('users')
        .doc(request.receiverId)
        .collection('chats')
        .doc(request.senderId);

    batch.set(receiverChatRef, {
      'chatId': request.chatId,
      'userId': request.senderId,
      'lastMessage': request.content,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': FieldValue.increment(1), // زيادة الرسائل غير المقروءة
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // ================================
  // ✅ 5. UPDATE MESSAGE STATUS
  // ================================
  Future<void> updateMessageStatus({
    required String chatId,
    required String messageId,
    required String userId,
    required String status,
  }) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'status.$userId': status});
    } catch (e) {
      print('Error updating status: $e');
    }
  }

  // ================================
  // ✅ 6. MARK AS DELIVERED
  // ================================
  Future<void> markMessagesAsDelivered({
    required String chatId,
    required String userId,
  }) async {
    try {
      final snap = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('status.$userId', isEqualTo: 'pending')
          .get();

      if (snap.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (var doc in snap.docs) {
        batch.update(doc.reference, {'status.$userId': 'delivered'});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking delivered: $e');
    }
  }

  // ================================
  // ✅ 7. MARK AS SEEN
  // ================================
  Future<void> markMessagesAsSeen({
    required String chatId,
    required String userId,
    required String otherUserId,
  }) async {
    try {
      final snap = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('status.$userId', whereIn: ['pending', 'delivered'])
          .get();

      if (snap.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (var doc in snap.docs) {
        batch.update(doc.reference, {'status.$userId': 'seen'});
      }
      await batch.commit();

      // تحديث العداد في محادثات المستخدم
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('chats')
          .doc(otherUserId)
          .update({'unreadCount': 0});

    } catch (e) {
      print('Error marking seen: $e');
    }
  }

  // ================================
  // ✅ 8. ADD/UPDATE REACTION
  // ================================
  Future<void> addOrUpdateReaction({
    required String chatId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
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
    required String chatId,
    required String messageId,
    required String userId,
  }) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
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
    required String chatId,
    required String messageId,
    required String deletedBy,
  }) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
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
  // ✅ 11. GET USER INFO
  // ================================
  Future<Map<String, dynamic>> getUserInfo(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) throw Exception('المستخدم غير موجود');

      final userData = Map<String, dynamic>.from(userDoc.data()!);
      userData['userId'] = userId;
      return userData;
    } catch (e) {
      print('Error loading user info: $e');
      rethrow;
    }
  }

  // ================================
  // ✅ 12. SMS SENDING (مميز للمحادثات الفردية)
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

  Future<Map<String, dynamic>> sendSmsToUser(
      String chatId, String number, String text, String messageId) async {
    const apiKey = "c735413907079a974249eaa7fb107ebd";
    const senderName = Constants.senderName;

    try {
      final normalizedNumber = _normalizePalestinianNumber(number);

      final url = Uri.parse(
        "https://tweetsms.ps/api.php?comm=sendsms"
            "&api_key=$apiKey&to=$normalizedNumber&message=${Uri.encodeComponent(text)}&sender=$senderName",
      );

      final response = await http.get(url);
      final result = response.body.trim();

      final isSuccess = response.statusCode == 200 && result.startsWith("1");

      // ✅ حفظ سجل SMS مع ربطه بالرسالة
      await _firestore
          .collection("chats")
          .doc(chatId)
          .collection("sms_logs")
          .add({
        "messageId": messageId,
        "phone": normalizedNumber,
        "status": isSuccess ? "success" : "failed",
        "message": isSuccess
            ? "تم الإرسال بنجاح"
            : _mapTweetSmsError(result, normalizedNumber),
        "timestamp": FieldValue.serverTimestamp(),
      });

      // ✅ تحديث حالة الرسالة إذا نجح الإرسال
      if (isSuccess) {
        // هنا يمكنك تحديث حالة الرسالة إذا أردت
      }

      return {
        "success": isSuccess,
        "message": isSuccess ? "تم الإرسال بنجاح" : "فشل الإرسال",
        "error": isSuccess ? null : _mapTweetSmsError(result, normalizedNumber)
      };
    } catch (e) {
      await _firestore
          .collection("chats")
          .doc(chatId)
          .collection("sms_logs")
          .add({
        "messageId": messageId,
        "phone": number,
        "status": "failed",
        "message": e.toString(),
        "timestamp": FieldValue.serverTimestamp(),
      });

      return {
        "success": false,
        "message": "فشل الإرسال",
        "error": e.toString()
      };
    }
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

  // ================================
  // ✅ 13. GET CHAT HISTORY
  // ================================
  Stream<QuerySnapshot> getUserChats(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('chats')
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }
}