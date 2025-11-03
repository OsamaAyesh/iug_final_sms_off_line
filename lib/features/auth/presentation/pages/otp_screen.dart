import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_images.dart';
import 'package:app_mobile/core/resources/manager_radius.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';
import 'package:app_mobile/core/resources/manager_width.dart';
import 'package:app_mobile/features/auth/presentation/widgets/back_ground_auth_widget.dart';
import '../../../../core/widgets/button_app.dart';
import '../controller/auth_controller.dart';

class OtpScreen extends StatelessWidget {
  final String phone;
  final String name;

  const OtpScreen({
    super.key,
    required this.phone,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    final TextEditingController otpController = TextEditingController();

    return Scaffold(
      body: Stack(
        children: [
          const BackGroundAuthWidget(),

          /// 🧱 المحتوى الرئيسي
          Padding(
            padding: EdgeInsets.symmetric(horizontal: ManagerWidth.w16),
            child: Column(
              children: [
                SizedBox(height: ManagerHeight.h97),

                /// 🔒 الأيقونة والعنوان
                Container(
                  height: ManagerHeight.h64,
                  width: ManagerWidth.w64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: ManagerColors.white.withOpacity(0.1),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: ManagerWidth.w10 ,vertical: ManagerHeight.h10),
                    child: Image.asset(
                      ManagerImages.iconLockWithOtp,
                      height: ManagerHeight.h36,
                      width: ManagerWidth.w36,
                    ),
                  ),
                ),
                SizedBox(height: ManagerHeight.h8),
                Text(
                  "أدخل رمز التحقق",
                  style: getBoldTextStyle(
                    fontSize: ManagerFontSize.s16,
                    color: ManagerColors.white,
                  ),
                ),
                SizedBox(height: ManagerHeight.h6),
                Text(
                  "لقد قمنا بإرسال رمز التأكيد لرقم الهاتف التالي",
                  style: getRegularTextStyle(
                    fontSize: ManagerFontSize.s12,
                    color: ManagerColors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: ManagerHeight.h4),
                Text(
                  phone,
                  style: getBoldTextStyle(
                    fontSize: ManagerFontSize.s13,
                    color: ManagerColors.white,
                  ),
                ),
                SizedBox(height: ManagerHeight.h24),

                /// ⚪ صندوق الإدخال
                Container(
                  decoration: BoxDecoration(
                    color: ManagerColors.white,
                    borderRadius: BorderRadius.circular(ManagerRadius.r8),
                    boxShadow: [
                      BoxShadow(
                        color: ManagerColors.black.withOpacity(0.08),
                        offset: const Offset(0, 2),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: ManagerHeight.h20,
                    horizontal: ManagerWidth.w12,
                  ),
                  child: Column(
                    children: [
                      Text(
                        "أدخل الرمز",
                        style: getBoldTextStyle(
                          fontSize: ManagerFontSize.s16,
                          color: ManagerColors.primaryColor,
                        ),
                      ),
                      SizedBox(height: ManagerHeight.h16),

                      /// 🔢 حقل الرمز
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Pinput(
                          length: 6,
                          controller: otpController,
                          defaultPinTheme: PinTheme(
                            width: ManagerWidth.w42,
                            height: ManagerHeight.h52,
                            textStyle: getBoldTextStyle(
                              fontSize: ManagerFontSize.s18,
                              color: ManagerColors.primaryColor,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: ManagerColors.primaryColor,
                                width: 1,
                              ),
                              borderRadius:
                              BorderRadius.circular(ManagerRadius.r8),
                            ),
                          ),
                          focusedPinTheme: PinTheme(
                            width: ManagerWidth.w42,
                            height: ManagerHeight.h52,
                            textStyle: getBoldTextStyle(
                              fontSize: ManagerFontSize.s18,
                              color: ManagerColors.primaryColor,
                            ),
                            decoration: BoxDecoration(
                              color:
                              ManagerColors.primaryColor.withOpacity(0.05),
                              border: Border.all(
                                color: ManagerColors.primaryColor,
                                width: 2,
                              ),
                              borderRadius:
                              BorderRadius.circular(ManagerRadius.r8),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: ManagerHeight.h10),

                      /// ⏱️ نص الوقت
                      Text(
                        "00:59",
                        style: getRegularTextStyle(
                          fontSize: ManagerFontSize.s12,
                          color: ManagerColors.greyWithColor,
                        ),
                      ),
                      SizedBox(height: ManagerHeight.h4),

                      Text(
                        "لم تستلم رمزاً ؟ طلب رمز جديد",
                        style: getRegularTextStyle(
                          fontSize: ManagerFontSize.s12,
                          color: ManagerColors.greyWithColor,
                        ),
                      ),
                      SizedBox(height: ManagerHeight.h16),

                      /// ✅ زر التحقق
                      Obx(() {
                        return controller.isLoading.value
                            ? const Center(
                          child: CircularProgressIndicator(),
                        )
                            : ButtonApp(
                          title: "تحقق",
                          paddingWidth: 0,
                          onPressed: () {
                            controller.verifyOtp(
                              phone,
                              otpController.text.trim(),
                              name,
                            );
                          },
                        );
                      }),
                    ],
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
