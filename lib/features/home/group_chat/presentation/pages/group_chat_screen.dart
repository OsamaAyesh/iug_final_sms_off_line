import 'dart:async';
import 'package:app_mobile/features/home/group_chat/domain/models/message_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../../core/resources/manager_colors.dart';
import '../../../../../core/resources/manager_font_size.dart';
import '../../../../../core/resources/manager_height.dart';
import '../../../../../core/resources/manager_styles.dart';
import '../../../../../core/resources/manager_width.dart';
import '../../../add_chat/presentation/pages/cloudinary_image_avatar.dart';
import '../../../info_goup/presentaion/pages/info_gruop_screen.dart';
import '../../data/data_source/chat_group_remote_data_source.dart';
import '../../data/repository/chat_group_repository_impl.dart';
import '../controller/chat_group_controller.dart';
import '../widgets/message_bubble.dart';
import '../widgets/reply_preview.dart';
import '../widgets/message_input_field.dart';
import 'message_status_screen.dart';

class ChatGroupScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String groupImage;
  final String participantsCount;

  const ChatGroupScreen({
    Key? key,
    required this.groupId,
    required this.groupName,
    required this.groupImage,
    required this.participantsCount,
  }) : super(key: key);

  @override
  State<ChatGroupScreen> createState() => _ChatGroupScreenState();
}

class _ChatGroupScreenState extends State<ChatGroupScreen> {
  final _scrollController = ScrollController();
  late final ChatGroupController controller;

  @override
  void initState() {
    super.initState();

    // تهيئة الـ Controller بشكل آمن
    _initializeController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.listenToMessages(widget.groupId);
    });
  }

  void _initializeController() {
    // تحقق إذا كان الـ Controller مسجل مسبقاً
    if (Get.isRegistered<ChatGroupController>()) {
      controller = Get.find<ChatGroupController>();
    } else {
      // إذا لم يكن مسجلاً، قم بتسجيله
      controller = Get.put(ChatGroupController(
          repository: ChatGroupRepositoryImpl(
              ChatGroupRemoteDataSource()
          )
      ));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ManagerColors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessagesList()),
          Obx(() => controller.replyMessage.value != null
              ? ReplyPreview(
            message: controller.replyMessage.value!,
            onCancel: () => controller.cancelReply(),
          )
              : const SizedBox.shrink()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: ManagerColors.primaryColor,
      elevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Get.back(),
      ),
      title: InkWell(
        onTap: () {
          Get.to(() => GroupInfoScreen(
            groupId: widget.groupId,
            groupName: widget.groupName,
            groupImage: widget.groupImage,
          ));
        },
        child: Row(
          children: [
            CloudinaryAvatar(
              imageUrl: widget.groupImage,
              fallbackText: widget.groupName,
              radius: 20,
            ),
            SizedBox(width: ManagerWidth.w10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.groupName,
                    style: getBoldTextStyle(
                      fontSize: ManagerFontSize.s16,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Obx(() => Text(
                    '${controller.messages.length} رسالة',
                    style: getRegularTextStyle(
                      fontSize: ManagerFontSize.s12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam, color: Colors.white),
          onPressed: _startVideoCall,
        ),
        IconButton(
          icon: const Icon(Icons.call, color: Colors.white),
          onPressed: _startVoiceCall,
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            switch (value) {
              case 'info':
                Get.to(() => GroupInfoScreen(
                  groupId: widget.groupId,
                  groupName: widget.groupName,
                  groupImage: widget.groupImage,
                ));
                break;
              case 'members':
                _showGroupMembers();
                break;
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem(
              value: 'info',
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: ManagerColors.primaryColor),
                  SizedBox(width: ManagerWidth.w8),
                  Text('معلومات المجموعة'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'members',
              child: Row(
                children: [
                  Icon(Icons.people_outline, color: ManagerColors.primaryColor),
                  SizedBox(width: ManagerWidth.w8),
                  Text('أعضاء المجموعة'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessagesList() {
    return Obx(() {
      final messages = controller.messages;

      if (messages.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.builder(
        controller: _scrollController,
        reverse: true,
        padding: EdgeInsets.all(ManagerWidth.w16),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          final isMe = controller.isMine(message.senderId);

          return MessageBubble(
            message: message,
            isMine: isMe,
            onReply: () => controller.replyTo(message),
            onTapStatus: () => _showMessageStatus(message),
            onToggleReaction: (emoji) => controller.toggleReaction(message.id, emoji),
            onDelete: () => _deleteMessage(message),
            canDelete: true,
          );
        },
      );
    });
  }

  Widget _buildMessageInput() {
    return MessageInputField(
      controller: controller.textController,
      onSend: (text) => _sendMessage(text),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    try {
      await controller.sendMessage(widget.groupId, text);

      // التمرير للأسفل بعد إرسال الرسالة
      _scrollToBottom();
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _deleteMessage(MessageModel message) async {
    final canDelete = await controller.canDeleteMessage(message);
    if (!canDelete) {
      Get.snackbar(
        'خطأ',
        'ليس لديك صلاحية لحذف هذه الرسالة',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    Get.defaultDialog(
      title: 'حذف الرسالة',
      middleText: 'هل أنت متأكد من حذف هذه الرسالة؟',
      textConfirm: 'نعم',
      textCancel: 'إلغاء',
      confirmTextColor: Colors.white,
      onConfirm: () async {
        Get.back();
        await controller.deleteMessage(message.id);
      },
      onCancel: () => Get.back(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 100,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: ManagerHeight.h20),
          Text(
            'ابدأ المحادثة',
            style: getBoldTextStyle(
              fontSize: ManagerFontSize.s18,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: ManagerHeight.h8),
          Text(
            'أرسل أول رسالة في المجموعة',
            style: getRegularTextStyle(
              fontSize: ManagerFontSize.s14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageStatus(MessageModel message) {
    Get.to(() => MessageStatusScreen(
      groupId: widget.groupId,
      message: message,
      groupName: widget.groupName,
    ));
  }

  void _startVideoCall() {
    Get.snackbar(
      'مكالمة فيديو',
      'جاري بدء مكالمة الفيديو...',
      backgroundColor: ManagerColors.primaryColor,
      colorText: Colors.white,
    );
  }

  void _startVoiceCall() {
    Get.snackbar(
      'مكالمة صوتية',
      'جاري بدء المكالمة الصوتية...',
      backgroundColor: ManagerColors.primaryColor,
      colorText: Colors.white,
    );
  }

  void _showGroupMembers() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('أعضاء المجموعة'),
        content: FutureBuilder<List<Map<String, dynamic>>>(
          future: controller.repository.getGroupMembers(widget.groupId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Text('لا يوجد أعضاء');
            }

            return Container(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final member = snapshot.data![index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: member['imageUrl'] != null
                          ? CachedNetworkImageProvider(member['imageUrl'])
                          : null,
                      child: member['imageUrl'] == null
                          ? Text(member['name']?[0] ?? '?')
                          : null,
                    ),
                    title: Text(member['name'] ?? 'Unknown'),
                    subtitle: Text(member['phone'] ?? ''),
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}