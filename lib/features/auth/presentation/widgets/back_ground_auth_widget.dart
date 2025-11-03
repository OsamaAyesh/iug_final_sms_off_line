import 'package:flutter/material.dart';

import '../../../../core/resources/manager_colors.dart';
import '../../../../core/resources/manager_height.dart';
import '../../../../core/resources/manager_images.dart';
class BackGroundAuthWidget extends StatelessWidget {
  const BackGroundAuthWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return  Container(
      height: ManagerHeight.h397,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: ManagerColors.primaryColor,
      ),
      child: Image.asset(ManagerImages.backgroundLogin,
        height: ManagerHeight.h397,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}
