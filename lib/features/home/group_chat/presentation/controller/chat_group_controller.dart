// المسار: lib/features/home/group_chat/presentation/controller/chat_group_controller.dart
// ✅ معدّل للعمل بدون Firebase Auth

import 'dart:async';
import 'package:app_mobile/features/home/group_chat/domain/models/message_model.dart';
import 'package:app_mobile/features/home/group_chat/domain/models/message_status_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; // أضف هذا للـ dependencies
import '../../../../../core/storage/local/app_settings_prefs.dart';
import '../../../../../core/util/snack_bar.dart';
import '../../../../auth/presentation/controller/auth_controller.dart';
import '../../data/repository/chat_group_repository.dart';
import '../../data/request/send_message_request.dart';

class ChatGroupController extends GetxController {
  final ChatGroupRepository repository;

  ChatGroupController({required this.repository});

  static ChatGroupController get to => Get.find<ChatGroupController>();

  // ================================
  // Controllers and States
  // ================================
  final textController = TextEditingController();
  final replyMessage = Rxn<MessageModel>();
  final messages = <MessageModel>[].obs;
  final messageStatuses = <MessageStatusModel>[].obs;
  final filteredStatuses = <MessageStatusModel>[].obs;
  final isLoading = false.obs;
  final isSendingSms = false.obs;
  final isSending = false.obs;

  String currentGroupId = '';
  String currentUserId = '';
  final groupMembers = <Map<String, dynamic>>[].obs;
  final groupAdmins = <String>[].obs;

  String? selectedSmsOption;

  // Stream subscriptions
  StreamSubscription? _messagesSubscription;

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
    super.onClose();
  }

  // ================================
  // ✅ USER MANAGEMENT (بدون Firebase Auth)
  // ================================

  Future<void> _initCurrentUser() async {
    currentUserId = await _getCurrentUserId();
  }

  /// ✅ جلب الـ userId من SharedPreferences أو النظام الخاص بك
  // Future<String> _getCurrentUserId() async {
  //   // الطريقة 1: من SharedPreferences
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final userId = prefs.getString('user_id') ?? prefs.getString('userId');
  //
  //     if (userId != null && userId.isNotEmpty) {
  //       currentUserId = userId;
  //       return userId;
  //     }
  //   } catch (e) {
  //     print('Error reading from SharedPreferences: $e');
  //   }
  //
  //   // الطريقة 2: من GetX (إذا كنت تحفظه في GetX Controller)
  //   // مثال:
  //   // final authController = Get.find<AuthController>();
  //   // if (authController.currentUser.value != null) {
  //   //   currentUserId = authController.currentUser.value!.id;
  //   //   return currentUserId;
  //   // }
  //
  //   // الطريقة 3: Fallback - استخدم الـ default
  //   // ⚠️ استبدل هذا بالطريقة الصحيحة في نظامك
  //   return '567450057'; // Default for development
  // }
