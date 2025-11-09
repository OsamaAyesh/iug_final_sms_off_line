import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';
import 'package:app_mobile/core/resources/manager_width.dart';
import 'package:app_mobile/features/home/add_chat/presentation/pages/cloudinary_image_avatar.dart';

import '../domain/models/profile_model.dart';
import 'controller/profile_controller.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ProfileController controller = Get.find<ProfileController>();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Obx(() {
        final profile = controller.profile.value;
        if (profile == null) {
          return _buildLoadingState();
        }

        return _buildEditForm(profile);
      }),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: ManagerColors.primaryColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Get.back(),
      ),
      title: Text(
        'تعديل الملف الشخصي',
        style: getBoldTextStyle(
          fontSize: ManagerFontSize.s18,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      actions: [
        Obx(() {
          return IconButton(
            icon: controller.isUpdating.value
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : Icon(Icons.check, color: Colors.white),
            onPressed: controller.isUpdating.value ? null : _saveProfile,
          );
        }),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildEditForm(ProfileModel profile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(ManagerWidth.w20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Profile Image
            _buildProfileImage(profile),
            SizedBox(height: ManagerHeight.h30),

            // Name Field
            _buildNameField(),
            SizedBox(height: ManagerHeight.h20),

            // Bio Field
            _buildBioField(),
            SizedBox(height: ManagerHeight.h30),

            // Read-only Fields
            _buildReadOnlyFields(profile),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage(ProfileModel profile) {
    return Center(
      child: Stack(
        children: [
          // ✅ صورة الملف الشخصي مع مؤشر تحميل
          Obx(() {
            if (controller.isUploadingImage.value) {
              return Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(ManagerColors.primaryColor),
                  ),
                ),
              );
            } else {
              return CloudinaryAvatar(
                imageUrl: profile.imageUrl,
                fallbackText: profile.name,
                radius: 60,
              );
            }
          }),

          // ✅ زر تغيير الصورة
          Positioned(
            bottom: 0,
            right: 0,
            child: Obx(() {
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ManagerColors.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: controller.isUploadingImage.value
                      ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Icon(Icons.camera_alt, size: 18, color: Colors.white),
                  onPressed: controller.isUploadingImage.value ? null : _changeProfileImage,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.person_outline,
              color: ManagerColors.primaryColor,
              size: 20,
            ),
            SizedBox(width: ManagerWidth.w8),
            Text(
              'الاسم',
              style: getBoldTextStyle(
                fontSize: ManagerFontSize.s14,
                color: ManagerColors.black,
              ),
            ),
            Text(
              ' *',
              style: getBoldTextStyle(
                fontSize: ManagerFontSize.s14,
                color: Colors.red,
              ),
            ),
          ],
        ),
        SizedBox(height: ManagerHeight.h10),
        TextFormField(
          controller: controller.nameController,
          textAlign: TextAlign.right,
          maxLength: 50,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'الرجاء إدخال الاسم';
            }
            if (value.trim().length < 2) {
              return 'الاسم يجب أن يكون حرفين على الأقل';
            }
            return null;
          },
          style: getRegularTextStyle(
            fontSize: ManagerFontSize.s14,
            color: ManagerColors.black,
          ),
          decoration: InputDecoration(
            hintText: 'أدخل اسمك',
            hintStyle: getRegularTextStyle(
              fontSize: ManagerFontSize.s14,
              color: Colors.grey.shade400,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ManagerColors.primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: ManagerWidth.w16,
              vertical: ManagerHeight.h16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.description,
              color: ManagerColors.primaryColor,
              size: 20,
            ),
            SizedBox(width: ManagerWidth.w8),
            Text(
              'نبذة عنك',
              style: getBoldTextStyle(
                fontSize: ManagerFontSize.s14,
                color: ManagerColors.black,
              ),
            ),
          ],
        ),
        SizedBox(height: ManagerHeight.h10),
        TextFormField(
          controller: controller.bioController,
          textAlign: TextAlign.right,
          maxLines: 3,
          maxLength: 200,
          style: getRegularTextStyle(
            fontSize: ManagerFontSize.s14,
            color: ManagerColors.black,
          ),
          decoration: InputDecoration(
            hintText: 'أخبرنا شيئاً عن نفسك...',
            hintStyle: getRegularTextStyle(
              fontSize: ManagerFontSize.s14,
              color: Colors.grey.shade400,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ManagerColors.primaryColor,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.all(ManagerWidth.w16),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyFields(ProfileModel profile) {
    return Container(
      padding: EdgeInsets.all(ManagerWidth.w16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildReadOnlyField(
            icon: Icons.phone,
            title: 'رقم الهاتف',
            value: profile.phone,
          ),
          SizedBox(height: ManagerHeight.h12),
          _buildReadOnlyField(
            icon: Icons.verified,
            title: 'الحالة',
            value: profile.isVerified ? 'موثوق' : 'غير موثوق',
          ),
          SizedBox(height: ManagerHeight.h12),
          _buildReadOnlyField(
            icon: Icons.calendar_today,
            title: 'تاريخ الإنشاء',
            value: _formatDate(profile.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        SizedBox(width: ManagerWidth.w12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: getBoldTextStyle(
                  fontSize: ManagerFontSize.s12,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: ManagerHeight.h4),
              Text(
                value,
                style: getRegularTextStyle(
                  fontSize: ManagerFontSize.s14,
                  color: ManagerColors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // ✅ تحديث دالة تغيير الصورة
  Future<void> _changeProfileImage() async {
    await controller.changeProfileImage();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      controller.updateProfile();
    }
  }
}