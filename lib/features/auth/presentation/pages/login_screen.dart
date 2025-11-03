import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_images.dart';
import 'package:app_mobile/core/resources/manager_strings.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';
import 'package:app_mobile/core/resources/manager_width.dart';
import 'package:app_mobile/features/auth/presentation/widgets/back_ground_auth_widget.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ///=Background Container With primary Color
          const BackGroundAuthWidget(),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ManagerWidth.w16,
            ),
            child: Column(
              children: [
                SizedBox(
                  height: ManagerHeight.h97,
                ),
                Image.asset(
                  ManagerImages.logo,
                  height: ManagerHeight.h69,
                  width: ManagerWidth.w128,
                ),
                SizedBox(
                  height: ManagerHeight.h12,
                ),
                Text(
                  ManagerStrings.loginTitleScreen,
                  style: getBoldTextStyle(
                    fontSize: ManagerFontSize.s18,
                    color: ManagerColors.white,
                  ),
                ),
                SizedBox(
                  height: ManagerHeight.h6,
                ),
                Text(
                  ManagerStrings.loginSubTitleScreen,
                  style: getRegularTextStyle(
                    fontSize: ManagerFontSize.s12,
                    color: ManagerColors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: ManagerHeight.h24,
                ),
                Container(
                  height: ManagerHeight.h273,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: ManagerColors.white,
                  ),
                  child: Column(
                    children: [

                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: ManagerWidth.w16),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: ManagerColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: ManagerWidth.w12,
                      vertical: ManagerHeight.h6,
                    ),
                    child: Row(
                      children: [
                        // 🔹 Dropdown لاختيار الدولة
                        StatefulBuilder(
                          builder: (context, setState) {
                            String selectedCode = '+970';
                            final List<Map<String, String>> countries = [
                              {'flag': '🇵🇸', 'code': '+970', 'name': 'فلسطين'},
                              {'flag': '🇮🇱', 'code': '+972', 'name': 'إسرائيل'},
                            ];
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedCode,
                                    items: countries.map((country) {
                                      return DropdownMenuItem<String>(
                                        value: country['code'],
                                        child: Row(
                                          children: [
                                            Text(country['flag']!, style: const TextStyle(fontSize: 20)),
                                            const SizedBox(width: 6),
                                            Text(
                                              country['code']!,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedCode = value!;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(width: 8),

                        // 🔹 حقل إدخال رقم الهاتف
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: '059XXXXXXX',
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                            ),
                            onChanged: (value) {
                              // منطق التحقق من الرقم
                              if (!value.startsWith('05')) {
                                debugPrint('⚠️ يجب أن يبدأ الرقم بـ 05');
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
