import 'package:app_mobile/core/widgets/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/resources/manager_colors.dart';
import '../../../../../core/resources/manager_font_size.dart';
import '../../../../../core/resources/manager_height.dart';
import '../../../../../core/resources/manager_styles.dart';
import '../../../../../core/resources/manager_width.dart';
import '../../../../../core/util/snack_bar.dart';
import '../../../add_chat/presentation/pages/add_chat_screen.dart';
import '../../../add_chat/presentation/pages/cloudinary_image_avatar.dart';
import '../../../add_chat/presentation/pages/select_members_screen.dart';
import '../../../group_chat/presentation/pages/group_chat_screen.dart';
import '../../../profile/domain/di/profile_di.dart';
import '../../../profile/pages/profile_screen.dart';
import '../../../single_chat/presentation/pages/single_chat_screen.dart'; // ✅ إضافة الاستيراد
import '../controller/chat_controller.dart';
import '../widgets/custom_tab_switcher_trader.dart';
import '../widgets/shimmer_widget.dart';
import '../../domain/di/chat_di.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
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
      if (!_tabController.indexIsChanging) controller.changeTab(_tabController.index);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await controller.checkUserLoggedIn();
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

  Widget _buildFAB() {
    return Obx(() {
      return FloatingActionButton(
        backgroundColor: ManagerColors.primaryColor,
        onPressed: controller.isUserLoggedIn.value ? _showAddMenu : _showLoginPrompt,
        child: Icon(
          controller.isUserLoggedIn.value ? Icons.add : Icons.login,
          color: Colors.white,
        ),
      );
    });
  }// ✅ دالة الانتقال إلى الملف الشخصي
  void _goToProfile() {
    if (controller.isUserLoggedIn.value) {
      // تأكد من تهيئة Profile DI أولاً
      ProfileDI.init();
      Get.to(() => ProfileScreen());
    } else {
      _showLoginPrompt();
    }
  }

