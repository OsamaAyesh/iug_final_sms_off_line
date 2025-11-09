import 'package:app_mobile/features/home/profile/pages/widgets/profile_action_button.dart';
import 'package:app_mobile/features/home/profile/pages/widgets/profile_header.dart';
import 'package:app_mobile/features/home/profile/pages/widgets/profile_info_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';
import 'package:app_mobile/core/resources/manager_width.dart';
import 'package:app_mobile/core/util/snack_bar.dart';
import 'package:app_mobile/features/home/add_chat/presentation/pages/cloudinary_image_avatar.dart';
import '../domain/models/profile_model.dart';
import 'controller/profile_controller.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileController controller = Get.find<ProfileController>();

  @override
  void initState() {
    super.initState();
    // ✅ لا نحتاج لـ ProfileDI.init() هنا لأنه تم تهيئته مسبقاً
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildLoadingState();
        }

        final profile = controller.profile.value;
        if (profile == null) {
          return _buildErrorState();
        }

        return _buildProfileContent(profile);
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
        'الملف الشخصي',
        style: getBoldTextStyle(
          fontSize: ManagerFontSize.s18,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: ManagerHeight.h16),
          Text(
            'فشل تحميل الملف الشخصي',
            style: getBoldTextStyle(
              fontSize: ManagerFontSize.s16,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: ManagerHeight.h8),
          ElevatedButton(
            onPressed: controller.loadProfile, // ✅ استخدام loadProfile بدلاً من _loadProfile
            child: Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(ProfileModel profile) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: ManagerHeight.h20),
      child: Column(
        children: [
          // Header Section
          ProfileHeader(profile: profile),

          SizedBox(height: ManagerHeight.h24),

          // Info Cards Section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: ManagerWidth.w16),
            child: Column(
              children: [
                ProfileInfoCard(
                  icon: Icons.person,
                  title: 'المعلومات الشخصية',
                  subtitle: 'الاسم، البايو، وغيرها',
                  onTap: () => Get.to(() => EditProfileScreen()),
                ),
                SizedBox(height: ManagerHeight.h12),
                ProfileInfoCard(
                  icon: Icons.phone,
                  title: 'رقم الهاتف',
                  subtitle: profile.phone,
                  onTap: () {
                    AppSnackbar.loading('لا يمكن تعديل رقم الهاتف');
                  },
                ),
                SizedBox(height: ManagerHeight.h12),
                ProfileInfoCard(
                  icon: Icons.verified,
                  title: 'الحالة',
                  subtitle: profile.isVerified ? 'موثوق' : 'غير موثوق',
                  onTap: () {
                    AppSnackbar.loading(profile.isVerified
                        ? 'هذا الحساب موثوق'
                        : 'هذا الحساب غير موثوق');
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: ManagerHeight.h32),

          // Actions Section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: ManagerWidth.w16),
            child: Column(
              children: [
                ProfileActionButton(
                  icon: Icons.edit,
                  title: 'تعديل الملف الشخصي',
                  color: ManagerColors.primaryColor,
                  onTap: () => Get.to(() => EditProfileScreen()),
                ),
                SizedBox(height: ManagerHeight.h12),
                ProfileActionButton(
                  icon: Icons.camera_alt,
                  title: 'تغيير صورة الملف',
                  color: Colors.blue,
                  onTap: _changeProfileImage,
                ),
                SizedBox(height: ManagerHeight.h12),
                ProfileActionButton(
                  icon: Icons.logout,
                  title: 'تسجيل الخروج',
                  color: Colors.red,
                  onTap: _logout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeProfileImage() async {
    // TODO: Implement image picker
    AppSnackbar.loading('ميزة تغيير الصورة قيد التطوير');
  }

  void _logout() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: ManagerWidth.w8),
            Text('تسجيل الخروج'),
          ],
        ),
        content: Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _performLogout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }

  void _performLogout() async {
    try {
      // TODO: Implement logout logic
      AppSnackbar.success('تم تسجيل الخروج بنجاح');
      Get.offAllNamed('/login'); // Adjust route as needed
    } catch (e) {
      AppSnackbar.error('فشل تسجيل الخروج: $e');
    }
  }
}