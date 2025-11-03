import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_radius.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';
import 'package:flutter/material.dart';

class ButtonApp extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  final double paddingWidth;

  const ButtonApp(
      {super.key,
        required this.title,
        required this.onPressed,
        required this.paddingWidth});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: paddingWidth),
        child: Container(
          height: ManagerHeight.h46,
          width: double.infinity,
          decoration: BoxDecoration(
            color: ManagerColors.primaryColor,
            borderRadius: BorderRadius.circular(ManagerRadius.r5),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: getBoldTextStyle(
              fontSize: ManagerFontSize.s14,
              color: ManagerColors.white,
            ),
          ),
        ),
      ),
    );
  }
}
