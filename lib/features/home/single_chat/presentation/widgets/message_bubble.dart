// المسار: lib/features/home/single_chat/presentation/widgets/single_message_bubble.dart

import 'package:app_mobile/features/home/single_chat/domain/models/message_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_width.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';
import '../controller/single_chat_controller.dart';

class SingleMessageBubble extends StatelessWidget {
  final SingleMessageModel message;
  final bool isMine;
  final VoidCallback onReply;
  final VoidCallback? onTapStatus;

  const SingleMessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.onReply,
    this.onTapStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isDeleted) {
      return _buildDeletedMessage();
    }

    return GestureDetector(
      onLongPress: () => _showMessageOptions(context),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: ManagerHeight.h6),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: isMine ? ManagerColors.primaryColor : Colors.grey.shade100,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMine ? 16 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (message.replyTo != null) _buildReplyPreview(),
              Padding(
                padding: EdgeInsets.all(ManagerWidth.w12),
                child: _buildMessageContent(),
              ),
              if (message.reactions != null && message.reactions!.isNotEmpty)
                _buildReactions(),
              Padding(
                padding: EdgeInsets.only(
                  left: ManagerWidth.w12,
                  right: ManagerWidth.w12,
                  bottom: ManagerHeight.h8,
                ),
                child: _buildMessageFooter(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeletedMessage() {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: ManagerHeight.h6),
        padding: EdgeInsets.all(ManagerWidth.w12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block, size: 16, color: Colors.grey.shade600),
            SizedBox(width: ManagerWidth.w8),
            Text(
              'تم حذف هذه الرسالة',
              style: getRegularTextStyle(
                fontSize: ManagerFontSize.s13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      margin: EdgeInsets.all(ManagerWidth.w8),
      padding: EdgeInsets.all(ManagerWidth.w8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isMine ? 0.2 : 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          right: BorderSide(
            color: isMine ? Colors.white : ManagerColors.primaryColor,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.reply,
                size: 14,
                color: isMine
                    ? Colors.white.withOpacity(0.9)
                    : Colors.grey.shade700,
              ),
              SizedBox(width: ManagerWidth.w4),
              Text(
                "ردًا على",
                style: getBoldTextStyle(
                  fontSize: ManagerFontSize.s10,
                  color: isMine
                      ? Colors.white.withOpacity(0.9)
                      : Colors.grey.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: ManagerHeight.h4),
          Text(
            message.replyTo ?? '',
            style: getRegularTextStyle(
              fontSize: ManagerFontSize.s12,
              color: isMine
                  ? Colors.white.withOpacity(0.8)
                  : Colors.grey.shade600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    return Text(
      message.content,
      style: getRegularTextStyle(
        fontSize: ManagerFontSize.s14,
        color: isMine ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildReactions() {
    final reactions = message.reactions!;
    final reactionCounts = <String, int>{};

    for (var emoji in reactions.values) {
      reactionCounts[emoji.toString()] =
          (reactionCounts[emoji.toString()] ?? 0) + 1;
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: ManagerWidth.w8),
      padding: EdgeInsets.all(ManagerWidth.w6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isMine ? 0.2 : 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 4,
        children: reactionCounts.entries.map((entry) {
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: ManagerWidth.w6,
              vertical: ManagerHeight.h2,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(entry.key, style: const TextStyle(fontSize: 14)),
                if (entry.value > 1) ...[
                  SizedBox(width: ManagerWidth.w2),
                  Text(
                    '${entry.value}',
                    style: getBoldTextStyle(
                      fontSize: ManagerFontSize.s10,
                      color: isMine ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMessageFooter() {
    final controller = SingleChatController.to;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(message.timestamp),
          style: getRegularTextStyle(
            fontSize: ManagerFontSize.s10,
            color: isMine ? Colors.white.withOpacity(0.7) : Colors.grey,
          ),
        ),
        if (isMine) ...[
          SizedBox(width: ManagerWidth.w4),
          GestureDetector(
            onTap: onTapStatus,
            child: Icon(
              controller.getMessageStatusIcon(message),
              size: 16,
              color: controller.getMessageStatusColor(message),
            ),
          ),
        ],
      ],
    );
  }

  void _showMessageOptions(BuildContext context) {
    final controller = SingleChatController.to;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: ManagerHeight.h8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.reply, color: ManagerColors.primaryColor),
              title: Text(
                'الرد على الرسالة',
                style: getRegularTextStyle(
                  fontSize: ManagerFontSize.s14,
                  color: Colors.black,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onReply();
              },
            ),
            ListTile(
              leading: Icon(Icons.add_reaction, color: ManagerColors.primaryColor),
              title: Text(
                'إضافة تفاعل',
                style: getRegularTextStyle(
                  fontSize: ManagerFontSize.s14,
                  color: Colors.black,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showReactionPicker(context);
              },
            ),
            if (isMine)
              ListTile(
                leading: Icon(Icons.info_outline, color: ManagerColors.primaryColor),
                title: Text(
                  'حالة الرسالة',
                  style: getRegularTextStyle(
                    fontSize: ManagerFontSize.s14,
                    color: Colors.black,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showMessageStatus(context);
                },
              ),
            ListTile(
              leading: Icon(Icons.copy, color: ManagerColors.primaryColor),
              title: Text(
                'نسخ النص',
                style: getRegularTextStyle(
                  fontSize: ManagerFontSize.s14,
                  color: Colors.black,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: message.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم نسخ النص'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            if (controller.isMine(message.senderId))
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  'حذف الرسالة',
                  style: getRegularTextStyle(
                    fontSize: ManagerFontSize.s14,
                    color: Colors.red,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context);
                },
              ),
            if (isMine && message.receiverStatus == 'pending')
              ListTile(
                leading: Icon(Icons.sms, color: Colors.green),
                title: Text(
                  'إرسال SMS',
                  style: getRegularTextStyle(
                    fontSize: ManagerFontSize.s14,
                    color: Colors.green,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  controller.sendSmsForMessage(message);
                },
              ),
            SizedBox(height: ManagerHeight.h8),
          ],
        ),
      ),
    );
  }

  void _showReactionPicker(BuildContext context) {
    final controller = SingleChatController.to;
    final reactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(ManagerWidth.w20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'اختر تفاعلك',
              style: getBoldTextStyle(
                fontSize: ManagerFontSize.s16,
                color: Colors.black,
              ),
            ),
            SizedBox(height: ManagerHeight.h20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: reactions.map((emoji) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    controller.addReaction(message, emoji);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: ManagerHeight.h20),
          ],
        ),
      ),
    );
  }

  void _showMessageStatus(BuildContext context) {
    final controller = SingleChatController.to;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('حالة الرسالة'),
        content: Text(
          'حالة الرسالة: ${controller.getMessageStatusText(message)}',
          style: getRegularTextStyle(
            fontSize: ManagerFontSize.s14,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final controller = SingleChatController.to;

    Get.dialog(
      AlertDialog(
        title: Text('حذف الرسالة'),
        content: Text('هل أنت متأكد من حذف هذه الرسالة؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteMessage(message);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('حذف'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }
}