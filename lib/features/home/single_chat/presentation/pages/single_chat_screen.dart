// المسار: lib/features/home/single_chat/presentation/pages/single_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';
import 'package:app_mobile/core/resources/manager_width.dart';
import '../../domain/di/single_chat_di.dart';
import '../controller/single_chat_controller.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input_field.dart'; // ✅ تم التعديل
import '../widgets/reply_preview.dart'; // ✅ تم التعديل

class SingleChatScreen extends StatefulWidget {
  final String otherUserId;
  final String? otherUserName;
  final String? otherUserImage;

  const SingleChatScreen({
    super.key,
    required this.otherUserId,
    this.otherUserName,
    this.otherUserImage,
  });

  @override
  State<SingleChatScreen> createState() => _SingleChatScreenState();
}

class _SingleChatScreenState extends State<SingleChatScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();

    // Initialize DI
    SingleChatDI.init();

    WidgetsBinding.instance.addObserver(this);

    final controller = SingleChatController.to;

    // Initialize chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initializeChat(widget.otherUserId);
    });

    // Mark as seen after delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        controller.markMessagesAsSeen();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came to foreground - mark as seen
      SingleChatController.to.markMessagesAsSeen();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = SingleChatController.to;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(controller),
      body: Column(
        children: [
          // Reply Preview
          Obx(() {
            if (controller.replyMessage.value != null) {
              return ReplyPreviewSingleChat( // ✅ تم التصحيح
                message: controller.replyMessage.value!,
                onCancel: controller.cancelReply,
              );
            }
            return const SizedBox.shrink();
          }),

          // Messages List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final messages = controller.messages;
              if (messages.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: EdgeInsets.all(ManagerWidth.w16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isMine = controller.isMineSync(message.senderId);

                  return SingleMessageBubble( // ✅ تم التصحيح
                    message: message,
                    isMine: isMine,
                    onReply: () => controller.replyTo(message),
                    onTapStatus: isMine ? () {} : null,
                  );
                },
              );
            }),
          ),

          // Input Field
          Obx(() {
            return MessageInputField( // ✅ تم التصحيح
              controller: controller.textController,
              onSend: (text) => controller.sendMessage(text),
              isSending: controller.isSending.value,
            );
          }),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(SingleChatController controller) {
    return AppBar(
      backgroundColor: ManagerColors.primaryColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Get.back(),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: widget.otherUserImage != null &&
                widget.otherUserImage!.isNotEmpty
                ? CachedNetworkImageProvider(widget.otherUserImage!)
                : null,
            child: widget.otherUserImage == null || widget.otherUserImage!.isEmpty
                ? Icon(Icons.person, color: Colors.grey.shade600, size: 20)
                : null,
          ),
          SizedBox(width: ManagerWidth.w8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() {
                  final userName = controller.otherUserInfo['name'] ??
                      widget.otherUserName ??
                      'مستخدم';
                  return Text(
                    userName,
                    style: getBoldTextStyle(
                      fontSize: ManagerFontSize.s14,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                }),
                Obx(() {
                  final isOnline = controller.otherUserInfo['isOnline'] ?? false;
                  return Text(
                    isOnline ? 'متصل الآن' : 'غير متصل',
                    style: getRegularTextStyle(
                      fontSize: ManagerFontSize.s10,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) => _handleMenuAction(value, controller),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'info',
              child: Row(
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 12),
                  Text('معلومات المستخدم'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'mute',
              child: Row(
                children: [
                  Icon(Icons.notifications_off_outlined),
                  SizedBox(width: 12),
                  Text('كتم الإشعارات'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'search',
              child: Row(
                children: [
                  Icon(Icons.search),
                  SizedBox(width: 12),
                  Text('بحث في المحادثة'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red),
                  SizedBox(width: 12),
                  Text('مسح المحادثة', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleMenuAction(String value, SingleChatController controller) {
    switch (value) {
      case 'info':
        _showUserInfo(controller);
        break;
      case 'mute':
        _muteNotifications();
        break;
      case 'search':
        _searchMessages();
        break;
      case 'clear':
        _clearChat();
        break;
    }
  }

  void _showUserInfo(SingleChatController controller) {
    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        title: Text('معلومات المستخدم'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الاسم: ${controller.otherUserInfo['name'] ?? 'غير معروف'}'),
            if (controller.otherUserInfo['phone'] != null)
              Text('الهاتف: ${controller.otherUserInfo['phone']}'),
            if (controller.otherUserInfo['isVerified'] == true)
              Row(
                children: [
                  Text('حساب موثوق'),
                  Icon(Icons.verified, color: Colors.blue, size: 16),
                ],
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _muteNotifications() {
    // TODO: Implement mute notifications
    Get.showSnackbar(GetSnackBar( // ✅ إصلاح: استخدام GetSnackBar بدلاً من AppSnackbar.info
      title: 'تم الكتم',
      message: 'تم كتم إشعارات هذه المحادثة',
      duration: Duration(seconds: 2),
      backgroundColor: Colors.green,
    ));
  }

  void _searchMessages() {
    // TODO: Implement search in chat
    Get.showSnackbar(GetSnackBar( // ✅ إصلاح: استخدام GetSnackBar بدلاً من AppSnackbar.info
      title: 'قريباً',
      message: 'ميزة البحث ستكون متاحة قريباً',
      duration: Duration(seconds: 2),
      backgroundColor: Colors.blue,
    ));
  }

  void _clearChat() {
    Get.dialog(
      AlertDialog(
        title: Text('مسح المحادثة'),
        content: Text('هل أنت متأكد من مسح كامل المحادثة؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.showSnackbar(GetSnackBar( // ✅ إصلاح: استخدام GetSnackBar
                title: 'قريباً',
                message: 'ميزة مسح المحادثة ستكون متاحة قريباً',
                duration: Duration(seconds: 2),
                backgroundColor: Colors.blue,
              ));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('مسح'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: ManagerHeight.h16),
          Text(
            "لا توجد رسائل بعد",
            style: getRegularTextStyle(
              fontSize: ManagerFontSize.s14,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: ManagerHeight.h8),
          Text(
            "ابدأ المحادثة الآن!",
            style: getRegularTextStyle(
              fontSize: ManagerFontSize.s12,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}