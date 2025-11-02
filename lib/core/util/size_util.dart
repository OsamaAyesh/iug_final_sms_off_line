import 'package:flutter/material.dart';
import '../../constants/constants/constants.dart';

/// A class defined to handle the sizes in the app
class SizeConfig {
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;
  static late double textScale;
  static late double scaleFactor;

  static void init(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    textScale = MediaQuery.of(context).textScaler.scale(1);

    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;

    scaleFactor = screenWidth / Constants.deviceWidth;
  }

  static double getFontSize(double sp) {
    return sp * scaleFactor * textScale;
  }

  static double getProportionateScreenWidth(double inputWidth) {
    return inputWidth * scaleFactor;
  }

  static double getProportionateScreenHeight(double inputHeight) {
    return inputHeight * scaleFactor;
  }

  static double getIconSize(double size) {
    return getProportionateScreenWidth(
      size,
    );
  }

  static double getRadius(double radius) {
    return getProportionateScreenWidth(
      radius,
    );
  }
}