// المسار: lib/features/home/single_chat/presentation/controller/single_chat_controller.dart

import 'dart:async';
import 'package:app_mobile/features/home/single_chat/domain/models/message_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/storage/local/app_settings_prefs.dart';
import '../../../../../core/util/snack_bar.dart';
import '../../data/repository/single_chat_repository.dart';
import '../../data/request/send_message_request.dart';

class SingleChatController extends GetxController {
  final SingleChatRepository repository;

  SingleChatController({required this.repository});

  static SingleChatController get to => Get.find<SingleChatController>();

  // ================================
  // Controllers and States
  // ================================
  final textController = TextEditingController();
  final replyMessage = Rxn<SingleMessageModel>();
  final messages = <SingleMessageModel>[].obs;
  final isLoading = false.obs;
  final isSending = false.obs;
  final isSendingSms = false.obs;

  String currentChatId = '';
  String currentUserId = '';
  String otherUserId = '';

  // ✅ إصلاح: استخدام RxMap بدلاً من Map عادية
  final otherUserInfo = RxMap<String, dynamic>();

  final userChats = <QueryDocumentSnapshot>[].obs;

  // Stream subscriptions
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _chatsSubscription;

  // ================================
  // ✅ INITIALIZATION
  // ================================

  @override
  void onInit() {
    super.onInit();
    _initCurrentUser();
  }

  @override
  void onClose() {
    textController.dispose();
    _messagesSubscription?.cancel();
    _chatsSubscription?.cancel();
    super.onClose();
  }

  // ================================
  // ✅ USER MANAGEMENT
  // ================================

  Future<void> _initCurrentUser() async {
    currentUserId = await _getCurrentUserId();
    _listenToUserChats();
  }

  Future<String> _getCurrentUserId() async {
    try {
      final prefs = AppSettingsPrefs(await SharedPreferences.getInstance());

      if (!prefs.getUserLoggedIn()) {
        throw Exception('المستخدم غير مسجل دخول');
      }

      final userId = prefs.getUserId();
      if (userId == null || userId.isEmpty) {
        throw Exception('لم يتم العثور على معرف المستخدم');
      }

      print('✅ تم جلب user_id: $userId');
      currentUserId = userId;
      return userId;

    } catch (e) {
      print('❌ خطأ في _getCurrentUserId: $e');
      AppSnackbar.error('يجب تسجيل الدخول أولاً');
      rethrow;
    }
  }

  Future<bool> checkUserLoggedIn() async {
    try {
      final prefs = AppSettingsPrefs(await SharedPreferences.getInstance());
      return prefs.hasUserData();
    } catch (e) {
      return false;
    }
  }

  // ================================
  // ✅ CHAT MANAGEMENT
  // ================================

  Future<void> initializeChat(String otherUserId) async {
    try {
      this.otherUserId = otherUserId;
      isLoading.value = true;

      // جلب معلومات المستخدم الآخر
      final userInfo = await repository.getUserInfo(otherUserId);
      otherUserInfo.assignAll(userInfo); // ✅ استخدام assignAll بدلاً من =

      // إنشاء أو جلب معرف المحادثة
      currentChatId = await repository.getOrCreateChatId(currentUserId, otherUserId);

      // الاستماع للرسائل
      listenToMessages();

      // تحميل المحادثات
      _listenToUserChats();

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      AppSnackbar.error('فشل تحميل المحادثة: $e');
    }
  }

  void listenToMessages() {
    if (currentChatId.isEmpty) return;

    isLoading.value = true;

    // Cancel previous subscription
    _messagesSubscription?.cancel();

    // Listen to messages
    _messagesSubscription = repository.getMessages(currentChatId).listen(
          (data) {
        messages.assignAll(data);
        isLoading.value = false;

        // Auto-mark as delivered
        _autoMarkAsDelivered();
      },
      onError: (error) {
        print('Error listening to messages: $error');
        isLoading.value = false;
        AppSnackbar.error('فشل تحميل الرسائل');
      },
    );
  }

