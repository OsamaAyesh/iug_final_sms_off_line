// المسار: lib/features/home/add_chat/presentation/controller/create_group_controller.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_mobile/core/storage/local/app_settings_prefs.dart';
import 'package:app_mobile/core/util/snack_bar.dart';

class CreateGroupController extends GetxController {
  final AppSettingsPrefs _prefs = Get.find<AppSettingsPrefs>();
  final ImagePicker _picker = ImagePicker();

  // Form Controllers
  final groupNameController = TextEditingController();
  final groupDescriptionController = TextEditingController();
  final searchController = TextEditingController();

  // States
  final selectedMembers = <String, Map<String, dynamic>>{}.obs;
  final allContacts = <Map<String, dynamic>>[].obs;
  final filteredContacts = <Map<String, dynamic>>[].obs;
  final groupImage = Rxn<File>();
  final isLoading = false.obs;
  final isCreating = false.obs;
  final isSearching = false.obs;

  // Settings
  final onlyAdminsCanSend = false.obs;
  final allowMembersToAdd = false.obs;

  // Getters
  String get currentUserId => _prefs.getUserId();
  String get currentUserName => _prefs.getUserName();
  String get currentUserPhone => _prefs.getUserPhone();

  @override
  void onInit() {
    super.onInit();
    _loadContacts();
    searchController.addListener(_filterContacts);
  }

  // ================================
  // 🔸 Load Contacts
  // ================================

