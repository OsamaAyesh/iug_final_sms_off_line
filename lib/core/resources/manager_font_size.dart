import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A class defined for font sizes in the app
class ManagerFontSize {
  static double _getSize(double size) {
    if (size <= 12) {
      return size.sp.clamp(10, 14);
    } else if (size <= 18) {
      return size.sp.clamp(12, 18);
    } else if (size <= 24) {
      return size.sp.clamp(14, 22);
    } else if (size <= 32) {
      return size.sp.clamp(16, 28);
    } else if (size <= 40) {
      return size.sp.clamp(18, 36);
    } else if (size <= 60) {
      return size.sp.clamp(20, 50);
    } else if (size <= 80) {
      return size.sp.clamp(22, 80);
    } else if (size <= 100) {
      return size.sp.clamp(24, 102);
    } else {
      return size.sp.clamp(26, 120);
    }
  }

  static double get s1 => _getSize(1);
  static double get s2 => _getSize(2);
  static double get s3 => _getSize(3);
  static double get s4 => _getSize(4);
  static double get s5 => _getSize(5);
  static double get s6 => _getSize(6);
  static double get s7 => _getSize(7);
  static double get s8 => _getSize(8);
  static double get s9 => _getSize(9);
  static double get s10 => _getSize(10);
  static double get s11 => _getSize(11);
  static double get s12 => _getSize(12);
  static double get s13 => _getSize(13);
  static double get s14 => _getSize(14);
  static double get s15 => _getSize(15);
  static double get s16 => _getSize(16);
  static double get s17 => _getSize(17);
  static double get s18 => _getSize(18);
  static double get s19 => _getSize(19);
  static double get s20 => _getSize(20);
  static double get s21 => _getSize(21);
  static double get s22 => _getSize(22);
  static double get s23 => _getSize(23);
  static double get s24 => _getSize(24);
  static double get s25 => _getSize(25);
  static double get s26 => _getSize(26);
  static double get s27 => _getSize(27);
  static double get s28 => _getSize(28);
  static double get s29 => _getSize(29);
  static double get s30 => _getSize(30);
  static double get s31 => _getSize(31);
  static double get s32 => _getSize(32);
  static double get s33 => _getSize(33);
  static double get s34 => _getSize(34);
  static double get s35 => _getSize(35);
  static double get s36 => _getSize(36);
  static double get s37 => _getSize(37);
  static double get s38 => _getSize(38);
  static double get s39 => _getSize(39);
  static double get s40 => _getSize(40);
  static double get s41 => _getSize(41);
  static double get s42 => _getSize(42);
  static double get s43 => _getSize(43);
  static double get s44 => _getSize(44);
  static double get s45 => _getSize(45);
  static double get s46 => _getSize(46);
  static double get s47 => _getSize(47);
  static double get s48 => _getSize(48);
  static double get s49 => _getSize(49);
  static double get s50 => _getSize(50);
  static double get s55 => _getSize(55);
  static double get s60 => _getSize(60);
  static double get s65 => _getSize(65);
  static double get s70 => _getSize(70);
  static double get s75 => _getSize(75);
  static double get s80 => _getSize(80);
  static double get s85 => _getSize(85);
  static double get s90 => _getSize(90);
  static double get s95 => _getSize(95);
  static double get s100 => _getSize(100);
}