// في ChatGroupController
  Future<String> _getCurrentUserId() async {
    try {
      // 🔹 تهيئة AppSettingsPrefs
      final prefs = AppSettingsPrefs(await SharedPreferences.getInstance());

      // 🔹 التحقق من تسجيل الدخول
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

  /// 🔹 إضافة دالة التحقق من تسجيل الدخول
  Future<bool> checkUserLoggedIn() async {
    try {
      final prefs = AppSettingsPrefs(await SharedPreferences.getInstance());
      return prefs.hasUserData();
    } catch (e) {
      return false;
    }
  }  /// ✅ تعيين الـ userId يدوياً (استخدمها عند تسجيل الدخول)
  Future<void> setCurrentUser(String userId) async {
    currentUserId = userId;

    // احفظه في SharedPreferences للاستخدام المستقبلي
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userId);
    } catch (e) {
      print('Error saving to SharedPreferences: $e');
    }
  }

  // ================================
  // ✅ MESSAGE LISTENING (Real-time)
  // ================================

  void listenToMessages(String groupId) {
    currentGroupId = groupId;
    isLoading.value = true;

    // Cancel previous subscription
    _messagesSubscription?.cancel();

    // Listen to messages
    _messagesSubscription = repository.getMessages(groupId).listen(
          (data) {
        messages.assignAll(data);
        isLoading.value = false;

        // Auto-mark as delivered
        _autoMarkAsDelivered(groupId);
      },
      onError: (error) {
        print('Error listening to messages: $error');
        isLoading.value = false;
        AppSnackbar.error('فشل تحميل الرسائل');
      },
    );

    // Load group info
    _loadGroupInfo(groupId);
  }

  Future<void> _loadGroupInfo(String groupId) async {
    try {
      final groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .get();

      if (groupDoc.exists) {
        final data = groupDoc.data();
        groupAdmins.value = List<String>.from(data?['admins'] ?? []);

        // Load members
        final members = await repository.getGroupMembers(groupId);
        groupMembers.assignAll(members);
      }
    } catch (e) {
      print('Error loading group info: $e');
    }
  }

  // ================================
  // ✅ AUTO STATUS UPDATE
  // ================================

  Future<void> _autoMarkAsDelivered(String groupId) async {
    if (currentUserId.isEmpty) {
      await _initCurrentUser();
    }

    final userId = currentUserId;
    if (userId.isEmpty) return;

    final undeliveredMessages = messages.where((msg) {
      final userStatus = msg.status[userId];
      return userStatus == 'pending' && msg.senderId != userId;
    }).toList();

    if (undeliveredMessages.isEmpty) return;

    try {
      // Batch update
      final messageIds = undeliveredMessages.map((m) => m.id).toList();
      await repository.batchUpdateMessageStatus(
        groupId: groupId,
        messageIds: messageIds,
        userId: userId,
        status: 'delivered',
      );
    } catch (e) {
      print('Error auto-marking delivered: $e');
    }
  }

  Future<void> markMessagesAsSeen() async {
    if (currentUserId.isEmpty) {
      await _initCurrentUser();
    }

    final userId = currentUserId;
    if (userId.isEmpty || currentGroupId.isEmpty) return;

    try {
      await repository.markMessagesAsSeen(
        groupId: currentGroupId,
        userId: userId,
      );
    } catch (e) {
      print('Error marking as seen: $e');
    }
  }

  // ================================
  // ✅ SEND MESSAGE (Optimistic UI)
  // ================================

  Future<void> sendMessage(String groupId, String content) async {
    if (content.trim().isEmpty || isSending.value) return;

    if (currentUserId.isEmpty) {
      await _initCurrentUser();
    }

    final userId = currentUserId;
    if (userId.isEmpty) {
      AppSnackbar.error('لم يتم تحديد المستخدم - الرجاء تسجيل الدخول');
      return;
    }

    isSending.value = true;

    try {
      final mentions = _extractMentions(content);

      final request = SendMessageRequest(
        groupId: groupId,
        senderId: userId,
        content: content.trim(),
        mentions: mentions,
        replyTo: replyMessage.value?.id,
        timestamp: DateTime.now(),
      );

      await repository.sendMessage(request);

      // Clear input
      textController.clear();
      replyMessage.value = null;

      // Send mention notifications
      if (mentions.isNotEmpty) {
        _sendMentionNotifications(groupId, mentions, content);
      }
    } catch (e) {
      AppSnackbar.error('فشل إرسال الرسالة: $e');
    } finally {
      isSending.value = false;
    }
  }

  List<String> _extractMentions(String content) {
    final mentions = <String>[];

    // Extract @username
    final mentionPattern = RegExp(r'@(\w+)');
    final matches = mentionPattern.allMatches(content);

    for (var match in matches) {
      final username = match.group(1);
      if (username != null) {
        mentions.add(username);
      }
    }

    // Check for @الكل or @all
    if (content.contains('@الكل') || content.contains('@all')) {
      mentions.add('@all');
    }

    return mentions;
  }

  Future<void> _sendMentionNotifications(
      String groupId, List<String> mentions, String content) async {
    // TODO: Implement push notifications for mentions
    print('Sending mention notifications to: $mentions');
  }

  // ================================
  // ✅ REPLY MANAGEMENT
  // ================================

  void replyTo(MessageModel message) {
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

  Future<void> addReaction(MessageModel message, String emoji) async {
    if (currentUserId.isEmpty) {
      await _initCurrentUser();
    }

    final userId = currentUserId;
    if (userId.isEmpty) return;

    try {
      // Check if user already reacted with same emoji
      final currentReaction = message.reactions?[userId];

      if (currentReaction == emoji) {
        // Remove reaction
        await repository.removeReaction(
          groupId: currentGroupId,
          messageId: message.id,
          userId: userId,
        );
      } else {
        // Add or update reaction
        await repository.addOrUpdateReaction(
          groupId: currentGroupId,
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
  // ✅ DELETE MESSAGE (مع التحقق من الصلاحيات)
  // ================================

  Future<void> deleteMessage(MessageModel message) async {
    if (currentUserId.isEmpty) {
      await _initCurrentUser();
    }

    final userId = currentUserId;
    if (userId.isEmpty) return;

    // ✅ Check permissions (في التطبيق لأننا لا نستخدم Firebase Auth)
    final isAdmin = groupAdmins.contains(userId);
    final isSender = message.senderId == userId;

    if (!isAdmin && !isSender) {
      AppSnackbar.warning('ليس لديك صلاحية لحذف هذه الرسالة');
      return;
    }

    try {
      await repository.deleteMessage(
        groupId: currentGroupId,
        messageId: message.id,
        deletedBy: userId,
      );
      AppSnackbar.success('تم حذف الرسالة');
    } catch (e) {
      AppSnackbar.error('فشل حذف الرسالة');
    }
  }

  // ================================
  // ✅ MESSAGE STATUS DETAILS
  // ================================

  Future<void> loadMessageStatuses(String groupId, MessageModel message) async {
    isLoading.value = true;

    try {
      final members = await repository.getGroupMembers(groupId);
      messageStatuses.clear();

      for (var member in members) {
        if (member['userId'] == message.senderId) continue;

        final status = message.status[member['userId']] ?? 'pending';

        messageStatuses.add(MessageStatusModel(
          userId: member['userId'],
          name: member['name'] ?? 'User',
          imageUrl: member['imageUrl'] ?? '',
          phoneNumber: member['phone'] ?? member['phoneCanon'],
          status: status,
          lastSeen: member['lastSeen'] != null
              ? (member['lastSeen'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(0),
        ));

      }

      filteredStatuses.assignAll(messageStatuses);
    } catch (e) {
      AppSnackbar.error('فشل تحميل حالات الرسالة');
    } finally {
      isLoading.value = false;
    }
  }

  void filterBy(String status) {
    if (status == "all") {
      filteredStatuses.assignAll(messageStatuses);
    } else {
      filteredStatuses.assignAll(
          messageStatuses.where((m) => m.status == status).toList());
    }
  }

  int getCountByStatus(String status) {
    return messageStatuses.where((m) => m.status == status).length;
  }

  int getPendingCount() => getCountByStatus("pending");
  int getFailedCount() => getCountByStatus("failed");
  int getDeliveredCount() => getCountByStatus("delivered");
  int getSeenCount() => getCountByStatus("seen");
  int getUnreadCount() =>
      messageStatuses.where((m) => m.status != "seen").length;
  int getTotalRecipients() => messageStatuses.length;

  // ================================
  // ✅ SMS MANAGEMENT
  // ================================

  void selectSmsOption(String option) {
    selectedSmsOption = option;
    update();
  }

  void clearSmsSelection() {
    selectedSmsOption = null;
    update();
  }

  List<MessageStatusModel> getUsersForSms() {
    if (selectedSmsOption == null) return [];

    switch (selectedSmsOption) {
      case "pending":
        return messageStatuses.where((m) => m.status == "pending").toList();
      case "failed":
        return messageStatuses.where((m) => m.status == "failed").toList();
      case "unread":
        return messageStatuses.where((m) => m.status != "seen").toList();
      case "all":
        return messageStatuses.toList();
      default:
        return [];
    }
  }

  Future<void> sendSmsTo(String type) async {
    if (isSendingSms.value) return;
    isSendingSms.value = true;

    try {
      final numbersToSend = <String>[];
      final userIdsToUpdate = <String>[];

      for (var user in messageStatuses) {
        if (user.phoneNumber == null || user.phoneNumber!.isEmpty) continue;

        bool shouldSend = switch (type) {
          "pending" => user.status == "pending",
          "failed" => user.status == "failed",
          "unread" => user.status != "seen",
          "all" => true,
          _ => false,
        };

        if (shouldSend) {
          numbersToSend.add(user.phoneNumber!);
          userIdsToUpdate.add(user.userId);
        }
      }

      if (numbersToSend.isEmpty) {
        AppSnackbar.warning('لا يوجد أرقام لإرسال الرسائل');
        return;
      }

      // Get group info
      final groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(currentGroupId)
          .get();
      final groupName = groupDoc.data()?['name'] ?? 'بدون اسم';

      // Build SMS content
      final lastMessage = messages.isNotEmpty ? messages.last.content : '';
      final smsBody = "رسالة جديدة في مجموعة ($groupName):\n$lastMessage";

      // Send SMS
      final result =
      await repository.sendSmsToUsers(currentGroupId, numbersToSend, smsBody);
      final sent = result["success"] ?? 0;
      final failed = result["failed"] ?? 0;

      // Update status after SMS
      await _updateStatusAfterSms(userIdsToUpdate);

      // Close dialogs
      if (Get.isDialogOpen ?? false) Get.back();
      if (Get.isBottomSheetOpen ?? false) Get.back();

      AppSnackbar.success("تم إرسال $sent رسالة، وفشلت $failed");

      // Reload statuses
      if (messages.isNotEmpty) {
        await loadMessageStatuses(currentGroupId, messages.last);
      }
    } catch (e) {
      AppSnackbar.error("فشل الإرسال: $e");
    } finally {
      isSendingSms.value = false;
      clearSmsSelection();
    }
  }

  Future<void> _updateStatusAfterSms(List<String> userIds) async {
    try {
      if (messages.isEmpty) return;
      final lastMessage = messages.last;

      for (var userId in userIds) {
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(currentGroupId)
            .collection('messages')
            .doc(lastMessage.id)
            .update({'status.$userId': 'delivered'});
      }
    } catch (e) {
      print('Error updating status after SMS: $e');
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

  bool isAdmin(String userId) {
    return groupAdmins.contains(userId);
  }

  bool canDeleteMessage(MessageModel message) {
    return isAdmin(currentUserId) || message.senderId == currentUserId;
  }
}