import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';
import 'package:app_mobile/core/resources/manager_width.dart';
import '../../../../../core/service/cloudinart_service.dart';
import '../../../info_goup/presentaion/pages/info_gruop_screen.dart';
import '../../domain/di/chat_group_di.dart';
import '../controller/chat_group_controller.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input_field.dart';
import '../widgets/reply_preview.dart';
import 'message_status_screen.dart';

class ChatGroupScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String groupImage;
  final String participantsCount;
  final String? currentUserId;

  const ChatGroupScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.groupImage,
    required this.participantsCount,
    this.currentUserId,
  });

  @override
  State<ChatGroupScreen> createState() => _ChatGroupScreenState();
}

class _ChatGroupScreenState extends State<ChatGroupScreen> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  bool _isUploading = false; // ✅ لتتبع حالة الرفع

  @override
  void initState() {
    super.initState();
    ChatGroupDI.init();
    WidgetsBinding.instance.addObserver(this);

    final controller = ChatGroupController.to;

    if (widget.currentUserId != null && widget.currentUserId!.isNotEmpty) {
      controller.setCurrentUser(widget.currentUserId!);
    }

    controller.listenToMessages(widget.groupId);
    ever(controller.messages, (_) => _scrollToBottom());

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) controller.markMessagesAsSeen();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ChatGroupController.to.markMessagesAsSeen();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool instant = false}) {
    if (!_scrollController.hasClients) return;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scrollController.hasClients) return;
      final position = _scrollController.position.maxScrollExtent;
      if (instant) {
        _scrollController.jumpTo(position);
      } else {
        _scrollController.animateTo(
          position,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ================================
  // ✅ معالجة الملفات المرفقة
  // ================================
  Future<void> _handleFileSelected(File file, String type) async {
    if (_isUploading) {
      Get.snackbar(
        'تنبيه',
        'يتم رفع ملف آخر، انتظر قليلاً',
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      String? fileUrl;
      String? thumbnailUrl;
      String messageContent = '';

      // عرض رسالة تحميل
      Get.dialog(
        WillPopScope(
          onWillPop: () async => false,
          child: Center(
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: ManagerColors.primaryColor,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'جاري رفع ${_getFileTypeArabic(type)}...',
                    style: getBoldTextStyle(
                      fontSize: ManagerFontSize.s14,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // رفع الملف حسب النوع
      switch (type) {
        case 'image':
          final result = await CloudinaryService.uploadImage(
            file: file,
            folder: 'chat_images/${widget.groupId}',
          );

          if (result['success'] == true) {
            fileUrl = result['url'];
            thumbnailUrl = result['thumbnailUrl'];
            messageContent = '📷 صورة';
          }
          break;

        case 'video':
          final result = await CloudinaryService.uploadVideo(
            file: file,
            folder: 'chat_videos/${widget.groupId}',
          );

          if (result['success'] == true) {
            fileUrl = result['url'];
            thumbnailUrl = result['thumbnailUrl'];
            messageContent = '🎥 فيديو';
          }
          break;

        case 'audio':
          final result = await CloudinaryService.uploadAudio(
            file: file,
            folder: 'chat_audio/${widget.groupId}',
          );

          if (result['success'] == true) {
            fileUrl = result['url'];
            messageContent = '🎤 تسجيل صوتي';
          }
          break;

        case 'file':
          final result = await CloudinaryService.uploadFile(
            file: file,
            folder: 'chat_files/${widget.groupId}',
          );

          if (result['success'] == true) {
            fileUrl = result['url'];
            final fileName = result['fileName'] ?? 'ملف';
            messageContent = '📎 $fileName';
          }
          break;
      }

      // إغلاق dialog التحميل
      Get.back();

      if (fileUrl != null) {
        // إرسال الرسالة مع رابط الملف
        final controller = ChatGroupController.to;

        // يمكنك هنا إنشاء رسالة مخصصة تحتوي على الملف
        // أو إرسال الرابط في النص
        await controller.sendMessage(
          widget.groupId,
          '$messageContent\n$fileUrl${thumbnailUrl != null ? '\n$thumbnailUrl' : ''}',
        );

        _scrollToBottom();

        Get.snackbar(
          'نجح',
          'تم رفع وإرسال ${_getFileTypeArabic(type)} بنجاح',
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          duration: Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'خطأ',
          'فشل رفع ${_getFileTypeArabic(type)}',
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back(); // إغلاق dialog
      print('❌ خطأ في رفع الملف: $e');
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء رفع ${_getFileTypeArabic(type)}: $e',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  String _getFileTypeArabic(String type) {
    switch (type) {
      case 'image':
        return 'الصورة';
      case 'video':
        return 'الفيديو';
      case 'audio':
        return 'التسجيل الصوتي';
      case 'file':
        return 'الملف';
      default:
        return 'الملف';
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ChatGroupController.to;

    return SafeArea(
      top: false,
      bottom: true,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            // Reply Preview
            Obx(() {
              if (controller.replyMessage.value != null) {
                return ReplyPreview(
                  message: controller.replyMessage.value!,
                  onCancel: controller.cancelReply,
                );
              }
              return const SizedBox.shrink();
            }),

            // Messages List
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = controller.messages;
                if (messages.isEmpty) {
                  return _buildEmptyState();
                }

                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(ManagerWidth.w16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = controller.isMineSync(message.senderId);

                    return MessageBubble(
                      message: message,
                      isMine: isMine,
                      onReply: () => controller.replyTo(message),
                      onTapStatus: isMine ? () => _showMessageStatus(message) : null,
                    );
                  },
                );
              }),
            ),

            // Input Field
            Obx(() {
              return MessageInputField(
                controller: controller.textController,
                onSend: (text) {
                  controller.sendMessage(widget.groupId, text);
                  _scrollToBottom();
                },
                onFileSelected: _handleFileSelected, // ✅ ربط معالج الملفات
                isSending: controller.isSending.value || _isUploading,
              );
            }),
          ],
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
      title: GestureDetector(
        onTap: (){
          Get.to(GroupInfoScreen(
            groupId: widget.groupId,
            groupImage: widget.groupImage,
            groupName: widget.groupName,
          ));
        },
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: widget.groupImage.isNotEmpty
                  ? CachedNetworkImageProvider(widget.groupImage)
                  : null,
              child: widget.groupImage.isEmpty
                  ? Icon(Icons.group, color: Colors.grey.shade600, size: 20)
                  : null,
            ),
            SizedBox(width: ManagerWidth.w8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.groupName,
                    style: getBoldTextStyle(
                      fontSize: ManagerFontSize.s14,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "${widget.participantsCount} مشارك",
                    style: getRegularTextStyle(
                      fontSize: ManagerFontSize.s10,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // actions: [
      //   PopupMenuButton<String>(
      //     icon: const Icon(Icons.more_vert, color: Colors.white),
      //     onSelected: _handleMenuAction,
      //     itemBuilder: (context) => [
      //       const PopupMenuItem(
      //         value: 'info',
      //         child: Row(
      //           children: [
      //             Icon(Icons.info_outline),
      //             SizedBox(width: 12),
      //             Text('معلومات المجموعة'),
      //           ],
      //         ),
      //       ),
      //       const PopupMenuItem(
      //         value: 'mute',
      //         child: Row(
      //           children: [
      //             Icon(Icons.notifications_off_outlined),
      //             SizedBox(width: 12),
      //             Text('كتم الإشعارات'),
      //           ],
      //         ),
      //       ),
      //       const PopupMenuItem(
      //         value: 'search',
      //         child: Row(
      //           children: [
      //             Icon(Icons.search),
      //             SizedBox(width: 12),
      //             Text('بحث'),
      //           ],
      //         ),
      //       ),
      //     ],
      //   ),
      // ],
    );
  }

  void _handleMenuAction(String value) {
    switch (value) {
      case 'info':
        break;
      case 'mute':
        break;
      case 'search':
        break;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade300),
          SizedBox(height: ManagerHeight.h16),
          Text(
            "لا توجد رسائل بعد",
            style: getRegularTextStyle(
              fontSize: ManagerFontSize.s14,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: ManagerHeight.h8),
          Text(
            "ابدأ المحادثة الآن!",
            style: getRegularTextStyle(
              fontSize: ManagerFontSize.s12,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageStatus(message) {
    Get.to(
          () => MessageStatusScreen(
        groupId: widget.groupId,
        message: message,
        groupName: widget.groupName,
      ),
      transition: Transition.rightToLeft,
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:app_mobile/core/resources/manager_colors.dart';
// import 'package:app_mobile/core/resources/manager_font_size.dart';
// import 'package:app_mobile/core/resources/manager_height.dart';
// import 'package:app_mobile/core/resources/manager_styles.dart';
// import 'package:app_mobile/core/resources/manager_width.dart';
// import '../../domain/di/chat_group_di.dart';
// import '../controller/chat_group_controller.dart';
// import '../widgets/message_bubble.dart';
// import '../widgets/message_input_field.dart';
// import '../widgets/reply_preview.dart';

// import 'message_status_screen.dart';
//
// class ChatGroupScreen extends StatefulWidget {
//   final String groupId;
//   final String groupName;
//   final String groupImage;
//   final String participantsCount;
//   final String? currentUserId;
//
//   const ChatGroupScreen({
//     super.key,
//     required this.groupId,
//     required this.groupName,
//     required this.groupImage,
//     required this.participantsCount,
//     this.currentUserId,
//   });
//
//   @override
//   State<ChatGroupScreen> createState() => _ChatGroupScreenState();
// }
//
// class _ChatGroupScreenState extends State<ChatGroupScreen> with WidgetsBindingObserver {
//   final ScrollController _scrollController = ScrollController();
//
//   @override
//   void initState() {
//     super.initState();
//     ChatGroupDI.init();
//     WidgetsBinding.instance.addObserver(this);
//
//     final controller = ChatGroupController.to;
//
//     if (widget.currentUserId != null && widget.currentUserId!.isNotEmpty) {
//       controller.setCurrentUser(widget.currentUserId!);
//     }
//
//     // Start listening to messages
//     controller.listenToMessages(widget.groupId);
//
//     // ✅ Scroll to bottom when messages first load
//     ever(controller.messages, (_) => _scrollToBottom());
//
//     // Mark as seen after a short delay
//     Future.delayed(const Duration(milliseconds: 500), () {
//       if (mounted) controller.markMessagesAsSeen();
//     });
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       ChatGroupController.to.markMessagesAsSeen();
//     }
//   }
//
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   // ================================
//   // ✅ AUTO SCROLL LOGIC
//   // ================================
//   void _scrollToBottom({bool instant = false}) {
//     if (!_scrollController.hasClients) return;
//     Future.delayed(const Duration(milliseconds: 100), () {
//       if (!_scrollController.hasClients) return;
//       final position = _scrollController.position.maxScrollExtent;
//       if (instant) {
//         _scrollController.jumpTo(position);
//       } else {
//         _scrollController.animateTo(
//           position,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final controller = ChatGroupController.to;
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: _buildAppBar(),
//       body: Column(
//         children: [
//           // Reply Preview
//           Obx(() {
//             if (controller.replyMessage.value != null) {
//               return ReplyPreview(
//                 message: controller.replyMessage.value!,
//                 onCancel: controller.cancelReply,
//               );
//             }
//             return const SizedBox.shrink();
//           }),
//
//           // Messages List
//           Expanded(
//             child: Obx(() {
//               if (controller.isLoading.value) {
//                 return const Center(child: CircularProgressIndicator());
//               }
//
//               final messages = controller.messages;
//               if (messages.isEmpty) {
//                 return _buildEmptyState();
//               }
//
//               // ✅ Scroll automatically after UI build
//               WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
//
//               return ListView.builder(
//                 controller: _scrollController,
//                 padding: EdgeInsets.all(ManagerWidth.w16),
//                 itemCount: messages.length,
//                 itemBuilder: (context, index) {
//                   final message = messages[index];
//                   final isMine = controller.isMineSync(message.senderId);
//
//                   return MessageBubble(
//                     message: message,
//                     isMine: isMine,
//                     onReply: () => controller.replyTo(message),
//                     onTapStatus: isMine ? () => _showMessageStatus(message) : null,
//                   );
//                 },
//               );
//             }),
//           ),
//
//           // Input Field
//           Obx(() {
//             return MessageInputField(
//               controller: controller.textController,
//               onSend: (text) {
//                 controller.sendMessage(widget.groupId, text);
//                 _scrollToBottom(); // ✅ Scroll when sending message
//               },
//               isSending: controller.isSending.value,
//             );
//           }),
//         ],
//       ),
//     );
//   }
//
//   // ================================
//   // ✅ APP BAR
//   // ================================
//   PreferredSizeWidget _buildAppBar() {
//     return AppBar(
//       backgroundColor: ManagerColors.primaryColor,
//       elevation: 0,
//       leading: IconButton(
//         icon: const Icon(Icons.arrow_back, color: Colors.white),
//         onPressed: () => Get.back(),
//       ),
//       title: Row(
//         children: [
//           CircleAvatar(
//             radius: 18,
//             backgroundColor: Colors.grey.shade300,
//             backgroundImage: widget.groupImage.isNotEmpty
//                 ? CachedNetworkImageProvider(widget.groupImage)
//                 : null,
//             child: widget.groupImage.isEmpty
//                 ? Icon(Icons.group, color: Colors.grey.shade600, size: 20)
//                 : null,
//           ),
//           SizedBox(width: ManagerWidth.w8),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   widget.groupName,
//                   style: getBoldTextStyle(
//                     fontSize: ManagerFontSize.s14,
//                     color: Colors.white,
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 Text(
//                   "${widget.participantsCount} مشارك",
//                   style: getRegularTextStyle(
//                     fontSize: ManagerFontSize.s10,
//                     color: Colors.white.withOpacity(0.8),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//       actions: [
//         PopupMenuButton<String>(
//           icon: const Icon(Icons.more_vert, color: Colors.white),
//           onSelected: _handleMenuAction,
//           itemBuilder: (context) => [
//             const PopupMenuItem(
//               value: 'info',
//               child: Row(
//                 children: [
//                   Icon(Icons.info_outline),
//                   SizedBox(width: 12),
//                   Text('معلومات المجموعة'),
//                 ],
//               ),
//             ),
//             const PopupMenuItem(
//               value: 'mute',
//               child: Row(
//                 children: [
//                   Icon(Icons.notifications_off_outlined),
//                   SizedBox(width: 12),
//                   Text('كتم الإشعارات'),
//                 ],
//               ),
//             ),
//             const PopupMenuItem(
//               value: 'search',
//               child: Row(
//                 children: [
//                   Icon(Icons.search),
//                   SizedBox(width: 12),
//                   Text('بحث'),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   void _handleMenuAction(String value) {
//     switch (value) {
//       case 'info':
//       // TODO: Navigate to group info
//         break;
//       case 'mute':
//       // TODO: Mute notifications
//         break;
//       case 'search':
//       // TODO: Search messages
//         break;
//     }
//   }
//
//   // ================================
//   // ✅ EMPTY STATE
//   // ================================
//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade300),
//           SizedBox(height: ManagerHeight.h16),
//           Text(
//             "لا توجد رسائل بعد",
//             style: getRegularTextStyle(
//               fontSize: ManagerFontSize.s14,
//               color: Colors.grey,
//             ),
//           ),
//           SizedBox(height: ManagerHeight.h8),
//           Text(
//             "ابدأ المحادثة الآن!",
//             style: getRegularTextStyle(
//               fontSize: ManagerFontSize.s12,
//               color: Colors.grey.shade400,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ================================
//   // ✅ MESSAGE STATUS
//   // ================================
//   void _showMessageStatus(message) {
//     Get.to(
//           () => MessageStatusScreen(
//         groupId: widget.groupId,
//         message: message,
//         groupName: widget.groupName,
//       ),
//       transition: Transition.rightToLeft,
//     );
//   }
// }
//
// // // المسار: lib/features/home/group_chat/presentation/pages/group_chat_screen.dart
// //
// // import 'package:flutter/material.dart';
// // import 'package:get/get.dart';
// // import 'package:cached_network_image/cached_network_image.dart';
// // import 'package:app_mobile/core/resources/manager_colors.dart';
// // import 'package:app_mobile/core/resources/manager_font_size.dart';
// // import 'package:app_mobile/core/resources/manager_height.dart';
// // import 'package:app_mobile/core/resources/manager_styles.dart';
// // import 'package:app_mobile/core/resources/manager_width.dart';
// // import '../../domain/di/chat_group_di.dart';
// // import '../controller/chat_group_controller.dart';
// // import '../widgets/message_bubble.dart';
// // import '../widgets/message_input_field.dart';
// // import '../widgets/reply_preview.dart';
// // import 'message_status_screen.dart';
// //
// // class ChatGroupScreen extends StatefulWidget {
// //   final String groupId;
// //   final String groupName;
// //   final String groupImage;
// //   final String participantsCount;
// //   final String? currentUserId;
// //
// //   const ChatGroupScreen({
// //     super.key,
// //     required this.groupId,
// //     required this.groupName,
// //     required this.groupImage,
// //     required this.participantsCount,
// //     this.currentUserId,
// //   });
// //
// //   @override
// //   State<ChatGroupScreen> createState() => _ChatGroupScreenState();
// // }
// //
// // class _ChatGroupScreenState extends State<ChatGroupScreen>
// //     with WidgetsBindingObserver {
// //   @override
// //   void initState() {
// //     super.initState();
// //
// //     // Initialize DI
// //     ChatGroupDI.init();
// //
// //     WidgetsBinding.instance.addObserver(this);
// //
// //     final controller = ChatGroupController.to;
// //
// //     // Set current user if provided
// //     if (widget.currentUserId != null && widget.currentUserId!.isNotEmpty) {
// //       controller.setCurrentUser(widget.currentUserId!);
// //     }
// //
// //     // Start listening to messages
// //     controller.listenToMessages(widget.groupId);
// //
// //     // Mark as seen after delay
// //     Future.delayed(const Duration(milliseconds: 500), () {
// //       if (mounted) {
// //         controller.markMessagesAsSeen();
// //       }
// //     });
// //   }
// //
// //   @override
// //   void didChangeAppLifecycleState(AppLifecycleState state) {
// //     if (state == AppLifecycleState.resumed) {
// //       // App came to foreground - mark as seen
// //       ChatGroupController.to.markMessagesAsSeen();
// //     }
// //   }
// //
// //   @override
// //   void dispose() {
// //     WidgetsBinding.instance.removeObserver(this);
// //     // Don't dispose DI here - let it manage its own lifecycle
// //     super.dispose();
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final controller = ChatGroupController.to;
// //
// //     return Scaffold(
// //       backgroundColor: Colors.white,
// //       appBar: _buildAppBar(),
// //       body: Column(
// //         children: [
// //           // Reply Preview
// //           Obx(() {
// //             if (controller.replyMessage.value != null) {
// //               return ReplyPreview(
// //                 message: controller.replyMessage.value!,
// //                 onCancel: controller.cancelReply,
// //               );
// //             }
// //             return const SizedBox.shrink();
// //           }),
// //
// //           // Messages List
// //           Expanded(
// //             child: Obx(() {
// //               if (controller.isLoading.value) {
// //                 return const Center(
// //                   child: CircularProgressIndicator(),
// //                 );
// //               }
// //
// //               final messages = controller.messages;
// //               if (messages.isEmpty) {
// //                 return _buildEmptyState();
// //               }
// //
// //               return ListView.builder(
// //                 padding: EdgeInsets.all(ManagerWidth.w16),
// //                 itemCount: messages.length,
// //                 itemBuilder: (context, index) {
// //                   final message = messages[index];
// //                   final isMine = controller.isMineSync(message.senderId);
// //
// //                   return MessageBubble(
// //                     message: message,
// //                     isMine: isMine,
// //                     onReply: () => controller.replyTo(message),
// //                     onTapStatus:
// //                     isMine ? () => _showMessageStatus(message) : null,
// //                   );
// //                 },
// //               );
// //             }),
// //           ),
// //
// //           // Input Field
// //           Obx(() {
// //             return MessageInputField(
// //               controller: controller.textController,
// //               onSend: (text) => controller.sendMessage(widget.groupId, text),
// //               isSending: controller.isSending.value,
// //             );
// //           }),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   // ================================
// //   // ✅ APP BAR
// //   // ================================
// //
// //   PreferredSizeWidget _buildAppBar() {
// //     return AppBar(
// //       backgroundColor: ManagerColors.primaryColor,
// //       elevation: 0,
// //       leading: IconButton(
// //         icon: const Icon(Icons.arrow_back, color: Colors.white),
// //         onPressed: () => Get.back(),
// //       ),
// //       title: Row(
// //         children: [
// //           CircleAvatar(
// //             radius: 18,
// //             backgroundColor: Colors.grey.shade300,
// //             backgroundImage: widget.groupImage.isNotEmpty
// //                 ? CachedNetworkImageProvider(widget.groupImage)
// //                 : null,
// //             child: widget.groupImage.isEmpty
// //                 ? Icon(Icons.group, color: Colors.grey.shade600, size: 20)
// //                 : null,
// //           ),
// //           SizedBox(width: ManagerWidth.w8),
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text(
// //                   widget.groupName,
// //                   style: getBoldTextStyle(
// //                     fontSize: ManagerFontSize.s14,
// //                     color: Colors.white,
// //                   ),
// //                   maxLines: 1,
// //                   overflow: TextOverflow.ellipsis,
// //                 ),
// //                 Text(
// //                   "${widget.participantsCount} مشارك",
// //                   style: getRegularTextStyle(
// //                     fontSize: ManagerFontSize.s10,
// //                     color: Colors.white.withOpacity(0.8),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //       actions: [
// //         PopupMenuButton<String>(
// //           icon: const Icon(Icons.more_vert, color: Colors.white),
// //           onSelected: _handleMenuAction,
// //           itemBuilder: (context) => [
// //             const PopupMenuItem(
// //               value: 'info',
// //               child: Row(
// //                 children: [
// //                   Icon(Icons.info_outline),
// //                   SizedBox(width: 12),
// //                   Text('معلومات المجموعة'),
// //                 ],
// //               ),
// //             ),
// //             const PopupMenuItem(
// //               value: 'mute',
// //               child: Row(
// //                 children: [
// //                   Icon(Icons.notifications_off_outlined),
// //                   SizedBox(width: 12),
// //                   Text('كتم الإشعارات'),
// //                 ],
// //               ),
// //             ),
// //             const PopupMenuItem(
// //               value: 'search',
// //               child: Row(
// //                 children: [
// //                   Icon(Icons.search),
// //                   SizedBox(width: 12),
// //                   Text('بحث'),
// //                 ],
// //               ),
// //             ),
// //           ],
// //         ),
// //       ],
// //     );
// //   }
// //
// //   void _handleMenuAction(String value) {
// //     switch (value) {
// //       case 'info':
// //       // TODO: Navigate to group info
// //         break;
// //       case 'mute':
// //       // TODO: Mute notifications
// //         break;
// //       case 'search':
// //       // TODO: Search messages
// //         break;
// //     }
// //   }
// //
// //   // ================================
// //   // ✅ EMPTY STATE
// //   // ================================
// //
// //   Widget _buildEmptyState() {
// //     return Center(
// //       child: Column(
// //         mainAxisAlignment: MainAxisAlignment.center,
// //         children: [
// //           Icon(
// //             Icons.chat_bubble_outline,
// //             size: 80,
// //             color: Colors.grey.shade300,
// //           ),
// //           SizedBox(height: ManagerHeight.h16),
// //           Text(
// //             "لا توجد رسائل بعد",
// //             style: getRegularTextStyle(
// //               fontSize: ManagerFontSize.s14,
// //               color: Colors.grey,
// //             ),
// //           ),
// //           SizedBox(height: ManagerHeight.h8),
// //           Text(
// //             "ابدأ المحادثة الآن!",
// //             style: getRegularTextStyle(
// //               fontSize: ManagerFontSize.s12,
// //               color: Colors.grey.shade400,
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   // ================================
// //   // ✅ MESSAGE STATUS
// //   // ================================
// //
// //   void _showMessageStatus(message) {
// //     Get.to(
// //           () => MessageStatusScreen(
// //         groupId: widget.groupId,
// //         message: message,
// //         groupName: widget.groupName,
// //       ),
// //       transition: Transition.rightToLeft,
// //     );
// //   }
// // }