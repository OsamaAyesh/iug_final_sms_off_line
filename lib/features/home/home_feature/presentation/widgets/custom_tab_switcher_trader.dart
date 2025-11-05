import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_radius.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';
import 'package:app_mobile/core/resources/manager_width.dart';
import 'package:flutter/material.dart';

class CustomTabSwitcherTrader extends StatelessWidget {
  final TabController controller;
  final List<String> tabs;

  const CustomTabSwitcherTrader({
    super.key,
    required this.controller,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ManagerWidth.w16),
      child: Container(
        height: ManagerHeight.h44,
        decoration: BoxDecoration(
          color: ManagerColors.primaryColor.withOpacity(0.01),
          borderRadius: BorderRadius.circular(ManagerRadius.r8),
        ),
        child: TabBar(
          controller: controller,
          indicatorPadding: EdgeInsets.zero,
          indicator: BoxDecoration(
            color: ManagerColors.primaryColor,
            borderRadius: _buildRadius(controller.index),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: ManagerColors.primaryColor,
          labelStyle: getBoldTextStyle(
            fontSize: ManagerFontSize.s10,
            color: Colors.white,
          ),
          unselectedLabelStyle: getRegularTextStyle(
            fontSize: ManagerFontSize.s10,
            color: ManagerColors.primaryColor,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          overlayColor: MaterialStateProperty.all(Colors.transparent),
          dividerColor: Colors.transparent,
          tabs: tabs.map((label) => Tab(text: label)).toList(),
        ),
      ),
    );
  }

  BorderRadius _buildRadius(int index) {
    // if (index == 0) {
    //   return BorderRadius.only(
    //     topRight: Radius.circular(ManagerRadius.r8),
    //     bottomRight: Radius.circular(ManagerRadius.r8),
    //   );
    // } else if (index == tabs.length - 1) {
    //   return BorderRadius.only(
    //     topLeft: Radius.circular(ManagerRadius.r8),
    //     bottomLeft: Radius.circular(ManagerRadius.r8),
    //   );
    // }
    return BorderRadius.circular(ManagerRadius.r8);
  }
}