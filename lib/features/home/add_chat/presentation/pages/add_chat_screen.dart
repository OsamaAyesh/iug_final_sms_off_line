import 'package:app_mobile/core/util/snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_mobile/core/storage/local/app_settings_prefs.dart';
import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';
import 'package:app_mobile/core/resources/manager_width.dart';
import 'package:app_mobile/features/home/single_chat/presentation/pages/single_chat_screen.dart';

import '../../../../../constants/di/dependency_injection.dart' show instance;

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

  final AppSettingsPrefs _prefs = instance<AppSettingsPrefs>();

  String get currentUserId => _prefs.getUserId();
  String get currentUserName => _prefs.getUserName();
  String get currentUserPhone => _prefs.getUserPhone();

  @override
  void initState() {
    super.initState();
    print('👤 المستخدم الحالي: $currentUserId - $currentUserName');
    _checkAuth();
  }

  void _checkAuth() {
    if (currentUserId.isEmpty) {
      AppSnackbar.warning('يجب تسجيل الدخول أولاً');
      Future.delayed(const Duration(seconds: 2), () => Get.back());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _normalizePhone(String phone) {
    String normalized = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (normalized.startsWith('0')) {
      normalized = normalized.substring(1);
    }
    if (normalized.startsWith('+970')) {
      normalized = normalized.replaceFirst('+970', '');
    }
    if (normalized.startsWith('970')) {
      normalized = normalized.replaceFirst('970', '');
    }
    return normalized;
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
          'أدخل رقم الهاتف للبحث عن المستخدم',
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
              'الاسم (اختياري)',
              style: getBoldTextStyle(
                fontSize: ManagerFontSize.s14,
                color: ManagerColors.black,
              ),
            ),
          ],
        ),
        SizedBox(height: ManagerHeight.h10),
        TextFormField(
          controller: _nameController,
          textAlign: TextAlign.right,
          style: getRegularTextStyle(
            fontSize: ManagerFontSize.s14,
            color: ManagerColors.black,
          ),
          decoration: InputDecoration(
            hintText: 'سيتم استخدام الاسم من الحساب',
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
            final normalized = _normalizePhone(value);
            if (normalized.length < 9) {
              return 'رقم الهاتف غير صحيح';
            }
            return null;
          },
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d+\s-]')),
          ],
          style: getRegularTextStyle(
            fontSize: ManagerFontSize.s14,
            color: ManagerColors.black,
          ),
          decoration: InputDecoration(
            hintText: '0567450057 أو +970567450057',
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
              'سيتم البحث عن المستخدم في التطبيق باستخدام رقم الهاتف',
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
              'جاري البحث...',
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
              'بحث وإضافة',
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

    if (currentUserId.isEmpty) {
      AppSnackbar.error('يجب تسجيل الدخول أولاً');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final phone = _phoneController.text.trim();
      final normalizedPhone = _normalizePhone(phone);

      print('🔍 البحث عن رقم: $phone');
      print('🔍 الرقم المطبّع: $normalizedPhone');
      print('👤 المستخدم الحالي: $currentUserId - $currentUserName');

      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('phoneCanon', isEqualTo: normalizedPhone)
          .limit(1)
          .get();
      if (userQuery.docs.isEmpty) {
        print('❌ لم يتم العثور على المستخدم');
        AppSnackbar.warning('المستخدم غير مسجل في التطبيق');
        return;
      }

      final contactDoc = userQuery.docs.first;
      final contactUserId = contactDoc.id;
      final contactData = contactDoc.data() as Map<String, dynamic>;

      print('✅ تم العثور على المستخدم: ${contactData['name']} - $contactUserId');

      if (contactUserId == currentUserId) {
        AppSnackbar.warning('لا يمكنك إضافة نفسك كجهة اتصال');
        return;
      }

      final existingContact = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('contacts')
          .doc(contactUserId)
          .get();

      if (existingContact.exists) {
        AppSnackbar.loading(
          title: 'موجود مسبقاً',
            'هذا المستخدم موجود في جهات الاتصال');

        await _openChatDirectly(contactUserId, contactData);
        return;
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('contacts')
          .doc(contactUserId)
          .set({
        'addedAt': FieldValue.serverTimestamp(),
        'name': _nameController.text.trim().isEmpty
            ? contactData['name']
            : _nameController.text.trim(),
        'phone': contactData['phone'],
        'imageUrl': contactData['imageUrl'],
      });

      print('✅ تمت إضافة جهة الاتصال بنجاح');

      await _createIndividualChat(contactUserId, contactData);

      AppSnackbar.success('تمت إضافة ${contactData['name']} وفتح محادثة جديدة');

      Get.back(result: true);
    } catch (e) {
      print('❌ خطأ: $e');
      AppSnackbar.error('فشل إضافة جهة الاتصال: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openChatDirectly(String contactUserId, Map<String, dynamic> contactData) async {
    try {
      final chatId = _generateChatId(currentUserId, contactUserId);

      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .get();

      if (chatDoc.exists) {
        Get.to(() => SingleChatScreen(
          otherUserId: contactUserId,
          otherUserName: contactData['name'],
          otherUserImage: contactData['imageUrl'],
        ));
      } else {
        await _createIndividualChat(contactUserId, contactData);
      }
    } catch (e) {
      print('❌ خطأ في فتح المحادثة: $e');
    }
  }


  Future<void> _createIndividualChat(
      String contactUserId, Map<String, dynamic> contactData) async {
    try {
      final chatId = _generateChatId(currentUserId, contactUserId);

      print('💬 محاولة إنشاء محادثة جديدة: $chatId');

      // ✅ تحقق أولًا إذا كانت المحادثة موجودة بالفعل
      final existingChat = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .get();

      if (existingChat.exists) {
        print('⚠️ المحادثة موجودة مسبقًا: $chatId');
        // افتح المحادثة الموجودة مباشرة
        Get.to(() => SingleChatScreen(
          otherUserId: contactUserId,
          otherUserName: contactData['name'],
          otherUserImage: contactData['imageUrl'],
        ));
        return;
      }

      // ✅ إذا لم تكن موجودة، أنشئها الآن
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

      await FirebaseFirestore.instance.collection('chats').doc(chatId).set(chatData);
      print('✅ تم إنشاء المحادثة بنجاح: $chatId');

      // إضافة رسالة ترحيب تلقائية
      await _addWelcomeMessage(chatId, contactData['name']);

      // فتح المحادثة بعد الإنشاء
      Get.to(() => SingleChatScreen(
        otherUserId: contactUserId,
        otherUserName: contactData['name'],
        otherUserImage: contactData['imageUrl'],
      ));
    } catch (e) {
      print('❌ خطأ في إنشاء المحادثة: $e');
      throw Exception('فشل إنشاء المحادثة: $e');
    }
  }

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

  String _generateChatId(String user1Id, String user2Id) {
    final sortedIds = [user1Id, user2Id]..sort();
    return 'individual_${sortedIds[0]}_${sortedIds[1]}';
  }
}
