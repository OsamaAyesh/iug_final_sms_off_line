import 'package:app_mobile/core/util/snack_bar.dart';
import 'package:app_mobile/features/home/home_feature/presentation/pages/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_images.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';
import 'package:app_mobile/core/resources/manager_width.dart';
import '../../../../core/widgets/button_app.dart';
import '../../../../core/resources/manager_strings.dart';

class SuccessVerifyScreen extends StatefulWidget {
  const SuccessVerifyScreen({super.key});

  @override
  State<SuccessVerifyScreen> createState() => _SuccessVerifyScreenState();
}

class _SuccessVerifyScreenState extends State<SuccessVerifyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Define fade and scale animations
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    // Start animation when screen opens
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          /// Background image layer
          Positioned.fill(
            child: Image.asset(
              ManagerImages.backGroundSuccessScreen,
              fit: BoxFit.cover,
            ),
          ),

          /// Main animated content
          FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: ManagerWidth.w20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: ManagerHeight.h40),

                    /// Success icon
                    Image.asset(
                      ManagerImages.iconSuccess,
                      height: ManagerHeight.h80,
                      width: ManagerWidth.w80,
                    ),

                    SizedBox(height: ManagerHeight.h16),

                    /// Title text
                    Text(
                      ManagerStrings.successTitle,
                      style: getBoldTextStyle(
                        fontSize: ManagerFontSize.s20,
                        color: ManagerColors.black,
                      ),
                    ),

                    SizedBox(height: ManagerHeight.h8),

                    /// Description text
                    Text(
                      ManagerStrings.successDescription,
                      style: getRegularTextStyle(
                        fontSize: ManagerFontSize.s13,
                        color: ManagerColors.greySuccess,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: ManagerHeight.h24),

                    /// Main action button
                    ButtonApp(
                      title: ManagerStrings.successButton,
                      paddingWidth: 0,
                      onPressed: () {
                        // Navigate to home or next screen
                        Get.to(HomeScreen());
                        // AppSnackbar.success("تم التحقق بنجاح، انتقل إلى الرئيسية");
                      },
                    ),

                    SizedBox(height: ManagerHeight.h16),

                    /// Privacy and policy link
                    GestureDetector(
                      onTap: () {
                        AppSnackbar.warning(ManagerStrings.successWarning);
                      },
                      child: Text(
                        ManagerStrings.successPrivacyLink,
                        style: getRegularTextStyle(
                          fontSize: ManagerFontSize.s12,
                          color: ManagerColors.black,
                          decoration: TextDecoration.underline
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
