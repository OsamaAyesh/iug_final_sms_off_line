// المسار: lib/features/home/add_chat/presentation/pages/select_members_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';
import 'package:app_mobile/core/resources/manager_width.dart';
import 'cloudinary_image_avatar.dart';
import 'create_group_details_screen.dart';

class SelectMembersScreen extends StatefulWidget {
  const SelectMembersScreen({super.key});

  @override
  State<SelectMembersScreen> createState() => _SelectMembersScreenState();
}

class _SelectMembersScreenState extends State<SelectMembersScreen> {
  final _searchController = TextEditingController();
  final _selectedMembers = <String, Map<String, dynamic>>{};
  List<Map<String, dynamic>> _allContacts = [];
  List<Map<String, dynamic>> _filteredContacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);

    try {
      final currentUserId = '567450057';

      print('📱 جاري تحميل جهات الاتصال...');

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
        });
      }

      print('✅ تم تحميل ${contacts.length} جهة اتصال');

      setState(() {
        _allContacts = contacts;
        _filteredContacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ خطأ في تحميل جهات الاتصال: $e');
      setState(() => _isLoading = false);
      Get.snackbar(
        'خطأ',
        'فشل تحميل جهات الاتصال: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = _allContacts;
      } else {
        _filteredContacts = _allContacts.where((contact) {
          final name = contact['name'].toString().toLowerCase();
          final phone = contact['phone'].toString().toLowerCase();
          final bio = contact['bio'].toString().toLowerCase();
          return name.contains(query) ||
              phone.contains(query) ||
              bio.contains(query);
        }).toList();
      }
    });
  }

  void _toggleMember(String id, Map<String, dynamic> contact) {
    setState(() {
      if (_selectedMembers.containsKey(id)) {
        _selectedMembers.remove(id);
      } else {
        _selectedMembers[id] = contact;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_selectedMembers.isNotEmpty) _buildSelectedChips(),
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(child: _buildContactsList()),
        ],
      ),
      floatingActionButton: _selectedMembers.length >= 2
          ? _buildNextButton()
          : null,
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
            'الخطوة 1 من 2',
            style: getRegularTextStyle(
              fontSize: ManagerFontSize.s12,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
      actions: [
        if (_selectedMembers.isNotEmpty)
          Center(
            child: Container(
              margin: EdgeInsets.only(left: ManagerWidth.w16),
              padding: EdgeInsets.symmetric(
                horizontal: ManagerWidth.w12,
                vertical: ManagerHeight.h6,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: ManagerWidth.w6),
                  Text(
                    '${_selectedMembers.length}',
                    style: getBoldTextStyle(
                      fontSize: ManagerFontSize.s14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(ManagerWidth.w16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              textAlign: TextAlign.right,
              style: getRegularTextStyle(
                fontSize: ManagerFontSize.s14,
                color: ManagerColors.black,
              ),
              decoration: InputDecoration(
                hintText: 'بحث عن جهة اتصال...',
                hintStyle: getRegularTextStyle(
                  fontSize: ManagerFontSize.s14,
                  color: Colors.grey.shade400,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: ManagerWidth.w16,
                  vertical: ManagerHeight.h12,
                ),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty) ...[
            SizedBox(width: ManagerWidth.w8),
            IconButton(
              icon: Icon(Icons.clear, color: Colors.grey.shade600),
              onPressed: () {
                _searchController.clear();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedChips() {
    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(
        horizontal: ManagerWidth.w16,
        vertical: ManagerHeight.h8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people,
                color: ManagerColors.primaryColor,
                size: 16,
              ),
              SizedBox(width: ManagerWidth.w6),
              Text(
                'الأعضاء المحددون (${_selectedMembers.length})',
                style: getBoldTextStyle(
                  fontSize: ManagerFontSize.s12,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: ManagerHeight.h8),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedMembers.length,
              separatorBuilder: (_, __) => SizedBox(width: ManagerWidth.w8),
              itemBuilder: (context, index) {
                final entry = _selectedMembers.entries.elementAt(index);
                final contact = entry.value;
                return _buildSelectedChip(entry.key, contact);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedChip(String id, Map<String, dynamic> contact) {
    return Chip(
      avatar: CloudinaryAvatar(
        imageUrl: contact['imageUrl'] ?? '',
        fallbackText: contact['name'] ?? 'U',
        radius: 16,
      ),
      label: Text(
        contact['name'],
        style: getRegularTextStyle(
          fontSize: ManagerFontSize.s13,
          color: ManagerColors.black,
        ),
      ),
      deleteIcon: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, size: 16, color: Colors.red),
      ),
      onDeleted: () => _toggleMember(id, contact),
      backgroundColor: ManagerColors.primaryColor.withOpacity(0.1),
      side: BorderSide(color: ManagerColors.primaryColor.withOpacity(0.3)),
    );
  }

  Widget _buildContactsList() {
    if (_filteredContacts.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: EdgeInsets.all(ManagerWidth.w16),
      itemCount: _filteredContacts.length,
      separatorBuilder: (_, __) => SizedBox(height: ManagerHeight.h8),
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        final isSelected = _selectedMembers.containsKey(contact['id']);
        return _buildContactCard(contact, isSelected);
      },
    );
  }

  Widget _buildContactCard(Map<String, dynamic> contact, bool isSelected) {
    return InkWell(
      onTap: () => _toggleMember(contact['id'], contact),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(ManagerWidth.w12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? ManagerColors.primaryColor
                : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: ManagerColors.primaryColor.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CloudinaryAvatar(
                  imageUrl: contact['imageUrl'] ?? '',
                  fallbackText: contact['name'] ?? 'U',
                  radius: 28,
                ),
                if (contact['isOnline'] == true)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: ManagerWidth.w12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact['name'],
                    style: getBoldTextStyle(
                      fontSize: ManagerFontSize.s15,
                      color: ManagerColors.black,
                    ),
                  ),
                  SizedBox(height: ManagerHeight.h4),
                  Text(
                    contact['bio']?.isNotEmpty == true
                        ? contact['bio']
                        : contact['phone'],
                    style: getRegularTextStyle(
                      fontSize: ManagerFontSize.s13,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected
                    ? ManagerColors.primaryColor
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? ManagerColors.primaryColor
                      : Colors.grey.shade400,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: isSelected
                  ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchController.text.isEmpty
                ? Icons.people_outline
                : Icons.search_off,
            size: 100,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: ManagerHeight.h20),
          Text(
            _searchController.text.isNotEmpty
                ? 'لا توجد نتائج'
                : 'لا توجد جهات اتصال',
            style: getBoldTextStyle(
              fontSize: ManagerFontSize.s18,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: ManagerHeight.h8),
          Text(
            _searchController.text.isNotEmpty
                ? 'حاول البحث بكلمات أخرى'
                : 'أضف جهات اتصال أولاً',
            style: getRegularTextStyle(
              fontSize: ManagerFontSize.s14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        if (_selectedMembers.length < 2) {
          Get.snackbar(
            'تنبيه',
            'يجب اختيار عضوين على الأقل',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
          return;
        }

        Get.to(
              () => CreateGroupDetailsScreen(
            selectedMembers: _selectedMembers,
          ),
          transition: Transition.rightToLeft,
        );
      },
      backgroundColor: ManagerColors.primaryColor,
      icon: const Icon(Icons.arrow_forward, color: Colors.white),
      label: Text(
        'التالي (${_selectedMembers.length})',
        style: getBoldTextStyle(
          fontSize: ManagerFontSize.s15,
          color: Colors.white,
        ),
      ),
    );
  }
}