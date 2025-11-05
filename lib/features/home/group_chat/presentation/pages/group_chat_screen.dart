// المسار: lib/features/home/group_chat/presentation/pages/group_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';
import 'package:app_mobile/core/resources/manager_width.dart';
import '../../domain/di/chat_group_di.dart';
import '../controller/chat_group_controller.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input_field.dart';
import '../widgets/reply_preview.dart';
import 'message_status_screen.dart';

class ChatGroupScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String groupImage;
  final String participantsCount;
  final String? currentUserId; // اختياري - userId للمستخدم الحالي

  const ChatGroupScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.groupImage,
    required this.participantsCount,
    this.currentUserId,
  });

  @override
  State<ChatGroupScreen> createState() => _ChatGroupScreenState();
}

class _ChatGroupScreenState extends State<ChatGroupScreen>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();

    // Initialize DI
    ChatGroupDI.init();

    WidgetsBinding.instance.addObserver(this);

    final controller = ChatGroupController.to;

    // Set current user if provided
    if (widget.currentUserId != null && widget.currentUserId!.isNotEmpty) {
      controller.setCurrentUser(widget.currentUserId!);
    }

    controller.listenToMessages(widget.groupId);

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
      ChatGroupController.to.markMessagesAsSeen();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ChatGroupDI.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ChatGroupController.to;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Reply Preview
          Obx(() {
            if (controller.replyMessage.value != null) {
              return ReplyPreview(
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

              return ListView.builder(
                padding: EdgeInsets.all(ManagerWidth.w16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isMine = controller.isMineSync(message.senderId);

                  return MessageBubble(
                    message: message,
                    isMine: isMine,
                    onReply: () => controller.replyTo(message),
                    onTapStatus: isMine ? () => _showMessageStatus(message) : null,
                  );
                },
              );
            }),
          ),

          // Input Field
          MessageInputField(
            controller: controller.textController,
            onSend: (text) => controller.sendMessage(widget.groupId, text),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
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
            backgroundImage: widget.groupImage.isNotEmpty
                ? CachedNetworkImageProvider(widget.groupImage)
                : null,
            child: widget.groupImage.isEmpty
                ? Icon(Icons.group, color: Colors.grey.shade600, size: 20)
                : null,
          ),
          SizedBox(width: ManagerWidth.w8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.groupName,
                  style: getBoldTextStyle(
                    fontSize: ManagerFontSize.s14,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "${widget.participantsCount} مشارك",
                  style: getRegularTextStyle(
                    fontSize: ManagerFontSize.s10,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            // Handle menu actions
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'info',
              child: Text('معلومات المجموعة'),
            ),
            const PopupMenuItem(
              value: 'mute',
              child: Text('كتم الإشعارات'),
            ),
            const PopupMenuItem(
              value: 'search',
              child: Text('بحث'),
            ),
          ],
        ),
      ],
    );
  }

  void _showMessageStatus(message) {
    Get.to(
          () => MessageStatusScreen(
        groupId: widget.groupId,
        message: message,
        groupName: widget.groupName,
      ),
      transition: Transition.rightToLeft,
    );
  }
}