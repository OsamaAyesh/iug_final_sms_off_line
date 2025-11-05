// المسار: lib/features/home/group_chat/presentation/pages/message_status_screen.dart

import 'package:app_mobile/features/home/group_chat/presentation/pages/sms_status_logs_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';
import 'package:app_mobile/core/resources/manager_width.dart';
import '../../domain/models/message_model.dart';
import '../controller/chat_group_controller.dart';
import '../widgets/send_sms_dialog.dart';

class MessageStatusScreen extends StatefulWidget {
  final String groupId;
  final MessageModel message;
  final String groupName;

  const MessageStatusScreen({
    super.key,
    required this.groupId,
    required this.message,
    required this.groupName,
  });

  @override
  State<MessageStatusScreen> createState() => _MessageStatusScreenState();
}

class _MessageStatusScreenState extends State<MessageStatusScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final controller = Get.find<ChatGroupController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadMessageStatuses(widget.groupId, widget.message);
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
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildMessagePreview(),
          _buildStatsOverview(),
          _buildTabBar(),
          Expanded(child: _buildTabBarView()),
        ],
      ),
      floatingActionButton: _buildSmsButton(),
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
            'حالة الرسالة',
            style: getBoldTextStyle(
              fontSize: ManagerFontSize.s16,
              color: Colors.white,
            ),
          ),
          Text(
            widget.groupName,
            style: getRegularTextStyle(
              fontSize: ManagerFontSize.s12,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagePreview() {
    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.message,
                color: ManagerColors.primaryColor,
                size: 20,
              ),
              SizedBox(width: ManagerWidth.w8),
              Text(
                'محتوى الرسالة',
                style: getBoldTextStyle(
                  fontSize: ManagerFontSize.s13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          SizedBox(height: ManagerHeight.h8),
          Container(
            padding: EdgeInsets.all(ManagerWidth.w12),
            decoration: BoxDecoration(
              color: ManagerColors.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ManagerColors.primaryColor.withOpacity(0.2),
              ),
            ),
            child: Text(
              widget.message.content,
              style: getRegularTextStyle(
                fontSize: ManagerFontSize.s14,
                color: ManagerColors.black,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: ManagerHeight.h8),
          Text(
            _formatTime(widget.message.timestamp),
            style: getRegularTextStyle(
              fontSize: ManagerFontSize.s11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Obx(() {
      final total = controller.getTotalRecipients();
      final seen = controller.getSeenCount();
      final delivered = controller.getDeliveredCount();
      final pending = controller.getPendingCount();
      final failed = controller.getFailedCount();

      return Container(
        width: double.infinity,
        margin: EdgeInsets.all(ManagerWidth.w16),
        padding: EdgeInsets.all(ManagerWidth.w16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ManagerColors.primaryColor,
              ManagerColors.primaryColor.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: ManagerColors.primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people, color: Colors.white, size: 20),
                SizedBox(width: ManagerWidth.w8),
                Text(
                  'إجمالي المستلمين',
                  style: getBoldTextStyle(
                    fontSize: ManagerFontSize.s14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: ManagerHeight.h8),
            Text(
              '$total',
              style: getBoldTextStyle(
                fontSize: ManagerFontSize.s32,
                color: Colors.white,
              ),
            ),
            SizedBox(height: ManagerHeight.h16),
            Divider(color: Colors.white.withOpacity(0.3), thickness: 1),
            SizedBox(height: ManagerHeight.h12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('تمت القراءة', seen, Icons.done_all, Colors.blue.shade100),
                _buildStatItem('تم التوصيل', delivered, Icons.done_all, Colors.green.shade100),
                _buildStatItem('قيد الإرسال', pending, Icons.schedule, Colors.orange.shade100),
                _buildStatItem('فشل', failed, Icons.error_outline, Colors.red.shade100),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem(String label, int count, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(ManagerWidth.w8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        SizedBox(height: ManagerHeight.h6),
        Text(
          '$count',
          style: getBoldTextStyle(
            fontSize: ManagerFontSize.s16,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: getRegularTextStyle(
            fontSize: ManagerFontSize.s10,
            color: Colors.white.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Obx(() {
      return Container(
        color: Colors.white,
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: ManagerColors.primaryColor,
          labelColor: ManagerColors.primaryColor,
          unselectedLabelColor: Colors.grey.shade600,
          labelStyle: getBoldTextStyle(fontSize: ManagerFontSize.s13,color: ManagerColors.black),
          unselectedLabelStyle: getRegularTextStyle(fontSize: ManagerFontSize.s13, color: ManagerColors.black),
          onTap: (index) {
            switch (index) {
              case 0:
                controller.filterBy("all");
                break;
              case 1:
                controller.filterBy("seen");
                break;
              case 2:
                controller.filterBy("delivered");
                break;
              case 3:
                controller.filterBy("pending");
                break;
              case 4:
                controller.filterBy("failed");
                break;
            }
          },
          tabs: [
            Tab(text: "الكل (${controller.getTotalRecipients()})"),
            Tab(text: "مقروءة (${controller.getSeenCount()})"),
            Tab(text: "موصلة (${controller.getDeliveredCount()})"),
            Tab(text: "قيد الإرسال (${controller.getPendingCount()})"),
            Tab(text: "فاشلة (${controller.getFailedCount()})"),
          ],
        ),
      );
    });
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildUsersList(), // الكل
        _buildUsersList(), // مقروءة
        _buildUsersList(), // موصلة
        _buildUsersList(), // قيد الإرسال
        _buildUsersList(), // فاشلة
      ],
    );
  }

  Widget _buildUsersList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final users = controller.filteredStatuses;

      if (users.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.separated(
        padding: EdgeInsets.all(ManagerWidth.w16),
        itemCount: users.length,
        separatorBuilder: (_, __) => SizedBox(height: ManagerHeight.h12),
        itemBuilder: (context, index) {
          final user = users[index];
          return _buildUserCard(user);
        },
      );
    });
  }

  Widget _buildUserCard(user) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (user.status) {
      case 'seen':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        statusText = 'تمت القراءة';
        break;
      case 'delivered':
        statusColor = Colors.green;
        statusIcon = Icons.done_all;
        statusText = 'تم التوصيل';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = 'قيد الإرسال';
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.error_outline;
        statusText = 'فشل الإرسال';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusText = 'غير معروف';
    }

    return Container(
      padding: EdgeInsets.all(ManagerWidth.w12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: statusColor.withOpacity(0.1),
            backgroundImage: user.imageUrl.isNotEmpty
                ? CachedNetworkImageProvider(user.imageUrl)
                : null,
            child: user.imageUrl.isEmpty
                ? Text(
              user.name[0].toUpperCase(),
              style: getBoldTextStyle(
                fontSize: ManagerFontSize.s16,
                color: statusColor,
              ),
            )
                : null,
          ),
          SizedBox(width: ManagerWidth.w12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: getBoldTextStyle(
                    fontSize: ManagerFontSize.s14,
                    color: ManagerColors.black,
                  ),
                ),
                SizedBox(height: ManagerHeight.h4),
                if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
                  Text(
                    user.phoneNumber!,
                    style: getRegularTextStyle(
                      fontSize: ManagerFontSize.s12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          // Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ManagerWidth.w10,
                  vertical: ManagerHeight.h6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    SizedBox(width: ManagerWidth.w4),
                    Text(
                      statusText,
                      style: getBoldTextStyle(
                        fontSize: ManagerFontSize.s11,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: ManagerHeight.h16),
          Text(
            'لا يوجد مستخدمين في هذه الفئة',
            style: getBoldTextStyle(
              fontSize: ManagerFontSize.s14,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: ManagerHeight.h8),
          Text(
            'جرب فئة أخرى',
            style: getRegularTextStyle(
              fontSize: ManagerFontSize.s12,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildSmsButton() {
  //   return Obx(() {
  //     final hasUnread = controller.getUnreadCount() > 0;
  //     final hasFailed = controller.getFailedCount() > 0;
  //
  //     if (!hasUnread && !hasFailed) return const SizedBox.shrink();
  //
  //     return FloatingActionButton.extended(
  //       onPressed: () {
  //         showDialog(
  //           context: context,
  //           builder: (_) => const SendSmsDialog(),
  //         );
  //
  //       },
  //       backgroundColor: ManagerColors.primaryColor,
  //       icon: const Icon(Icons.sms, color: Colors.white),
  //       label: Text(
  //         'إرسال SMS',
  //         style: getBoldTextStyle(
  //           fontSize: ManagerFontSize.s14,
  //           color: Colors.white,
  //         ),
  //       ),
  //     );
  //   });
  // }
  Widget _buildSmsButton() {
    return Obx(() {
      final hasUnread = controller.getUnreadCount() > 0;
      final hasFailed = controller.getFailedCount() > 0;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🔹 زر سجل الرسائل (Logs)
          FloatingActionButton.extended(
            heroTag: "logs_button",
            onPressed: () {
              Get.to(() => SmsLogsScreen(groupId: widget.groupId));
            },
            backgroundColor: Colors.grey.shade800,
            icon: const Icon(Icons.list_alt, color: Colors.white),
            label: Text(
              'سجل الرسائل',
              style: getBoldTextStyle(
                fontSize: ManagerFontSize.s13,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: ManagerWidth.w12),

          // 🔹 زر إرسال SMS (يظهر فقط إذا في مستخدمين لم تصلهم أو فشلت)
          if (hasUnread || hasFailed)
            FloatingActionButton.extended(
              heroTag: "sms_button",
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const SendSmsDialog(),
                );
              },
              backgroundColor: ManagerColors.primaryColor,
              icon: const Icon(Icons.sms_rounded, color: Colors.white),
              label: Text(
                'إرسال SMS',
                style: getBoldTextStyle(
                  fontSize: ManagerFontSize.s13,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      );
    });
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }
}