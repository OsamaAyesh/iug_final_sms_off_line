import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_images.dart';
import 'package:app_mobile/core/resources/manager_radius.dart';
import 'package:app_mobile/core/resources/manager_strings.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';
import 'package:app_mobile/core/resources/manager_width.dart';
import 'package:app_mobile/features/auth/presentation/widgets/back_ground_auth_widget.dart';
import '../../../../core/widgets/button_app.dart';
import '../../../../core/widgets/custom_animated_phone_field.dart';
import '../controller/auth_controller.dart';
import 'otp_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();

    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();

    return Scaffold(
      body: Stack(
        children: [
          const BackGroundAuthWidget(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: ManagerWidth.w16),
            child: Column(
              children: [
                SizedBox(height: ManagerHeight.h97),
                Image.asset(
                  ManagerImages.logo,
                  height: ManagerHeight.h69,
                  width: ManagerWidth.w128,
                ),
                SizedBox(height: ManagerHeight.h12),
                Text(
                  ManagerStrings.loginTitleScreen,
                  style: getBoldTextStyle(
                    fontSize: ManagerFontSize.s18,
                    color: ManagerColors.white,
                  ),
                ),
                SizedBox(height: ManagerHeight.h6),
                Text(
                  ManagerStrings.loginSubTitleScreen,
                  style: getRegularTextStyle(
                    fontSize: ManagerFontSize.s12,
                    color: ManagerColors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: ManagerHeight.h24),
                Container(
                  decoration: BoxDecoration(
                    color: ManagerColors.white,
                    borderRadius: BorderRadius.circular(ManagerRadius.r8),
                    boxShadow: [
                      BoxShadow(
                        color: ManagerColors.black.withOpacity(0.08),
                        offset: const Offset(0, 2),
                        blurRadius: 20,
                      )
                    ],
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: ManagerHeight.h20,
                    horizontal: ManagerWidth.w12,
                  ),
                  child: Column(
                    children: [
                      Text(
                        ManagerStrings.enterDataLogin,
                        style: getBoldTextStyle(
                          fontSize: ManagerFontSize.s16,
                          color: ManagerColors.primaryColor,
                        ),
                      ),
                      SizedBox(height: ManagerHeight.h16),
                      CustomAnimatedTextField(
                        label: ManagerStrings.enterDataLogin1,
                        controller: nameController,
                      ),
                      SizedBox(height: ManagerHeight.h12),
                      CustomAnimatedTextField(
                        label: ManagerStrings.enterDataLogin2,
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        isPhoneNumber: true,
                      ),
                      SizedBox(height: ManagerHeight.h6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          ManagerStrings.enterDataLogin3,
                          style: getRegularTextStyle(
                            fontSize: ManagerFontSize.s12,
                            color: ManagerColors.primaryColor,
                          ),
                        ),
                      ),
                      SizedBox(height: ManagerHeight.h16),
                      ButtonApp(
                        title: ManagerStrings.enterDataLogin4,
                        paddingWidth: 0,
                        onPressed: () async {
                          final controller = Get.find<AuthController>();
                          await controller.sendOtp(
                            nameController.text.trim(),
                            phoneController.text.trim(),
                          );

                          if (controller.isOtpSent.value) {
                            Get.to(() => OtpScreen(
                              phone: phoneController.text.trim(),
                              name: nameController.text.trim(),
                            ));
                          }
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: ManagerHeight.h16),
                Text.rich(
                  TextSpan(
                    text: ManagerStrings.hintPrivacyLogin1,
                    style: getRegularTextStyle(
                      fontSize: ManagerFontSize.s12,
                      color: ManagerColors.black,
                    ),
                    children: [
                      TextSpan(
                        text: ManagerStrings.hintPrivacyLogin2,
                        style: getBoldTextStyle(
                          fontSize: ManagerFontSize.s12,
                          color: ManagerColors.primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

