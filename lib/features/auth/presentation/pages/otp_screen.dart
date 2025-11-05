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
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/resources/manager_strings.dart';
import '../controller/auth_controller.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final String name;

  const OtpScreen({
    super.key,
    required this.phone,
    required this.name,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final TextEditingController otpController = TextEditingController();
  final controller = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// Background widget
          const BackGroundAuthWidget(),

          /// Main content with animation
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: ManagerWidth.w16),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: ManagerHeight.h97),

                      /// Lock icon
                      Container(
                        height: ManagerHeight.h64,
                        width: ManagerWidth.w64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: ManagerColors.white.withOpacity(0.1),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: ManagerWidth.w10,
                            vertical: ManagerHeight.h10,
                          ),
                          child: Image.asset(
                            ManagerImages.iconLockWithOtp,
                            height: ManagerHeight.h36,
                            width: ManagerWidth.w36,
                          ),
                        ),
                      ),

                      SizedBox(height: ManagerHeight.h8),

                      /// Title text
                      Text(
                        ManagerStrings.otpTitle,
                        style: getBoldTextStyle(
                          fontSize: ManagerFontSize.s16,
                          color: ManagerColors.white,
                        ),
                      ),
                      SizedBox(height: ManagerHeight.h6),

                      /// Subtitle text
                      Text(
                        ManagerStrings.otpSubTitle,
                        style: getRegularTextStyle(
                          fontSize: ManagerFontSize.s12,
                          color: ManagerColors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: ManagerHeight.h4),

                      /// Display user phone
                      Text(
                        widget.phone,
                        style: getBoldTextStyle(
                          fontSize: ManagerFontSize.s13,
                          color: ManagerColors.white,
                        ),
                      ),
                      SizedBox(height: ManagerHeight.h24),

                      /// White container for OTP input and button
                      Container(
                        decoration: BoxDecoration(
                          color: ManagerColors.white,
                          borderRadius:
                          BorderRadius.circular(ManagerRadius.r8),
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
                            /// Section title
                            Text(
                              ManagerStrings.otpEnterCode,
                              style: getBoldTextStyle(
                                fontSize: ManagerFontSize.s16,
                                color: ManagerColors.primaryColor,
                              ),
                            ),
                            SizedBox(height: ManagerHeight.h16),

                            /// OTP field
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
                                    borderRadius: BorderRadius.circular(
                                        ManagerRadius.r8),
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
                                    color: ManagerColors.primaryColor
                                        .withOpacity(0.05),
                                    border: Border.all(
                                      color: ManagerColors.primaryColor,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                        ManagerRadius.r8),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: ManagerHeight.h10),

                            /// Timer text
                            Text(
                              ManagerStrings.otpTimer,
                              style: getRegularTextStyle(
                                fontSize: ManagerFontSize.s12,
                                color: ManagerColors.greyWithColor,
                              ),
                            ),
                            SizedBox(height: ManagerHeight.h4),

                            /// Resend message
                            Text(
                              "${ManagerStrings.otpDidNotReceive} ${ManagerStrings.otpRequestNew}",
                              style: getRegularTextStyle(
                                fontSize: ManagerFontSize.s12,
                                color: ManagerColors.greyWithColor,
                              ),
                            ),
                            SizedBox(height: ManagerHeight.h16),

                            /// Verify button
                            ButtonApp(
                              title: ManagerStrings.otpVerify,
                              paddingWidth: 0,
                              onPressed: () {
                                controller.verifyOtp(
                                  widget.phone,
                                  otpController.text.trim(),
                                  widget.name,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          /// ✅ Dynamic loading overlay (covers entire screen when isLoading = true)
          Obx(() {
            if (controller.isLoading.value) {
              return AnimatedOpacity(
                opacity: 1,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black.withOpacity(0.4),
                  child: const Center(child: LoadingWidget()),
                ),
              );
            } else {
              return const SizedBox.shrink();
            }
          }),
        ],
      ),
    );
  }
}