  Future<void> _loadContacts() async {
    if (currentUserId.isEmpty) {
      AppSnackbar.error('يجب تسجيل الدخول أولاً');
      return;
    }

    isLoading.value = true;

    try {
      print('📱 جاري تحميل جهات الاتصال للمستخدم: $currentUserId');

      // جلب جميع المستخدمين من Firestore
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      final List<Map<String, dynamic>> contacts = [];

      for (var doc in usersSnapshot.docs) {
        // تخطي المستخدم الحالي
        if (doc.id == currentUserId) continue;

        final data = doc.data();
        contacts.add({
          'id': doc.id,
          'name': data['name'] ?? 'غير معروف',
          'phone': data['phone'] ?? '',
          'phoneCanon': data['phoneCanon'] ?? '',
          'imageUrl': data['imageUrl'] ?? '',
          'bio': data['bio'] ?? '',
          'isOnline': data['isOnline'] ?? false,
          'isVerified': data['isVerified'] ?? false,
        });
      }

      print('✅ تم تحميل ${contacts.length} جهة اتصال');

      allContacts.assignAll(contacts);
      filteredContacts.assignAll(contacts);
    } catch (e) {
      print('❌ خطأ في تحميل جهات الاتصال: $e');
      AppSnackbar.error('فشل تحميل جهات الاتصال: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ================================
  // 🔸 Search & Filter
  // ================================

  void _filterContacts() {
    final query = searchController.text.toLowerCase();

    if (query.isEmpty) {
      filteredContacts.assignAll(allContacts);
      return;
    }

    filteredContacts.assignAll(
      allContacts.where((contact) {
        final name = contact['name'].toString().toLowerCase();
        final phone = contact['phone'].toString().toLowerCase();
        final bio = contact['bio'].toString().toLowerCase();

        return name.contains(query) ||
            phone.contains(query) ||
            bio.contains(query);
      }).toList(),
    );
  }

  // ================================
  // 🔸 Member Selection
  // ================================

  void toggleMember(String id, Map<String, dynamic> contact) {
    if (selectedMembers.containsKey(id)) {
      selectedMembers.remove(id);
    } else {
      selectedMembers[id] = contact;
    }
  }

  void removeMember(String id) {
    selectedMembers.remove(id);
  }

  void clearSelection() {
    selectedMembers.clear();
  }

  bool isMemberSelected(String id) {
    return selectedMembers.containsKey(id);
  }

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
      AppSnackbar.error('فشل اختيار الصورة: $e');
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
      AppSnackbar.error('فشل التقاط الصورة: $e');
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
      AppSnackbar.error('الرجاء إدخال اسم المجموعة');
      return;
    }

    if (selectedMembers.length < 2) {
      AppSnackbar.error('يجب اختيار عضوين على الأقل');
      return;
    }

    if (currentUserId.isEmpty) {
      AppSnackbar.error('يجب تسجيل الدخول أولاً');
      return;
    }

    isCreating.value = true;

    try {
      final groupName = groupNameController.text.trim();
      final description = groupDescriptionController.text.trim();

      // قائمة الأعضاء (المستخدم الحالي + المحددين)
      final participants = [currentUserId, ...selectedMembers.keys];

      // بيانات المجموعة
      final groupData = {
        'name': groupName,
        'description': description,
        'imageUrl': '', // TODO: Add image upload
        'createdBy': currentUserId,
        'createdBy_name': currentUserName,
        'createdAt': FieldValue.serverTimestamp(),
        'participants': participants,
        'admins': [currentUserId],
        'lastMessage': 'تم إنشاء المجموعة',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': currentUserId,
        'messageCount': 0,
        'unreadCount': {},
        'settings': {
          'onlyAdminsCanSend': onlyAdminsCanSend.value,
          'allowMembersToAddOthers': allowMembersToAdd.value,
        },
      };

      // إنشاء المجموعة
      final groupRef = await FirebaseFirestore.instance
          .collection('groups')
          .add(groupData);

      print('✅ تم إنشاء المجموعة: ${groupRef.id}');

      // رسالة ترحيب
      await groupRef.collection('messages').add({
        'text': 'مرحباً بالجميع في $groupName! 🎉',
        'senderId': currentUserId,
        'senderName': currentUserName,
        'senderImage': '',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'sent',
        'type': 'system',
      });

      AppSnackbar.success('تم إنشاء المجموعة بنجاح');

      // تنظيف النموذج
      _clearForm();

      // العودة للصفحة الرئيسية
      Get.until((route) => route.isFirst);

    } catch (e) {
      print('❌ خطأ في إنشاء المجموعة: $e');
      AppSnackbar.error('فشل إنشاء المجموعة: $e');
    } finally {
      isCreating.value = false;
    }
  }

  // ================================
  // 🔸 Add Contact & Start Chat
  // ================================

  Future<void> addContactAndStartChat({
    required String phone,
    String? name,
  }) async {
    if (currentUserId.isEmpty) {
      AppSnackbar.error('يجب تسجيل الدخول أولاً');
      return;
    }

    isLoading.value = true;

    try {
      final normalizedPhone = _normalizePhone(phone);

      print('🔍 البحث عن رقم: $phone');
      print('🔍 الرقم المطبّع: $normalizedPhone');
      print('👤 المستخدم الحالي: $currentUserId - $currentUserName');

      // البحث في Firestore
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('phoneCanon', isEqualTo: normalizedPhone)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        print('❌ لم يتم العثور على المستخدم');
        AppSnackbar.warning('المستخدم غير موجود في التطبيق');
        return;
      }

      final contactDoc = userQuery.docs.first;
      final contactUserId = contactDoc.id;
      final contactData = contactDoc.data() as Map<String, dynamic>;

      print('✅ تم العثور على المستخدم: ${contactData['name']} - $contactUserId');

      // تحقق من أن المستخدم لا يضيف نفسه
      if (contactUserId == currentUserId) {
        AppSnackbar.warning('لا يمكنك إضافة نفسك كجهة اتصال');
        return;
      }

      // تحقق من أن المستخدم ليس مضافاً مسبقاً
      final existingContact = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('contacts')
          .doc(contactUserId)
          .get();

      if (existingContact.exists) {
        // إذا كان موجوداً، انتقل مباشرة إلى المحادثة
        await _startIndividualChat(contactUserId, contactData);
        return;
      }

      // 🔹 الخطوة 1: إضافة المستخدم إلى جهات الاتصال
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('contacts')
          .doc(contactUserId)
          .set({
        'addedAt': FieldValue.serverTimestamp(),
        'name': name?.trim().isEmpty == true
            ? contactData['name']
            : name?.trim(),
        'phone': contactData['phone'],
        'imageUrl': contactData['imageUrl'],
      });

      print('✅ تمت إضافة جهة الاتصال بنجاح');

      // 🔹 الخطوة 2: إنشاء محادثة فردية تلقائياً
      await _startIndividualChat(contactUserId, contactData);

    } catch (e) {
      print('❌ خطأ في إضافة جهة الاتصال: $e');
      AppSnackbar.error('فشل إضافة جهة الاتصال: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 🔹 بدء محادثة فردية
  Future<void> _startIndividualChat(String contactUserId, Map<String, dynamic> contactData) async {
    try {
      final chatId = _generateChatId(currentUserId, contactUserId);

      print('💬 بدء محادثة جديدة: $chatId');

      // تحقق إذا كانت المحادثة موجودة مسبقاً
      final existingChat = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .get();

      if (!existingChat.exists) {
        // إنشاء محادثة جديدة
        final chatData = {
          'id': chatId,
          'type': 'individual',
          'participants': [currentUserId, contactUserId],
          'participantsData': {
            currentUserId: {
              'name': currentUserName,
              'phone': currentUserPhone,
              'imageUrl': _prefs.getUserImage() ?? '',
            },
            contactUserId: {
              'name': contactData['name'],
              'phone': contactData['phone'],
              'imageUrl': contactData['imageUrl'] ?? '',
            },
          },
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastMessage': 'بدأت المحادثة',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSender': currentUserId,
          'unreadCount': {
            currentUserId: 0,
            contactUserId: 0,
          },
        };

        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .set(chatData);

        print('✅ تم إنشاء المحادثة بنجاح: $chatId');

        // إضافة رسالة ترحيب تلقائية
        await _addWelcomeMessage(chatId, contactData['name']);
      }

      AppSnackbar.success('تم بدء المحادثة مع ${contactData['name']}');

      // الانتقال إلى شاشة المحادثة الفردية
      Get.offAllNamed('/single-chat', arguments: {
        'chatId': chatId,
        'otherUserId': contactUserId,
        'otherUserName': contactData['name'],
        'otherUserImage': contactData['imageUrl'],
      });

    } catch (e) {
      print('❌ خطأ في بدء المحادثة: $e');
      throw Exception('فشل بدء المحادثة: $e');
    }
  }

  /// 🔹 إضافة رسالة ترحيب تلقائية
  Future<void> _addWelcomeMessage(String chatId, String contactName) async {
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'text': 'مرحباً $contactName! 👋',
        'senderId': currentUserId,
        'senderName': currentUserName,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
        'status': 'sent',
      });

      print('✅ تم إضافة رسالة الترحيب');
    } catch (e) {
      print('❌ خطأ في إضافة رسالة الترحيب: $e');
    }
  }

