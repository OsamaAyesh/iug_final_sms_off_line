// المسار: lib/features/home/group_chat/presentation/widgets/message_input_field.dart

import 'package:flutter/material.dart';
import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_width.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';

class MessageInputField extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSend;
  final bool isSending;

  const MessageInputField({
    super.key,
    required this.controller,
    required this.onSend,
    this.isSending = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ManagerWidth.w12,
        vertical: ManagerHeight.h8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment Button
            IconButton(
              icon: Icon(
                Icons.add_circle_outline,
                color: Colors.grey.shade600,
                size: 26,
              ),
              onPressed: isSending ? null : () {
                _showAttachmentOptions(context);
              },
            ),

            // Text Field
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ManagerWidth.w12,
                  vertical: ManagerHeight.h4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: controller,
                  style: getRegularTextStyle(
                    fontSize: ManagerFontSize.s14,
                    color: ManagerColors.black,
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  enabled: !isSending,
                  decoration: InputDecoration(
                    hintText: isSending ? "جاري الإرسال..." : "اكتب رسالتك...",
                    hintStyle: getRegularTextStyle(
                      fontSize: ManagerFontSize.s14,
                      color: Colors.grey.shade400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: ManagerHeight.h10,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(width: ManagerWidth.w4),

            // Send Button
            Container(
              decoration: BoxDecoration(
                color: isSending
                    ? Colors.grey.shade400
                    : ManagerColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: isSending
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: isSending
                    ? null
                    : () {
                  if (controller.text.trim().isNotEmpty) {
                    onSend(controller.text.trim());
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions(BuildContext context) {
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
            SizedBox(height: ManagerHeight.h8),
            Padding(
              padding: EdgeInsets.all(ManagerWidth.w16),
              child: Column(
                children: [
                  _attachmentOption(
                    context,
                    'صورة',
                    Icons.image,
                    Colors.purple,
                        () {
                      Navigator.pop(context);
                      // TODO: اختيار صورة
                    },
                  ),
                  _attachmentOption(
                    context,
                    'فيديو',
                    Icons.videocam,
                    Colors.red,
                        () {
                      Navigator.pop(context);
                      // TODO: اختيار فيديو
                    },
                  ),
                  _attachmentOption(
                    context,
                    'ملف',
                    Icons.insert_drive_file,
                    Colors.blue,
                        () {
                      Navigator.pop(context);
                      // TODO: اختيار ملف
                    },
                  ),
                  _attachmentOption(
                    context,
                    'منشن للجميع',
                    Icons.alternate_email,
                    Colors.orange,
                        () {
                      Navigator.pop(context);
                      controller.text += '@الكل ';
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _attachmentOption(
      BuildContext context,
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(ManagerWidth.w10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: getRegularTextStyle(
          fontSize: ManagerFontSize.s14,
          color: Colors.black,
        ),
      ),
      onTap: onTap,
    );
  }
}