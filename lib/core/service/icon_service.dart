import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../resources/manager_colors.dart';
import '../resources/manager_icon_size.dart';
import '../resources/manager_icons.dart';

class IconService {
  final Map<IconData, IconData> icons = {
    ManagerIcons.arrowBackAndroid: ManagerIcons.arrowBackIos,
  };

  IconData? getPlatformIcon(IconData icon) {
    if (Platform.isIOS) {
      if (icons.containsKey(icon)) {
        return icons[icon];
      } else if (icons.containsValue(icon)) {
        return icon;
      }
    } else {
      if (icons.containsKey(icon)) {
        return icon;
      } else if (icons.containsValue(icon)) {
        return icons.entries.firstWhere((entry) => entry.value == icon).key;
      }
    }
    return icon;
  }

  Icon getIcon({
    required IconData icon,
    Color? color,
    double? iconSize,
  }) {
    return Icon(
      getPlatformIcon(icon),
      color: color ?? ManagerColors.primaryColor,
      size: iconSize ?? ManagerIconSize.s20,
    );
  }
}
