import 'package:app_mobile/features/auth/presentation/pages/otp_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_images.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';
import 'package:app_mobile/core/resources/manager_width.dart';
import '../../../../core/widgets/button_app.dart';

class SuccessVerifyScreen extends StatelessWidget {
  const SuccessVerifyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          ///
          Positioned.fill(
            child: Image.asset(
              ManagerImages.backGroundSuccessScreen,
              fit: BoxFit.cover,
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: ManagerWidth.w20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: ManagerHeight.h40),

                /// 🎉 الأيقونة
                Image.asset(
                  ManagerImages.iconSuccess,
                  height: ManagerHeight.h80,
                  width: ManagerWidth.w80,
                ),

                SizedBox(height: ManagerHeight.h16),

                /// 🎯 العنوان
                Text(
                  "تهانينا!",
                  style: getBoldTextStyle(
                    fontSize: ManagerFontSize.s20,
                    color: ManagerColors.black,
                  ),
                ),

                SizedBox(height: ManagerHeight.h8),

                /// 💬 الوصف
                Text(
                  "لقد تم التحقق من الرمز بنجاح، يمكنك الآن متابعة العمل مع جميع مزايا تطبيقنا وقتاً سعيداً.",
                  style: getRegularTextStyle(
                    fontSize: ManagerFontSize.s13,
                    color: ManagerColors.greyWithColor,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: ManagerHeight.h24),

                /// 🔵 زر الانتقال
                ButtonApp(
                  title: "الذهاب إلى الرئيسية",
                  paddingWidth: 0,
                  onPressed: () {
                    Get.to(OtpScreen(phone: "0567450057", name: "Osama Ayesh"));
                  },
                ),

                SizedBox(height: ManagerHeight.h16),

                /// 📄 رابط الخصوصية
                GestureDetector(
                  onTap: () {
                    Get.toNamed('/privacy');
                  },
                  child: Text(
                    "تصفح سياسات الاستخدام والخصوصية",
                    style: getRegularTextStyle(
                      fontSize: ManagerFontSize.s12,
                      color: ManagerColors.primaryColor,
                      // decoration: ManagerColors.black,
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
}
