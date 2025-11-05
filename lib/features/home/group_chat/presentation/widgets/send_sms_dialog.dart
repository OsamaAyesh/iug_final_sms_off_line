import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_width.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';
import '../controller/chat_group_controller.dart';

class SendSmsDialog extends StatelessWidget {
  const SendSmsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ChatGroupController.to;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(ManagerWidth.w16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "إرسال رسائل SMS",
              style: getBoldTextStyle(
                fontSize: ManagerFontSize.s16,
                color: ManagerColors.black,
              ),
            ),
            SizedBox(height: ManagerHeight.h8),
            Text(
              "اختر من تريد إرسال الرسالة إليهم عبر SMS",
              style: getRegularTextStyle(
                fontSize: ManagerFontSize.s12,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: ManagerHeight.h16),

            // 🟢 خيارات
            _smsOption(
              "من لم تصلهم الرسالة",
              Icons.error_outline,
              "1 مستخدم",
              onTap: () => controller.sendSmsTo("failed"),
            ),
            _smsOption(
              "من لم يقرؤوا الرسالة",
              Icons.access_time,
              "3 مستخدمين",
              onTap: () => controller.sendSmsTo("unread"),
            ),
            _smsOption(
              "جميع المستخدمين",
              Icons.send,
              "5 مستخدمين",
              onTap: () => controller.sendSmsTo("all"),
            ),
            SizedBox(height: ManagerHeight.h16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    "إلغاء",
                    style: getRegularTextStyle(
                      fontSize: ManagerFontSize.s12,
                      color: Colors.grey,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Get.back();
                    controller.sendSmsTo("selected");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ManagerColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    "إرسال",
                    style: getBoldTextStyle(
                      fontSize: ManagerFontSize.s12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _smsOption(String title, IconData icon, String subtitle,
      {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: ManagerHeight.h10),
        padding: EdgeInsets.all(ManagerWidth.w12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: ManagerColors.primaryColor),
            SizedBox(width: ManagerWidth.w12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: getBoldTextStyle(
                      fontSize: ManagerFontSize.s13,
                      color: ManagerColors.black,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: getRegularTextStyle(
                      fontSize: ManagerFontSize.s11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
