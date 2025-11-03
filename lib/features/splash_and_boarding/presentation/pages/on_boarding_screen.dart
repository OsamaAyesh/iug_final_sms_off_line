import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';
import 'package:app_mobile/core/resources/manager_width.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../core/resources/manager_colors.dart';
import '../../../../core/resources/manager_images.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({Key? key}) : super(key: key);

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  final PageController _controller = PageController();
  bool isLastPage = false;

  final List<Map<String, String>> onBoardingData = [
    {
      "title": "ابدأ تواصلك المؤسسي الذكي!",
      "description":
          "أنشئ بيئة اتصال فعّالة بين إدارتك وموظفيك، وابقَ على اطلاع دائم بكل الإشعارات والرسائل من مؤسستك الأكاديمية.",
    },
    {
      "title": "تواصل حتى دون إنترنت!",
      "description":
          "أرسل الرسائل والملاحظات عبر الإنترنت أو SMS لضمان وصولها لجميع أعضائك في كل الظروف.",
    },
    {
      "title": "إدارة ذكية للمجموعات والمحادثات!",
      "description":
          "تحكّم في المراسلات داخل المجموعات، وتواصل من مكان واحد بمشاركة المرفقات والصور والملاحظات بسهولة تامة.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: onBoardingData.length,
                onPageChanged: (index) {
                  setState(
                      () => isLastPage = index == onBoardingData.length - 1);
                },
                itemBuilder: (context, index) {
                  final item = onBoardingData[index];
                  return Padding(
                    padding:  EdgeInsets.symmetric(horizontal: ManagerWidth.w16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          ManagerImages.screenOnBoardingImage,
                          height: size.height * 0.45,
                        ),
                        const SizedBox(height: 30),
                        Text(
                          item['title']!,
                          style: getRegularTextStyle(
                              fontSize: ManagerFontSize.s18,
                              color: ManagerColors.black),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item['description']!,
                          textAlign: TextAlign.center,
                          style: getRegularTextStyle(
                              fontSize: ManagerFontSize.s12,
                              color: ManagerColors.greyOnBoarding),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Page indicator
            SmoothPageIndicator(
              controller: _controller,
              count: onBoardingData.length,
              effect: ExpandingDotsEffect(
                activeDotColor: ManagerColors.primaryColor,
                dotColor: Colors.grey.shade300,
                dotHeight: 8,
                dotWidth: 8,
                expansionFactor: 3,
              ),
            ),

            const SizedBox(height: 25),

            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      // Skip logic
                    },
                    child: Text(
                      "تخطي",
                      style: TextStyle(color: Colors.grey[600], fontSize: 15),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ManagerColors.primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      if (isLastPage) {
                        // Navigate to login
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Text(isLastPage ? "تسجيل الدخول" : "التالي"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
