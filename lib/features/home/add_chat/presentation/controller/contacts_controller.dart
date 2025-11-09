// المسار: lib/features/contacts/presentation/controller/contacts_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_mobile/core/storage/local/app_settings_prefs.dart';
import '../../domain/models/contact_model.dart';
import '../../domain/use_cases/get_all_contacts_usecase.dart';
import '../../domain/use_cases/add_contact_usecase.dart';
import '../../domain/use_cases/find_contact_by_phone_usecase.dart';

class ContactsController extends GetxController {
  final GetAllContactsUseCase getAllContactsUseCase;
  final AddContactUseCase addContactUseCase;
  final FindContactByPhoneUseCase findContactByPhoneUseCase;
  final AppSettingsPrefs _prefs = Get.find<AppSettingsPrefs>();

  ContactsController({
    required this.getAllContactsUseCase,
    required this.addContactUseCase,
    required this.findContactByPhoneUseCase,
  });

  static ContactsController get to => Get.find<ContactsController>();

  // States
  final contacts = <ContactModel>[].obs;
  final filteredContacts = <ContactModel>[].obs;
  final selectedContacts = <String>[].obs;
  final isLoading = false.obs;
  final searchController = TextEditingController();

  // Form Controllers
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  // ✅ استخدام user_id من SharedPreferences
  String get currentUserId => _prefs.getUserId();
  String get currentUserName => _prefs.getUserName();

  @override
  void onInit() {
    super.onInit();

    // التحقق من المصادقة أولاً
    if (currentUserId.isEmpty) {
      Get.snackbar(
        'تنبيه',
        'يجب تسجيل الدخول أولاً',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    print('👤 تحميل جهات الاتصال للمستخدم: $currentUserId - $currentUserName');
    loadContacts();

    // Search listener
    searchController.addListener(() {
      filterContacts(searchController.text);
    });
  }

  // ================================
  // 🔸 Load Contacts
  // ================================

  Future<void> loadContacts() async {
    if (currentUserId.isEmpty) {
      Get.snackbar(
        'خطأ',
        'يجب تسجيل الدخول أولاً',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    try {
      final result = await getAllContactsUseCase.call(currentUserId);
      contacts.assignAll(result);
      filteredContacts.assignAll(result);
      print('✅ تم تحميل ${result.length} جهة اتصال');
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل تحميل جهات الاتصال: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ================================
  // 🔸 Search & Filter
  // ================================

  void filterContacts(String query) {
    if (query.isEmpty) {
      filteredContacts.assignAll(contacts);
      return;
    }

    filteredContacts.assignAll(
      contacts.where((contact) {
        final nameLower = contact.name.toLowerCase();
        final phoneLower = contact.phone.toLowerCase();
        final queryLower = query.toLowerCase();

        return nameLower.contains(queryLower) ||
            phoneLower.contains(queryLower);
      }).toList(),
    );
  }

  // ================================
  // 🔸 Add Contact
  // ================================

  Future<void> addContact({
    required String name,
    required String phone,
  }) async {
    // التحقق من المصادقة
    if (currentUserId.isEmpty) {
      Get.snackbar(
        'خطأ',
        'يجب تسجيل الدخول أولاً',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (name.trim().isEmpty || phone.trim().isEmpty) {
      Get.snackbar(
        'خطأ',
        'الرجاء إدخال الاسم ورقم الهاتف',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    try {
      // Find contact by phone
      final contact = await findContactByPhoneUseCase.call(phone);

      if (contact == null) {
        Get.snackbar(
          'غير موجود',
          'المستخدم غير موجود في التطبيق',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      // Add contact
      await addContactUseCase.call(currentUserId, contact.id);

      Get.snackbar(
        'نجح',
        'تمت إضافة جهة الاتصال بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Clear form
      nameController.clear();
      phoneController.clear();

      // Reload contacts
      await loadContacts();

      Get.back();
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل إضافة جهة الاتصال: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ================================
  // 🔸 Selection Management
  // ================================

  void toggleSelection(String contactId) {
    if (selectedContacts.contains(contactId)) {
      selectedContacts.remove(contactId);
    } else {
      selectedContacts.add(contactId);
    }
  }

  void selectAll() {
    selectedContacts.assignAll(
      filteredContacts.map((c) => c.id).toList(),
    );
  }

  void clearSelection() {
    selectedContacts.clear();
  }

  bool isSelected(String contactId) {
    return selectedContacts.contains(contactId);
  }

  @override
  void onClose() {
    searchController.dispose();
    nameController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}