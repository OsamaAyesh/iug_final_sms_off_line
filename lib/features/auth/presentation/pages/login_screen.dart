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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  final controller = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Start the animation when screen opens
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// Background layer
          const BackGroundAuthWidget(),

          /// Main content with fade and slide animation
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
                  
                      /// Logo
                      Image.asset(
                        ManagerImages.logo,
                        height: ManagerHeight.h69,
                        width: ManagerWidth.w128,
                      ),
                      SizedBox(height: ManagerHeight.h12),
                  
                      /// Title text
                      Text(
                        ManagerStrings.loginTitleScreen,
                        style: getBoldTextStyle(
                          fontSize: ManagerFontSize.s18,
                          color: ManagerColors.white,
                        ),
                      ),
                      SizedBox(height: ManagerHeight.h6),
                  
                      /// Subtitle text
                      Text(
                        ManagerStrings.loginSubTitleScreen,
                        style: getRegularTextStyle(
                          fontSize: ManagerFontSize.s12,
                          color: ManagerColors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: ManagerHeight.h24),
                  
                      /// White container for login fields
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
                            /// Section title
                            Text(
                              ManagerStrings.enterDataLogin,
                              style: getBoldTextStyle(
                                fontSize: ManagerFontSize.s16,
                                color: ManagerColors.primaryColor,
                              ),
                            ),
                            SizedBox(height: ManagerHeight.h16),
                  
                            /// Full name input
                            CustomAnimatedTextField(
                              label: ManagerStrings.enterDataLogin1,
                              controller: nameController,
                            ),
                            SizedBox(height: ManagerHeight.h12),
                  
                            /// Phone number input
                            CustomAnimatedTextField(
                              label: ManagerStrings.enterDataLogin2,
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              isPhoneNumber: true,
                            ),
                            SizedBox(height: ManagerHeight.h6),
                  
                            /// Phone note
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
                  
                            /// Login button
                            ButtonApp(
                              title: ManagerStrings.enterDataLogin4,
                              paddingWidth: 0,
                              onPressed: () async {
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
                  
                      /// Privacy text
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
