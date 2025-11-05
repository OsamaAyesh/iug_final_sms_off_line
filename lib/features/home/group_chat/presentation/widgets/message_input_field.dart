import 'package:flutter/material.dart';
import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_width.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';

class MessageInputField extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSend;

  const MessageInputField({
    super.key,
    required this.controller,
    required this.onSend,
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
                color: ManagerColors.primaryColor,
                size: 26,
              ),
              onPressed: () {
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
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        style: getRegularTextStyle(
                          fontSize: ManagerFontSize.s14,
                          color: ManagerColors.black,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: "اكتب رسالتك...",
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
                    IconButton(
                      icon: Icon(Icons.emoji_emotions_outlined,
                          color: Colors.grey.shade600),
                      onPressed: () {
                        // TODO: إضافة منتقي الإيموجي
                      },
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(width: ManagerWidth.w4),

            // Send Button
            Container(
              decoration: BoxDecoration(
                color: ManagerColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isNotEmpty) {
                    onSend(text);
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
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(ManagerWidth.w20),
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
            SizedBox(height: ManagerHeight.h20),
            Text(
              'إرفاق ملف',
              style: getBoldTextStyle(
                fontSize: ManagerFontSize.s16,
                color: Colors.black,
              ),
            ),
            SizedBox(height: ManagerHeight.h20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.image,
                  label: 'صورة',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: اختيار صورة
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.videocam,
                  label: 'فيديو',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: اختيار فيديو
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.insert_drive_file,
                  label: 'ملف',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: اختيار ملف
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.alternate_email,
                  label: 'منشن للجميع',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    controller.text += '@الجميع ';
                  },
                ),
              ],
            ),
            SizedBox(height: ManagerHeight.h20),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          SizedBox(height: ManagerHeight.h8),
          Text(
            label,
            style: getRegularTextStyle(
              fontSize: ManagerFontSize.s12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}