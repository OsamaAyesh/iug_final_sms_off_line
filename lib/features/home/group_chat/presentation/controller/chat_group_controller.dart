import 'dart:async';
import 'package:app_mobile/features/home/group_chat/domain/models/message_model.dart';
import 'package:app_mobile/features/home/group_chat/domain/models/message_status_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../../../core/util/snack_bar.dart';
import '../../data/repository/chat_group_repository.dart';
import '../../data/request/send_message_request.dart';

class ChatGroupController extends GetxController {
  // ================================
  // DI & Dependencies
  // ================================
  final ChatGroupRepository repository;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ChatGroupController({required this.repository});

  static ChatGroupController get to => Get.find<ChatGroupController>();

  // ================================
  // State Management
  // ================================

  // UI Controllers
  final TextEditingController textController = TextEditingController();
  final Rx<MessageModel?> replyMessage = Rx<MessageModel?>(null);

  // Data Streams
  final RxList<MessageModel> messages = <MessageModel>[].obs;
  final RxList<MessageStatusModel> messageStatuses = <MessageStatusModel>[].obs;
  final RxList<MessageStatusModel> filteredStatuses = <MessageStatusModel>[].obs;
  final RxList<Map<String, dynamic>> groupMembers = <Map<String, dynamic>>[].obs;

  // Loading States
  final RxBool isSendingSms = false.obs;
  final RxBool isConnected = true.obs;
  final RxBool isLoading = false.obs;
  final RxBool isSendingMessage = false.obs;

  // App State
  final RxString currentGroupId = ''.obs;
  final RxString currentUserId = ''.obs;
  final RxString selectedSmsOption = RxString('');

  // Constants
  static const List<String> availableReactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
  static const List<String> messageStatusesList = ['pending', 'delivered', 'seen', 'failed'];

  // Timers
  Timer? _connectionTimer;
  Timer? _statusMonitorTimer;
  Timer? _typingTimer;

  // ================================
  // Lifecycle Management
  // ================================

  @override
  void onInit() {
    super.onInit();
    _initializeController();
  }

  @override
  void onClose() {
    _cleanupResources();
    super.onClose();
  }

  void _initializeController() {
    _initializeUser();
    _startConnectionMonitoring();
    _startStatusMonitoring();
    _printDebugInfo('Controller Initialized');
  }

  void _cleanupResources() {
    _connectionTimer?.cancel();
    _statusMonitorTimer?.cancel();
    _typingTimer?.cancel();
    textController.dispose();
    _printDebugInfo('Controller Disposed');
  }

  // ================================
  // Connection & Network Management
  // ================================

