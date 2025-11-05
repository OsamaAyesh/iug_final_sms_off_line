import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';
import 'package:app_mobile/core/resources/manager_width.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class EmptyStateWidget extends StatelessWidget {
  final String? messageAr;
  final String? messageEn;
  final String? lottieAsset;

  const EmptyStateWidget({
    super.key,
    this.messageAr = "لا توجد بيانات لعرضها حاليًا",
    this.messageEn,
    this.lottieAsset,
  });

  @override
  Widget build(BuildContext context) {
    // قراءة اللغة الحالية
    final locale = Get.locale?.languageCode ?? 'ar';
    final isArabic = locale == 'ar';

    // اختيار الرسالة حسب اللغة
    final message = isArabic
        ? (messageAr ?? "لا توجد بيانات لعرضها حاليًا")
        : (messageEn ?? "No data available currently");

    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              lottieAsset ?? 'assets/json/empty.json',
              width: ManagerWidth.w260,
              repeat: true,
              fit: BoxFit.contain,
            ),
            SizedBox(height: ManagerHeight.h24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: getRegularTextStyle(
                fontSize: ManagerFontSize.s14,
                color: ManagerColors.greyWithColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
