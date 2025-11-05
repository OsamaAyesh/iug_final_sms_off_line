import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';
import 'package:app_mobile/core/resources/manager_width.dart';
import '../controller/chat_group_controller.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input_field.dart';

class ChatGroupScreen extends StatelessWidget {
  final String groupId;
  final String groupName;
  final String groupImage;
  final String participantsCount;

  const ChatGroupScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.groupImage,
    required this.participantsCount,
  });

  @override
  Widget build(BuildContext context) {
    final controller = ChatGroupController.to;
    controller.listenToMessages(groupId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: ManagerColors.primaryColor,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: CachedNetworkImageProvider(groupImage),
            ),
            SizedBox(width: ManagerWidth.w8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  groupName,
                  style: getBoldTextStyle(
                    fontSize: ManagerFontSize.s14,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "$participantsCount مشارك",
                  style: getRegularTextStyle(
                    fontSize: ManagerFontSize.s10,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: const [
          Icon(Icons.more_vert, color: Colors.white),
          SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final messages = controller.messages;
              if (messages.isEmpty) {
                return const Center(child: Text("لا توجد رسائل بعد"));
              }

              return ListView.builder(
                padding: EdgeInsets.all(ManagerWidth.w16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isMine = controller.isMine(message.senderId);

                  return MessageBubble(
                    message: message,
                    isMine: isMine,
                    onReply: () => controller.replyTo(message),
                  );
                },
              );
            }),
          ),
          MessageInputField(
            controller: controller.textController,
            onSend: (text) => controller.sendMessage(groupId, text),
          ),
        ],
      ),
    );
  }
}
