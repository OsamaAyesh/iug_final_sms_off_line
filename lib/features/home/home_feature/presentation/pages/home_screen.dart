// المسار: lib/features/home/home_feature/presentation/pages/home_screen.dart

import 'package:app_mobile/core/widgets/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/resources/manager_colors.dart';
import '../../../../../core/resources/manager_font_size.dart';
import '../../../../../core/resources/manager_height.dart';
import '../../../../../core/resources/manager_styles.dart';
import '../../../../../core/resources/manager_width.dart';
import '../../../../../core/util/empty_state_widget.dart';
import '../../../../../core/util/snack_bar.dart';
import '../../../add_chat/presentation/pages/add_chat_screen.dart';
import '../../../add_chat/presentation/pages/cloudinary_image_avatar.dart';
import '../../../add_chat/presentation/pages/select_members_screen.dart';
import '../../../group_chat/presentation/pages/group_chat_screen.dart';
import '../controller/chat_controller.dart';
import '../widgets/custom_tab_switcher_trader.dart';
import '../../domain/di/chat_di.dart';
import '../widgets/shimmer_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ChatController controller;
  final List<String> _tabs = ["الكل", "الدردشات", "المجموعات"];

  @override
  void initState() {
    super.initState();

    ChatDI.init();
    controller = ChatDI.controller;

    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      controller.changeTab(_tabController.index);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkUserStatus();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkUserStatus() async {
    final isLoggedIn = await controller.checkUserLoggedIn();
    print('👤 User login status: $isLoggedIn');
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

  // ✅ إصلاح: استخدام GetBuilder بدلاً من Obx للـ FAB
  Widget _buildFAB() {
    return GetBuilder<ChatController>(
      builder: (controller) {
        if (!controller.isUserLoggedIn.value) {
          return FloatingActionButton(
            backgroundColor: ManagerColors.primaryColor,
            onPressed: _showLoginPrompt,
            child: const Icon(Icons.login, color: Colors.white),
          );
        }

        return FloatingActionButton(
          backgroundColor: ManagerColors.primaryColor,
          onPressed: _showAddMenu,
          child: const Icon(Icons.add, color: Colors.white),
        );
      },
    );
  }

  void _showLoginPrompt() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.person_add, color: Colors.blue),
            SizedBox(width: ManagerWidth.w8),
            Text('تسجيل الدخول'),
          ],
        ),
        content: Text('سجل الدخول لبدء محادثات جديدة وإنشاء مجموعات'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('لاحقاً'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _showInfoSnackbar('سيتم توجيهك إلى شاشة تسجيل الدخول');
            },
            child: Text('تسجيل الدخول'),
          ),
        ],
      ),
    );
  }

  void _showInfoSnackbar(String message) {
    Get.snackbar(
      'معلومة',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: Duration(seconds: 3),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: ManagerHeight.h20),
            Text(
              'إضافة جديد',
              style: getBoldTextStyle(
                fontSize: ManagerFontSize.s18,
                color: ManagerColors.black,
              ),
            ),
            SizedBox(height: ManagerHeight.h20),
            _buildMenuItem(
              icon: Icons.person_add,
              iconColor: Colors.blue,
              title: 'إضافة جهة اتصال',
              subtitle: 'أضف شخصاً جديداً إلى جهات الاتصال',
              onTap: () {
                Get.back();
                if (controller.isUserLoggedIn.value) {
                  Get.to(() => const AddChatScreen());
                } else {
                  _showLoginPrompt();
                }
              },
            ),
            const Divider(height: 1),
            _buildMenuItem(
              icon: Icons.group_add,
              iconColor: Colors.green,
              title: 'إنشاء مجموعة',
              subtitle: 'أنشئ مجموعة جديدة مع أصدقائك',
              onTap: () {
                Get.back();
                if (controller.isUserLoggedIn.value) {
                  Get.to(() => const SelectMembersScreen());
                } else {
                  _showLoginPrompt();
                }
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

  // ✅ إصلاح: استخدام GetBuilder للـ Header
  Widget _buildHeader() {
    return GetBuilder<ChatController>(
      builder: (controller) {
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
                  _buildProfileAvatar(controller),
                  SizedBox(width: ManagerWidth.w8),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) => _handleMenuAction(value, controller),
                    itemBuilder: (context) => [
                      if (controller.isUserLoggedIn.value) ...[
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
                      ],
                      const PopupMenuItem(
                        value: 'refresh',
                        child: Row(
                          children: [
                            Icon(Icons.refresh),
                            SizedBox(width: 12),
                            Text('تحديث'),
                          ],
                        ),
                      ),
                      if (controller.isUserLoggedIn.value)
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
                      if (!controller.isUserLoggedIn.value)
                        const PopupMenuItem(
                          value: 'login',
                          child: Row(
                            children: [
                              Icon(Icons.login, color: Colors.green),
                              SizedBox(width: 12),
                              Text('تسجيل الدخول', style: TextStyle(color: Colors.green)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: ManagerHeight.h16),
              _buildSearchBar(controller),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileAvatar(ChatController controller) {
    final imageUrl = controller.currentUserImageUrl.value;

    if (!controller.isUserLoggedIn.value) {
      return GestureDetector(
        onTap: _showLoginPrompt,
        child: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.white,
          child: Icon(Icons.person_add, color: ManagerColors.primaryColor),
        ),
      );
    }

    if (imageUrl == null || imageUrl.isEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.white,
        child: Icon(Icons.person, color: Colors.grey),
      );
    }

    return CloudinaryAvatar(
      imageUrl: imageUrl,
      fallbackText: 'User',
      radius: 20,
    );
  }

  Widget _buildSearchBar(ChatController controller) {
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
        enabled: true,
      ),
    );
  }

  void _handleMenuAction(String value, ChatController controller) {
    switch (value) {
      case 'settings':
        break;
      case 'profile':
        break;
      case 'refresh':
        controller.smartRefresh();
        break;
      case 'logout':
        _showLogoutDialog(controller);
        break;
      case 'login':
        _showLoginPrompt();
        break;
    }
  }

  void _showLogoutDialog(ChatController controller) {
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
              Get.back();
              _performLogout(controller);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }

  void _performLogout(ChatController controller) async {
    try {
      await controller.resetUser();
      AppSnackbar.success('تم تسجيل الخروج بنجاح');
      setState(() {});
    } catch (e) {
      AppSnackbar.error('فشل تسجيل الخروج: $e');
    }
  }

  // ✅ إصلاح: استخدام GetBuilder للـ ChatList
  Widget _buildChatList() {
    return GetBuilder<ChatController>(
      builder: (controller) {
        // // ✅ إضافة حالة التحميل الأولي
        // if (controller.isInitialLoading.value) {
        //   return const ChatListShimmer(itemCount: 6);
        // }

        if (controller.isLoading.value) {
          return const Center(child: LoadingWidget());
        }

        if (controller.hasIndexError.value) {
          return _buildIndexErrorState(controller);
        }

        if (controller.filteredChats.isEmpty) {
          return _buildNoChatsState(controller);
        }

        return _buildChatsListView(controller);
      },
    );
  }

  Widget _buildIndexErrorState(ChatController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sync_problem_outlined,
            size: 80,
            color: Colors.orange.shade300,
          ),
          SizedBox(height: ManagerHeight.h16),
          Text(
            "جاري تحميل المحادثات",
            style: getBoldTextStyle(
              fontSize: ManagerFontSize.s16,
              color: Colors.orange.shade600,
            ),
          ),
          SizedBox(height: ManagerHeight.h8),
          Text(
            "هذا قد يستغرق بضع ثوانٍ",
            style: getRegularTextStyle(
              fontSize: ManagerFontSize.s14,
              color: Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ManagerHeight.h20),
          CircularProgressIndicator(),
          SizedBox(height: ManagerHeight.h20),
          OutlinedButton(
            onPressed: () => controller.smartRefresh(),
            child: Text("إعادة المحاولة"),
          ),
        ],
      ),
    );
  }

  Widget _buildNoChatsState(ChatController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: ManagerHeight.h16),
          Text(
            controller.isUserLoggedIn.value
                ? "لا توجد محادثات"
                : "مرحباً بك!",
            style: getBoldTextStyle(
              fontSize: ManagerFontSize.s16,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: ManagerHeight.h8),
          Text(
            controller.isUserLoggedIn.value
                ? "ابدأ محادثة جديدة بالضغط على زر (+)"
                : "سجل الدخول لبدء محادثات جديدة وإنشاء مجموعات",
            style: getRegularTextStyle(
              fontSize: ManagerFontSize.s14,
              color: Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ManagerHeight.h20),
          if (controller.isUserLoggedIn.value)
            ElevatedButton.icon(
              onPressed: _showAddMenu,
              icon: Icon(Icons.add),
              label: Text("بدء محادثة جديدة"),
              style: ElevatedButton.styleFrom(
                backgroundColor: ManagerColors.primaryColor,
                foregroundColor: Colors.white,
              ),
            )
          // else
          //   ElevatedButton.icon(
          //     onPressed: _showLoginPrompt,
          //     icon: Icon(Icons.login),
          //     label: Text("تسجيل الدخول"),
          //     style: ElevatedButton.styleFrom(
          //       backgroundColor: ManagerColors.primaryColor,
          //       foregroundColor: Colors.white,
          //     ),
          //   ),
        ],
      ),
    );
  }

  Widget _buildChatsListView(ChatController controller) {
    return RefreshIndicator(
      onRefresh: () async {
        await controller.smartRefresh();
      },
      child: ListView.builder(
        itemCount: controller.filteredChats.length,
        itemBuilder: (context, index) {
          final chat = controller.filteredChats[index];

          if (!chat.isUserParticipant && controller.isUserLoggedIn.value) {
            return SizedBox.shrink();
          }

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
                ? _buildGroupTile(chat, controller)
                : _buildPrivateTile(chat, controller),
          );
        },
      ),
    );
  }

  Future<bool> _confirmDelete(ChatModel chat) async {
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

  Widget _buildPrivateTile(ChatModel chat, ChatController controller) {
    return ListTile(
      onTap: () {
        if (controller.isUserLoggedIn.value) {
          controller.markChatAsRead(chat.id, false);
          Get.snackbar('قريباً', 'المحادثات الخاصة قيد التطوير');
        } else {
          _showLoginPrompt();
        }
      },
      contentPadding: EdgeInsets.symmetric(
        horizontal: ManagerWidth.w16,
        vertical: ManagerHeight.h8,
      ),
      leading: SizedBox(
        width: 48,
        height: 48,
        child: CloudinaryAvatar(
          imageUrl: chat.imageUrl,
          fallbackText: chat.name,
          radius: 24,
        ),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (chat.unreadCount > 0 && controller.isUserLoggedIn.value) ...[
            SizedBox(width: ManagerWidth.w8),
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

  Widget _buildGroupTile(ChatModel chat, ChatController controller) {
    return ListTile(
      onTap: () {
        if (controller.isUserLoggedIn.value) {
          controller.markChatAsRead(chat.id, true);
          Get.to(() => ChatGroupScreen(
            groupId: chat.id,
            groupName: chat.name,
            groupImage: chat.imageUrl,
            participantsCount: chat.membersCount.toString(),
          ));
        } else {
          _showLoginPrompt();
        }
      },
      contentPadding: EdgeInsets.symmetric(
        horizontal: ManagerWidth.w16,
        vertical: ManagerHeight.h8,
      ),
      leading: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (chat.unreadCount > 0 && controller.isUserLoggedIn.value) ...[
            SizedBox(width: ManagerWidth.w8),
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
      trailing: SizedBox(
        width: 80,
        child: Column(
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
      ),
    );
  }
}