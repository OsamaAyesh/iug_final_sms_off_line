// المسار: lib/features/home/chat/presentation/pages/home_screen.dart

import 'package:app_mobile/core/widgets/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../../core/resources/manager_colors.dart';
import '../../../../../core/resources/manager_font_size.dart';
import '../../../../../core/resources/manager_height.dart';
import '../../../../../core/resources/manager_styles.dart';
import '../../../../../core/resources/manager_width.dart';
import '../../../../../core/util/empty_state_widget.dart';
import '../../../add_chat/presentation/pages/add_chat_screen.dart';
import '../../../add_chat/presentation/pages/select_members_screen.dart';
import '../../../group_chat/presentation/pages/group_chat_screen.dart';
import '../controller/chat_controller.dart';
import '../widgets/custom_tab_switcher_trader.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ChatController controller = Get.put(ChatController());
  final List<String> _tabs = ["الكل", "الدردشات", "المجموعات"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      controller.changeTab(_tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ManagerColors.white,
      floatingActionButton: _buildFAB(),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            SizedBox(height: ManagerHeight.h12),
            CustomTabSwitcherTrader(controller: _tabController, tabs: _tabs),
            SizedBox(height: ManagerHeight.h8),
            Expanded(child: _buildChatList()),
          ],
        ),
      ),
    );
  }

  // ================================
  // 🔸 FAB with Menu
  // ================================

  Widget _buildFAB() {
    return FloatingActionButton(
      backgroundColor: ManagerColors.primaryColor,
      onPressed: _showAddMenu,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  void _showAddMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(ManagerWidth.w20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: ManagerHeight.h20),

            // Title
            Text(
              'إضافة جديد',
              style: getBoldTextStyle(
                fontSize: ManagerFontSize.s18,
                color: ManagerColors.black,
              ),
            ),
            SizedBox(height: ManagerHeight.h20),

            // Add Contact
            _buildMenuItem(
              icon: Icons.person_add,
              iconColor: Colors.blue,
              title: 'إضافة جهة اتصال',
              subtitle: 'أضف شخصاً جديداً إلى جهات الاتصال',
              onTap: () {
                Get.back();
                Get.to(() => const AddChatScreen());
              },
            ),

            const Divider(height: 1),

            // Create Group
            _buildMenuItem(
              icon: Icons.group_add,
              iconColor: Colors.green,
              title: 'إنشاء مجموعة',
              subtitle: 'أنشئ مجموعة جديدة مع أصدقائك',
              onTap: () {
                Get.back();
                Get.to(() => const SelectMembersScreen());
              },
            ),

            SizedBox(height: ManagerHeight.h10),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(ManagerWidth.w10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: getBoldTextStyle(
          fontSize: ManagerFontSize.s15,
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
      onTap: onTap,
    );
  }

  // ================================
  // 🔸 Header
  // ================================

  Widget _buildHeader() {
    return Container(
      color: ManagerColors.primaryColor,
      padding: EdgeInsets.symmetric(
        horizontal: ManagerWidth.w16,
        vertical: ManagerHeight.h16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "المحادثات",
                style: getRegularTextStyle(
                  fontSize: ManagerFontSize.s20,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              _buildProfileAvatar(),
              SizedBox(width: ManagerWidth.w8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: _handleMenuAction,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings),
                        SizedBox(width: 12),
                        Text('الإعدادات'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person),
                        SizedBox(width: 12),
                        Text('الملف الشخصي'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 12),
                        Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: ManagerHeight.h16),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Obx(() {
      final imageUrl = controller.currentUserImageUrl.value;

      if (imageUrl == null || imageUrl.isEmpty) {
        return const CircleAvatar(
          radius: 20,
          backgroundColor: Colors.white,
          child: Icon(Icons.person, color: Colors.grey),
        );
      }

      // return CloudinaryAvatar(
      //   imageUrl: imageUrl,
      //   fallbackText: 'User',
      //   radius: 20,
      // );
    });
  }

  Widget _buildSearchBar() {
    return Container(
      height: ManagerHeight.h40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller.searchController,
        onChanged: controller.onSearchChanged,
        textAlignVertical: TextAlignVertical.center,
        style: getRegularTextStyle(
          fontSize: ManagerFontSize.s12,
          color: ManagerColors.black,
        ),
        decoration: InputDecoration(
          hintText: "ابحث في المحادثات...",
          hintStyle: getRegularTextStyle(
            fontSize: ManagerFontSize.s12,
            color: ManagerColors.greyWithColor,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Colors.grey,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: ManagerHeight.h10,
            horizontal: ManagerWidth.w10,
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(String value) {
    switch (value) {
      case 'settings':
      // Navigate to settings
        break;
      case 'profile':
      // Navigate to profile
        break;
      case 'logout':
        _showLogoutDialog();
        break;
    }
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              // Handle logout
              Get.back();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }

  // ================================
  // 🔸 Chat List
  // ================================

  Widget _buildChatList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: LoadingWidget());
      }

      final chats = controller.filteredChats;
      if (chats.isEmpty) {
        return Center(
          child: EmptyStateWidget(
            messageAr: _getEmptyMessage(),
          ),
        );
      }

      return ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          return Dismissible(
            key: Key(chat.id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.only(left: ManagerWidth.w20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (direction) => _confirmDelete(chat),
            onDismissed: (direction) {
              controller.deleteChat(chat.id, chat.isGroup);
            },
            child: chat.isGroup
                ? _buildGroupTile(chat)
                : _buildPrivateTile(chat),
          );
        },
      );
    });
  }

  String _getEmptyMessage() {
    switch (controller.selectedTabIndex.value) {
      case 1:
        return 'لا توجد محادثات خاصة';
      case 2:
        return 'لا توجد مجموعات';
      default:
        return 'لا توجد محادثات';
    }
  }

  Future<bool> _confirmDelete(chat) async {
    return await Get.dialog<bool>(
      AlertDialog(
        title: const Text('حذف المحادثة'),
        content: Text(
          chat.isGroup
              ? 'هل تريد مغادرة المجموعة "${chat.name}"؟'
              : 'هل تريد حذف المحادثة مع "${chat.name}"؟',
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
    ) ?? false;
  }

  // ================================
  // 🔸 Chat Tiles
  // ================================

  Widget _buildPrivateTile(chat) {
    return ListTile(
      onTap: () {
        controller.markChatAsRead(chat.id, false);
        Get.to(() => PrivateChatScreen(
          chatId: chat.id,
          otherUserId: chat.otherUserId ?? '',
          otherUserName: chat.name,
          otherUserImage: chat.imageUrl,
        ));
      },
      contentPadding: EdgeInsets.symmetric(
        horizontal: ManagerWidth.w16,
        vertical: ManagerHeight.h8,
      ),
      leading: CloudinaryAvatar(
        imageUrl: chat.imageUrl,
        fallbackText: chat.name,
        radius: 24,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              chat.name,
              style: getBoldTextStyle(
                fontSize: ManagerFontSize.s14,
                color: ManagerColors.black,
              ),
            ),
          ),
          if (chat.unreadCount > 0)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: ManagerWidth.w8,
                vertical: ManagerHeight.h4,
              ),
              decoration: BoxDecoration(
                color: ManagerColors.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${chat.unreadCount}',
                style: getBoldTextStyle(
                  fontSize: ManagerFontSize.s10,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        chat.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: getRegularTextStyle(
          fontSize: ManagerFontSize.s12,
          color: Colors.grey,
        ),
      ),
      trailing: Text(
        chat.time,
        style: getRegularTextStyle(
          fontSize: ManagerFontSize.s10,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildGroupTile(chat) {
    return ListTile(
      onTap: () {
        controller.markChatAsRead(chat.id, true);
        Get.to(() => ChatGroupScreen(
          groupId: chat.id,
          groupName: chat.name,
          groupImage: chat.imageUrl,
          participantsCount: chat.membersCount.toString(),
        ));
      },
      contentPadding: EdgeInsets.symmetric(
        horizontal: ManagerWidth.w16,
        vertical: ManagerHeight.h8,
      ),
      leading: Stack(
        children: [
          CloudinaryAvatar(
            imageUrl: chat.imageUrl,
            fallbackText: chat.name,
            radius: 24,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.group,
                size: 14,
                color: ManagerColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              chat.name,
              style: getBoldTextStyle(
                fontSize: ManagerFontSize.s14,
                color: ManagerColors.black,
              ),
            ),
          ),
          if (chat.unreadCount > 0)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: ManagerWidth.w8,
                vertical: ManagerHeight.h4,
              ),
              decoration: BoxDecoration(
                color: ManagerColors.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${chat.unreadCount}',
                style: getBoldTextStyle(
                  fontSize: ManagerFontSize.s10,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        chat.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: getRegularTextStyle(
          fontSize: ManagerFontSize.s12,
          color: Colors.grey,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            chat.time,
            style: getRegularTextStyle(
              fontSize: ManagerFontSize.s10,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: ManagerHeight.h4),
          Text(
            "${chat.membersCount} مشاركين",
            style: getRegularTextStyle(
              fontSize: ManagerFontSize.s10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}