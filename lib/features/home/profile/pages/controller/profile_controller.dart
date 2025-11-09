import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:app_mobile/core/storage/local/app_settings_prefs.dart';
import 'package:app_mobile/core/util/snack_bar.dart';
import 'package:app_mobile/core/service/image_picker_service.dart';
import '../../../../../core/service/cloudinart_service.dart';
import '../../domain/models/profile_model.dart';
import '../../domain/use_cases/get_profile_usecase.dart';
import '../../domain/use_cases/update_profile_usecase.dart';
import '../../domain/use_cases/upload_profile_image_usecase.dart';

class ProfileController extends GetxController {
  final GetProfileUseCase getProfileUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  final UploadProfileImageUseCase uploadProfileImageUseCase;
  final AppSettingsPrefs _prefs = GetIt.instance<AppSettingsPrefs>();

  ProfileController({
    required this.getProfileUseCase,
    required this.updateProfileUseCase,
    required this.uploadProfileImageUseCase,
  });

  static ProfileController get to => Get.find<ProfileController>();

  // States
  final profile = Rxn<ProfileModel>();
  final isLoading = false.obs;
  final isUpdating = false.obs;
  final isUploadingImage = false.obs;

  // Form Controllers
  final nameController = TextEditingController();
  final bioController = TextEditingController();

  String get currentUserId => _prefs.getUserId();
  String get currentUserName => _prefs.getUserName();
  String get currentUserImage => _prefs.getUserImage() ?? '';

  @override
  void onInit() {
    super.onInit();
    print('👤 ProfileController initialized for user: $currentUserId');
    loadProfile();
  }

  /// 🔹 تحميل بيانات الملف الشخصي
  Future<void> loadProfile() async {
    if (currentUserId.isEmpty) {
      print('⚠️ Cannot load profile - user not logged in');
      AppSnackbar.loading('يجب تسجيل الدخول أولاً');
      return;
    }

    isLoading.value = true;

    try {
      print('🔄 Loading profile for user: $currentUserId');
      final userProfile = await getProfileUseCase.call(currentUserId);
      profile.value = userProfile;

      // تعيين القيم في الـ controllers للتحرير
      nameController.text = userProfile.name;
      bioController.text = userProfile.bio ?? '';

      print('✅ Profile loaded successfully: ${userProfile.name}');
      print('📞 Phone: ${userProfile.phone}');
      print('🖼️ Image: ${userProfile.imageUrl ?? "No image"}');

    } catch (e) {
      print('❌ Error loading profile: $e');
      AppSnackbar.error('فشل تحميل الملف الشخصي: $e');

      // ✅ إنشاء ملف شخصي افتراضي في حالة الخطأ
      _createDefaultProfile();
    } finally {
      isLoading.value = false;
    }
  }