  /// 🔹 إنشاء معرف فريد للمحادثة
  String _generateChatId(String user1Id, String user2Id) {
    final sortedIds = [user1Id, user2Id]..sort();
    return 'individual_${sortedIds[0]}_${sortedIds[1]}';
  }

  /// 🔹 تطبيع رقم الهاتف
  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^\d]'), '');
  }

  // ================================
  // 🔸 Clear Form
  // ================================

  void _clearForm() {
    groupNameController.clear();
    groupDescriptionController.clear();
    selectedMembers.clear();
    groupImage.value = null;
    searchController.clear();
    onlyAdminsCanSend.value = false;
    allowMembersToAdd.value = false;
  }

  @override
  void onClose() {
    groupNameController.dispose();
    groupDescriptionController.dispose();
    searchController.dispose();
    super.onClose();
  }
}
// // // المسار: lib/features/groups/presentation/controller/create_group_controller.dart
// //
// // import 'dart:io';
// // import 'package:flutter/material.dart';
// // import 'package:get/get.dart';
// // import 'package:image_picker/image_picker.dart';
// // import '../../domain/use_cases/create_group_usecase.dart';
// // import '../../domain/use_cases/upload_group_image_use_case.dart';
// //
// // class CreateGroupController extends GetxController {
// //   final CreateGroupUseCase createGroupUseCase;
// //   final UploadGroupImageUseCase uploadImageUseCase;
// //
// //   CreateGroupController({
// //     required this.createGroupUseCase,
// //     required this.uploadImageUseCase,
// //   });
// //
// //   static CreateGroupController get to => Get.find<CreateGroupController>();
// //
// //   final ImagePicker _picker = ImagePicker();
// //
// //   // Form Controllers
// //   final groupNameController = TextEditingController();
// //   final groupDescriptionController = TextEditingController();
// //
// //   // States
// //   final selectedMembers = <String>[].obs;
// //   final groupImage = Rxn<File>();
// //   final isLoading = false.obs;
// //   final isUploading = false.obs;
// //   final uploadProgress = 0.0.obs;
// //
// //   // Settings
// //   final onlyAdminsCanSend = false.obs;
// //   final allowMembersToAdd = false.obs;
// //
// //   String currentUserId = '567450057'; // Default for development
// //
// //   // ================================
// //   // 🔸 Image Selection
// //   // ================================
// //
// //   Future<void> pickImage() async {
// //     try {
// //       final XFile? image = await _picker.pickImage(
// //         source: ImageSource.gallery,
// //         maxWidth: 1024,
// //         maxHeight: 1024,
// //         imageQuality: 85,
// //       );
// //
// //       if (image != null) {
// //         groupImage.value = File(image.path);
// //       }
// //     } catch (e) {
// //       Get.snackbar(
// //         'خطأ',
// //         'فشل اختيار الصورة: $e',
// //         snackPosition: SnackPosition.BOTTOM,
// //         backgroundColor: Colors.red,
// //         colorText: Colors.white,
// //       );
// //     }
// //   }
// //
// //   Future<void> takePhoto() async {
// //     try {
// //       final XFile? image = await _picker.pickImage(
// //         source: ImageSource.camera,
// //         maxWidth: 1024,
// //         maxHeight: 1024,
// //         imageQuality: 85,
// //       );
// //
// //       if (image != null) {
// //         groupImage.value = File(image.path);
// //       }
// //     } catch (e) {
// //       Get.snackbar(
// //         'خطأ',
// //         'فشل التقاط الصورة: $e',
// //         snackPosition: SnackPosition.BOTTOM,
// //         backgroundColor: Colors.red,
// //         colorText: Colors.white,
// //       );
// //     }
// //   }
// //
// //   void removeImage() {
// //     groupImage.value = null;
// //   }
// //
// //   // ================================
// //   // 🔸 Create Group
// //   // ================================
// //
// //   Future<void> createGroup() async {
// //     final groupName = groupNameController.text.trim();
// //
// //     if (groupName.isEmpty) {
// //       Get.snackbar(
// //         'خطأ',
// //         'الرجاء إدخال اسم المجموعة',
// //         snackPosition: SnackPosition.BOTTOM,
// //         backgroundColor: Colors.orange,
// //         colorText: Colors.white,
// //       );
// //       return;
// //     }
// //
// //     if (selectedMembers.length < 2) {
// //       Get.snackbar(
// //         'خطأ',
// //         'يجب اختيار عضوين على الأقل',
// //         snackPosition: SnackPosition.BOTTOM,
// //         backgroundColor: Colors.orange,
// //         colorText: Colors.white,
// //       );
// //       return;
// //     }
// //
// //     isLoading.value = true;
// //
// //     try {
// //       final params = CreateGroupParams(
// //         name: groupName,
// //         description: groupDescriptionController.text.trim(),
// //         createdBy: currentUserId,
// //         participants: selectedMembers.toList(),
// //         imageFile: groupImage.value,
// //         onlyAdminsCanSend: onlyAdminsCanSend.value,
// //         allowMembersToAddOthers: allowMembersToAdd.value,
// //       );
// //
// //       final groupId = await createGroupUseCase.call(params);
// //
// //       Get.snackbar(
// //         'نجح',
// //         'تم إنشاء المجموعة بنجاح',
// //         snackPosition: SnackPosition.BOTTOM,
// //         backgroundColor: Colors.green,
// //         colorText: Colors.white,
// //         duration: const Duration(seconds: 2),
// //       );
// //
// //       // Clear form
// //       _clearForm();
// //
// //       // Navigate to group chat
// //       // Get.offAll(() => GroupChatScreen(groupId: groupId, ...));
// //
// //       // Get.back();
// //       // Get.back();
// //     } catch (e) {
// //       Get.snackbar(
// //         'خطأ',
// //         'فشل إنشاء المجموعة: $e',
// //         snackPosition: SnackPosition.BOTTOM,
// //         backgroundColor: Colors.red,
// //         colorText: Colors.white,
// //       );
// //     } finally {
// //       isLoading.value = false;
// //     }

