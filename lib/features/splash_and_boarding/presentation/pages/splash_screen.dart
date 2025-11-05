import 'dart:async';
import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_images.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';
import 'package:app_mobile/features/auth/presentation/pages/login_screen.dart';
import 'package:app_mobile/features/splash_and_boarding/presentation/pages/on_boarding_screen.dart';
import 'package:app_mobile/features/splash_and_boarding/presentation/widgets/logo_in_splash_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/storage/local/app_settings_prefs.dart';
import '../../../home/home_feature/presentation/pages/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late AppSettingsPrefs _prefs;

  @override
  void initState() {
    super.initState();
    _initPrefsAndNavigate();
  }

  Future<void> _initPrefsAndNavigate() async {
    final sharedPrefs = await SharedPreferences.getInstance();
    _prefs = AppSettingsPrefs(sharedPrefs);
    await Future.delayed(const Duration(seconds: 2));

    _navigateBasedOnPrefs();
  }

  void _navigateBasedOnPrefs() {
    bool isOutBoardingViewed = _prefs.getOutBoardingScreenViewed();
    bool isLoggedIn = _prefs.getUserLoggedIn();

    if (!isOutBoardingViewed) {
      Get.offAll(const OnBoardingScreen());
    } else if (!isLoggedIn) {
      Get.offAll(const LoginScreen());
    } else {
      Get.offAll(const HomeScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      child: Scaffold(
        backgroundColor: ManagerColors.primaryColor,
        body: Stack(
          children: [
            /// Background Image
            Image.asset(
              ManagerImages.backgroundImageSplash,
              height: ManagerHeight.h700,
              width: double.infinity,
              fit: BoxFit.cover,
            ),

            /// Logo Widget
            const LogoInSplashWidget(),

            /// Version Application
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
      ),
    );
  }
}
