
import 'dart:io';
import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/util/snack_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';

class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  /// ✅ اختيار صورة من المعرض
  static Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('❌ Error picking image from gallery: $e');
      AppSnackbar.error('فشل اختيار الصورة: $e');
      return null;
    }
  }

  /// ✅ التقاط صورة من الكاميرا
  static Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('❌ Error picking image from camera: $e');
      AppSnackbar.error('فشل التقاط الصورة: $e');
      return null;
    }
  }
}