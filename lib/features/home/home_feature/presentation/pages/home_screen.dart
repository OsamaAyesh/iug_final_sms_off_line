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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ManagerColors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: ManagerColors.primaryColor,
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white),
      ),
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
              CachedNetworkImage(
                imageUrl:
                // controller.currentUserImageUrl ??
                    "https://example.com/profile.jpg", // رابط البروفايل من Firestore لاحقًا
                imageBuilder: (context, imageProvider) => CircleAvatar(
                  radius: 20,
                  backgroundImage: imageProvider,
                ),
                placeholder: (context, url) => const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.grey,
                  ),
                ),
                errorWidget: (context, url, error) => const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Colors.black),
                ),
              ),
              SizedBox(width: ManagerWidth.w8),
              const Icon(Icons.more_vert, color: Colors.white),
            ],
          ),
          SizedBox(height: ManagerHeight.h16),
          Container(
            height: ManagerHeight.h40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: controller.searchController,
              onChanged: controller.onSearchChanged,
              textAlignVertical: TextAlignVertical.center, // ✅ يجعل النص في المنتصف
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
                  vertical: ManagerHeight.h10, // ✅ ضبط التوسيط العمودي
                  horizontal: ManagerWidth.w10,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: LoadingWidget());
      }

      final chats = controller.filteredChats;
      if (chats.isEmpty) {
        return const Center(
          child: EmptyStateWidget(
            messageAr: "لا يوجد محادثات",
          ),
        );
      }

      return ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          return chat.isGroup
              ? _buildGroupTile(chat)
              : _buildPrivateTile(chat);
        },
      );
    });
  }

  // ✅ تصميم الدردشة الفردية
  Widget _buildPrivateTile(chat) => ListTile(
    contentPadding: EdgeInsets.symmetric(
      horizontal: ManagerWidth.w16,
      vertical: ManagerHeight.h8,
    ),
    leading: CircleAvatar(
      radius: 24,
      backgroundImage:
      chat.imageUrl.isNotEmpty ? NetworkImage(chat.imageUrl) : null,
      child: chat.imageUrl.isEmpty
          ? const Icon(Icons.person, color: Colors.white)
          : null,
    ),
    title: Text(
      chat.name,
      style: getBoldTextStyle(
        fontSize: ManagerFontSize.s14,
        color: ManagerColors.black,
      ),
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

  // ✅ تصميم المجموعة
  Widget _buildGroupTile(chat) => ListTile(
    onTap: () {
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
        CircleAvatar(
          radius: 24,
          backgroundImage:
          chat.imageUrl.isNotEmpty ? NetworkImage(chat.imageUrl) : null,
          child: chat.imageUrl.isEmpty
              ? const Icon(Icons.group, color: Colors.white)
              : null,
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
            child: Icon(Icons.group,
                size: 14, color: ManagerColors.primaryColor),
          ),
        ),
      ],
    ),
    title: Text(
      chat.name,
      style: getBoldTextStyle(
        fontSize: ManagerFontSize.s14,
        color: ManagerColors.black,
      ),
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
