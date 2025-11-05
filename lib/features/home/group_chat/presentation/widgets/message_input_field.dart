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
        horizontal: ManagerWidth.w16,
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
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: getRegularTextStyle(
                fontSize: ManagerFontSize.s14,
                color: ManagerColors.black,
              ),
              decoration: const InputDecoration(
                hintText: "اكتب الرسالة...",
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            color: Colors.grey,
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.send_rounded),
            color: ManagerColors.primaryColor,
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onSend(controller.text.trim());
                controller.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