  void _startConnectionMonitoring() {
    _connectionTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _checkConnectionStatus();
    });
  }

  void _startStatusMonitoring() {
    _statusMonitorTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (currentGroupId.value.isNotEmpty && currentUserId.value.isNotEmpty) {
        _updateMessageStatuses();
      }
    });
  }

  Future<void> _checkConnectionStatus() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final wasConnected = isConnected.value;
      isConnected.value = connectivityResult != ConnectivityResult.none;

      if (isConnected.value && !wasConnected) {
        _printDebugInfo('Internet connection restored');
        _retryFailedOperations();
      } else if (!isConnected.value && wasConnected) {
        _printDebugInfo('Internet connection lost');
      }
    } catch (e) {
      isConnected.value = false;
      _printError('Connection check failed', e);
    }
  }

  void _retryFailedOperations() {
    // إعادة محاولة العمليات الفاشلة عند عودة الاتصال
    if (currentGroupId.value.isNotEmpty) {
      listenToMessages(currentGroupId.value);
    }
  }

  // ================================
  // User Management
  // ================================

  Future<void> _initializeUser() async {
    try {
      final user = await _getCurrentUser();
      currentUserId.value = user?.uid ?? await _createTemporaryUser();
      _printDebugInfo('User initialized: ${currentUserId.value}');
    } catch (e) {
      _printError('User initialization failed', e);
      currentUserId.value = await _createTemporaryUser();
    }
  }

  Future<User?> _getCurrentUser() async {
    try {
      return _auth.currentUser;
    } catch (e) {
      _printError('Failed to get current user', e);
      return null;
    }
  }

  Future<String> _createTemporaryUser() {
    final tempUserId = 'temp_user_${DateTime.now().millisecondsSinceEpoch}';
    _printDebugInfo('Created temporary user: $tempUserId');
    return Future.value(tempUserId);
  }

  void setCurrentUser(String userId) {
    currentUserId.value = userId;
    _printDebugInfo('User set to: $userId');
  }

  // ================================
  // Message Management
  // ================================

  void listenToMessages(String groupId) {
    _executeSafeOperation(
      operation: () async {
        currentGroupId.value = groupId;
        _printDebugInfo('Starting message listener for group: $groupId');

        final subscription = repository.getMessages(groupId, currentUserId.value).listen(
          _handleIncomingMessages,
          onError: _handleMessageError,
          cancelOnError: false,
        );

        return subscription; // إرجاع الـ subscription للتحكم فيه لاحقاً
      },
      errorMessage: 'Failed to start message listener',
    );
  }

  void _handleIncomingMessages(List<MessageModel> incomingMessages) {
    final validMessages = _filterValidMessages(incomingMessages);

    if (validMessages.isNotEmpty) {
      messages.assignAll(validMessages);
      _printDebugInfo('Processed ${validMessages.length} valid messages');
      _markMessagesAsSeenAutomatically();
    } else {
      _printDebugInfo('No valid messages received');
    }
  }

  void _handleMessageError(dynamic error) {
    _printError('Message stream error', error);
    AppSnackbar.error('فشل في تحميل الرسائل');

    // إعادة المحاولة بعد تأخير
    Future.delayed(const Duration(seconds: 3), () {
      if (currentGroupId.value.isNotEmpty) {
        listenToMessages(currentGroupId.value);
      }
    });
  }

  List<MessageModel> _filterValidMessages(List<MessageModel> messages) {
    return messages.where((message) =>
    message.content != null &&
        message.content!.isNotEmpty &&
        message.senderId.isNotEmpty
    ).toList();
  }

  Future<void> sendMessage(String groupId, String content) async {
    if (!_validateMessageInput(content)) return;

    await _executeSafeOperation(
      operation: () async {
        isSendingMessage.value = true;
        _printDebugInfo('Sending message to group: $groupId');

        final request = _createMessageRequest(groupId, content);
        await repository.sendMessage(request);

        _handleMessageSentSuccessfully(request);
      },
      errorMessage: 'Failed to send message',
      finallyCallback: () => isSendingMessage.value = false,
    );
  }

  bool _validateMessageInput(String content) {
    final trimmedContent = content.trim();

    if (trimmedContent.isEmpty) {
      _printDebugInfo('Attempted to send empty message');
      return false;
    }

    if (!isConnected.value) {
      AppSnackbar.error('لا يوجد اتصال بالإنترنت');
      return false;
    }

    return true;
  }

  SendMessageRequest _createMessageRequest(String groupId, String content) {
    return SendMessageRequest(
      groupId: groupId,
      senderId: currentUserId.value,
      content: content.trim(),
      mentions: _extractMentions(content),
      replyTo: replyMessage.value?.id,
      timestamp: DateTime.now(),
    );
  }

  void _handleMessageSentSuccessfully(SendMessageRequest request) {
    textController.clear();
    replyMessage.value = null;
    _addMessageLocally(request);
    _printDebugInfo('Message sent successfully');
  }

  void _addMessageLocally(SendMessageRequest request) {
    final localMessage = MessageModel(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      senderId: request.senderId,
      content: request.content,
      mentions: request.mentions,
      replyTo: request.replyTo,
      status: {request.senderId: 'sent'},
      timestamp: request.timestamp,
      isGroup: true,
      reactions: {},
      isEdited: false,
    );

    messages.insert(0, localMessage);
    _printDebugInfo('Message added to local cache');
  }

  // ================================
  // Message Status Management
  // ================================

  Future<void> _updateMessageStatuses() async {
    if (!isConnected.value) return;

    await _executeSafeOperation(
      operation: () async {
        final messagesToUpdate = messages.where(_shouldUpdateStatus).toList();

        if (messagesToUpdate.isNotEmpty) {
          _printDebugInfo('Updating status for ${messagesToUpdate.length} messages');
          await _batchUpdateStatuses(messagesToUpdate, 'delivered');
        }
      },
      errorMessage: 'Failed to update message statuses',
    );
  }

  bool _shouldUpdateStatus(MessageModel message) {
    final userStatus = message.status[currentUserId.value];
    return message.senderId != currentUserId.value &&
        (userStatus == 'pending' || userStatus == null);
  }

  Future<void> _markMessagesAsSeenAutomatically() async {
    if (!isConnected.value) return;

    await _executeSafeOperation(
      operation: () async {
        final unseenMessages = messages.where(_shouldMarkAsSeen).toList();

        if (unseenMessages.isNotEmpty) {
          _printDebugInfo('Marking ${unseenMessages.length} messages as seen');
          await _batchUpdateStatuses(unseenMessages, 'seen');
        }
      },
      errorMessage: 'Failed to mark messages as seen',
    );
  }

  bool _shouldMarkAsSeen(MessageModel message) {
    final userStatus = message.status[currentUserId.value];
    return message.senderId != currentUserId.value && userStatus == 'delivered';
  }

  Future<void> _batchUpdateStatuses(List<MessageModel> messages, String status) async {
    for (final message in messages) {
      await repository.updateMessageStatus(
        groupId: currentGroupId.value,
        messageId: message.id,
        userId: currentUserId.value,
        status: status,
      );
    }
  }

  // ================================
  // Reactions & Mentions
  // ================================

  Future<void> toggleReaction(String messageId, String emoji) async {
    await _executeSafeOperation(
      operation: () async {
        _printDebugInfo('Toggling reaction: $emoji on message: $messageId');

        await repository.toggleMessageReaction(
          groupId: currentGroupId.value,
          messageId: messageId,
          userId: currentUserId.value,
          emoji: emoji,
        );

        _printDebugInfo('Reaction toggled successfully');
      },
      errorMessage: 'Failed to toggle reaction',
    );
  }

  List<String> _extractMentions(String content) {
    final mentions = <String>[];
    final mentionPattern = RegExp(r'@(\w+)');
    final matches = mentionPattern.allMatches(content);

    for (final match in matches) {
      final username = match.group(1);
      if (username != null) {
        mentions.add(username);
      }
    }

    if (content.contains('@الجميع') || content.contains('@everyone')) {
      mentions.add('الجميع');
    }

    _printDebugInfo('Extracted ${mentions.length} mentions');
    return mentions;
  }

  // ================================
  // Message Moderation
  // ================================

  Future<void> deleteMessage(String messageId) async {
    await _executeSafeOperation(
      operation: () async {
        final canDelete = await _verifyDeletePermission(messageId);

        if (!canDelete) {
          AppSnackbar.error('ليس لديك صلاحية لحذف هذه الرسالة');
          return;
        }

        await _performMessageDeletion(messageId);
      },
      errorMessage: 'Failed to delete message',
    );
  }

  Future<bool> _verifyDeletePermission(String messageId) async {
    final message = messages.firstWhere(
          (msg) => msg.id == messageId,
      orElse: () => MessageModel(
        id: '',
        senderId: '',
        content: '',
        status: {},
        timestamp: DateTime.now(),
      ),
    );

    if (message.senderId == currentUserId.value) return true;

    return await _checkIfAdmin(currentUserId.value);
  }

  Future<void> _performMessageDeletion(String messageId) async {
    await repository.deleteMessage(
      groupId: currentGroupId.value,
      messageId: messageId,
      userId: currentUserId.value,
      isAdmin: await _checkIfAdmin(currentUserId.value),
    );

    messages.removeWhere((msg) => msg.id == messageId);
    _printDebugInfo('Message deleted successfully');
    AppSnackbar.success('تم حذف الرسالة بنجاح');
  }

  Future<bool> canDeleteMessage(MessageModel message) async {
    if (message.senderId == currentUserId.value) return true;
    return await _checkIfAdmin(currentUserId.value);
  }

  // ================================
  // Admin & Permissions
  // ================================

  Future<bool> _checkIfAdmin(String userId) async {
    return await _executeSafeOperation(
      operation: () async {
        final groupDoc = await _firestore
            .collection('groups')
            .doc(currentGroupId.value)
            .get();

        if (!groupDoc.exists) {
          _printDebugInfo('Group not found: ${currentGroupId.value}');
          return false;
        }

        final admins = List<String>.from(groupDoc.data()?['admins'] ?? []);
        final isAdmin = admins.contains(userId);

        _printDebugInfo('Admin check - User: $userId, Is Admin: $isAdmin');
        return isAdmin;
      },
      errorMessage: 'Failed to check admin status',
      defaultValue: false,
    );
  }

  // ================================
  // Reply System
  // ================================

  void replyTo(MessageModel message) {
    replyMessage.value = message;
    _printDebugInfo('Replying to message: ${message.id}');

    // التركيز على حقل النص تلقائياً
    Future.delayed(const Duration(milliseconds: 100), () {
      // يمكن إضافة منطق التركيز هنا
    });
  }

  void cancelReply() {
    replyMessage.value = null;
    _printDebugInfo('Reply cancelled');
  }

  // ================================
  // Message Status Tracking
  // ================================

  Future<void> loadMessageStatuses(String groupId, MessageModel message) async {
    await _executeSafeOperation(
      operation: () async {
        _printDebugInfo('Loading statuses for message: ${message.id}');

        final members = await repository.getGroupMembers(groupId);
        messageStatuses.clear();

        for (final member in members) {
          if (member['userId'] == message.senderId) continue;

          final status = message.status[member['userId']] ?? 'pending';

          messageStatuses.add(MessageStatusModel(
            userId: member['userId'],
            name: member['name'] ?? 'User',
            imageUrl: member['imageUrl'] ?? '',
            phoneNumber: member['phone'] ?? member['phoneNumber'] ?? '',
            status: status,
            isOnline: false,
            lastSeen: DateTime.now(),
          ));
        }

        filteredStatuses.assignAll(messageStatuses);
        _printDebugInfo('Loaded ${messageStatuses.length} message statuses');
      },
      errorMessage: 'Failed to load message statuses',
    );
  }

  void filterBy(String status) {
    if (status == "all") {
      filteredStatuses.assignAll(messageStatuses);
    } else {
      filteredStatuses.assignAll(
          messageStatuses.where((m) => m.status == status).toList()
      );
    }
    _printDebugInfo('Filtered statuses by: $status');
  }

  // ================================
  // SMS Management
  // ================================

  List<MessageStatusModel> getUsersForSms() {
    if (selectedSmsOption.value.isEmpty) return [];

    final users = _getFilteredUsersForSms();
    _printDebugInfo('Prepared ${users.length} users for SMS');
    return users;
  }

  List<MessageStatusModel> _getFilteredUsersForSms() {
    switch (selectedSmsOption.value) {
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

    await _executeSafeOperation(
      operation: () async {
        isSendingSms.value = true;
        _printDebugInfo('Starting SMS sending for type: $type');

        final smsData = await _prepareSmsData(type);
        if (smsData.numbers.isEmpty) return;

        await _executeSmsSending(smsData);
      },
      errorMessage: 'Failed to send SMS',
      finallyCallback: () {
        isSendingSms.value = false;
        selectedSmsOption.value = '';
      },
    );
  }

  Future<({List<String> numbers, List<String> userIds, String body})> _prepareSmsData(String type) async {
    final List<String> numbers = [];
    final List<String> userIds = [];

    for (final user in messageStatuses) {
      if (user.phoneNumber == null || user.phoneNumber!.isEmpty) continue;
      if (_shouldSendSmsToUser(user, type)) {
        numbers.add(user.phoneNumber!);
        userIds.add(user.userId);
      }
    }

    if (numbers.isEmpty) {
      AppSnackbar.warning('لا يوجد أرقام لإرسال الرسائل');
      return (numbers: <String>[], userIds: <String>[], body: '');
    }

    final groupDoc = await _firestore.collection('groups').doc(currentGroupId.value).get();
    final groupName = groupDoc.data()?['name'] ?? 'بدون اسم';
    final lastMessage = messages.isNotEmpty ? messages.last.content : '';
    final body = "رسالة جديدة في مجموعة ($groupName):\n$lastMessage";

    return (numbers: numbers, userIds: userIds, body: body);
  }

  bool _shouldSendSmsToUser(MessageStatusModel user, String type) {
    switch (type) {
      case "pending": return user.status == "pending";
      case "failed": return user.status == "failed";
      case "unread": return user.status != "seen";
      case "all": return true;
      default: return false;
    }
  }

  Future<void> _executeSmsSending(({List<String> numbers, List<String> userIds, String body}) smsData) async {
    final result = await repository.sendSmsToUsers(
      currentGroupId.value,
      smsData.numbers,
      smsData.body,
    );

    await _updateStatusAfterSms(smsData.userIds);
    _handleSmsResult(result);
  }

  Future<void> _updateStatusAfterSms(List<String> userIds) async {
    if (messages.isEmpty) return;

    await _executeSafeOperation(
      operation: () async {
        final lastMessage = messages.last;

        for (final userId in userIds) {
          await repository.updateMessageStatus(
            groupId: currentGroupId.value,
            messageId: lastMessage.id,
            userId: userId,
            status: 'delivered',
          );
        }

        _printDebugInfo('Updated status for ${userIds.length} users after SMS');
      },
      errorMessage: 'Failed to update status after SMS',
    );
  }

  void _handleSmsResult(Map<String, int> result) {
    final sent = result["success"] ?? 0;
    final failed = result["failed"] ?? 0;

    if (Get.isDialogOpen ?? false) Get.back();
    if (Get.isBottomSheetOpen ?? false) Get.back();

    AppSnackbar.success("تم إرسال $sent رسالة، وفشلت $failed");
    _printDebugInfo('SMS sending completed - Sent: $sent, Failed: $failed');

    if (messages.isNotEmpty) {
      loadMessageStatuses(currentGroupId.value, messages.last);
    }
  }

  // ================================
  // Statistics Getters
  // ================================

  int getPendingCount() => messageStatuses.where((m) => m.status == "pending").length;
  int getFailedCount() => messageStatuses.where((m) => m.status == "failed").length;
  int getUnreadCount() => messageStatuses.where((m) => m.status != "seen").length;
  int getDeliveredCount() => messageStatuses.where((m) => m.status == "delivered").length;
  int getSeenCount() => messageStatuses.where((m) => m.status == "seen").length;
  int getTotalRecipients() => messageStatuses.length;

  // ================================
  // Utility Methods
  // ================================

  Future<T> _executeSafeOperation<T>({
    required Future<T> Function() operation,
    required String errorMessage,
    T? defaultValue,
    VoidCallback? finallyCallback,
  }) async {
    try {
      return await operation();
    } catch (e) {
      _printError(errorMessage, e);
      AppSnackbar.error('$errorMessage: ${e.toString()}');

      if (defaultValue != null) {
        return defaultValue;
      }

      rethrow;
    } finally {
      finallyCallback?.call();
    }
  }

  void _printDebugInfo(String message) {
    print('💡 [ChatController] $message');
  }

  void _printError(String message, dynamic error) {
    print('❌ [ChatController] $message: $error');
    if (error is Error) {
      print('📝 StackTrace: ${error.stackTrace}');
    }
  }

  // ================================
  // Public Getters & Helpers
  // ================================

  bool isMine(String senderId) => senderId == currentUserId.value;

  String getMessageStatusIcon(MessageModel message) {
    if (message.isFailed) return '❌';
    if (message.isSeen) return '👁️';
    if (message.isDelivered) return '✓✓';
    if (message.isPending) return '⏳';
    return '✓';
  }

  Color getMessageStatusColor(MessageModel message) {
    if (message.isFailed) return Colors.red;
    if (message.isSeen) return Colors.blue;
    if (message.isDelivered) return Colors.green;
    if (message.isPending) return Colors.orange;
    return Colors.grey;
  }

  // ================================
  // Debug & Development
  // ================================

  void printDebugInfo() {
    _printDebugInfo('''
=== CHAT CONTROLLER DEBUG INFO ===
Group ID: ${currentGroupId.value}
User ID: ${currentUserId.value}
Messages Count: ${messages.length}
Connection Status: ${isConnected.value}
Loading States - SMS: ${isSendingSms.value}, Message: ${isSendingMessage.value}
Reply Active: ${replyMessage.value != null}
==================================
''');
  }

  // Test Methods
  void addTestMessage() {
    final testMessage = MessageModel(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      senderId: currentUserId.value,
      content: 'مرحباً! هذه رسالة تجريبية من النظام المحسن 🚀',
      mentions: [],
      status: {currentUserId.value: 'sent'},
      timestamp: DateTime.now(),
      isGroup: true,
      reactions: {},
      isEdited: false,
    );

    messages.insert(0, testMessage);
    _printDebugInfo('Test message added for demonstration');
  }

  void clearAllData() {
    messages.clear();
    messageStatuses.clear();
    filteredStatuses.clear();
    replyMessage.value = null;
    _printDebugInfo('All data cleared');
  }
}