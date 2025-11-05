// المسار: lib/features/home/group_chat/presentation/widgets/send_sms_dialog.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_width.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';
import '../controller/chat_group_controller.dart';

class SendSmsDialog extends StatefulWidget {
  const SendSmsDialog({super.key});

  @override
  State<SendSmsDialog> createState() => _SendSmsDialogState();
}

class _SendSmsDialogState extends State<SendSmsDialog> {
  String? selectedOption;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatGroupController>();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.80,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(ManagerWidth.w16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoBox(),
                    SizedBox(height: ManagerHeight.h20),
                    _buildOptions(controller),
                    if (selectedOption != null) ...[
                      SizedBox(height: ManagerHeight.h20),
                      _buildSelectedOverview(controller),
                      SizedBox(height: ManagerHeight.h16),
                      _buildUsersList(controller),
                    ],
                  ],
                ),
              ),
            ),
            _buildFooter(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ManagerWidth.w16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ManagerColors.primaryColor,
            ManagerColors.primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(ManagerWidth.w10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.sms_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
          SizedBox(width: ManagerWidth.w12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "إرسال رسائل SMS",
                  style: getBoldTextStyle(
                    fontSize: ManagerFontSize.s17,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "اختر المستلمين وأرسل",
                  style: getRegularTextStyle(
                    fontSize: ManagerFontSize.s12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Get.back(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: EdgeInsets.all(ManagerWidth.w12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.blue.shade100.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(ManagerWidth.w8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.info_outline,
              color: Colors.blue.shade700,
              size: 20,
            ),
          ),
          SizedBox(width: ManagerWidth.w12),
          Expanded(
            child: Text(
              "سيتم إرسال إشعار SMS للمستخدمين المحددين لإعلامهم بالرسالة",
              style: getRegularTextStyle(
                fontSize: ManagerFontSize.s12,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions(ChatGroupController controller) {
    return Obx(() => Column(
      children: [
        _smsOption(
          context,
          "قيد الإرسال",
          Icons.schedule_outlined,
          "${controller.getPendingCount()} مستخدم",
          "لم تصل الرسالة للمستخدم بعد",
          Colors.orange,
          "pending",
        ),
        SizedBox(height: ManagerHeight.h12),
        _smsOption(
          context,
          "فشل الإرسال",
          Icons.error_outline,
          "${controller.getFailedCount()} مستخدم",
          "فشل إرسال الرسالة",
          Colors.red,
          "failed",
        ),
        SizedBox(height: ManagerHeight.h12),
        _smsOption(
          context,
          "لم يقرؤوا الرسالة",
          Icons.mark_email_unread_outlined,
          "${controller.getUnreadCount()} مستخدم",
          "لم يفتحوا الشات بعد",
          Colors.deepOrange,
          "unread",
        ),
        SizedBox(height: ManagerHeight.h12),
        _smsOption(
          context,
          "جميع المستلمين",
          Icons.people_outline,
          "${controller.getTotalRecipients()} مستخدم",
          "إرسال للجميع",
          ManagerColors.primaryColor,
          "all",
        ),
      ],
    ));
  }

  Widget _smsOption(
      BuildContext context,
      String title,
      IconData icon,
      String count,
      String description,
      Color color,
      String optionKey,
      ) {
    final isSelected = selectedOption == optionKey;
    final controller = Get.find<ChatGroupController>();

    // تحقق من وجود مستخدمين
    int userCount = 0;
    switch (optionKey) {
      case 'pending':
        userCount = controller.getPendingCount();
        break;
      case 'failed':
        userCount = controller.getFailedCount();
        break;
      case 'unread':
        userCount = controller.getUnreadCount();
        break;
      case 'all':
        userCount = controller.getTotalRecipients();
        break;
    }

    final isDisabled = userCount == 0;

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: InkWell(
        onTap: isDisabled
            ? null
            : () {
          setState(() {
            selectedOption = optionKey;
          });
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.all(ManagerWidth.w14),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.grey.shade50,
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2.5 : 1.5,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(ManagerWidth.w12),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.2) : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              SizedBox(width: ManagerWidth.w14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: getBoldTextStyle(
                              fontSize: ManagerFontSize.s14,
                              color: ManagerColors.black,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ManagerWidth.w8,
                            vertical: ManagerHeight.h4,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            count,
                            style: getBoldTextStyle(
                              fontSize: ManagerFontSize.s11,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: ManagerHeight.h4),
                    Text(
                      description,
                      style: getRegularTextStyle(
                        fontSize: ManagerFontSize.s12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: ManagerWidth.w12),
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? color : Colors.grey.shade400,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedOverview(ChatGroupController controller) {
    String title = '';
    String description = '';
    int count = 0;
    Color color = Colors.blue;
    IconData icon = Icons.info;

    switch (selectedOption) {
      case 'pending':
        title = 'قيد الإرسال';
        description = 'الرسالة لم تصل للمستخدمين بعد';
        count = controller.getPendingCount();
        color = Colors.orange;
        icon = Icons.schedule;
        break;
      case 'failed':
        title = 'فشل الإرسال';
        description = 'فشل إرسال الرسالة لهؤلاء المستخدمين';
        count = controller.getFailedCount();
        color = Colors.red;
        icon = Icons.error_outline;
        break;
      case 'unread':
        title = 'لم يقرؤوا الرسالة';
        description = 'المستخدمون لم يفتحوا الشات بعد';
        count = controller.getUnreadCount();
        color = Colors.deepOrange;
        icon = Icons.mark_email_unread;
        break;
      case 'all':
        title = 'جميع المستلمين';
        description = 'سيتم الإرسال لجميع المستخدمين';
        count = controller.getTotalRecipients();
        color = ManagerColors.primaryColor;
        icon = Icons.people;
        break;
    }

    return Container(
      padding: EdgeInsets.all(ManagerWidth.w16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(ManagerWidth.w8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.check_circle, color: Colors.white, size: 18),
              ),
              SizedBox(width: ManagerWidth.w10),
              Text(
                'الفئة المحددة',
                style: getBoldTextStyle(
                  fontSize: ManagerFontSize.s13,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: ManagerHeight.h12),
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              SizedBox(width: ManagerWidth.w8),
              Expanded(
                child: Text(
                  title,
                  style: getBoldTextStyle(
                    fontSize: ManagerFontSize.s15,
                    color: ManagerColors.black,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ManagerWidth.w12,
                  vertical: ManagerHeight.h6,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: getBoldTextStyle(
                    fontSize: ManagerFontSize.s14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ManagerHeight.h8),
          Text(
            description,
            style: getRegularTextStyle(
              fontSize: ManagerFontSize.s12,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: ManagerHeight.h8),
          Container(
            padding: EdgeInsets.all(ManagerWidth.w10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.sms, color: color, size: 16),
                SizedBox(width: ManagerWidth.w6),
                Expanded(
                  child: Text(
                    'سيتم إرسال SMS إلى $count مستخدم',
                    style: getBoldTextStyle(
                      fontSize: ManagerFontSize.s12,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(ChatGroupController controller) {
    final users = controller.getUsersForSms();

    if (users.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(ManagerWidth.w12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, color: Colors.grey.shade700, size: 18),
              SizedBox(width: ManagerWidth.w8),
              Text(
                'قائمة المستخدمين (${users.length})',
                style: getBoldTextStyle(
                  fontSize: ManagerFontSize.s13,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: ManagerHeight.h10),
          ...users.take(3).map((user) => Padding(
            padding: EdgeInsets.only(bottom: ManagerHeight.h6),
            child: Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                SizedBox(width: ManagerWidth.w8),
                Expanded(
                  child: Text(
                    user.name,
                    style: getRegularTextStyle(
                      fontSize: ManagerFontSize.s12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                if (user.phoneNumber != null)
                  Text(
                    user.phoneNumber!,
                    style: getRegularTextStyle(
                      fontSize: ManagerFontSize.s11,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          )),
          if (users.length > 3)
            Text(
              'و ${users.length - 3} آخرين...',
              style: getRegularTextStyle(
                fontSize: ManagerFontSize.s11,
                color: Colors.grey.shade500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter(ChatGroupController controller) {
    return Container(
      padding: EdgeInsets.all(ManagerWidth.w16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Get.back(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: ManagerHeight.h14,
                ),
              ),
              child: Text(
                "إلغاء",
                style: getBoldTextStyle(
                  fontSize: ManagerFontSize.s14,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ),
          SizedBox(width: ManagerWidth.w12),
          Expanded(
            flex: 2,
            child: Obx(() => ElevatedButton.icon(
              onPressed: selectedOption == null || controller.isSendingSms.value
                  ? null
                  : () => _confirmAndSend(controller),
              style: ElevatedButton.styleFrom(
                backgroundColor: ManagerColors.primaryColor,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: ManagerHeight.h14,
                ),
                elevation: selectedOption != null ? 4 : 0,
              ),
              icon: controller.isSendingSms.value
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              label: Text(
                controller.isSendingSms.value ? "جاري الإرسال..." : "إرسال SMS",
                style: getBoldTextStyle(
                  fontSize: ManagerFontSize.s14,
                  color: Colors.white,
                ),
              ),
            )),
          ),
        ],
      ),
    );
  }

  void _confirmAndSend(ChatGroupController controller) {
    if (selectedOption == null) return;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(ManagerWidth.w8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            ),
            SizedBox(width: ManagerWidth.w12),
            Expanded(
              child: Text(
                'تأكيد الإرسال',
                style: getBoldTextStyle(
                  fontSize: ManagerFontSize.s16,
                  color: ManagerColors.black,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل أنت متأكد من إرسال رسائل SMS إلى المستخدمين المحددين؟',
              style: getRegularTextStyle(
                fontSize: ManagerFontSize.s14,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: ManagerHeight.h12),
            Container(
              padding: EdgeInsets.all(ManagerWidth.w12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                  SizedBox(width: ManagerWidth.w8),
                  Expanded(
                    child: Text(
                      'سيتم تحديث حالة الرسالة بعد الإرسال',
                      style: getRegularTextStyle(
                        fontSize: ManagerFontSize.s12,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'إلغاء',
              style: getRegularTextStyle(
                fontSize: ManagerFontSize.s14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async{
              Get.back();
              await controller.sendSmsTo(selectedOption!);
              if (Get.isDialogOpen ?? false) Get.back(); // إغلاق الـ Dialog بعد انتهاء الإرسال
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ManagerColors.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: ManagerWidth.w20,
                vertical: ManagerHeight.h12,
              ),
            ),
            icon: const Icon(Icons.send, color: Colors.white, size: 18),
            label: Text(
              'تأكيد وإرسال',
              style: getBoldTextStyle(
                fontSize: ManagerFontSize.s14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}