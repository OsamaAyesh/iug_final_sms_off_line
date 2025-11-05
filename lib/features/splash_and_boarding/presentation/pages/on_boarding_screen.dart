import 'package:app_mobile/features/auth/presentation/pages/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/resources/manager_colors.dart';
import '../../../../core/resources/manager_font_size.dart';
import '../../../../core/resources/manager_height.dart';
import '../../../../core/resources/manager_images.dart';
import '../../../../core/resources/manager_styles.dart';
import '../../../../core/resources/manager_width.dart';
import '../../../../core/resources/manager_strings.dart';
import '../../../../core/storage/local/app_settings_prefs.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({Key? key}) : super(key: key);

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _controller = PageController();
  bool isLastPage = false;
  int currentIndex = 0;
  late AppSettingsPrefs _prefs;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, String>> onBoardingData = [
    {
      "title": ManagerStrings.onBoardingTitle1,
      "description": ManagerStrings.onBoardingDescription1,
    },
    {
      "title": ManagerStrings.onBoardingTitle2,
      "description": ManagerStrings.onBoardingDescription2,
    },
    {
      "title": ManagerStrings.onBoardingTitle3,
      "description": ManagerStrings.onBoardingDescription3,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initPrefs();

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
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  Future<void> _initPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = AppSettingsPrefs(prefs);
  }

  void _animateToPage(int index) {
    setState(() {
      currentIndex = index;
      isLastPage = index == onBoardingData.length - 1;
    });

    _animationController.reset();
    _animationController.forward();
  }

  Future<void> _goToLogin() async {
    await _prefs.setOutBoardingScreenViewed();
    if (!mounted) return;
    Get.offAll(() => const LoginScreen());
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = onBoardingData[currentIndex];

    return Scaffold(
      backgroundColor: ManagerColors.white,
      body: SafeArea(
        top: false,
        bottom: true,
        child: Stack(
          children: [
            /// Background Image
            Center(
              child: Image.asset(
                ManagerImages.screenOnBoardingImage,
                height: ManagerHeight.h660,
                width: ManagerWidth.w304,
                fit: BoxFit.contain,
              ),
            ),

            /// Invisible PageView (swiping logic)
            PageView.builder(
              controller: _controller,
              itemCount: onBoardingData.length,
              physics: const BouncingScrollPhysics(),
              onPageChanged: _animateToPage,
              itemBuilder: (context, index) => const SizedBox(),
            ),

            /// Bottom Card
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: ManagerWidth.w16,
                  vertical: ManagerHeight.h12,
                ),
                decoration: BoxDecoration(
                  color: ManagerColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(
                  vertical: ManagerHeight.h24,
                  horizontal: ManagerWidth.w16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// Animated Texts
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              children: [
                                Text(
                                  item["title"]!,
                                  style: getBoldTextStyle(
                                    fontSize: ManagerFontSize.s16,
                                    color: ManagerColors.black,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: ManagerHeight.h8),
                                Text(
                                  item["description"]!,
                                  style: getRegularTextStyle(
                                    fontSize: ManagerFontSize.s12,
                                    color: ManagerColors.greyWithColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: ManagerHeight.h16),

                    /// Page Indicator
                    SmoothPageIndicator(
                      controller: _controller,
                      count: onBoardingData.length,
                      effect: ExpandingDotsEffect(
                        activeDotColor: ManagerColors.primaryColor,
                        dotColor: Colors.grey.shade300,
                        dotHeight: 6,
                        dotWidth: 6,
                        expansionFactor: 3,
                      ),
                      onDotClicked: (index) {
                        _controller.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),

                    SizedBox(height: ManagerHeight.h20),

                    /// Buttons
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ManagerColors.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: ManagerHeight.h12,
                          ),
                        ),
                        onPressed: () {
                          if (isLastPage) {
                            _goToLogin();
                          } else {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: Text(
                          isLastPage
                              ? ManagerStrings.onBoardingLoginButton
                              : ManagerStrings.onBoardingNextButton,
                          style: getBoldTextStyle(
                            fontSize: ManagerFontSize.s14,
                            color: ManagerColors.white,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: ManagerHeight.h6),

                    TextButton(
                      onPressed: _goToLogin,
                      child: Text(
                        ManagerStrings.onBoardingSkipButton,
                        style: getRegularTextStyle(
                          fontSize: ManagerFontSize.s12,
                          color: ManagerColors.greyWithColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
