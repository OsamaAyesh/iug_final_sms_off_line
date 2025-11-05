// المسار: lib/features/home/add_chat/presentation/pages/select_members_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';
import 'package:app_mobile/core/resources/manager_width.dart';
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
      final currentUserId = '567450057'; // استبدل بالـ user ID الفعلي

      final contactsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('contacts')
          .get();

      final List<Map<String, dynamic>> contacts = [];

      for (var doc in contactsSnapshot.docs) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(doc.id)
            .get();

        if (userDoc.exists) {
          contacts.add({
            'id': doc.id,
            'name': userDoc.data()?['name'] ?? 'غير معروف',
            'phone': userDoc.data()?['phone'] ?? '',
            'imageUrl': userDoc.data()?['imageUrl'],
            'bio': userDoc.data()?['bio'],
            'isOnline': userDoc.data()?['isOnline'] ?? false,
          });
        }
      }

      setState(() {
        _allContacts = contacts;
        _filteredContacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
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
          return name.contains(query) || phone.contains(query);
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContactsList(),
          ),
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
      title: Text(
        'إنشاء مجموعة',
        style: getBoldTextStyle(
          fontSize: ManagerFontSize.s18,
          color: Colors.white,
        ),
      ),
      actions: [
        if (_selectedMembers.isNotEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.only(left: ManagerWidth.w16),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ManagerWidth.w12,
                  vertical: ManagerHeight.h6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'تم اختيار ${_selectedMembers.length}',
                  style: getBoldTextStyle(
                    fontSize: ManagerFontSize.s13,
                    color: Colors.white,
                  ),
                ),
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
    );
  }

  Widget _buildSelectedChips() {
    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(
        horizontal: ManagerWidth.w16,
        vertical: ManagerHeight.h8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
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
    );
  }

  Widget _buildSelectedChip(String id, Map<String, dynamic> contact) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: ManagerColors.primaryColor.withOpacity(0.1),
        backgroundImage: contact['imageUrl'] != null
            ? CachedNetworkImageProvider(contact['imageUrl'])
            : null,
        child: contact['imageUrl'] == null
            ? Text(
          contact['name'][0].toUpperCase(),
          style: getBoldTextStyle(
            fontSize: ManagerFontSize.s12,
            color: ManagerColors.primaryColor,
          ),
        )
            : null,
      ),
      label: Text(
        contact['name'],
        style: getRegularTextStyle(
          fontSize: ManagerFontSize.s13,
          color: ManagerColors.black,
        ),
      ),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: () => _toggleMember(id, contact),
      backgroundColor: Colors.grey.shade100,
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
      child: Container(
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
                CircleAvatar(
                  radius: 28,
                  backgroundColor: ManagerColors.primaryColor.withOpacity(0.1),
                  backgroundImage: contact['imageUrl'] != null
                      ? CachedNetworkImageProvider(contact['imageUrl'])
                      : null,
                  child: contact['imageUrl'] == null
                      ? Text(
                    contact['name'][0].toUpperCase(),
                    style: getBoldTextStyle(
                      fontSize: ManagerFontSize.s20,
                      color: ManagerColors.primaryColor,
                    ),
                  )
                      : null,
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
                    contact['bio'] ?? contact['phone'],
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
            Container(
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
            Icons.people_outline,
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
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        Get.to(
              () => CreateGroupDetailsScreen(
            selectedMembers: _selectedMembers,
          ),
        );
      },
      backgroundColor: ManagerColors.primaryColor,
      icon: const Icon(Icons.arrow_forward, color: Colors.white),
      label: Text(
        'التالي',
        style: getBoldTextStyle(
          fontSize: ManagerFontSize.s15,
          color: Colors.white,
        ),
      ),
    );
  }
}