// //   }
// //
// //   // ================================
// //   // 🔸 Member Selection
// //   // ================================
// //
// //   void toggleMember(String memberId) {
// //     if (selectedMembers.contains(memberId)) {
// //       selectedMembers.remove(memberId);
// //     } else {
// //       selectedMembers.add(memberId);
// //     }
// //   }
// //
// //   void removeMember(String memberId) {
// //     selectedMembers.remove(memberId);
// //   }
// //
// //   bool isMemberSelected(String memberId) {
// //     return selectedMembers.contains(memberId);
// //   }
// //
// //   // ================================
// //   // 🔸 Clear Form
// //   // ================================
// //
// //   void _clearForm() {
// //     groupNameController.clear();
// //     groupDescriptionController.clear();
// //     selectedMembers.clear();
// //     groupImage.value = null;
// //     onlyAdminsCanSend.value = false;
// //     allowMembersToAdd.value = false;
// //   }
// //
// //   @override
// //   void onClose() {
// //     groupNameController.dispose();
// //     groupDescriptionController.dispose();
// //     super.onClose();
// //   }
// // }
// // المسار: lib/features/home/add_chat/presentation/pages/create_group_details_screen.dart
//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:app_mobile/core/storage/local/app_settings_prefs.dart';
// import 'package:app_mobile/core/resources/manager_colors.dart';
// import 'package:app_mobile/core/resources/manager_font_size.dart';
// import 'package:app_mobile/core/resources/manager_height.dart';

