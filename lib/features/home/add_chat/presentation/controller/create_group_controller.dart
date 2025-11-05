// المسار: lib/features/groups/presentation/controller/create_group_controller.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/use_cases/create_group_usecase.dart';
import '../../domain/use_cases/upload_group_image_use_case.dart';

class CreateGroupController extends GetxController {
  final CreateGroupUseCase createGroupUseCase;
  final UploadGroupImageUseCase uploadImageUseCase;

  CreateGroupController({
    required this.createGroupUseCase,
    required this.uploadImageUseCase,
  });

  static CreateGroupController get to => Get.find<CreateGroupController>();

  final ImagePicker _picker = ImagePicker();

  // Form Controllers
  final groupNameController = TextEditingController();
  final groupDescriptionController = TextEditingController();

  // States
  final selectedMembers = <String>[].obs;
  final groupImage = Rxn<File>();
  final isLoading = false.obs;
  final isUploading = false.obs;
  final uploadProgress = 0.0.obs;

  // Settings
  final onlyAdminsCanSend = false.obs;
  final allowMembersToAdd = false.obs;

  String currentUserId = '567450057'; // Default for development

  // ================================
  // 🔸 Image Selection
  // ================================

  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        groupImage.value = File(image.path);
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

  Future<void> takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        groupImage.value = File(image.path);
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل التقاط الصورة: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void removeImage() {
    groupImage.value = null;
  }

  // ================================
  // 🔸 Create Group
  // ================================

  Future<void> createGroup() async {
    final groupName = groupNameController.text.trim();

    if (groupName.isEmpty) {
      Get.snackbar(
        'خطأ',
        'الرجاء إدخال اسم المجموعة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (selectedMembers.length < 2) {
      Get.snackbar(
        'خطأ',
        'يجب اختيار عضوين على الأقل',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    try {
      final params = CreateGroupParams(
        name: groupName,
        description: groupDescriptionController.text.trim(),
        createdBy: currentUserId,
        participants: selectedMembers.toList(),
        imageFile: groupImage.value,
        onlyAdminsCanSend: onlyAdminsCanSend.value,
        allowMembersToAddOthers: allowMembersToAdd.value,
      );

      final groupId = await createGroupUseCase.call(params);

      Get.snackbar(
        'نجح',
        'تم إنشاء المجموعة بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // Clear form
      _clearForm();

      // Navigate to group chat
      // Get.offAll(() => GroupChatScreen(groupId: groupId, ...));

      // Get.back();
      // Get.back();
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل إنشاء المجموعة: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ================================
  // 🔸 Member Selection
  // ================================

  void toggleMember(String memberId) {
    if (selectedMembers.contains(memberId)) {
      selectedMembers.remove(memberId);
    } else {
      selectedMembers.add(memberId);
    }
  }

  void removeMember(String memberId) {
    selectedMembers.remove(memberId);
  }

  bool isMemberSelected(String memberId) {
    return selectedMembers.contains(memberId);
  }

  // ================================
  // 🔸 Clear Form
  // ================================

  void _clearForm() {
    groupNameController.clear();
    groupDescriptionController.clear();
    selectedMembers.clear();
    groupImage.value = null;
    onlyAdminsCanSend.value = false;
    allowMembersToAdd.value = false;
  }

  @override
  void onClose() {
    groupNameController.dispose();
    groupDescriptionController.dispose();
    super.onClose();
  }
}