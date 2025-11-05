import 'package:app_mobile/features/home/group_chat/domain/models/message_model.dart';
import 'package:app_mobile/features/home/group_chat/domain/models/message_status_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/request/send_message_request.dart';
import '../../domain/use_cases/get_messages_usecase.dart';
import '../../domain/use_cases/send_message_usecase.dart';
import '../../domain/use_cases/send_sms_usecase.dart';
import '../../domain/use_cases/update_message_status_usecase.dart';

class ChatGroupController extends GetxController {
  // 🔹 Dependencies (Injected via DI)
  final GetMessagesUseCase getMessagesUseCase;
  final SendMessageUseCase sendMessageUseCase;
  final UpdateMessageStatusUseCase updateStatusUseCase;
  final SendSmsUseCase sendSmsUseCase;

  ChatGroupController({
    required this.getMessagesUseCase,
    required this.sendMessageUseCase,
    required this.updateStatusUseCase,
    required this.sendSmsUseCase,
  });

  /// Shortcut instance
  static ChatGroupController get to => Get.find<ChatGroupController>();

  // 🔹 Controllers & States
  final textController = TextEditingController();
  final replyMessage = Rxn<MessageModel>();
  final messages = <MessageModel>[].obs;
  final messageStatuses = <MessageStatusModel>[].obs;
  final isLoading = false.obs;

  // ================================
  // 🔸 Messages
  // ================================

  /// Start listening to messages for a group
  void listenToMessages(String groupId) {
    isLoading.value = true;
    getMessagesUseCase.call(groupId).listen((data) {
      messages.assignAll(data);
      isLoading.value = false;
    });
  }

  /// Send new message
  Future<void> sendMessage(String groupId, String content) async {
    if (content.trim().isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final request = SendMessageRequest(
      groupId: groupId,
      senderId: user.uid,
      content: content.trim(),
      mentions: [],
      replyTo: replyMessage.value?.content,
      timestamp: DateTime.now(),
    );

    await sendMessageUseCase.call(request);
    replyMessage.value = null;
  }

  /// Reply to a specific message
  void replyTo(MessageModel message) {
    replyMessage.value = message;
  }

  /// Check if the message is mine
  bool isMine(String senderId) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid == senderId;
  }

  // ================================
  // 🔸 Message Statuses
  // ================================

  /// Load message statuses from Firestore (or any source)
  Future<void> loadMessageStatuses(String groupId, String messageId) async {
    // سيتم لاحقًا الربط مع Firebase.
    // هنا سنترك فقط التهيئة بدون بيانات تجريبية.
    messageStatuses.clear();
  }

  /// Get number of users by specific status
  int getCountByStatus(String status) {
    return messageStatuses.where((m) => m.status == status).length;
  }

  /// Filter list by tab (all, seen, delivered, failed, pending)
  final filteredStatuses = <MessageStatusModel>[].obs;

  void filterBy(String status) {
    if (status == "all") {
      filteredStatuses.assignAll(messageStatuses);
    } else {
      filteredStatuses.assignAll(
        messageStatuses.where((m) => m.status == status).toList(),
      );
    }
  }

  // ================================
  // 🔸 SMS Handling
  // ================================

  /// Send SMS to users (manual send)
  Future<void> sendSmsTo(String type) async {
    // Fetch failed/unread numbers dynamically
    final numbersToSend = messageStatuses
        .where((m) =>
    (type == "failed" && m.status == "failed") ||
        (type == "unread" && m.status != "seen") ||
        (type == "all"))
        .map((m) => m.userId) // لاحقاً استبدل بـ phoneNumber
        .toList();

    if (numbersToSend.isEmpty) return;

    await sendSmsUseCase.sendSmsToUsers(
      numbersToSend,
      "تم إرسال الرسالة عبر SMS",
    );

    // تحديث الحالات إلى seen بعد الإرسال الناجح
    for (var m in messageStatuses) {
      m.status = "seen";
    }
    messageStatuses.refresh();
  }

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }
}