  void _listenToUserChats() {
    if (currentUserId.isEmpty) return;

    _chatsSubscription?.cancel();
    _chatsSubscription = repository.getUserChats(currentUserId).listen(
          (snapshot) {
        userChats.assignAll(snapshot.docs);
      },
      onError: (error) {
        print('Error listening to chats: $error');
      },
    );
  }

  // ================================
  // ✅ AUTO STATUS UPDATE
  // ================================

  Future<void> _autoMarkAsDelivered() async {
    if (currentUserId.isEmpty || currentChatId.isEmpty) return;

    final undeliveredMessages = messages.where((msg) {
      return msg.receiverStatus == 'pending' && msg.senderId != currentUserId;
    }).toList();

    if (undeliveredMessages.isEmpty) return;

    try {
      for (var message in undeliveredMessages) {
        await repository.updateMessageStatus(
          chatId: currentChatId,
          messageId: message.id,
          userId: currentUserId,
          status: 'delivered',
        );
      }
    } catch (e) {
      print('Error auto-marking delivered: $e');
    }
  }

  Future<void> markMessagesAsSeen() async {
    if (currentUserId.isEmpty || currentChatId.isEmpty || otherUserId.isEmpty) return;

    try {
      await repository.markMessagesAsSeen(
        chatId: currentChatId,
        userId: currentUserId,
        otherUserId: otherUserId,
      );
    } catch (e) {
      print('Error marking as seen: $e');
    }
  }

