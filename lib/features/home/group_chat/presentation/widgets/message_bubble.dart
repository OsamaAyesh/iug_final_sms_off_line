import 'package:app_mobile/features/home/group_chat/domain/models/message_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_width.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';
import 'package:path/path.dart' show context;
import '../controller/chat_group_controller.dart';

class MessageBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMine;
  final VoidCallback onReply;
  final VoidCallback onTapStatus;
  final Function(String) onToggleReaction;
  final VoidCallback onDelete;
  final bool canDelete;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.onReply,
    required this.onTapStatus,
    required this.onToggleReaction,
    required this.onDelete,
    required this.canDelete,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showMessageOptions(context),
      onDoubleTap: () => widget.onToggleReaction('❤️'),
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: ManagerHeight.h4,
          horizontal: ManagerWidth.w8,
        ),
        child: Row(
          mainAxisAlignment: widget.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!widget.isMine) ...[
              _buildSenderAvatar(),
              SizedBox(width: ManagerWidth.w8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: widget.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!widget.isMine) _buildSenderName(),
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isMine ? ManagerColors.primaryColor : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(widget.isMine ? 16 : 4),
                        topRight: Radius.circular(widget.isMine ? 4 : 16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Reply Preview
                        if (widget.message.replyTo != null) _buildReplyPreview(),

                        // Message Content
                        Padding(
                          padding: EdgeInsets.all(ManagerWidth.w12),
                          child: _buildMessageContent(),
                        ),

                        // Reactions
                        if (widget.message.reactions.isNotEmpty) _buildReactions(),

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
                ],
              ),
            ),
            if (widget.isMine) ...[
              SizedBox(width: ManagerWidth.w8),
              _buildStatusIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSenderAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: ManagerColors.primaryColor.withOpacity(0.1),
      child: Icon(
        Icons.person,
        size: 16,
        color: ManagerColors.primaryColor,
      ),
    );
  }

  Widget _buildSenderName() {
    return Padding(
      padding: EdgeInsets.only(bottom: ManagerHeight.h4, right: ManagerWidth.w8),
      child: Text(
        'المستخدم',
        style: getBoldTextStyle(
          fontSize: ManagerFontSize.s12,
          color: ManagerColors.primaryColor,
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      margin: EdgeInsets.all(ManagerWidth.w8),
      padding: EdgeInsets.all(ManagerWidth.w8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(widget.isMine ? 0.2 : 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: widget.isMine ? Colors.white : ManagerColors.primaryColor,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.reply,
            size: 14,
            color: widget.isMine ? Colors.white.withOpacity(0.9) : Colors.grey.shade700,
          ),
          SizedBox(width: ManagerWidth.w4),
          Expanded(
            child: Text(
              "ردًا على رسالة",
              style: getRegularTextStyle(
                fontSize: ManagerFontSize.s11,
                color: widget.isMine ? Colors.white.withOpacity(0.9) : Colors.grey.shade700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    return Text(
      widget.message.content,
      style: getRegularTextStyle(
        fontSize: ManagerFontSize.s14,
        color: widget.isMine ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildReactions() {
    final uniqueReactions = widget.message.reactions.values
        .expand((list) => list)
        .toSet()
        .toList();

    if (uniqueReactions.isEmpty) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: ManagerWidth.w8),
      child: Wrap(
        spacing: ManagerWidth.w4,
        runSpacing: ManagerHeight.h2,
        children: uniqueReactions.map((emoji) {
          final count = widget.message.getReactionCount(emoji);
          return GestureDetector(
            onTap: () => widget.onToggleReaction(emoji),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: ManagerWidth.w6,
                vertical: ManagerHeight.h2,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                '$emoji $count',
                style: getRegularTextStyle(
                  fontSize: ManagerFontSize.s10,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMessageFooter() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(widget.message.timestamp),
          style: getRegularTextStyle(
            fontSize: ManagerFontSize.s10,
            color: widget.isMine ? Colors.white.withOpacity(0.7) : Colors.grey.shade600,
          ),
        ),
        if (widget.message.isEdited) ...[
          SizedBox(width: ManagerWidth.w4),
          Text(
            'تم التعديل',
            style: getRegularTextStyle(
              fontSize: ManagerFontSize.s9,
              color: widget.isMine ? Colors.white.withOpacity(0.7) : Colors.grey.shade500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusIndicator() {
    final controller = Get.find<ChatGroupController>();
    final statusIcon = controller.getMessageStatusIcon(widget.message);
    final statusColor = controller.getMessageStatusColor(widget.message);

    return GestureDetector(
      onTap: widget.onTapStatus,
      child: Container(
        padding: EdgeInsets.all(ManagerWidth.w4),
        child: Text(
          statusIcon,
          style: TextStyle(
            color: statusColor,
            fontSize: ManagerFontSize.s12,
          ),
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    final controller = Get.find<ChatGroupController>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(ManagerWidth.w16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: ManagerHeight.h16),

            // Quick Reactions
            _buildQuickReactions(),
            SizedBox(height: ManagerHeight.h16),
            Divider(color: Colors.grey.shade300),
            SizedBox(height: ManagerHeight.h8),

            // Options
            if (widget.canDelete)
              _buildOptionTile(
                icon: Icons.delete,
                title: 'حذف الرسالة',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  widget.onDelete();
                },
              ),

            _buildOptionTile(
              icon: Icons.reply,
              title: 'رد',
              onTap: () {
                Navigator.pop(context);
                widget.onReply();
              },
            ),

            _buildOptionTile(
              icon: Icons.info_outline,
              title: 'حالة الرسالة',
              onTap: () {
                Navigator.pop(context);
                widget.onTapStatus();
              },
            ),

            _buildOptionTile(
              icon: Icons.copy,
              title: 'نسخ النص',
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: widget.message.content));
                // Get.snackbar(
                //   'تم النسخ',
                //   'تم نسخ النص إلى الحافظة',
                //   backgroundColor: Coklo,
                //   colorText: Colors.white,
                // );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReactions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: ChatGroupController.availableReactions.map((emoji) {
        return IconButton(
          icon: Text(emoji, style: TextStyle(fontSize: ManagerFontSize.s20)),
          onPressed: () {
            Navigator.pop(context as BuildContext);
            widget.onToggleReaction(emoji);
          },
        );
      }).toList(),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? ManagerColors.primaryColor),
      title: Text(
        title,
        style: getRegularTextStyle(
          fontSize: ManagerFontSize.s14,
          color: color ?? Colors.black,
        ),
      ),
      onTap: onTap,
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }
}