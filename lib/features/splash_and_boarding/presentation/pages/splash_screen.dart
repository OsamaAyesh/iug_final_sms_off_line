import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_images.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';
import 'package:app_mobile/features/splash_and_boarding/presentation/widgets/logo_in_splash_widget.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToOnboarding();
  }

  void _navigateToOnboarding() {
    // Timer(const Duration(seconds: 3), () {
    //   // if (mounted) {
    //   //   // Navigator.of(context).pushReplacementNamed('/onboarding');
    //   // }
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ManagerColors.primaryColor,
      body: Stack(
        children: [
          ///Background Image
          Image.asset(
            ManagerImages.backgroundImageSplash,
            height: ManagerHeight.h700,
            width: double.infinity,
            fit: BoxFit.cover,
          ),

          
          ///Logo Widget
          const LogoInSplashWidget(),

          ///Version Application
          Positioned(
            bottom: ManagerHeight.h40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'v 1.0.0',
                style: getRegularTextStyle(
                  fontSize: ManagerFontSize.s12,
                  color: ManagerColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
