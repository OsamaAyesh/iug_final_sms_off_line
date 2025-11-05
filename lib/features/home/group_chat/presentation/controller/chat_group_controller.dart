import 'package:app_mobile/features/home/group_chat/domain/models/message_model.dart';
import 'package:app_mobile/features/home/group_chat/domain/models/message_status_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../../core/util/snack_bar.dart';
import '../../data/repository/chat_group_repository.dart';
import '../../data/request/send_message_request.dart';

class ChatGroupController extends GetxController {
  final ChatGroupRepository repository;

  ChatGroupController({required this.repository});

  static ChatGroupController get to => Get.find<ChatGroupController>();

  // Controllers and States
  final textController = TextEditingController();
  final replyMessage = Rxn<MessageModel>();
  final messages = <MessageModel>[].obs;
  final messageStatuses = <MessageStatusModel>[].obs;
  final filteredStatuses = <MessageStatusModel>[].obs;
  final isLoading = false.obs;
  final isSendingSms = false.obs;

  String currentGroupId = '';
  String currentUserId = '';
  final groupMembers = <Map<String, dynamic>>[].obs;

  String? selectedSmsOption;

  // ================================
  // User Management
  // ================================

  Future<String> _getCurrentUserId() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      currentUserId = firebaseUser.uid;
      return firebaseUser.uid;
    }

    if (currentUserId.isNotEmpty) return currentUserId;

    try {
      final usersSnapshot =
      await FirebaseFirestore.instance.collection('users').limit(1).get();
      if (usersSnapshot.docs.isNotEmpty) {
        currentUserId = usersSnapshot.docs.first.id;
        return currentUserId;
      }
    } catch (e) {
      print('Error getting user from Firestore: $e');
    }

    return '567450057';
  }

  void setCurrentUser(String userId) {
    currentUserId = userId;
  }

  // ================================
  // Message Management
  // ================================

  void listenToMessages(String groupId) {
    currentGroupId = groupId;
    isLoading.value = true;

    repository.getMessages(groupId).listen((data) {
      messages.assignAll(data);
      isLoading.value = false;
      _markCurrentUserMessagesAsDelivered(groupId);
    }, onError: (error) {
      print('Error listening to messages: $error');
      isLoading.value = false;
    });
  }

  Future<void> _markCurrentUserMessagesAsDelivered(String groupId) async {
    final userId = await _getCurrentUserId();
    final undeliveredMessages = messages.where((msg) {
      final userStatus = msg.status[userId];
      return userStatus == 'pending' && msg.senderId != userId;
    }).toList();

    for (var message in undeliveredMessages) {
      try {
        await repository.markMessageAsDelivered(
          groupId: groupId,
          messageId: message.id,
          userId: userId,
        );
      } catch (e) {
        print('Error marking as delivered: $e');
      }
    }
  }

  Future<void> markMessagesAsSeen() async {
    final userId = await _getCurrentUserId();
    try {
      await repository.markMessagesAsSeen(
        groupId: currentGroupId,
        userId: userId,
      );
    } catch (e) {
      print('Error marking as seen: $e');
    }
  }

  Future<void> sendMessage(String groupId, String content) async {
    if (content.trim().isEmpty) return;

    final userId = await _getCurrentUserId();
    final mentions = _extractMentions(content);

    final request = SendMessageRequest(
      groupId: groupId,
      senderId: userId,
      content: content.trim(),
      mentions: mentions,
      replyTo: replyMessage.value?.id,
      timestamp: DateTime.now(),
    );

    try {
      await repository.sendMessage(request);
      textController.clear();
      replyMessage.value = null;
      AppSnackbar.success('Message sent successfully');
    } catch (e) {
      AppSnackbar.error('Failed to send message: $e');
    }
  }

  List<String> _extractMentions(String content) {
    final mentions = <String>[];
    final mentionPattern = RegExp(r'@(\w+)');
    final matches = mentionPattern.allMatches(content);
    for (var match in matches) {
      final username = match.group(1);
      if (username != null) mentions.add(username);
    }
    return mentions;
  }

  void replyTo(MessageModel message) {
    replyMessage.value = message;
  }

  void cancelReply() {
    replyMessage.value = null;
  }

  Future<bool> isMine(String senderId) async {
    final userId = await _getCurrentUserId();
    return userId == senderId;
  }

  bool isMineSync(String senderId) {
    if (currentUserId.isEmpty) return false;
    return currentUserId == senderId;
  }

  // ================================
  // Message Status Management
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
        ));
      }

      filteredStatuses.assignAll(messageStatuses);
    } catch (e) {
      AppSnackbar.error('Failed to load message statuses: $e');
    } finally {
      isLoading.value = false;
    }
  }

  int getCountByStatus(String status) {
    return messageStatuses.where((m) => m.status == status).length;
  }

  void filterBy(String status) {
    if (status == "all") {
      filteredStatuses.assignAll(messageStatuses);
    } else {
      filteredStatuses
          .assignAll(messageStatuses.where((m) => m.status == status).toList());
    }
  }

  // ================================
  // SMS Management
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

