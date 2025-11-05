// المسار: lib/features/home/add_chat/presentation/pages/create_group_details_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';
import 'package:app_mobile/core/resources/manager_width.dart';

import 'cloudinary_image_avatar.dart';

class CreateGroupDetailsScreen extends StatefulWidget {
  final Map<String, Map<String, dynamic>> selectedMembers;

  const CreateGroupDetailsScreen({
    Key? key,
    required this.selectedMembers,
  }) : super(key: key);

  @override
  State<CreateGroupDetailsScreen> createState() =>
      _CreateGroupDetailsScreenState();
}

class _CreateGroupDetailsScreenState extends State<CreateGroupDetailsScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isCreating = false;

  String get currentUserId => '567450057'; // استبدل بـ FirebaseAuth

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(ManagerWidth.w20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: ManagerHeight.h30),
              _buildGroupImage(),
              SizedBox(height: ManagerHeight.h30),
              _buildNameField(),
              SizedBox(height: ManagerHeight.h20),
              _buildDescriptionField(),
              SizedBox(height: ManagerHeight.h30),
              _buildMembersPreview(),
              SizedBox(height: ManagerHeight.h30),
              _buildCreateButton(),
            ],
          ),
        ),
      ),
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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إنشاء مجموعة جديدة',
            style: getBoldTextStyle(
              fontSize: ManagerFontSize.s18,
              color: Colors.white,
            ),
          ),
          Text(
            'الخطوة 2 من 2',
            style: getRegularTextStyle(
              fontSize: ManagerFontSize.s12,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(ManagerWidth.w16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.blue.shade100.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(ManagerWidth.w10),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.info_outline,
              color: Colors.blue.shade700,
              size: 24,
            ),
          ),
          SizedBox(width: ManagerWidth.w12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'معلومات المجموعة',
                  style: getBoldTextStyle(
                    fontSize: ManagerFontSize.s14,
                    color: Colors.blue.shade900,
                  ),
                ),
                SizedBox(height: ManagerHeight.h4),
                Text(
                  'أدخل اسم ووصف للمجموعة',
                  style: getRegularTextStyle(
                    fontSize: ManagerFontSize.s12,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupImage() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: ManagerColors.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ManagerColors.primaryColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.group,
                  size: 60,
                  color: ManagerColors.primaryColor,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ManagerColors.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.camera_alt, size: 18),
                    color: Colors.white,
                    onPressed: () {
                      Get.snackbar('قريباً', 'اختيار صورة قيد التطوير');
                    },
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ManagerHeight.h12),
          Text(
            'إضافة صورة المجموعة',
            style: getRegularTextStyle(
              fontSize: ManagerFontSize.s13,
              color: Colors.grey.shade600,
            ),
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
              Icons.group,
              color: ManagerColors.primaryColor,
              size: 20,
            ),
            SizedBox(width: ManagerWidth.w8),
            Text(
              'اسم المجموعة',
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
          controller: _nameController,
          textAlign: TextAlign.right,
          maxLength: 50,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'الرجاء إدخال اسم المجموعة';
            }
            if (value.trim().length < 3) {
              return 'الاسم يجب أن يكون 3 أحرف على الأقل';
            }
            return null;
          },
          style: getRegularTextStyle(
            fontSize: ManagerFontSize.s14,
            color: ManagerColors.black,
          ),
          decoration: InputDecoration(
            hintText: 'مثال: مجموعة الأصدقاء',
            hintStyle: getRegularTextStyle(
              fontSize: ManagerFontSize.s14,
              color: Colors.grey.shade400,
            ),
            filled: true,
            fillColor: Colors.white,
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
            prefixIcon: Icon(
              Icons.edit,
              color: Colors.grey.shade400,
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

  Widget _buildDescriptionField() {
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
              'وصف المجموعة (اختياري)',
              style: getBoldTextStyle(
                fontSize: ManagerFontSize.s14,
                color: ManagerColors.black,
              ),
            ),
          ],
        ),
        SizedBox(height: ManagerHeight.h10),
        TextFormField(
          controller: _descriptionController,
          textAlign: TextAlign.right,
          maxLines: 3,
          maxLength: 200,
          style: getRegularTextStyle(
            fontSize: ManagerFontSize.s14,
            color: ManagerColors.black,
          ),
          decoration: InputDecoration(
            hintText: 'أضف وصفاً للمجموعة...',
            hintStyle: getRegularTextStyle(
              fontSize: ManagerFontSize.s14,
              color: Colors.grey.shade400,
            ),
            filled: true,
            fillColor: Colors.white,
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

  Widget _buildMembersPreview() {
    return Container(
      padding: EdgeInsets.all(ManagerWidth.w16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people,
                color: ManagerColors.primaryColor,
                size: 20,
              ),
              SizedBox(width: ManagerWidth.w8),
              Text(
                'الأعضاء (${widget.selectedMembers.length + 1})',
                style: getBoldTextStyle(
                  fontSize: ManagerFontSize.s14,
                  color: ManagerColors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: ManagerHeight.h12),
          const Divider(height: 1),
          SizedBox(height: ManagerHeight.h12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // أنت (المنشئ)
              _buildMemberChip('أنت', '', isCreator: true),
              // الأعضاء المحددين
              ...widget.selectedMembers.values
                  .map((member) => _buildMemberChip(
                member['name'],
                member['imageUrl'] ?? '',
              ))
                  .toList(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberChip(String name, String imageUrl, {bool isCreator = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ManagerWidth.w10,
        vertical: ManagerHeight.h6,
      ),
      decoration: BoxDecoration(
        color: isCreator
            ? ManagerColors.primaryColor.withOpacity(0.1)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCreator
              ? ManagerColors.primaryColor.withOpacity(0.3)
              : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageUrl.isNotEmpty)
            CloudinaryAvatar(
              imageUrl: imageUrl,
              fallbackText: name,
              radius: 12,
            )
          else
            CircleAvatar(
              radius: 12,
              backgroundColor: isCreator
                  ? ManagerColors.primaryColor
                  : Colors.grey.shade300,
              child: Icon(
                isCreator ? Icons.star : Icons.person,
                size: 14,
                color: Colors.white,
              ),
            ),
          SizedBox(width: ManagerWidth.w6),
          Text(
            name,
            style: getRegularTextStyle(
              fontSize: ManagerFontSize.s13,
              color: isCreator ? ManagerColors.primaryColor : ManagerColors.black,
            ),
          ),
          if (isCreator) ...[
            SizedBox(width: ManagerWidth.w4),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: ManagerWidth.w6,
                vertical: ManagerHeight.h2,
              ),
              decoration: BoxDecoration(
                color: ManagerColors.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'منشئ',
                style: getRegularTextStyle(
                  fontSize: ManagerFontSize.s10,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isCreating ? null : _createGroup,
        style: ElevatedButton.styleFrom(
          backgroundColor: ManagerColors.primaryColor,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(vertical: ManagerHeight.h16),
          elevation: 4,
        ),
        child: _isCreating
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: ManagerWidth.w12),
            Text(
              'جاري الإنشاء...',
              style: getBoldTextStyle(
                fontSize: ManagerFontSize.s15,
                color: Colors.white,
              ),
            ),
          ],
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: ManagerWidth.w10),
            Text(
              'إنشاء المجموعة',
              style: getBoldTextStyle(
                fontSize: ManagerFontSize.s15,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isCreating = true);

    try {
      final groupName = _nameController.text.trim();
      final description = _descriptionController.text.trim();

      // قائمة الأعضاء (المستخدم الحالي + المحددين)
      final participants = [currentUserId, ...widget.selectedMembers.keys];

      // بيانات المجموعة
      final groupData = {
        'name': groupName,
        'description': description,
        'imageUrl': '', // TODO: Add image upload
        'createdBy': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'participants': participants,
        'admins': [currentUserId], // المنشئ هو المشرف الأول
        'lastMessage': 'تم إنشاء المجموعة',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': currentUserId,
        'messageCount': 0,
        'unreadCount': {}, // سيتم تحديثه عند إرسال الرسائل
      };

      // إنشاء المجموعة
      final groupRef =
      await FirebaseFirestore.instance.collection('groups').add(groupData);

      print('✅ تم إنشاء المجموعة: ${groupRef.id}');

      // رسالة ترحيب
      await groupRef.collection('messages').add({
        'text': 'مرحباً بالجميع في $groupName! 🎉',
        'senderId': currentUserId,
        'senderName': 'النظام',
        'senderImage': '',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'sent',
        'mentions': [],
        'type': 'system',
      });

      Get.snackbar(
        'نجح',
        'تم إنشاء المجموعة بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
        duration: const Duration(seconds: 2),
      );

      // العودة للصفحة الرئيسية
      Get.until((route) => route.isFirst);
    } catch (e) {
      print('❌ خطأ في إنشاء المجموعة: $e');
      Get.snackbar(
        'خطأ',
        'فشل إنشاء المجموعة: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}