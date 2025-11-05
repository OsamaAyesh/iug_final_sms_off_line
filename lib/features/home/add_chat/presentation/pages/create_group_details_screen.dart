// المسار: lib/features/home/add_chat/presentation/pages/create_group_details_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';
import 'package:app_mobile/core/resources/manager_width.dart';
import '../../../../../core/service/cloudinart_service.dart';

class CreateGroupDetailsScreen extends StatefulWidget {
  final Map<String, Map<String, dynamic>> selectedMembers;

  const CreateGroupDetailsScreen({
    super.key,
    required this.selectedMembers,
  });

  @override
  State<CreateGroupDetailsScreen> createState() =>
      _CreateGroupDetailsScreenState();
}

class _CreateGroupDetailsScreenState extends State<CreateGroupDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();

  File? _groupImage;
  bool _isLoading = false;
  bool _isUploading = false;
  bool _onlyAdminsCanSend = false;
  bool _allowMembersToAdd = false;

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
          padding: EdgeInsets.all(ManagerWidth.w16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(),
              SizedBox(height: ManagerHeight.h24),
              _buildNameField(),
              SizedBox(height: ManagerHeight.h16),
              _buildDescriptionField(),
              SizedBox(height: ManagerHeight.h24),
              _buildSettingsSection(),
              SizedBox(height: ManagerHeight.h24),
              _buildMembersSection(),
              SizedBox(height: ManagerHeight.h24),
              if (_isUploading) _buildUploadingIndicator(),
              _buildCreateButton(),
              SizedBox(height: ManagerHeight.h20),
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
      title: Text(
        'تفاصيل المجموعة',
        style: getBoldTextStyle(
          fontSize: ManagerFontSize.s18,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
              image: _groupImage != null
                  ? DecorationImage(
                image: FileImage(_groupImage!),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: _groupImage == null
                ? Icon(
              Icons.group,
              size: 60,
              color: Colors.grey.shade400,
            )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Row(
              children: [
                if (_groupImage != null)
                  InkWell(
                    onTap: () => setState(() => _groupImage = null),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ManagerColors.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
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
              Icons.group_outlined,
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
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'الرجاء إدخال اسم المجموعة';
            }
            return null;
          },
          style: getRegularTextStyle(
            fontSize: ManagerFontSize.s14,
            color: ManagerColors.black,
          ),
          decoration: InputDecoration(
            hintText: 'أدخل اسم المجموعة',
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
            contentPadding: EdgeInsets.symmetric(
              horizontal: ManagerWidth.w16,
              vertical: ManagerHeight.h14,
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
              Icons.description_outlined,
              color: ManagerColors.primaryColor,
              size: 20,
            ),
            SizedBox(width: ManagerWidth.w8),
            Text(
              'الوصف (اختياري)',
              style: getBoldTextStyle(
                fontSize: ManagerFontSize.s14,
                color: ManagerColors.black,
              ),
            ),
          ],
        ),
        SizedBox(height: ManagerHeight.h10),
        TextField(
          controller: _descriptionController,
          textAlign: TextAlign.right,
          maxLines: 3,
          style: getRegularTextStyle(
            fontSize: ManagerFontSize.s14,
            color: ManagerColors.black,
          ),
          decoration: InputDecoration(
            hintText: 'أدخل وصف المجموعة',
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

  Widget _buildSettingsSection() {
    return Container(
      padding: EdgeInsets.all(ManagerWidth.w16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings_outlined,
                color: ManagerColors.primaryColor,
                size: 20,
              ),
              SizedBox(width: ManagerWidth.w8),
              Text(
                'الإعدادات',
                style: getBoldTextStyle(
                  fontSize: ManagerFontSize.s15,
                  color: ManagerColors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: ManagerHeight.h16),
          SwitchListTile(
            value: _onlyAdminsCanSend,
            onChanged: (value) => setState(() => _onlyAdminsCanSend = value),
            title: Text(
              'فقط المشرفون يمكنهم الإرسال',
              style: getRegularTextStyle(
                fontSize: ManagerFontSize.s14,
                color: ManagerColors.black,
              ),
            ),
            activeColor: ManagerColors.primaryColor,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: _allowMembersToAdd,
            onChanged: (value) => setState(() => _allowMembersToAdd = value),
            title: Text(
              'السماح للأعضاء بإضافة أعضاء آخرين',
              style: getRegularTextStyle(
                fontSize: ManagerFontSize.s14,
                color: ManagerColors.black,
              ),
            ),
            activeColor: ManagerColors.primaryColor,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection() {
    return Container(
      padding: EdgeInsets.all(ManagerWidth.w16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people_outline,
                color: ManagerColors.primaryColor,
                size: 20,
              ),
              SizedBox(width: ManagerWidth.w8),
              Text(
                'الأعضاء (${widget.selectedMembers.length})',
                style: getBoldTextStyle(
                  fontSize: ManagerFontSize.s15,
                  color: ManagerColors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: ManagerHeight.h12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.selectedMembers.values.map((member) {
              return Chip(
                avatar: CircleAvatar(
                  backgroundColor: ManagerColors.primaryColor.withOpacity(0.1),
                  backgroundImage: member['imageUrl'] != null
                      ? CachedNetworkImageProvider(member['imageUrl'])
                      : null,
                  child: member['imageUrl'] == null
                      ? Text(
                    member['name'][0].toUpperCase(),
                    style: getBoldTextStyle(
                      fontSize: ManagerFontSize.s12,
                      color: ManagerColors.primaryColor,
                    ),
                  )
                      : null,
                ),
                label: Text(
                  member['name'],
                  style: getRegularTextStyle(
                    fontSize: ManagerFontSize.s13,
                    color: ManagerColors.black,
                  ),
                ),
                backgroundColor: Colors.grey.shade100,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadingIndicator() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: ManagerWidth.w12),
            Text(
              'جاري رفع الصورة إلى Cloudinary...',
              style: getRegularTextStyle(
                fontSize: ManagerFontSize.s13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        SizedBox(height: ManagerHeight.h16),
      ],
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleCreateGroup,
        style: ElevatedButton.styleFrom(
          backgroundColor: ManagerColors.primaryColor,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(vertical: ManagerHeight.h16),
          elevation: 4,
        ),
        child: _isLoading
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
            const Icon(Icons.group_add, color: Colors.white),
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

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('الكاميرا'),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('المعرض'),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _groupImage = File(image.path));
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل اختيار الصورة: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _handleCreateGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUserId = '567450057'; // استبدل بالـ user ID الفعلي
      final groupName = _nameController.text.trim();
      final description = _descriptionController.text.trim();

      // Create group document
      final groupRef = FirebaseFirestore.instance.collection('groups').doc();
      final groupId = groupRef.id;

      String? imageUrl;

      // رفع الصورة إلى Cloudinary إذا كانت موجودة
      if (_groupImage != null) {
        setState(() => _isUploading = true);

        imageUrl = await CloudinaryService.upload(
          file: _groupImage!,
          type: 'image',
          folder: 'chat_media/groups/$groupId',
        );

        setState(() => _isUploading = false);
      }

      // Prepare participants list
      final participants = [currentUserId, ...widget.selectedMembers.keys];

      // Create group in Firestore
      await groupRef.set({
        'name': groupName,
        'description': description,
        'imageUrl': imageUrl, // رابط Cloudinary
        'createdBy': currentUserId,
        'admins': [currentUserId],
        'participants': participants,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'settings': {
          'onlyAdminsCanSend': _onlyAdminsCanSend,
          'onlyAdminsCanEdit': true,
          'allowMembersToAddOthers': _allowMembersToAdd,
          'showMembersList': true,
        },
      });

      Get.snackbar(
        'نجح',
        'تم إنشاء المجموعة بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );

      // Navigate back to home
      Get.until((route) => route.isFirst);
    } catch (e) {
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
        setState(() {
          _isLoading = false;
          _isUploading = false;
        });
      }
    }
  }
}