  // ================================
  // ✅ SEND MESSAGE
  // ================================

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || isSending.value) return;

    if (currentUserId.isEmpty) {
      await _initCurrentUser();
    }

    if (currentUserId.isEmpty || otherUserId.isEmpty) {
      AppSnackbar.error('لم يتم تحديد المستخدم - الرجاء تسجيل الدخول');
      return;
    }

    isSending.value = true;

    try {
      final request = SendSingleMessageRequest(
        chatId: currentChatId,
        senderId: currentUserId,
        receiverId: otherUserId,
        content: content.trim(),
        mentions: _extractMentions(content),
        replyTo: replyMessage.value?.id,
        timestamp: DateTime.now(),
      );

      await repository.sendMessage(request);

      // Clear input
      textController.clear();
      replyMessage.value = null;

    } catch (e) {
      AppSnackbar.error('فشل إرسال الرسالة: $e');
    } finally {
      isSending.value = false;
    }
  }

  List<String> _extractMentions(String content) {
    final mentions = <String>[];
    final mentionPattern = RegExp(r'@(\w+)');
    final matches = mentionPattern.allMatches(content);

    for (var match in matches) {
      final username = match.group(1);
      if (username != null) {
        mentions.add(username);
      }
    }

    return mentions;
  }

  // ================================
  // ✅ REPLY MANAGEMENT
  // ================================

  void replyTo(SingleMessageModel message) {
    if (!message.isDeleted) {
      replyMessage.value = message;
    }
  }

  void cancelReply() {
    replyMessage.value = null;
  }

  // ================================
  // ✅ REACTIONS
  // ================================

  Future<void> addReaction(SingleMessageModel message, String emoji) async {
    if (currentUserId.isEmpty) {
      await _initCurrentUser();
    }

    final userId = currentUserId;
    if (userId.isEmpty) return;

    try {
      final currentReaction = message.reactions?[userId];

      if (currentReaction == emoji) {
        // Remove reaction
        await repository.removeReaction(
          chatId: currentChatId,
          messageId: message.id,
          userId: userId,
        );
      } else {
        // Add or update reaction
        await repository.addOrUpdateReaction(
          chatId: currentChatId,
          messageId: message.id,
          userId: userId,
          emoji: emoji,
        );
      }
    } catch (e) {
      AppSnackbar.error('فشل إضافة التفاعل');
    }
  }

  // ================================
  // ✅ DELETE MESSAGE
  // ================================

  Future<void> deleteMessage(SingleMessageModel message) async {
    if (currentUserId.isEmpty) {
      await _initCurrentUser();
    }

    final userId = currentUserId;
    if (userId.isEmpty) return;

    // ✅ Check permissions (المرسل فقط يمكنه الحذف في المحادثات الفردية)
    final isSender = message.senderId == userId;

    if (!isSender) {
      AppSnackbar.warning('يمكنك حذف رسائلك فقط');
      return;
    }

    try {
      await repository.deleteMessage(
        chatId: currentChatId,
        messageId: message.id,
        deletedBy: userId,
      );
      AppSnackbar.success('تم حذف الرسالة');
    } catch (e) {
      AppSnackbar.error('فشل حذف الرسالة');
    }
  }

  // ================================
  // ✅ SMS MANAGEMENT (مميز للمحادثات الفردية)
  // ================================

  Future<void> sendSmsForMessage(SingleMessageModel message) async {
    if (isSendingSms.value) return;

    // ✅ إصلاح: استخدام otherUserInfo.value للوصول للبيانات
    final phoneNumber = otherUserInfo.value['phone'] ?? otherUserInfo.value['phoneCanon'];
    if (phoneNumber == null || phoneNumber.isEmpty) {
      AppSnackbar.error('لا يوجد رقم هاتف للمستخدم');
      return;
    }

    isSendingSms.value = true;

    try {
      final smsContent = "رسالة جديدة من ${otherUserInfo.value['name'] ?? 'مستخدم'}: ${message.content}";

      final result = await repository.sendSmsToUser(
        currentChatId,
        phoneNumber,
        smsContent,
        message.id,
      );

      if (result['success'] == true) {
        AppSnackbar.success('تم إرسال SMS بنجاح');

        // تحديث حالة الرسالة إذا لزم
        if (message.receiverStatus == 'pending') {
          await repository.updateMessageStatus(
            chatId: currentChatId,
            messageId: message.id,
            userId: otherUserId,
            status: 'delivered',
          );
        }
      } else {
        AppSnackbar.error('فشل إرسال SMS: ${result['error']}');
      }
    } catch (e) {
      AppSnackbar.error('فشل إرسال SMS: $e');
    } finally {
      isSendingSms.value = false;
    }
  }

  // ================================
  // ✅ MESSAGE STATUS INFO
  // ================================

  String getMessageStatusText(SingleMessageModel message) {
    // ✅ إصلاح: استخدام isMine من الـ model
    if (message.isMine) {
      switch (message.receiverStatus) {
        case 'seen':
          return 'تمت المشاهدة';
        case 'delivered':
          return 'تم التوصيل';
        case 'pending':
          return 'قيد الإرسال';
        case 'failed':
          return 'فشل الإرسال';
        default:
          return 'مرسلة';
      }
    } else {
      return 'تم الاستلام';
    }
  }

  IconData getMessageStatusIcon(SingleMessageModel message) {
    // ✅ إصلاح: استخدام isMine من الـ model
    if (message.isMine) {
      switch (message.receiverStatus) {
        case 'seen':
          return Icons.done_all;
        case 'delivered':
          return Icons.done_all;
        case 'pending':
          return Icons.schedule;
        case 'failed':
          return Icons.error_outline;
        default:
          return Icons.done;
      }
    } else {
      return Icons.done;
    }
  }

  Color getMessageStatusColor(SingleMessageModel message) {
    // ✅ إصلاح: استخدام isMine من الـ model
    if (message.isMine) {
      switch (message.receiverStatus) {
        case 'seen':
          return Colors.blue;
        case 'delivered':
          return Colors.green;
        case 'pending':
          return Colors.orange;
        case 'failed':
          return Colors.red;
        default:
          return Colors.grey;
      }
    } else {
      return Colors.grey;
    }
  }

  // ================================
  // ✅ HELPERS
  // ================================

  bool isMine(String senderId) {
    return currentUserId == senderId;
  }

  bool isMineSync(String senderId) {
    if (currentUserId.isEmpty) return false;
    return currentUserId == senderId;
  }

  SingleMessageModel? getLastMessage() {
    return messages.isNotEmpty ? messages.last : null;
  }

  int getUnreadCountForChat(String chatUserId) {
    try {
      final chat = userChats.firstWhere(
            (doc) => doc.id == chatUserId,
        orElse: () => throw Exception(),
      );
      return chat['unreadCount'] ?? 0;
    } catch (e) {
      return 0;
    }
  }
}