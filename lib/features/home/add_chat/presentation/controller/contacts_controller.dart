// المسار: lib/features/contacts/presentation/controller/contacts_controller.dart

import 'package:app_mobile/core/util/snack_bar.dart';
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

  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  String get currentUserId => _prefs.getUserId();
  String get currentUserName => _prefs.getUserName();

  @override
  void onInit() {
    super.onInit();

    if (currentUserId.isEmpty) {
      AppSnackbar.warning("يجب تسجيل الدخول أولاً");
      return;
    }

    print('👤 تحميل جهات الاتصال للمستخدم: $currentUserId - $currentUserName');
    loadContacts();

    searchController.addListener(() {
      filterContacts(searchController.text);
    });
  }


  Future<void> loadContacts() async {
    if (currentUserId.isEmpty) {
      AppSnackbar.error('يجب تسجيل الدخول أولاً');
      return;
    }

    isLoading.value = true;

    try {
      final result = await getAllContactsUseCase.call(currentUserId);
      contacts.assignAll(result);
      filteredContacts.assignAll(result);
      print('✅ تم تحميل ${result.length} جهة اتصال');
    } catch (e) {
      AppSnackbar.error('فشل تحميل جهات الاتصال: $e');
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
      AppSnackbar.error('يجب تسجيل الدخول أولاً');

      return;
    }

    if (name.trim().isEmpty || phone.trim().isEmpty) {
      AppSnackbar.warning('الرجاء إدخال الاسم ورقم الهاتف');

      return;
    }

    isLoading.value = true;

    try {
      // Find contact by phone
      final contact = await findContactByPhoneUseCase.call(phone);

      if (contact == null) {
        AppSnackbar.warning('المستخدم غير موجود في التطبيق');
        return;
      }

      // Add contact
      await addContactUseCase.call(currentUserId, contact.id);
      AppSnackbar.success('تمت إضافة جهة الاتصال بنجاح');


      // Clear form
      nameController.clear();
      phoneController.clear();

      // Reload contacts
      await loadContacts();

      Get.back();
    } catch (e) {
      AppSnackbar.error('فشل إضافة جهة الاتصال: $e');
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