import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../resources/manager_colors.dart';
import '../resources/manager_font_size.dart';
import '../resources/manager_styles.dart';

class AppSnackbar {
  static bool get isArabic => Get.locale?.languageCode == 'ar';
  static void success( String arabicMessage,{

    String? englishMessage,
    String? title,
  }) {
    final isArabic = Get.locale?.languageCode == 'ar';
    final message = isArabic ? arabicMessage : (englishMessage ?? arabicMessage);

    Get.snackbar(
      '',
      '',
      titleText: Text(
        title ?? (isArabic ? 'تم بنجاح' : 'Success'),
        style: getBoldTextStyle(
          fontSize: ManagerFontSize.s14,
          color: Colors.green.shade900,
        ),
      ),
      messageText: Text(
        message,
        style: getRegularTextStyle(
          fontSize: ManagerFontSize.s12,
          color: ManagerColors.black,
        ),
      ),
      backgroundColor: Colors.green.shade100,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 12,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.check_circle, color: Colors.green),
    );
  }

  // static void success(String message,{String? title}) {
  //   Get.snackbar(
  //     '',
  //     '',
  //     titleText: Text(
  //       title ?? (isArabic ? 'تم بنجاح' : 'Success'),
  //       style: getBoldTextStyle(
  //         fontSize: ManagerFontSize.s14,
  //         color: Colors.green.shade900,
  //       ),
  //     ),
  //     messageText: Text(
  //       message,
  //       style: getRegularTextStyle(
  //         fontSize: ManagerFontSize.s12,
  //         color: ManagerColors.black,
  //       ),
  //     ),
  //     backgroundColor: Colors.green.shade100,
  //     margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //     borderRadius: 12,
  //     snackPosition: SnackPosition.BOTTOM,
  //     duration: const Duration(seconds: 3),
  //     icon: const Icon(Icons.check_circle, color: Colors.green),
  //   );
  // }

  // static void error(String message,{String? title}) {
  //   Get.snackbar(
  //     '',
  //     '',
  //     titleText: Text(
  //       title ?? (isArabic ? 'حدث خطأ' : 'Error'),
  //       style: getBoldTextStyle(
  //         fontSize: ManagerFontSize.s14,
  //         color: Colors.red.shade900,
  //       ),
  //     ),
  //     messageText: Text(
  //       message,
  //       style: getRegularTextStyle(
  //         fontSize: ManagerFontSize.s12,
  //         color: ManagerColors.black,
  //       ),
  //     ),
  //     backgroundColor: Colors.red.shade100,
  //     margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //     borderRadius: 12,
  //     snackPosition: SnackPosition.BOTTOM,
  //     duration: const Duration(seconds: 3),
  //     icon: const Icon(Icons.error_outline, color: Colors.red),
  //   );
  // }
  static void error( String arabicMessage,{
    String? englishMessage,
    String? title,
  }) {
    final isArabic = Get.locale?.languageCode == 'ar';
    final message = isArabic ? arabicMessage : (englishMessage ?? arabicMessage);

    Get.snackbar(
      '',
      '',
      titleText: Text(
        title ?? (isArabic ? 'حدث خطأ' : 'Error'),
        style: getBoldTextStyle(
          fontSize: ManagerFontSize.s14,
          color: Colors.red.shade900,
        ),
      ),
      messageText: Text(
        message,
        style: getRegularTextStyle(
          fontSize: ManagerFontSize.s12,
          color: ManagerColors.black,
        ),
      ),
      backgroundColor: Colors.red.shade100,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 12,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.error_outline, color: Colors.red),
    );
  }

  static void warning(String arabicMessage,{
    String? englishMessage,
    String? title,
  }) {
    final isArabic = Get.locale?.languageCode == 'ar';
    final message = isArabic ? arabicMessage : (englishMessage ?? arabicMessage);

    Get.snackbar(
      '',
      '',
      titleText: Text(
        title ?? (isArabic ? 'تنبيه' : 'Warning'),
        style: getBoldTextStyle(
          fontSize: ManagerFontSize.s14,
          color: Colors.orange.shade900,
        ),
      ),
      messageText: Text(
        message,
        style: getRegularTextStyle(
          fontSize: ManagerFontSize.s12,
          color: ManagerColors.black,
        ),
      ),
      backgroundColor: Colors.orange.shade100,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 12,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.warning_amber_outlined, color: Colors.orange),
    );
  }

  // static void warning(String message, {String? title}) {
  //   Get.snackbar(
  //     '',
  //     '',
  //     titleText: Text(
  //       title ?? (isArabic ? 'تنبيه' : 'Warning'),
  //       style: getBoldTextStyle(
  //         fontSize: ManagerFontSize.s14,
  //         color: Colors.orange.shade900,
  //       ),
  //     ),
  //     messageText: Text(
  //       message,
  //       style: getRegularTextStyle(
  //         fontSize: ManagerFontSize.s12,
  //         color: ManagerColors.black,
  //       ),
  //     ),
  //     backgroundColor: Colors.orange.shade100,
  //     margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //     borderRadius: 12,
  //     snackPosition: SnackPosition.BOTTOM,
  //     duration: const Duration(seconds: 3),
  //     icon: const Icon(Icons.warning_amber_outlined, color: Colors.orange),
  //   );
  // }
  // static void loading(String message, {String? title}) {
  //   Get.snackbar(
  //     '',
  //     '',
  //     titleText: Text(
  //       title ?? (isArabic ? 'جاري المعالجة' : 'Processing...'),        style: getBoldTextStyle(
  //         fontSize: ManagerFontSize.s14,
  //         color: Colors.blue.shade900,
  //       ),
  //     ),
  //     messageText: Text(
  //       message,
  //       style: getRegularTextStyle(
  //         fontSize: ManagerFontSize.s12,
  //         color: ManagerColors.black,
  //       ),
  //     ),
  //     backgroundColor: Colors.blue.shade100,
  //     margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //     borderRadius: 12,
  //     snackPosition: SnackPosition.BOTTOM,
  //     duration: const Duration(seconds: 2), // أقصر لكونها حالة مؤقتة
  //     icon: const Icon(Icons.hourglass_bottom, color: Colors.blue),
  //   );
  // }
  static void loading(  String arabicMessage,
  {
    String? englishMessage,
    String? title,
  }) {
    final isArabic = Get.locale?.languageCode == 'ar';
    final message = isArabic ? arabicMessage : (englishMessage ?? arabicMessage);

    Get.snackbar(
      '',
      '',
      titleText: Text(
        title ?? (isArabic ? 'جاري المعالجة' : 'Processing...'),
        style: getBoldTextStyle(
          fontSize: ManagerFontSize.s14,
          color: Colors.blue.shade900,
        ),
      ),
      messageText: Text(
        message,
        style: getRegularTextStyle(
          fontSize: ManagerFontSize.s12,
          color: ManagerColors.black,
        ),
      ),
      backgroundColor: Colors.blue.shade100,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 12,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2), // مؤقتة وسريعة
      icon: const Icon(Icons.hourglass_bottom, color: Colors.blue),
    );
  }

}