// import 'package:app_mobile/core/resources/manager_styles.dart';
// import 'package:app_mobile/core/resources/manager_width.dart';
//
// import '../pages/cloudinary_image_avatar.dart';
//
// class CreateGroupDetailsScreen extends StatefulWidget {
//   final Map<String, Map<String, dynamic>> selectedMembers;
//
//   const CreateGroupDetailsScreen({
//     Key? key,
//     required this.selectedMembers,
//   }) : super(key: key);
//
//   @override
//   State<CreateGroupDetailsScreen> createState() =>
//       _CreateGroupDetailsScreenState();
// }
//
// class _CreateGroupDetailsScreenState extends State<CreateGroupDetailsScreen> {
//   final _nameController = TextEditingController();
//   final _descriptionController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   bool _isCreating = false;
//
//   // استخدام AppSettingsPrefs للحصول على بيانات المستخدم
//   final AppSettingsPrefs _prefs = Get.find<AppSettingsPrefs>();
//
//   String get currentUserId => _prefs.getUserId();
//   String get currentUserName => _prefs.getUserName();
//
//   @override
//   void initState() {
//     super.initState();
//     print('👤 المستخدم الحالي: $currentUserId - $currentUserName');
//   }
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _descriptionController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade50,
//       appBar: _buildAppBar(),
//       body: Form(
//         key: _formKey,
//         child: SingleChildScrollView(
//           padding: EdgeInsets.all(ManagerWidth.w20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildHeader(),
//               SizedBox(height: ManagerHeight.h30),
//               _buildGroupImage(),
//               SizedBox(height: ManagerHeight.h30),
//               _buildNameField(),
//               SizedBox(height: ManagerHeight.h20),
//               _buildDescriptionField(),
//               SizedBox(height: ManagerHeight.h30),
//               _buildMembersPreview(),
//               SizedBox(height: ManagerHeight.h30),
//               _buildCreateButton(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   PreferredSizeWidget _buildAppBar() {
//     return AppBar(
//       backgroundColor: ManagerColors.primaryColor,
//       elevation: 0,
//       leading: IconButton(
//         icon: const Icon(Icons.arrow_back, color: Colors.white),
//         onPressed: () => Get.back(),
//       ),
//       title: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'إنشاء مجموعة جديدة',
//             style: getBoldTextStyle(
//               fontSize: ManagerFontSize.s18,
//               color: Colors.white,
//             ),
//           ),
//           Text(
//             'الخطوة 2 من 2',
//             style: getRegularTextStyle(
//               fontSize: ManagerFontSize.s12,
//               color: Colors.white.withOpacity(0.9),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildHeader() {
//     return Container(
//       padding: EdgeInsets.all(ManagerWidth.w16),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             Colors.blue.shade50,
//             Colors.blue.shade100.withOpacity(0.3),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.blue.shade200),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: EdgeInsets.all(ManagerWidth.w10),
//             decoration: BoxDecoration(
//               color: Colors.blue.shade100,
//               shape: BoxShape.circle,
//             ),
//             child: Icon(
//               Icons.info_outline,
//               color: Colors.blue.shade700,
//               size: 24,
//             ),
//           ),
//           SizedBox(width: ManagerWidth.w12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'معلومات المجموعة',
//                   style: getBoldTextStyle(
//                     fontSize: ManagerFontSize.s14,
//                     color: Colors.blue.shade900,
//                   ),
//                 ),
//                 SizedBox(height: ManagerHeight.h4),
//                 Text(
//                   'أدخل اسم ووصف للمجموعة',
//                   style: getRegularTextStyle(
//                     fontSize: ManagerFontSize.s12,
//                     color: Colors.blue.shade700,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildGroupImage() {
//     return Center(
//       child: Column(
//         children: [
//           Stack(
//             children: [
//               Container(
//                 width: 120,
//                 height: 120,
//                 decoration: BoxDecoration(
//                   color: ManagerColors.primaryColor.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                   border: Border.all(
//                     color: ManagerColors.primaryColor.withOpacity(0.3),
//                     width: 2,
//                   ),
//                 ),
//                 child: Icon(
//                   Icons.group,
//                   size: 60,
//                   color: ManagerColors.primaryColor,
//                 ),
//               ),
//               Positioned(
//                 bottom: 0,
//                 right: 0,
//                 child: Container(
//                   width: 36,
//                   height: 36,
//                   decoration: BoxDecoration(
//                     color: ManagerColors.primaryColor,
//                     shape: BoxShape.circle,
//                     border: Border.all(color: Colors.white, width: 2),
//                   ),
//                   child: IconButton(
//                     padding: EdgeInsets.zero,
//                     icon: const Icon(Icons.camera_alt, size: 18),
//                     color: Colors.white,
//                     onPressed: () {
//                       Get.snackbar('قريباً', 'اختيار صورة قيد التطوير');
//                     },
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: ManagerHeight.h12),
//           Text(
//             'إضافة صورة المجموعة',
//             style: getRegularTextStyle(
//               fontSize: ManagerFontSize.s13,
//               color: Colors.grey.shade600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildNameField() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Icon(
//               Icons.group,
//               color: ManagerColors.primaryColor,
//               size: 20,
//             ),
//             SizedBox(width: ManagerWidth.w8),
//             Text(
//               'اسم المجموعة',
//               style: getBoldTextStyle(
//                 fontSize: ManagerFontSize.s14,
//                 color: ManagerColors.black,
//               ),
//             ),
//             Text(
//               ' *',
//               style: getBoldTextStyle(
//                 fontSize: ManagerFontSize.s14,
//                 color: Colors.red,
//               ),
//             ),
//           ],
//         ),
//         SizedBox(height: ManagerHeight.h10),
//         TextFormField(
//           controller: _nameController,
//           textAlign: TextAlign.right,
//           maxLength: 50,
//           validator: (value) {
//             if (value == null || value.trim().isEmpty) {
//               return 'الرجاء إدخال اسم المجموعة';
//             }
//             if (value.trim().length < 3) {
//               return 'الاسم يجب أن يكون 3 أحرف على الأقل';
//             }
//             return null;
//           },
//           style: getRegularTextStyle(
//             fontSize: ManagerFontSize.s14,
//             color: ManagerColors.black,
//           ),
//           decoration: InputDecoration(
//             hintText: 'مثال: مجموعة الأصدقاء',
//             hintStyle: getRegularTextStyle(
//               fontSize: ManagerFontSize.s14,
//               color: Colors.grey.shade400,
//             ),
//             filled: true,
//             fillColor: Colors.white,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(color: Colors.grey.shade300),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(color: Colors.grey.shade300),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(
//                 color: ManagerColors.primaryColor,
//                 width: 2,
//               ),
//             ),
//             errorBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: const BorderSide(color: Colors.red),
//             ),
//             prefixIcon: Icon(
//               Icons.edit,
//               color: Colors.grey.shade400,
//             ),
//             contentPadding: EdgeInsets.symmetric(
//               horizontal: ManagerWidth.w16,
//               vertical: ManagerHeight.h16,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildDescriptionField() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Icon(
//               Icons.description,
//               color: ManagerColors.primaryColor,
//               size: 20,
//             ),
//             SizedBox(width: ManagerWidth.w8),
//             Text(
//               'وصف المجموعة (اختياري)',
//               style: getBoldTextStyle(
//                 fontSize: ManagerFontSize.s14,
//                 color: ManagerColors.black,
//               ),
//             ),
//           ],
//         ),
//         SizedBox(height: ManagerHeight.h10),
//         TextFormField(
//           controller: _descriptionController,
//           textAlign: TextAlign.right,
//           maxLines: 3,
//           maxLength: 200,
//           style: getRegularTextStyle(
//             fontSize: ManagerFontSize.s14,
//             color: ManagerColors.black,
//           ),
//           decoration: InputDecoration(
//             hintText: 'أضف وصفاً للمجموعة...',
//             hintStyle: getRegularTextStyle(
//               fontSize: ManagerFontSize.s14,
//               color: Colors.grey.shade400,
//             ),
//             filled: true,
//             fillColor: Colors.white,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(color: Colors.grey.shade300),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(color: Colors.grey.shade300),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(
//                 color: ManagerColors.primaryColor,
//                 width: 2,
//               ),
//             ),
//             contentPadding: EdgeInsets.all(ManagerWidth.w16),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildMembersPreview() {
//     return Container(
//       padding: EdgeInsets.all(ManagerWidth.w16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.shade200),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(
//                 Icons.people,
//                 color: ManagerColors.primaryColor,
//                 size: 20,
//               ),
//               SizedBox(width: ManagerWidth.w8),
//               Text(
//                 'الأعضاء (${widget.selectedMembers.length + 1})',
//                 style: getBoldTextStyle(
//                   fontSize: ManagerFontSize.s14,
//                   color: ManagerColors.black,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: ManagerHeight.h12),
//           const Divider(height: 1),
//           SizedBox(height: ManagerHeight.h12),
//           Wrap(
//             spacing: 8,
//             runSpacing: 8,
//             children: [
//               // أنت (المنشئ)
//               _buildMemberChip('أنت', '', isCreator: true),
//               // الأعضاء المحددين
//               ...widget.selectedMembers.values
//                   .map((member) => _buildMemberChip(
//                 member['name'],
//                 member['imageUrl'] ?? '',
//               ))
//                   .toList(),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildMemberChip(String name, String imageUrl, {bool isCreator = false}) {
//     return Container(
//       padding: EdgeInsets.symmetric(
//         horizontal: ManagerWidth.w10,
//         vertical: ManagerHeight.h6,
//       ),
//       decoration: BoxDecoration(
//         color: isCreator
//             ? ManagerColors.primaryColor.withOpacity(0.1)
//             : Colors.grey.shade100,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(
//           color: isCreator
//               ? ManagerColors.primaryColor.withOpacity(0.3)
//               : Colors.grey.shade300,
//         ),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           if (imageUrl.isNotEmpty)
//             CloudinaryAvatar(
//               imageUrl: imageUrl,
//               fallbackText: name,
//               radius: 12,
//             )
//           else
//             CircleAvatar(
//               radius: 12,
//               backgroundColor: isCreator
//                   ? ManagerColors.primaryColor
//                   : Colors.grey.shade300,
//               child: Icon(
//                 isCreator ? Icons.star : Icons.person,
//                 size: 14,
//                 color: Colors.white,
//               ),
//             ),
//           SizedBox(width: ManagerWidth.w6),
//           Text(
//             name,
//             style: getRegularTextStyle(
//               fontSize: ManagerFontSize.s13,
//               color: isCreator ? ManagerColors.primaryColor : ManagerColors.black,
//             ),
//           ),
//           if (isCreator) ...[
//             SizedBox(width: ManagerWidth.w4),
//             Container(
//               padding: EdgeInsets.symmetric(
//                 horizontal: ManagerWidth.w6,
//                 vertical: ManagerHeight.h2,
//               ),
//               decoration: BoxDecoration(
//                 color: ManagerColors.primaryColor,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Text(
//                 'منشئ',
//                 style: getRegularTextStyle(
//                   fontSize: ManagerFontSize.s10,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
//
//   Widget _buildCreateButton() {
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed: _isCreating ? null : _createGroup,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: ManagerColors.primaryColor,
//           disabledBackgroundColor: Colors.grey.shade300,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           padding: EdgeInsets.symmetric(vertical: ManagerHeight.h16),
//           elevation: 4,
//         ),
//         child: _isCreating
//             ? Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const SizedBox(
//               width: 20,
//               height: 20,
//               child: CircularProgressIndicator(
//                 strokeWidth: 2,
//                 valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//               ),
//             ),
//             SizedBox(width: ManagerWidth.w12),
//             Text(
//               'جاري الإنشاء...',
//               style: getBoldTextStyle(
//                 fontSize: ManagerFontSize.s15,
//                 color: Colors.white,
//               ),
//             ),
//           ],
//         )
//             : Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.check_circle, color: Colors.white),
//             SizedBox(width: ManagerWidth.w10),
//             Text(
//               'إنشاء المجموعة',
//               style: getBoldTextStyle(
//                 fontSize: ManagerFontSize.s15,
//                 color: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Future<void> _createGroup() async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }
//
//     // التحقق من المصادقة
//     if (currentUserId.isEmpty) {
//       Get.snackbar(
//         'خطأ',
//         'يجب تسجيل الدخول أولاً',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//       return;
//     }
//
//     setState(() => _isCreating = true);
//
//     try {
//       final groupName = _nameController.text.trim();
//       final description = _descriptionController.text.trim();
//
//       // قائمة الأعضاء (المستخدم الحالي + المحددين)
//       final participants = [currentUserId, ...widget.selectedMembers.keys];
//
//       // بيانات المجموعة
//       final groupData = {
//         'name': groupName,
//         'description': description,
//         'imageUrl': '', // TODO: Add image upload
//         'createdBy': currentUserId,
//         'createdBy_name': currentUserName,
//         'createdAt': FieldValue.serverTimestamp(),
//         'participants': participants,
//         'admins': [currentUserId], // المنشئ هو المشرف الأول
//         'lastMessage': 'تم إنشاء المجموعة',
//         'lastMessageTime': FieldValue.serverTimestamp(),
//         'lastMessageSender': currentUserId,
//         'messageCount': 0,
//         'unreadCount': {}, // سيتم تحديثه عند إرسال الرسائل
//       };
//
//       // إنشاء المجموعة
//       final groupRef =
//       await FirebaseFirestore.instance.collection('groups').add(groupData);
//
//       print('✅ تم إنشاء المجموعة: ${groupRef.id}');
//
//       // رسالة ترحيب
//       await groupRef.collection('messages').add({
//         'text': 'مرحباً بالجميع في $groupName! 🎉',
//         'senderId': currentUserId,
//         'senderName': currentUserName,
//         'senderImage': '',
//         'timestamp': FieldValue.serverTimestamp(),
//         'status': 'sent',
//         'mentions': [],
//         'type': 'system',
//       });
//
//       Get.snackbar(
//         'نجح',
//         'تم إنشاء المجموعة بنجاح',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.green,
//         colorText: Colors.white,
//         icon: const Icon(Icons.check_circle, color: Colors.white),
//         duration: const Duration(seconds: 2),
//       );
//
//       // العودة للصفحة الرئيسية
//       Get.until((route) => route.isFirst);
//     } catch (e) {
//       print('❌ خطأ في إنشاء المجموعة: $e');
//       Get.snackbar(
//         'خطأ',
//         'فشل إنشاء المجموعة: $e',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//         icon: const Icon(Icons.error, color: Colors.white),
//       );
//     } finally {
//       if (mounted) {
//         setState(() => _isCreating = false);
//       }
//     }
//   }
// }