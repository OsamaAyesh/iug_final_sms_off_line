// المسار: lib/features/home/single_chat/data/repository/single_chat_repository.dart

import 'package:app_mobile/features/home/single_chat/domain/models/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../request/send_message_request.dart';

abstract class SingleChatRepository {
  /// إنشاء أو جلب معرف المحادثة
  Future<String> getOrCreateChatId(String user1Id, String user2Id);

  /// الحصول على الرسائل
  Stream<List<SingleMessageModel>> getMessages(String chatId);

  /// إرسال رسالة
  Future<void> sendMessage(SendSingleMessageRequest request);

  /// تحديث حالة الرسالة
  Future<void> updateMessageStatus({
    required String chatId,
    required String messageId,
    required String userId,
    required String status,
  });

  /// تعليم الرسائل كمستلمة
  Future<void> markMessagesAsDelivered({
    required String chatId,
    required String userId,
  });

  /// تعليم الرسائل كمقروءة
  Future<void> markMessagesAsSeen({
    required String chatId,
    required String userId,
    required String otherUserId,
  });

  /// إضافة أو تحديث تفاعل
  Future<void> addOrUpdateReaction({
    required String chatId,
    required String messageId,
    required String userId,
    required String emoji,
  });

  /// إزالة تفاعل
  Future<void> removeReaction({
    required String chatId,
    required String messageId,
    required String userId,
  });

  /// حذف رسالة
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
    required String deletedBy,
  });

  /// الحصول على معلومات المستخدم
  Future<Map<String, dynamic>> getUserInfo(String userId);

  /// إرسال SMS للمستخدم
  Future<Map<String, dynamic>> sendSmsToUser(
      String chatId,
      String number,
      String text,
      String messageId,
      );

  /// الحصول على محادثات المستخدم
  Stream<QuerySnapshot> getUserChats(String userId);
}