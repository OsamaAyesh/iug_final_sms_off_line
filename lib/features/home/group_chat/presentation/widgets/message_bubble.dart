// المسار: lib/features/home/group_chat/presentation/widgets/message_bubble.dart

import 'package:app_mobile/features/home/group_chat/domain/models/message_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_width.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final VoidCallback onReply;
  final VoidCallback? onTapStatus;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.onReply,
    this.onTapStatus,
  });

  @override
  Widget build(BuildContext context) {
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
            color: isMine
                ? ManagerColors.primaryColor
                : Colors.grey.shade100,
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
              // Reply Preview
              if (message.replyTo != null) _buildReplyPreview(),

              // Message Content
              Padding(
                padding: EdgeInsets.all(ManagerWidth.w12),
                child: _buildMessageContent(),
              ),

              // Message Footer
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

  Widget _buildMessageFooter() {
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
            child: _buildStatusIcon(),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;

    if (message.isFailed) {
      icon = Icons.error_outline;
      color = Colors.red.shade300;
    } else if (message.isSeen) {
      icon = Icons.done_all;
      color = Colors.blue.shade200;
    } else if (message.isDelivered) {
      icon = Icons.done_all;
      color = Colors.white.withOpacity(0.7);
    } else {
      icon = Icons.done;
      color = Colors.white.withOpacity(0.7);
    }

    return Icon(
      icon,
      size: 16,
      color: color,
    );
  }

  void _showMessageOptions(BuildContext context) {
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
              leading: Icon(
                Icons.reply,
                color: ManagerColors.primaryColor,
              ),
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
            if (isMine && onTapStatus != null)
              ListTile(
                leading: Icon(
                  Icons.info_outline,
                  color: ManagerColors.primaryColor,
                ),
                title: Text(
                  'حالة الرسالة',
                  style: getRegularTextStyle(
                    fontSize: ManagerFontSize.s14,
                    color: Colors.black,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onTapStatus!();
                },
              ),
            ListTile(
              leading: Icon(
                Icons.copy,
                color: ManagerColors.primaryColor,
              ),
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
            SizedBox(height: ManagerHeight.h8),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }
}