  /// 🔹 إنشاء ملف شخصي افتراضي في حالة الخطأ
  void _createDefaultProfile() {
    final defaultProfile = ProfileModel(
      id: currentUserId,
      name: currentUserName.isNotEmpty ? currentUserName : 'مستخدم',
      phone: _prefs.getUserPhone() ?? '',
      imageUrl: currentUserImage.isNotEmpty ? currentUserImage : null,
      bio: null,
      lastSeen: DateTime.now(),
      isOnline: true,
      isVerified: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    profile.value = defaultProfile;
    nameController.text = defaultProfile.name;
    bioController.text = defaultProfile.bio ?? '';

    print('✅ Created default profile for user: ${defaultProfile.name}');
  }

  /// 🔹 تحديث بيانات الملف الشخصي
  Future<void> updateProfile() async {
    if (profile.value == null) {
      AppSnackbar.error('لا يمكن تحديث الملف الشخصي - البيانات غير متوفرة');
      return;
    }

    // التحقق من صحة البيانات
    final name = nameController.text.trim();
    final bio = bioController.text.trim();

    if (name.isEmpty) {
      AppSnackbar.error('الرجاء إدخال الاسم');
      return;
    }

    if (name.length < 2) {
      AppSnackbar.error('الاسم يجب أن يكون حرفين على الأقل');
      return;
    }

    isUpdating.value = true;

    try {
      print('🔄 Updating profile for user: $currentUserId');

      final updatedProfile = profile.value!.copyWith(
        name: name,
        bio: bio.isEmpty ? null : bio,
        // ✅ إزالة updatedAt من هنا - سيتعامل معها UseCase
      );

      await updateProfileUseCase.call(currentUserId, updatedProfile);

      // تحديث الـ profile المحلي
      profile.value = updatedProfile;

      // تحديث الـ SharedPreferences
      _prefs.setUserName(updatedProfile.name);

      print('✅ Profile updated successfully: ${updatedProfile.name}');
      AppSnackbar.success('تم تحديث الملف الشخصي بنجاح');

      // العودة للشاشة السابقة بعد التحديث
      Future.delayed(const Duration(milliseconds: 500), () {
        if (Get.isDialogOpen == false) {
          Get.back();
        }
      });

    } catch (e) {
      print('❌ Error updating profile: $e');
      AppSnackbar.error('فشل تحديث الملف الشخصي: $e');
    } finally {
      isUpdating.value = false;
    }
  }

  /// 🔹 تغيير صورة الملف الشخصي
  Future<void> changeProfileImage() async {
    if (currentUserId.isEmpty) {
      AppSnackbar.error('يجب تسجيل الدخول أولاً');
      return;
    }

    try {
      print('🔄 Starting profile image change...');

      // اختيار الصورة من المعرض
      final File? imageFile = await ImagePickerService.pickImageFromGallery();

      if (imageFile == null) {
        print('ℹ️ User cancelled image selection');
        return; // المستخدم ألغى العملية
      }

      isUploadingImage.value = true;

      print('📤 Uploading image to Cloudinary...');

      // ✅ استخدام الدالة الصحيحة من CloudinaryService
      final imageUrl = await CloudinaryService.upload(
        file: imageFile,
        type: 'image',
        folder: 'profile_images/$currentUserId',
      );

      print('✅ Image uploaded successfully: $imageUrl');

      // تحديث الصورة في الـ profile
      final updatedProfile = profile.value!.copyWith(
        imageUrl: imageUrl,
        // ✅ إزالة updatedAt من هنا
      );

      print('🔄 Updating profile with new image...');
      await updateProfileUseCase.call(currentUserId, updatedProfile);

      // تحديث البيانات المحلية
      profile.value = updatedProfile;
      _prefs.setUserImage(imageUrl);

      print('✅ Profile image updated successfully');
      AppSnackbar.success('تم تحديث صورة الملف الشخصي بنجاح');

    } catch (e) {
      print('❌ Error changing profile image: $e');
      AppSnackbar.error('فشل تحديث صورة الملف الشخصي: $e');
    } finally {
      isUploadingImage.value = false;
    }
  }

  /// 🔹 تحديث حالة الاتصال (متصل/غير متصل)
  void setOnlineStatus(bool isOnline) {
    if (profile.value == null) return;

    final updatedProfile = profile.value!.copyWith(
      isOnline: isOnline,
      lastSeen: isOnline ? null : DateTime.now(),
      // ✅ إزالة updatedAt من هنا
    );

    // تحديث الحالة محلياً أولاً
    profile.value = updatedProfile;

    // تحديث الخادم في الخلفية
    updateProfileUseCase.call(currentUserId, updatedProfile).catchError((e) {
      print('❌ Failed to update online status: $e');
      // إعادة الحالة السابقة في حالة الخطأ
      profile.value = profile.value!.copyWith(isOnline: !isOnline);
    });
  }

  /// 🔹 الحصول على نص آخر ظهور
  String getLastSeenText() {
    final currentProfile = profile.value;
    if (currentProfile == null) return 'غير معروف';

    if (currentProfile.isOnline) {
      return 'متصل الآن';
    }

    final lastSeen = currentProfile.lastSeen;
    if (lastSeen == null) {
      return 'آخر ظهور غير معروف';
    }

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inSeconds < 60) {
      return 'كان متصلًا الآن';
    } else if (difference.inMinutes < 1) {
      return 'كان متصلًا الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays == 1) {
      return 'منذ يوم';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else {
      return '${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
    }
  }

  /// 🔹 التحقق من اكتمال بيانات الملف الشخصي
  bool get isProfileComplete {
    final currentProfile = profile.value;
    if (currentProfile == null) return false;

    return currentProfile.name.isNotEmpty &&
        currentProfile.name != 'مستخدم' &&
        currentProfile.phone.isNotEmpty;
  }

  /// 🔹 الحصول على الأحرف الأولى من الاسم للصورة الافتراضية
  String get nameInitials {
    final name = profile.value?.name ?? currentUserName;
    if (name.isEmpty) return '?';

    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (name.length >= 2) {
      return name.substring(0, 2).toUpperCase();
    } else {
      return name[0].toUpperCase();
    }
  }

  /// 🔹 إعادة تحميل البيانات
  Future<void> refreshProfile() async {
    print('🔄 Refreshing profile data...');
    await loadProfile();
  }

  /// 🔹 تنظيف البيانات عند تسجيل الخروج
  void clearProfile() {
    profile.value = null;
    nameController.clear();
    bioController.clear();
    isLoading.value = false;
    isUpdating.value = false;
    isUploadingImage.value = false;

    print('✅ Profile data cleared');
  }

  /// 🔹 التحقق من صلاحية البيانات
  bool get isValid {
    final name = nameController.text.trim();
    return name.isNotEmpty && name.length >= 2;
  }

  @override
  void onClose() {
    nameController.dispose();
    bioController.dispose();
    print('🔚 ProfileController disposed');
    super.onClose();
  }
}