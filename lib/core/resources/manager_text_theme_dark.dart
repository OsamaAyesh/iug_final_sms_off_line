import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:flutter/material.dart';
import 'manager_colors.dart';
import 'manager_styles.dart';

/// A class defined for text theme dark the app
class ManagerTextThemeDark extends TextTheme {
  @override
  TextStyle get displayMedium => getMediumTextStyle(
        fontSize: ManagerFontSize.s20,
        color: ManagerColors.primaryColor,
      );

  @override
  TextStyle get displaySmall => getBoldTextStyle(
        fontSize: ManagerFontSize.s16,
        color: ManagerColors.primaryColor,
      );

  @override
  TextStyle get headlineMedium => getMediumTextStyle(
        fontSize: ManagerFontSize.s16,
        color: ManagerColors.primaryColor,
      );

  @override
  TextStyle get headlineSmall => getRegularTextStyle(
        fontSize: ManagerFontSize.s16,
        color: ManagerColors.primaryColor,
      );

  @override
  TextStyle get titleMedium => getMediumTextStyle(
        fontSize: ManagerFontSize.s16,
        color: ManagerColors.primaryColor,
      );

  @override
  TextStyle get bodyLarge => getRegularTextStyle(
        fontSize: ManagerFontSize.s16,
        color: ManagerColors.primaryColor,
      );
}
