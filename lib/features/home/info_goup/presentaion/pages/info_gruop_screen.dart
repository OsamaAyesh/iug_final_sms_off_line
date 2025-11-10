// المسار: lib/features/home/group_chat/presentation/pages/group_info_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_mobile/core/storage/local/app_settings_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/resources/manager_colors.dart';
import '../../../../../core/resources/manager_font_size.dart';
import '../../../../../core/resources/manager_height.dart';
import '../../../../../core/resources/manager_styles.dart';
import '../../../../../core/resources/manager_width.dart';
import '../../../add_chat/presentation/pages/cloudinary_image_avatar.dart';

class GroupInfoScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String groupImage;

  const GroupInfoScreen({
    Key? key,
    required this.groupId,
    required this.groupName,
    required this.groupImage,
  }) : super(key: key);

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final _firestore = FirebaseFirestore.instance;
  late AppSettingsPrefs _prefs;

  // بيانات المستخدم الحالي
  String _currentUserId = '';
  String _currentUserName = '';
  String _currentUserPhone = '';

  Map<String, dynamic> groupData = {};
  List<Map<String, dynamic>> members = [];
  List<String> admins = [];
  bool isLoading = true;
  bool isUserDataLoaded = false;

  StreamSubscription? _groupSubscription;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  @override
  void dispose() {
    _groupSubscription?.cancel();
    super.dispose();
  }

  // ✅ تهيئة بيانات المستخدم من نظام المصادقة
  Future<void> _initializeUserData() async {
    try {
      final sharedPrefs = await SharedPreferences.getInstance();
      _prefs = AppSettingsPrefs(sharedPrefs);

      // جلب بيانات المستخدم من SharedPreferences
      _currentUserId = _prefs.getUserId() ?? '';
      _currentUserName = _prefs.getUserName() ?? '';
      _currentUserPhone = _prefs.getUserPhone() ?? '';

      if (_currentUserId.isEmpty) {
        print('❌ لم يتم العثور على بيانات المستخدم');
        Get.snackbar('خطأ', 'لم يتم العثور على بيانات المستخدم');
        Get.back();
        return;
      }

      setState(() {
        isUserDataLoaded = true;
      });

      print('✅ بيانات المستخدم المحملة:');
      print('   - user_id: $_currentUserId');
      print('   - user_name: $_currentUserName');
      print('   - user_phone: $_currentUserPhone');

      // بعد تحميل بيانات المستخدم، نقوم بتحميل بيانات المجموعة
      _loadGroupInfo();
    } catch (e) {
      print('❌ خطأ في تحميل بيانات المستخدم: $e');
      Get.snackbar('خطأ', 'فشل في تحميل بيانات المستخدم');
      Get.back();
    }
  }

  Future<void> _loadGroupInfo() async {
    if (!isUserDataLoaded) return;

    setState(() => isLoading = true);

    try {
      _groupSubscription = _firestore
          .collection('groups')
          .doc(widget.groupId)
          .snapshots()
          .listen((snapshot) async {
        if (!snapshot.exists) {
          Get.back();
          return;
        }

        groupData = snapshot.data() ?? {};
        admins = List<String>.from(groupData['admins'] ?? []);
        final participantIds = List<String>.from(groupData['participants'] ?? []);

        // ✅ تحميل تفاصيل الأعضاء
        final membersList = <Map<String, dynamic>>[];
        for (final userId in participantIds) {
          try {
            final userDoc = await _firestore.collection('users').doc(userId).get();
            if (userDoc.exists) {
              final userData = userDoc.data()!;
              membersList.add({
                'id': userId,
                'name': userData['name'] ?? 'مستخدم',
                'imageUrl': userData['imageUrl'] ?? '',
                'phone': userData['phone'] ?? '',
                'bio': userData['bio'] ?? '',
                'isOnline': userData['isOnline'] ?? false,
                'isAdmin': admins.contains(userId),
              });
            } else {
              // إذا لم يتم العثور على المستخدم في قاعدة البيانات
              membersList.add({
                'id': userId,
                'name': 'مستخدم',
                'imageUrl': '',
                'phone': '',
                'bio': '',
                'isOnline': false,
                'isAdmin': admins.contains(userId),
              });
            }
          } catch (e) {
            print('❌ خطأ في تحميل المستخدم $userId: $e');
            membersList.add({
              'id': userId,
              'name': 'مستخدم',
              'imageUrl': '',
              'phone': '',
              'bio': '',
              'isOnline': false,
              'isAdmin': admins.contains(userId),
            });
          }
        }

        if (mounted) {
          setState(() {
            members = membersList;
            isLoading = false;
          });
        }
      });
    } catch (e) {
      print('❌ خطأ في تحميل معلومات المجموعة: $e');
      setState(() => isLoading = false);
      Get.snackbar('خطأ', 'فشل في تحميل معلومات المجموعة');
    }
  }

  // ✅ التحقق من صلاحيات المستخدم
  bool get isAdmin => admins.contains(_currentUserId);
  bool get isCreator => groupData['createdBy'] == _currentUserId;
  bool get isMember => members.any((member) => member['id'] == _currentUserId);

  @override
  Widget build(BuildContext context) {
    if (!isUserDataLoaded) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: ManagerColors.primaryColor),
              SizedBox(height: ManagerHeight.h16),
              Text(
                'جاري تحميل بيانات المستخدم...',
                style: getRegularTextStyle(
                  fontSize: ManagerFontSize.s14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (!isMember)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: ManagerHeight.h16),
                    Text(
                      'غير مسموح بالوصول',
                      style: getBoldTextStyle(
                        fontSize: ManagerFontSize.s18,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: ManagerHeight.h8),
                    Text(
                      'أنت لست عضوًا في هذه المجموعة',
                      style: getRegularTextStyle(
                        fontSize: ManagerFontSize.s14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: ManagerHeight.h16),
                    ElevatedButton(
                      onPressed: () => Get.back(),
                      child: const Text('رجوع'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildListDelegate([
                _buildGroupHeader(),
                SizedBox(height: ManagerHeight.h8),
                _buildGroupDescription(),
                SizedBox(height: ManagerHeight.h8),
                _buildMembersSection(),
                // SizedBox(height: ManagerHeight.h8),
                // _buildMediaSection(),
                SizedBox(height: ManagerHeight.h8),
                _buildSettingsSection(),
                SizedBox(height: ManagerHeight.h8),
                _buildDangerZone(),
                SizedBox(height: ManagerHeight.h50),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: ManagerColors.primaryColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Get.back(),
      ),
      actions: [
        if (isAdmin)
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _editGroupInfo,
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.groupName,
          style: getBoldTextStyle(
            fontSize: ManagerFontSize.s16,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ManagerColors.primaryColor,
                ManagerColors.primaryColor.withOpacity(0.8),
              ],
            ),
          ),
          child: Center(
            child: CloudinaryAvatar(
              imageUrl: widget.groupImage,
              fallbackText: widget.groupName,
              radius: 50,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupHeader() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(ManagerWidth.w16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                icon: Icons.people,
                label: 'الأعضاء',
                value: '${members.length}',
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade300),
              _buildStatItem(
                icon: Icons.admin_panel_settings,
                label: 'المشرفون',
                value: '${admins.length}',
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade300),
              _buildStatItem(
                icon: Icons.message,
                label: 'الرسائل',
                value: '${groupData['messageCount'] ?? 0}',
              ),
            ],
          ),
          SizedBox(height: ManagerHeight.h16),
          // ✅ معلومات المستخدم الحالي
          if (isMember)
            Container(
              padding: EdgeInsets.all(ManagerWidth.w12),
              decoration: BoxDecoration(
                color: ManagerColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ManagerColors.primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: ManagerColors.primaryColor, size: 20),
                  SizedBox(width: ManagerWidth.w8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'أنت في هذه المجموعة',
                          style: getBoldTextStyle(
                            fontSize: ManagerFontSize.s14,
                            color: ManagerColors.primaryColor,
                          ),
                        ),
                        SizedBox(height: ManagerHeight.h4),
                        Text(
                          _currentUserName.isNotEmpty ? _currentUserName : 'مستخدم',
                          style: getRegularTextStyle(
                            fontSize: ManagerFontSize.s13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        if (_currentUserPhone.isNotEmpty)
                          Text(
                            _currentUserPhone,
                            style: getRegularTextStyle(
                              fontSize: ManagerFontSize.s12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isAdmin)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ManagerWidth.w8,
                        vertical: ManagerHeight.h2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'مشرف',
                        style: getRegularTextStyle(
                          fontSize: ManagerFontSize.s11,
                          color: Colors.orange.shade700,
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

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: ManagerColors.primaryColor, size: 24),
        SizedBox(height: ManagerHeight.h8),
        Text(
          value,
          style: getBoldTextStyle(
            fontSize: ManagerFontSize.s18,
            color: ManagerColors.black,
          ),
        ),
        Text(
          label,
          style: getRegularTextStyle(
            fontSize: ManagerFontSize.s12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupDescription() {
    final description = groupData['description'] ?? '';

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(ManagerWidth.w16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: ManagerColors.primaryColor, size: 20),
              SizedBox(width: ManagerWidth.w8),
              Text(
                'وصف المجموعة',
                style: getBoldTextStyle(
                  fontSize: ManagerFontSize.s15,
                  color: ManagerColors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: ManagerHeight.h12),
          Text(
            description.isEmpty ? 'لا يوجد وصف للمجموعة' : description,
            style: getRegularTextStyle(
              fontSize: ManagerFontSize.s14,
              color: description.isEmpty ? Colors.grey.shade500 : ManagerColors.black,
            ),
          ),
          if (isAdmin) ...[
            SizedBox(height: ManagerHeight.h12),
            TextButton.icon(
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('تعديل الوصف'),
              onPressed: _editDescription,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMembersSection() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(ManagerWidth.w16),
            child: Row(
              children: [
                Icon(Icons.people, color: ManagerColors.primaryColor, size: 20),
                SizedBox(width: ManagerWidth.w8),
                Text(
                  'الأعضاء (${members.length})',
                  style: getBoldTextStyle(
                    fontSize: ManagerFontSize.s15,
                    color: ManagerColors.black,
                  ),
                ),
                const Spacer(),
                if (isAdmin)
                  IconButton(
                    icon: Icon(Icons.person_add, color: ManagerColors.primaryColor),
                    onPressed: _addMembers,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return _buildMemberTile(member);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(Map<String, dynamic> member) {
    final isMe = member['id'] == _currentUserId;
    final isMemberAdmin = member['isAdmin'] == true;

    return ListTile(
      leading: Stack(
        children: [
          CloudinaryAvatar(
            imageUrl: member['imageUrl'],
            fallbackText: member['name'],
            radius: 24,
          ),
          if (member['isOnline'] == true)
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
      title: Row(
        children: [
          Expanded(
            child: Text(
              member['name'],
              style: getBoldTextStyle(
                fontSize: ManagerFontSize.s14,
                color: ManagerColors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isMe)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: ManagerWidth.w8,
                vertical: ManagerHeight.h2,
              ),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'أنت',
                style: getRegularTextStyle(
                  fontSize: ManagerFontSize.s11,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          if (isMemberAdmin)
            Container(
              margin: EdgeInsets.only(right: ManagerWidth.w8),
              padding: EdgeInsets.symmetric(
                horizontal: ManagerWidth.w8,
                vertical: ManagerHeight.h2,
              ),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'مشرف',
                style: getRegularTextStyle(
                  fontSize: ManagerFontSize.s11,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        member['bio']?.isNotEmpty == true ? member['bio'] : (member['phone'] ?? ''),
        style: getRegularTextStyle(
          fontSize: ManagerFontSize.s13,
          color: Colors.grey.shade600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: (isAdmin && !isMe)
          ? PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
        onSelected: (value) => _handleMemberAction(value, member),
        itemBuilder: (context) => [
          if (!isMemberAdmin)
            const PopupMenuItem(
              value: 'make_admin',
              child: Row(
                children: [
                  Icon(Icons.admin_panel_settings, size: 20),
                  SizedBox(width: 12),
                  Text('جعله مشرف'),
                ],
              ),
            ),
          if (isMemberAdmin && !isCreator)
            const PopupMenuItem(
              value: 'remove_admin',
              child: Row(
                children: [
                  Icon(Icons.remove_moderator, size: 20),
                  SizedBox(width: 12),
                  Text('إزالة من المشرفين'),
                ],
              ),
            ),
          const PopupMenuItem(
            value: 'remove',
            child: Row(
              children: [
                Icon(Icons.person_remove, size: 20, color: Colors.red),
                SizedBox(width: 12),
                Text('إزالة من المجموعة',
                    style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      )
          : null,
    );
  }

  Future<void> _handleMemberAction(String action, Map<String, dynamic> member) async {
    final memberId = member['id'];
    final memberName = member['name'];

    try {
      switch (action) {
        case 'make_admin':
          await _firestore.collection('groups').doc(widget.groupId).update({
            'admins': FieldValue.arrayUnion([memberId]),
          });
          Get.snackbar('نجح', 'تم جعل $memberName مشرفاً');
          break;

        case 'remove_admin':
          await _firestore.collection('groups').doc(widget.groupId).update({
            'admins': FieldValue.arrayRemove([memberId]),
          });
          Get.snackbar('نجح', 'تم إزالة $memberName من المشرفين');
          break;

        case 'remove':
          final confirm = await Get.dialog<bool>(
            AlertDialog(
              title: const Text('إزالة عضو'),
              content: Text('هل تريد إزالة $memberName من المجموعة؟'),
              actions: [
                TextButton(
                  onPressed: () => Get.back(result: false),
                  child: const Text('إلغاء'),
                ),
                TextButton(
                  onPressed: () => Get.back(result: true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('إزالة'),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await _firestore.collection('groups').doc(widget.groupId).update({
              'participants': FieldValue.arrayRemove([memberId]),
              'admins': FieldValue.arrayRemove([memberId]),
            });
            Get.snackbar('نجح', 'تم إزالة $memberName من المجموعة');
          }
          break;
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشلت العملية: $e');
    }
  }

  Widget _buildMediaSection() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(ManagerWidth.w16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_library, color: ManagerColors.primaryColor, size: 20),
              SizedBox(width: ManagerWidth.w8),
              Text(
                'الوسائط والملفات',
                style: getBoldTextStyle(
                  fontSize: ManagerFontSize.s15,
                  color: ManagerColors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: ManagerHeight.h16),
          Row(
            children: [
              Expanded(
                child: _buildMediaCard(
                  icon: Icons.image,
                  label: 'الصور',
                  count: '0',
                  color: Colors.purple,
                ),
              ),
              SizedBox(width: ManagerWidth.w12),
              Expanded(
                child: _buildMediaCard(
                  icon: Icons.videocam,
                  label: 'الفيديوهات',
                  count: '0',
                  color: Colors.red,
                ),
              ),
            ],
          ),
          SizedBox(height: ManagerHeight.h12),
          Row(
            children: [
              Expanded(
                child: _buildMediaCard(
                  icon: Icons.insert_drive_file,
                  label: 'الملفات',
                  count: '0',
                  color: Colors.blue,
                ),
              ),
              SizedBox(width: ManagerWidth.w12),
              Expanded(
                child: _buildMediaCard(
                  icon: Icons.link,
                  label: 'الروابط',
                  count: '0',
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaCard({
    required IconData icon,
    required String label,
    required String count,
    required Color color,
  }) {
    return InkWell(
      onTap: () {
        Get.snackbar('قريباً', 'عرض $label قيد التطوير');
      },
      child: Container(
        padding: EdgeInsets.all(ManagerWidth.w12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            SizedBox(height: ManagerHeight.h8),
            Text(
              count,
              style: getBoldTextStyle(
                fontSize: ManagerFontSize.s16,
                color: color,
              ),
            ),
            Text(
              label,
              style: getRegularTextStyle(
                fontSize: ManagerFontSize.s12,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildSettingTile(
            icon: Icons.notifications,
            title: 'الإشعارات',
            subtitle: 'تخصيص إشعارات المجموعة',
            onTap: () {
              Get.snackbar('قريباً', 'إعدادات الإشعارات قيد التطوير');
            },
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.lock,
            title: 'الخصوصية',
            subtitle: 'من يمكنه إضافة أعضاء',
            trailing: Text(
              isAdmin ? 'المشرفون فقط' : 'الجميع',
              style: getRegularTextStyle(
                fontSize: ManagerFontSize.s13,
                color: Colors.grey.shade600,
              ),
            ),
            onTap: isAdmin ? _changePrivacySettings : null,
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.photo,
            title: 'صورة المجموعة',
            subtitle: 'تغيير صورة المجموعة',
            onTap: isAdmin
                ? () {
              Get.snackbar('قريباً', 'تغيير الصورة قيد التطوير');
            }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(ManagerWidth.w8),
        decoration: BoxDecoration(
          color: ManagerColors.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: ManagerColors.primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: getBoldTextStyle(
          fontSize: ManagerFontSize.s14,
          color: ManagerColors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: getRegularTextStyle(
          fontSize: ManagerFontSize.s13,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: trailing ?? (onTap != null ? const Icon(Icons.arrow_forward_ios, size: 16) : null),
      onTap: onTap,
      enabled: onTap != null,
    );
  }

  Widget _buildDangerZone() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          if (isCreator) ...[
            _buildDangerTile(
              icon: Icons.delete_forever,
              title: 'حذف المجموعة',
              subtitle: 'حذف المجموعة نهائياً',
              onTap: _deleteGroup,
            ),
            const Divider(height: 1),
          ],
          _buildDangerTile(
            icon: Icons.exit_to_app,
            title: 'مغادرة المجموعة',
            subtitle: 'الخروج من المجموعة',
            onTap: _leaveGroup,
          ),
        ],
      ),
    );
  }

  Widget _buildDangerTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(ManagerWidth.w8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.red, size: 20),
      ),
      title: Text(
        title,
        style: getBoldTextStyle(
          fontSize: ManagerFontSize.s14,
          color: Colors.red,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: getRegularTextStyle(
          fontSize: ManagerFontSize.s13,
          color: Colors.grey.shade600,
        ),
      ),
      onTap: onTap,
    );
  }

  Future<void> _editGroupInfo() async {
    Get.snackbar('قريباً', 'تعديل معلومات المجموعة قيد التطوير');
  }

  Future<void> _editDescription() async {
    final controller = TextEditingController(text: groupData['description'] ?? '');

    Get.dialog(
      AlertDialog(
        title: const Text('تعديل الوصف'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 200,
          decoration: const InputDecoration(
            hintText: 'اكتب وصف المجموعة...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _firestore.collection('groups').doc(widget.groupId).update({
                  'description': controller.text.trim(),
                });
                Get.back();
                Get.snackbar('نجح', 'تم تحديث الوصف');
              } catch (e) {
                Get.snackbar('خطأ', 'فشل تحديث الوصف');
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _addMembers() async {
    Get.snackbar('قريباً', 'إضافة أعضاء قيد التطوير');
  }

  Future<void> _changePrivacySettings() async {
    Get.snackbar('قريباً', 'إعدادات الخصوصية قيد التطوير');
  }

  Future<void> _deleteGroup() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('حذف المجموعة'),
        content: const Text(
          'هل أنت متأكد من حذف المجموعة؟ لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('groups').doc(widget.groupId).delete();
        Get.back();
        Get.back();
        Get.snackbar('نجح', 'تم حذف المجموعة');
      } catch (e) {
        Get.snackbar('خطأ', 'فشل حذف المجموعة: $e');
      }
    }
  }

  Future<void> _leaveGroup() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('مغادرة المجموعة'),
        content: Text(
          isCreator
              ? 'أنت منشئ المجموعة. يجب عليك نقل الملكية قبل المغادرة.'
              : 'هل أنت متأكد من مغادرة المجموعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('إلغاء'),
          ),
          if (!isCreator)
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('مغادرة'),
            ),
        ],
      ),
    );

    if (confirm == true && !isCreator) {
      try {
        await _firestore.collection('groups').doc(widget.groupId).update({
          'participants': FieldValue.arrayRemove([_currentUserId]),
          'admins': FieldValue.arrayRemove([_currentUserId]),
        });
        Get.back();
        Get.back();
        Get.snackbar('نجح', 'تم مغادرة المجموعة');
      } catch (e) {
        Get.snackbar('خطأ', 'فشلت المغادرة: $e');
      }
    }
  }
}