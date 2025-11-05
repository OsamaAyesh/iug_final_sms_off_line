import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';
import 'package:app_mobile/core/resources/manager_width.dart';
import '../controller/chat_group_controller.dart';
import '../widgets/send_sms_dialog.dart';

class MessageStatusScreen extends StatelessWidget {
  final String groupName;
  final String messageContent;

  const MessageStatusScreen({
    super.key,
    required this.groupName,
    required this.messageContent,
  });

  @override
  Widget build(BuildContext context) {
    final controller = ChatGroupController.to;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: ManagerColors.primaryColor,
        elevation: 0,
        title: Text(
          "حالة الرسالة",
          style: getBoldTextStyle(
            fontSize: ManagerFontSize.s16,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // 🟦 العنوان
          Container(
            color: ManagerColors.primaryColor,
            padding: EdgeInsets.all(ManagerWidth.w16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  groupName,
                  style: getBoldTextStyle(
                    fontSize: ManagerFontSize.s16,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: ManagerHeight.h8),
                Text(
                  messageContent,
                  style: getRegularTextStyle(
                    fontSize: ManagerFontSize.s12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          // 🟦 تبويبات الحالات
          Container(
            padding: EdgeInsets.all(ManagerWidth.w16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statusBox("الكل", controller.messages.length),
                _statusBox("قرأوا", controller.getCountByStatus("seen")),
                _statusBox("وصلتهم", controller.getCountByStatus("delivered")),
                _statusBox("معلق", controller.getCountByStatus("pending")),
                _statusBox("فشل", controller.getCountByStatus("failed")),
              ],
            ),
          ),

          // 🟦 قائمة المستخدمين
          Expanded(
            child: Obx(() {
              final filtered = controller.filteredStatuses;
              if (filtered.isEmpty) {
                return const Center(child: Text("لا يوجد بيانات حالياً"));
              }

              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final user = filtered[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(user.imageUrl),
                      radius: 24,
                    ),
                    title: Text(
                      user.name,
                      style: getBoldTextStyle(
                        fontSize: ManagerFontSize.s14,
                        color: ManagerColors.black,
                      ),
                    ),
                    subtitle: Text(
                      user.statusText,
                      style: getRegularTextStyle(
                        fontSize: ManagerFontSize.s12,
                        color: Colors.grey,
                      ),
                    ),
                    trailing: user.status == "failed"
                        ? Text(
                      "يحتاج SMS",
                      style: getRegularTextStyle(
                        fontSize: ManagerFontSize.s10,
                        color: Colors.red,
                      ),
                    )
                        : null,
                  );
                },
              );
            }),
          ),

          // 🟦 زر إرسال SMS
          Padding(
            padding: EdgeInsets.all(ManagerWidth.w16),
            child: SizedBox(
              width: double.infinity,
              height: ManagerHeight.h44,
              child: ElevatedButton.icon(
                onPressed: () {
                  Get.dialog(const SendSmsDialog());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ManagerColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.sms, color: Colors.white),
                label: Text(
                  "إرسال رسائل SMS",
                  style: getBoldTextStyle(
                    fontSize: ManagerFontSize.s14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBox(String title, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: getBoldTextStyle(
            fontSize: ManagerFontSize.s16,
            color: ManagerColors.primaryColor,
          ),
        ),
        Text(
          title,
          style: getRegularTextStyle(
            fontSize: ManagerFontSize.s12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