// ✅ تحديث دالة معالجة الإجراءات
  void _handleMenuAction(String value, ChatController controller) {
    switch (value) {
      case 'profile':
        _goToProfile(); // الانتقال إلى الملف الشخصي
        break;
      case 'refresh':
        controller.smartRefresh();
        break;
      case 'logout':
        _performLogout();
        break;
      case 'login':
        _showLoginPrompt();
        break;
    }
  }

  Widget _buildHeader() {
    return Obx(() {
      final imageUrl = controller.currentUserImageUrl.value;
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
                Text("المحادثات",
                    style: getRegularTextStyle(
                      fontSize: ManagerFontSize.s20,
                      color: Colors.white,
                    )),
                const Spacer(),
                // صورة المستخدم - قابلة للنقل للانتقال إلى الملف الشخصي
                if (controller.isUserLoggedIn.value)
                  GestureDetector(
                    onTap: _goToProfile, // ✅ دالة جديدة للانتقال إلى الملف الشخصي
                    child: CloudinaryAvatar(
                        imageUrl: imageUrl,
                        fallbackText: 'User',
                        radius: 20
                    ),
                  )
                else
                  GestureDetector(
                    onTap: _showLoginPrompt,
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person_add, color: Colors.blue),
                    ),
                  ),

                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) => _handleMenuAction(value, controller),
                  itemBuilder: (context) => [
                    // ✅ إضافة خيار الملف الشخصي
                    if (controller.isUserLoggedIn.value)
                      const PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(Icons.person, color: Colors.blue),
                            SizedBox(width: 10),
                            Text('الملف الشخصي'),
                          ],
                        ),
                      ),

                    const PopupMenuItem(
                      value: 'refresh',
                      child: Row(
                        children: [
                          Icon(Icons.refresh),
                          SizedBox(width: 10),
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
                            SizedBox(width: 10),
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
                            SizedBox(width: 10),
                            Text('تسجيل الدخول', style: TextStyle(color: Colors.green)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),            SizedBox(height: ManagerHeight.h16),
            _buildSearchBar(),
          ],
        ),
      );
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
        decoration: InputDecoration(
          hintText: "ابحث في المحادثات...",
          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: ManagerHeight.h10,
            horizontal: ManagerWidth.w10,
          ),
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return Obx(() {
      if (controller.isInitialLoading.value) {
        return const ChatListShimmer(itemCount: 6);
      }

      if (controller.isLoading.value) {
        return const Center(child: LoadingWidget());
      }

      if (controller.hasIndexError.value) {
        return _buildErrorState();
      }

      if (controller.filteredChats.isEmpty) {
        return _buildNoChatsState();
      }

      return RefreshIndicator(
        onRefresh: controller.smartRefresh,
        child: ListView.builder(
          itemCount: controller.filteredChats.length,
          itemBuilder: (context, index) {
            final chat = controller.filteredChats[index];
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
        ),
      );
    });
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sync_problem, color: Colors.orange.shade400, size: 60),
          SizedBox(height: ManagerHeight.h10),
          Text("حدثت مشكلة أثناء تحميل المحادثات",
              style: getBoldTextStyle(
                  fontSize: ManagerFontSize.s14, color: Colors.orange.shade400)),
          SizedBox(height: ManagerHeight.h10),
          OutlinedButton(
            onPressed: controller.smartRefresh,
            child: const Text("إعادة المحاولة"),
          )
        ],
      ),
    );
  }

  Widget _buildNoChatsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade300),
          SizedBox(height: ManagerHeight.h16),
          Text(
            controller.isUserLoggedIn.value ? "لا توجد محادثات" : "مرحباً بك!",
            style: getBoldTextStyle(
              fontSize: ManagerFontSize.s16,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: ManagerHeight.h8),
          Text(
            controller.isUserLoggedIn.value
                ? "ابدأ محادثة جديدة بالضغط على (+)"
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
              icon: const Icon(Icons.add),
              label: const Text("بدء محادثة جديدة"),
              style: ElevatedButton.styleFrom(
                backgroundColor: ManagerColors.primaryColor,
                foregroundColor: Colors.white,
              ),
            )
        ],
      ),
    );
  }

  Widget _buildPrivateTile(ChatModel chat) {
    return ListTile(
      onTap: () {
        if (controller.isUserLoggedIn.value) {
          controller.markChatAsRead(chat.id, false);
          // ✅ فتح المحادثة الفردية مباشرة
          _openPrivateChat(chat);
        } else {
          _showLoginPrompt();
        }
      },
      leading: CloudinaryAvatar(
        imageUrl: chat.imageUrl,
        fallbackText: chat.name,
        radius: 24,
      ),
      title: Text(chat.name,
          style: getBoldTextStyle(fontSize: ManagerFontSize.s14, color: ManagerColors.black)),
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
        style: getRegularTextStyle(fontSize: ManagerFontSize.s10, color: Colors.grey),
      ),
    );
  }

  Widget _buildGroupTile(ChatModel chat) {
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
      leading: Stack(
        children: [
          CloudinaryAvatar(imageUrl: chat.imageUrl, fallbackText: chat.name, radius: 24),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(Icons.group, size: 14, color: ManagerColors.primaryColor),
            ),
          ),
        ],
      ),
      title: Text(chat.name,
          style: getBoldTextStyle(fontSize: ManagerFontSize.s14, color: ManagerColors.black)),
      subtitle: Text(
        chat.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: getRegularTextStyle(fontSize: ManagerFontSize.s12, color: Colors.grey),
      ),
      trailing: SizedBox(
        width: 80,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(chat.time,
                style: getRegularTextStyle(fontSize: ManagerFontSize.s10, color: Colors.grey)),
            SizedBox(height: ManagerHeight.h4),
            Text("${chat.membersCount} مشاركين",
                style: getRegularTextStyle(fontSize: ManagerFontSize.s10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // ✅ دالة جديدة لفتح المحادثة الفردية
  void _openPrivateChat(ChatModel chat) {
    try {
      final otherUserId = _extractOtherUserId(chat.id);

      if (otherUserId != null) {
        Get.to(() => SingleChatScreen(
          otherUserId: otherUserId,
          otherUserName: chat.name,
          otherUserImage: chat.imageUrl,
        ));
      } else {
        Get.snackbar(
          'خطأ',
          'تعذر فتح المحادثة',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل فتح المحادثة: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ✅ دالة استخراج معرف المستخدم الآخر
  String? _extractOtherUserId(String chatId) {
    try {
      if (chatId.startsWith('individual_')) {
        final parts = chatId.split('_');
        if (parts.length >= 3) {
          final user1 = parts[1];
          final user2 = parts[2];
          final currentUserId = controller.currentUserId;

          return user1 == currentUserId ? user2 : user1;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
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
          TextButton(onPressed: () => Get.back(result: false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    ) ??
        false;
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
            Text('إضافة جديد',
                style: getBoldTextStyle(fontSize: ManagerFontSize.s18, color: ManagerColors.black)),
            SizedBox(height: ManagerHeight.h20),
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
      title: Text(title,
          style: getBoldTextStyle(fontSize: ManagerFontSize.s15, color: ManagerColors.black)),
      subtitle: Text(subtitle,
          style: getRegularTextStyle(fontSize: ManagerFontSize.s13, color: Colors.grey.shade600)),
      onTap: onTap,
    );
  }

  void _showLoginPrompt() {
    Get.snackbar(
      'تسجيل الدخول',
      'سجل الدخول لبدء محادثات جديدة وإنشاء مجموعات',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  // void _handleMenuAction(String value) {
  //   switch (value) {
  //     case 'refresh':
  //       controller.smartRefresh();
  //       break;
  //     case 'logout':
  //       _performLogout();
  //       break;
  //     case 'login':
  //       _showLoginPrompt();
  //       break;
  //   }
  // }

  void _performLogout() async {
    try {
      await controller.resetUser();
      AppSnackbar.success('تم تسجيل الخروج بنجاح');
      setState(() {});
    } catch (e) {
      AppSnackbar.error('فشل تسجيل الخروج: $e');
    }
  }
}