//   Future<void> sendSmsTo(String type) async {
//     if (isSendingSms.value) return;
//     isSendingSms.value = true;
//
//     try {
//       final List<String> numbersToSend = [];
//       final List<String> userIdsToUpdate = [];
//
//       for (var user in messageStatuses) {
//         if (user.phoneNumber == null || user.phoneNumber!.isEmpty) continue;
//         bool shouldSend = false;
//
//         switch (type) {
//           case "pending":
//             shouldSend = user.status == "pending";
//             break;
//           case "failed":
//             shouldSend = user.status == "failed";
//             break;
//           case "unread":
//             shouldSend = user.status != "seen";
//             break;
//           case "all":
//             shouldSend = true;
//             break;
//         }
//
//         if (shouldSend) {
//           numbersToSend.add(user.phoneNumber!);
//           userIdsToUpdate.add(user.userId);
//         }
//       }
//
//       if (numbersToSend.isEmpty) {
//         AppSnackbar.warning('No numbers found to send SMS');
//         return;
//       }
//
//       // Retrieve group name
//       final groupDoc = await FirebaseFirestore.instance
//           .collection('groups')
//           .doc(currentGroupId)
//           .get();
//       final groupName = groupDoc.data()?['name'] ?? 'Unnamed Group';
//
//       // Get latest message
//       if (messages.isEmpty) {
//         AppSnackbar.warning('No message content found to send');
//         return;
//       }
//       final lastMessage = messages.last;
//       final messageContent = lastMessage.content;
//
//       // Build detailed message body
//       final smsBody = '''
// New message in "$groupName"
//
// $messageContent
//
// - Offline SMS App
// ''';
//
//       // Send SMS
//       await repository.sendSmsToUsers(numbersToSend, smsBody);
//
//       // Update message status after SMS sent
//       await _updateStatusAfterSms(userIdsToUpdate);
//
//       // Close dialogs
//       if (Get.isDialogOpen ?? false) Get.back();
//       if (Get.isBottomSheetOpen ?? false) Get.back();
//
//       AppSnackbar.success(
//         '${numbersToSend.length} SMS sent successfully and statuses updated',
//       );
//
//       await loadMessageStatuses(currentGroupId, messages.last);
//     } catch (e) {
//       AppSnackbar.error('Failed to send SMS: $e');
//     } finally {
//       isSendingSms.value = false;
//       clearSmsSelection();
//     }
//   }
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

      final groupDoc =
      await FirebaseFirestore.instance.collection('groups').doc(currentGroupId).get();
      final groupName = groupDoc.data()?['name'] ?? 'بدون اسم';

      final lastMessage = messages.isNotEmpty ? messages.last.content : '';
      final smsBody = "رسالة جديدة في مجموعة ($groupName):\n$lastMessage";

      final result = await repository.sendSmsToUsers(currentGroupId, numbersToSend, smsBody);
      final sent = result["success"] ?? 0;
      final failed = result["failed"] ?? 0;

      await _updateStatusAfterSms(userIdsToUpdate);

      if (Get.isDialogOpen ?? false) Get.back();
      if (Get.isBottomSheetOpen ?? false) Get.back();

      AppSnackbar.success("تم إرسال $sent رسالة، وفشلت $failed");

      await loadMessageStatuses(currentGroupId, messages.last);
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

  int getPendingCount() {
    return messageStatuses.where((m) => m.status == "pending").length;
  }

  int getFailedCount() {
    return messageStatuses.where((m) => m.status == "failed").length;
  }

  int getUnreadCount() {
    return messageStatuses.where((m) => m.status != "seen").length;
  }

  int getDeliveredCount() {
    return messageStatuses.where((m) => m.status == "delivered").length;
  }

  int getSeenCount() {
    return messageStatuses.where((m) => m.status == "seen").length;
  }

  int getTotalRecipients() {
    return messageStatuses.length;
  }

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }
}
