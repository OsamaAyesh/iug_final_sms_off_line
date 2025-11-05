// المسار: lib/features/home/add_chat/presentation/pages/add_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';
import 'package:app_mobile/core/resources/manager_width.dart';

class AddChatScreen extends StatefulWidget {
  const AddChatScreen({super.key});

  @override
  State<AddChatScreen> createState() => _AddChatScreenState();
}

class _AddChatScreenState extends State<AddChatScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
              _buildNameField(),
              SizedBox(height: ManagerHeight.h20),
              _buildPhoneField(),
              SizedBox(height: ManagerHeight.h30),
              _buildInfoBox(),
              SizedBox(height: ManagerHeight.h40),
              _buildAddButton(),
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
        'إضافة جهة اتصال جديدة',
        style: getBoldTextStyle(
          fontSize: ManagerFontSize.s16,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ManagerColors.primaryColor,
                ManagerColors.primaryColor.withOpacity(0.7),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_add,
            color: Colors.white,
            size: 50,
          ),
        ),
        SizedBox(height: ManagerHeight.h16),
        Text(
          'أضف جهة اتصال',
          style: getBoldTextStyle(
            fontSize: ManagerFontSize.s20,
            color: ManagerColors.black,
          ),
        ),
        SizedBox(height: ManagerHeight.h8),
        Text(
          'أدخل المعلومات الأساسية للجهة',
          style: getRegularTextStyle(
            fontSize: ManagerFontSize.s14,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
              'الاسم الكامل',
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
              return 'الرجاء إدخال الاسم';
            }
            return null;
          },
          style: getRegularTextStyle(
            fontSize: ManagerFontSize.s14,
            color: ManagerColors.black,
          ),
          decoration: InputDecoration(
            hintText: 'أدخل الاسم الكامل',
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
            prefixIcon: Icon(
              Icons.person,
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

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.phone_outlined,
              color: ManagerColors.primaryColor,
              size: 20,
            ),
            SizedBox(width: ManagerWidth.w8),
            Text(
              'رقم الجوال',
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
          controller: _phoneController,
          textAlign: TextAlign.right,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'الرجاء إدخال رقم الهاتف';
            }
            if (value.length < 9) {
              return 'رقم الهاتف غير صحيح';
            }
            return null;
          },
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: getRegularTextStyle(
            fontSize: ManagerFontSize.s14,
            color: ManagerColors.black,
          ),
          decoration: InputDecoration(
            hintText: '+970599123456',
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
            prefixIcon: Icon(
              Icons.phone_android,
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

  Widget _buildInfoBox() {
    return Container(
      padding: EdgeInsets.all(ManagerWidth.w14),
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
            padding: EdgeInsets.all(ManagerWidth.w8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.info_outline,
              color: Colors.blue.shade700,
              size: 20,
            ),
          ),
          SizedBox(width: ManagerWidth.w12),
          Expanded(
            child: Text(
              'سيتم البحث عن المستخدم برقم الهاتف وإضافته إلى جهات الاتصال',
              style: getRegularTextStyle(
                fontSize: ManagerFontSize.s12,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleAddContact,
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
              'جاري الإضافة...',
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
            const Icon(Icons.person_add, color: Colors.white),
            SizedBox(width: ManagerWidth.w10),
            Text(
              'إضافة جهة الاتصال',
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

  Future<void> _handleAddContact() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final phone = _phoneController.text.trim();
      final name = _nameController.text.trim();

      // البحث عن المستخدم في Firebase
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        Get.snackbar(
          'غير موجود',
          'المستخدم غير مسجل في التطبيق',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          icon: const Icon(Icons.warning_amber, color: Colors.white),
        );
        return;
      }

      final contactUserId = userQuery.docs.first.id;
      final currentUserId = '567450057'; // استبدل بالـ user ID الفعلي

      // إضافة للجهات
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('contacts')
          .doc(contactUserId)
          .set({
        'addedAt': FieldValue.serverTimestamp(),
        'name': name,
      });

      Get.snackbar(
        'نجح',
        'تمت إضافة جهة الاتصال بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );

      Get.back(result: true);
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل إضافة جهة الاتصال: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}