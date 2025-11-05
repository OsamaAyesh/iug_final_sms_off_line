import 'package:app_mobile/features/home/group_chat/domain/models/message_model.dart';
import 'package:flutter/material.dart';
import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final VoidCallback onReply;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMine ? ManagerColors.primaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment:
          isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.replyTo != null)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "ردًا على: ${message.replyTo}",
                  style: getRegularTextStyle(
                    fontSize: ManagerFontSize.s10,
                    color: isMine ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
              ),
            Text(
              message.content,
              style: getRegularTextStyle(
                fontSize: ManagerFontSize.s14,
                color: isMine ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: getRegularTextStyle(
                    fontSize: ManagerFontSize.s10,
                    color: isMine ? Colors.white70 : Colors.grey,
                  ),
                ),
                IconButton(
                  onPressed: onReply,
                  icon: const Icon(Icons.reply, size: 14),
                  color: isMine ? Colors.white70 : Colors.grey,
                ),
              ],
            ),
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
