// المسار: lib/features/home/group_chat/presentation/widgets/message_bubble_updated.dart

import 'package:app_mobile/features/home/group_chat/domain/models/attachment_model.dart';
import 'package:app_mobile/features/home/group_chat/domain/models/message_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_width.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';
import 'package:just_audio/just_audio.dart';
import '../controller/chat_group_controller.dart';
import 'message_image_widget.dart';
import 'message_audio_widget.dart';
import 'message_file_widget.dart';
import 'message_video_widget.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final VoidCallback onReply;
  final VoidCallback? onTapStatus;
  final List<AttachmentModel>? attachments;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.onReply,
    this.onTapStatus,
    this.attachments,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isDeleted) {
      return _buildDeletedMessage();
    }

    // ✅ الحل النهائي: استخراج جميع البيانات المطلوبة
    final allAttachments = _getAllAttachments();
    final displayContent = _getDisplayContent();
    final hasRealContent = _hasRealContent(displayContent);

    return GestureDetector(
      onLongPress: () => _showMessageOptions(context),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: ManagerHeight.h6),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: isMine ? ManagerColors.primaryColor : Colors.grey.shade100,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMine ? 16 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Reply Preview
              if (message.replyTo != null) _buildReplyPreview(),

              // ✅ الوسائط (مرة واحدة فقط)
              if (allAttachments.isNotEmpty)
                _buildAttachments(allAttachments),

              // ✅ المحتوى النصي (فقط إذا كان هناك نص حقيقي)
              if (hasRealContent)
                Padding(
                  padding: EdgeInsets.all(ManagerWidth.w12),
                  child: _buildMessageContent(displayContent),
                ),

              // Reactions
              if (message.reactions != null && message.reactions!.isNotEmpty)
                _buildReactions(),

              // Message Footer (Time + Status)
              Padding(
                padding: EdgeInsets.only(
                  left: ManagerWidth.w12,
                  right: ManagerWidth.w12,
                  bottom: ManagerHeight.h8,
                ),
                child: _buildMessageFooter(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================
  // ✅ الحل النهائي: جمع جميع الـ Attachments
  // ================================
  List<AttachmentModel> _getAllAttachments() {
    final allAttachments = <AttachmentModel>[];

    // إضافة الـ attachments الممررة مباشرة
    if (attachments != null && attachments!.isNotEmpty) {
      allAttachments.addAll(attachments!);
    }

    // استخراج الـ attachments من المحتوى النصي
    final extractedAttachments = _extractAttachmentsFromContent();
    allAttachments.addAll(extractedAttachments);

    return allAttachments;
  }

  // ================================
  // ✅ استخراج الـ Attachments من المحتوى (محدث)
  // ================================
  List<AttachmentModel> _extractAttachmentsFromContent() {
    final attachments = <AttachmentModel>[];
    final content = message.content;

    // البحث عن روابط Cloudinary
    final cloudinaryPattern = RegExp(r'https://res\.cloudinary\.com/[^\s]+');
    final matches = cloudinaryPattern.allMatches(content);

    // ✅ البحث عن metadata للنوع في محتوى الرسالة
    final forcedType = _getForcedMediaTypeFromContent(content);

    for (final match in matches) {
      final url = match.group(0)!;

      // ✅ استخدام النوع المحدد في metadata إذا وجد، وإلا التحديد التلقائي
      String type;
      if (forcedType != null) {
        type = forcedType;
      } else {
        type = _getMediaTypeFromUrl(url);
      }

      attachments.add(AttachmentModel(
        id: '${message.id}_${attachments.length}',
        url: url,
        type: type,
        fileName: _getFileNameFromUrl(url),
        uploadProgress: 1.0,
      ));
    }

    return attachments;
  }

  // ================================
  // ✅ استخراج النوع المحدد من محتوى الرسالة
  // ================================
  String? _getForcedMediaTypeFromContent(String content) {
    // ✅ البحث عن metadata في محتوى الرسالة
    final metadataPattern = RegExp(r'\|type:([^|]+)\|');
    final metadataMatch = metadataPattern.firstMatch(content);

    if (metadataMatch != null) {
      final type = metadataMatch.group(1);
      if (['image', 'video', 'audio', 'file'].contains(type)) {
        return type;
      }
    }

    // ✅ إذا لم يوجد metadata، نفحص النص والأيقونات
    final lowerContent = content.toLowerCase();

    if (lowerContent.contains('🎤') ||
        lowerContent.contains('تسجيل صوتي') ||
        lowerContent.contains('صوتي') ||
        lowerContent.contains('audio') ||
        lowerContent.contains('voice')) {
      return 'audio';
    }

    if (lowerContent.contains('📷') ||
        lowerContent.contains('صورة') ||
        lowerContent.contains('image')) {
      return 'image';
    }

    if (lowerContent.contains('🎥') ||
        lowerContent.contains('فيديو') ||
        lowerContent.contains('video')) {
      return 'video';
    }

    if (lowerContent.contains('📎') ||
        lowerContent.contains('ملف') ||
        lowerContent.contains('file')) {
      return 'file';
    }

    return null;
  }

  // ================================
  // ✅ الحل النهائي: تنظيف المحتوى النصي
  // ================================
  String _getDisplayContent() {
    String content = message.content;

    // إذا كان هناك attachments مباشرة، نعيد المحتوى الأصلي (لأن الوسائط منفصلة)
    if (attachments != null && attachments!.isNotEmpty) {
      return content.trim();
    }

    // إزالة روابط Cloudinary من النص
    final cloudinaryPattern = RegExp(r'https://res\.cloudinary\.com/[^\s]+');
    content = content.replaceAll(cloudinaryPattern, '').trim();

    // إزالة metadata من النص
    final metadataPattern = RegExp(r'\|type:[^|]+\|');
    content = content.replaceAll(metadataPattern, '').trim();

    // إزالة أيقونات الوسائط إذا كانت وحدها
    final mediaIconsPattern = RegExp(r'^(📷|🎥|🎤|📎)\s*$');
    if (mediaIconsPattern.hasMatch(content)) {
      return '';
    }

    return content;
  }

  // ================================
  // ✅ التحقق من وجود محتوى نصي حقيقي
  // ================================
  bool _hasRealContent(String content) {
    if (content.isEmpty) return false;

    // التحقق إذا كان المحتوى يحتوي فقط على مسافات أو رموز وسائط
    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) return false;

    final mediaIconsPattern = RegExp(r'^(📷|🎥|🎤|📎)\s*$');
    if (mediaIconsPattern.hasMatch(trimmedContent)) {
      return false;
    }

    return true;
  }

  // ================================
  // ✅ بناء الوسائط
  // ================================
  Widget _buildAttachments(List<AttachmentModel> attachments) {
    return Padding(
      padding: EdgeInsets.all(ManagerWidth.w8),
      child: Column(
        children: attachments.map((attachment) {
          switch (attachment.type) {
            case 'image':
              return MessageImageWidget(
                attachment: attachment,
                isMine: isMine,
              );
            case 'video':
              return MessageVideoWidget(
                attachment: attachment,
                isMine: isMine,
              );
            case 'audio':
              return _buildWhatsAppVoiceMessage(attachment);
            case 'file':
              return MessageFileWidget(
                attachment: attachment,
                isMine: isMine,
              );
            default:
              return const SizedBox.shrink();
          }
        }).toList(),
      ),
    );
  }

  // ================================
  // ✅ تصميم الرسالة الصوتية مثل واتساب (محدث)
  // ================================
  Widget _buildWhatsAppVoiceMessage(AttachmentModel attachment) {
    return Container(
      margin: EdgeInsets.all(ManagerWidth.w8),
      child: _WhatsAppVoiceMessagePlayer(
        attachment: attachment,
        isMine: isMine,
      ),
    );
  }

  // ================================
  // ✅ المحتوى النصي
  // ================================
  Widget _buildMessageContent(String content) {
    return Text(
      _highlightMentions(content),
      style: getRegularTextStyle(
        fontSize: ManagerFontSize.s14,
        color: isMine ? Colors.white : Colors.black87,
      ),
    );
  }

  // ================================
  // ✅ تحديد نوع الوسائط من الرابط (محدث)
  // ================================
  String _getMediaTypeFromUrl(String url) {
    final uri = Uri.parse(url);
    final path = uri.path.toLowerCase();

    // ✅ الحل الجديد: فحص مجلد الرفع في Cloudinary
    if (path.contains('/chat_audio/') || path.contains('/audio/')) {
      return 'audio';
    }
    else if (path.contains('/chat_videos/') || path.contains('/video/')) {
      return 'video';
    }
    else if (path.contains('/chat_images/') || path.contains('/image/')) {
      return 'image';
    }
    else if (path.contains('/chat_files/') || path.contains('/file/')) {
      return 'file';
    }

    // ✅ فحص المسار للتحديد الدقيق للنوع
    if (path.contains('/image/') ||
        path.contains('/upload/') && (
            path.contains('.jpg') ||
                path.contains('.png') ||
                path.contains('.jpeg') ||
                path.contains('.webp')
        )) {
      return 'image';
    }
    else if (path.contains('/video/') ||
        path.contains('/upload/') && (
            path.contains('.mp4') ||
                path.contains('.mov') ||
                path.contains('.avi')
        )) {
      return 'video';
    }
    else if (path.contains('/audio/') ||
        path.contains('/upload/') && (
            path.contains('.mp3') ||
                path.contains('.m4a') ||
                path.contains('.wav') ||
                path.contains('.aac')
        )) {
      return 'audio';
    }
    else if (path.contains('/file/') ||
        path.contains('/upload/') && (
            path.contains('.pdf') ||
                path.contains('.doc') ||
                path.contains('.docx') ||
                path.contains('.txt')
        )) {
      return 'file';
    }

    // ✅ إذا لم نتمكن من التحديد، نفحص محتوى الرسالة
    return _getMediaTypeFromMessageContent();
  }

  // ================================
  // ✅ تحديد النوع من محتوى الرسالة
  // ================================
  String _getMediaTypeFromMessageContent() {
    final content = message.content.toLowerCase();

    if (content.contains('📷') || content.contains('صورة')) {
      return 'image';
    } else if (content.contains('🎥') || content.contains('فيديو')) {
      return 'video';
    } else if (content.contains('🎤') ||
        content.contains('تسجيل صوتي') ||
        content.contains('صوتي')) {
      return 'audio';
    } else if (content.contains('📎') || content.contains('ملف')) {
      return 'file';
    }

    // ✅ الإفتراضي هو ملف إذا لم نتمكن من التحديد
    return 'file';
  }

  // ================================
  // ✅ دوال مساعدة
  // ================================
  String _getFileNameFromUrl(String url) {
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;
    return pathSegments.isNotEmpty ? pathSegments.last : 'file';
  }

  String _highlightMentions(String content) {
    // TODO: تنفيذ إبراز الإشارات
    return content;
  }

  // ================================
  // ✅ باقي الدوال (بدون تغيير)
  // ================================
  Widget _buildDeletedMessage() {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: ManagerHeight.h6),
        padding: EdgeInsets.all(ManagerWidth.w12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block, size: 16, color: Colors.grey.shade600),
            SizedBox(width: ManagerWidth.w8),
            Text(
              'تم حذف هذه الرسالة',
              style: getRegularTextStyle(
                fontSize: ManagerFontSize.s13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      margin: EdgeInsets.all(ManagerWidth.w8),
      padding: EdgeInsets.all(ManagerWidth.w8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isMine ? 0.2 : 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          right: BorderSide(
            color: isMine ? Colors.white : ManagerColors.primaryColor,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.reply,
                size: 14,
                color: isMine
                    ? Colors.white.withOpacity(0.9)
                    : Colors.grey.shade700,
              ),
              SizedBox(width: ManagerWidth.w4),
              Text(
                "ردًا على",
                style: getBoldTextStyle(
                  fontSize: ManagerFontSize.s10,
                  color: isMine
                      ? Colors.white.withOpacity(0.9)
                      : Colors.grey.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: ManagerHeight.h4),
          Text(
            message.replyTo ?? '',
            style: getRegularTextStyle(
              fontSize: ManagerFontSize.s12,
              color: isMine
                  ? Colors.white.withOpacity(0.8)
                  : Colors.grey.shade600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildReactions() {
    final reactions = message.reactions!;
    final reactionCounts = <String, int>{};

    for (var emoji in reactions.values) {
      reactionCounts[emoji.toString()] =
          (reactionCounts[emoji.toString()] ?? 0) + 1;
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: ManagerWidth.w8),
      padding: EdgeInsets.all(ManagerWidth.w6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isMine ? 0.2 : 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 4,
        children: reactionCounts.entries.map((entry) {
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: ManagerWidth.w6,
              vertical: ManagerHeight.h2,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(entry.key, style: const TextStyle(fontSize: 14)),
                if (entry.value > 1) ...[
                  SizedBox(width: ManagerWidth.w2),
                  Text(
                    '${entry.value}',
                    style: getBoldTextStyle(
                      fontSize: ManagerFontSize.s10,
                      color: isMine ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMessageFooter() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(message.timestamp),
          style: getRegularTextStyle(
            fontSize: ManagerFontSize.s10,
            color: isMine ? Colors.white.withOpacity(0.7) : Colors.grey,
          ),
        ),
        if (isMine) ...[
          SizedBox(width: ManagerWidth.w4),
          GestureDetector(
            onTap: onTapStatus,
            child: _buildStatusIcon(),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;

    if (message.isFailed) {
      icon = Icons.error_outline;
      color = Colors.red.shade300;
    } else if (message.isFullySeen) {
      icon = Icons.done_all;
      color = Colors.blue.shade200;
    } else if (message.isSeen) {
      icon = Icons.done_all;
      color = Colors.blue.shade200;
    } else if (message.isFullyDelivered) {
      icon = Icons.done_all;
      color = Colors.white.withOpacity(0.7);
    } else if (message.isDelivered) {
      icon = Icons.done_all;
      color = Colors.white.withOpacity(0.7);
    } else {
      icon = Icons.done;
      color = Colors.white.withOpacity(0.7);
    }

    return Icon(
      icon,
      size: 16,
      color: color,
    );
  }

  void _showMessageOptions(BuildContext context) {
    final controller = ChatGroupController.to;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: ManagerHeight.h8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.reply, color: ManagerColors.primaryColor),
              title: Text(
                'الرد على الرسالة',
                style: getRegularTextStyle(
                  fontSize: ManagerFontSize.s14,
                  color: Colors.black,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onReply();
              },
            ),
            ListTile(
              leading: Icon(Icons.add_reaction, color: ManagerColors.primaryColor),
              title: Text(
                'إضافة تفاعل',
                style: getRegularTextStyle(
                  fontSize: ManagerFontSize.s14,
                  color: Colors.black,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showReactionPicker(context);
              },
            ),
            if (isMine && onTapStatus != null)
              ListTile(
                leading: Icon(Icons.info_outline, color: ManagerColors.primaryColor),
                title: Text(
                  'حالة الرسالة',
                  style: getRegularTextStyle(
                    fontSize: ManagerFontSize.s14,
                    color: Colors.black,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onTapStatus!();
                },
              ),
            ListTile(
              leading: Icon(Icons.copy, color: ManagerColors.primaryColor),
              title: Text(
                'نسخ النص',
                style: getRegularTextStyle(
                  fontSize: ManagerFontSize.s14,
                  color: Colors.black,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: message.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم نسخ النص'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            if (controller.canDeleteMessage(message))
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  'حذف الرسالة',
                  style: getRegularTextStyle(
                    fontSize: ManagerFontSize.s14,
                    color: Colors.red,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context);
                },
              ),
            SizedBox(height: ManagerHeight.h8),
          ],
        ),
      ),
    );
  }

  void _showReactionPicker(BuildContext context) {
    final controller = ChatGroupController.to;
    final reactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(ManagerWidth.w20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'اختر تفاعلك',
              style: getBoldTextStyle(
                fontSize: ManagerFontSize.s16,
                color: Colors.black,
              ),
            ),
            SizedBox(height: ManagerHeight.h20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: reactions.map((emoji) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    controller.addReaction(message, emoji);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: ManagerHeight.h20),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final controller = ChatGroupController.to;

    Get.dialog(
      AlertDialog(
        title: const Text('حذف الرسالة'),
        content: const Text('هل أنت متأكد من حذف هذه الرسالة؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteMessage(message);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }
}

// ================================
// ✅ مشغل الرسائل الصوتية بتصميم واتساب مع الموجات المتذبذبة
// ================================
class _WhatsAppVoiceMessagePlayer extends StatefulWidget {
  final AttachmentModel attachment;
  final bool isMine;

  const _WhatsAppVoiceMessagePlayer({
    required this.attachment,
    required this.isMine,
  });

  @override
  State<_WhatsAppVoiceMessagePlayer> createState() => __WhatsAppVoiceMessagePlayerState();
}

class __WhatsAppVoiceMessagePlayerState extends State<_WhatsAppVoiceMessagePlayer>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;

  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // قيم الموجات (تتغير مع الصوت)
  List<double> _waveHeights = [4, 8, 12, 16, 20, 16, 12, 8, 4];
  List<double> _currentWaveHeights = [4, 8, 12, 16, 20, 16, 12, 8, 4];

  @override
  void initState() {
    super.initState();

    // تهيئة animation controller للموجات
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _waveAnimation = Tween<double>(begin: 0, end: 1).animate(_waveController)
      ..addListener(() {
        _updateWaveHeights();
      });

    _initAudioPlayer();
  }

  void _updateWaveHeights() {
    if (_isPlaying) {
      setState(() {
        _currentWaveHeights = _waveHeights.map((height) {
          // تأثير عشوائي للموجات أثناء التشغيل
          final randomFactor = 0.7 + (0.3 * _waveAnimation.value);
          return height * randomFactor;
        }).toList();
      });
    } else {
      setState(() {
        _currentWaveHeights = _waveHeights;
      });
    }
  }

  Future<void> _initAudioPlayer() async {
    try {
      _audioPlayer.durationStream.listen((duration) {
        if (mounted) {
          setState(() {
            _duration = duration ?? Duration.zero;
          });
        }
      });

      _audioPlayer.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });

      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (mounted) {
            setState(() {
              _isPlaying = false;
              _position = Duration.zero;
              _waveController.stop();
            });
          }
          _audioPlayer.seek(Duration.zero);
        }
      });
    } catch (e) {
      print('❌ خطأ في تهيئة مشغل الصوت: $e');
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isLoading) return;

      if (_isPlaying) {
        await _audioPlayer.pause();
        setState(() {
          _isPlaying = false;
          _waveController.stop();
        });
      } else {
        setState(() {
          _isLoading = true;
        });

        if (_audioPlayer.duration == null) {
          if (widget.attachment.localPath != null) {
            await _audioPlayer.setFilePath(widget.attachment.localPath!);
          } else {
            await _audioPlayer.setUrl(widget.attachment.url);
          }
        }

        await _audioPlayer.play();
        setState(() {
          _isPlaying = true;
          _isLoading = false;
          _waveController.repeat();
        });
      }
    } catch (e) {
      print('❌ خطأ في تشغيل الصوت: $e');
      setState(() {
        _isLoading = false;
        _isPlaying = false;
        _waveController.stop();
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240, // عرض مناسب للموجات
      padding: EdgeInsets.symmetric(horizontal: ManagerWidth.w12, vertical: ManagerHeight.h8),
      decoration: BoxDecoration(
        color: widget.isMine
            ? ManagerColors.primaryColor.withOpacity(0.9)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ✅ زر التشغيل/الإيقاف
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: widget.isMine ? Colors.white : ManagerColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: _isLoading
                  ? Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.isMine ? ManagerColors.primaryColor : Colors.white,
                    ),
                  ),
                ),
              )
                  : Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                size: 16,
                color: widget.isMine ? ManagerColors.primaryColor : Colors.white,
              ),
            ),
          ),

          SizedBox(width: ManagerWidth.w8),

          // ✅ الموجات المتذبذبة
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // شريط التقدم
                Container(
                  height: 3,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: widget.isMine ? Colors.white.withOpacity(0.3) : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Stack(
                    children: [
                      // الجزء المكتمل من الشريط
                      Container(
                        height: 3,
                        width: _duration.inMilliseconds > 0
                            ? (_position.inMilliseconds / _duration.inMilliseconds) * (MediaQuery.of(context).size.width * 0.4)
                            : 0,
                        decoration: BoxDecoration(
                          color: widget.isMine ? Colors.white : ManagerColors.primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: ManagerHeight.h6),

                // الموجات الصوتية
                Container(
                  height: 24,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _currentWaveHeights.asMap().entries.map((entry) {
                      final index = entry.key;
                      final height = entry.value;

                      return AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        width: 3,
                        height: height,
                        decoration: BoxDecoration(
                          color: widget.isMine ? Colors.white : ManagerColors.primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                SizedBox(height: ManagerHeight.h4),

                // الوقت
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: TextStyle(
                        fontSize: ManagerFontSize.s12,
                        color: widget.isMine ? Colors.white.withOpacity(0.9) : Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: TextStyle(
                        fontSize: ManagerFontSize.s12,
                        color: widget.isMine ? Colors.white.withOpacity(0.7) : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(width: ManagerWidth.w8),

          // ✅ أيقونة الميكروفون
          Icon(
            Icons.mic,
            size: 18,
            color: widget.isMine ? Colors.white.withOpacity(0.8) : Colors.grey.shade600,
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      final hours = twoDigits(duration.inHours);
      return '$hours:$minutes:$seconds';
    }

    return '$minutes:$seconds';
  }
}
// // المسار: lib/features/home/group_chat/presentation/widgets/message_bubble_updated.dart
//
// import 'package:app_mobile/features/home/group_chat/domain/models/attachment_model.dart';
// import 'package:app_mobile/features/home/group_chat/domain/models/message_model.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:app_mobile/core/resources/manager_colors.dart';
// import 'package:app_mobile/core/resources/manager_font_size.dart';
// import 'package:app_mobile/core/resources/manager_height.dart';
// import 'package:app_mobile/core/resources/manager_width.dart';
// import 'package:app_mobile/core/resources/manager_styles.dart';
// import 'package:just_audio/just_audio.dart';
// import '../controller/chat_group_controller.dart';
// import 'message_image_widget.dart';
// import 'message_audio_widget.dart';
// import 'message_file_widget.dart';
// import 'message_video_widget.dart';
//
// class MessageBubble extends StatelessWidget {
//   final MessageModel message;
//   final bool isMine;
//   final VoidCallback onReply;
//   final VoidCallback? onTapStatus;
//   final List<AttachmentModel>? attachments;
//
//   const MessageBubble({
//     super.key,
//     required this.message,
//     required this.isMine,
//     required this.onReply,
//     this.onTapStatus,
//     this.attachments,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     if (message.isDeleted) {
//       return _buildDeletedMessage();
//     }
//
//     // ✅ الحل النهائي: استخراج جميع البيانات المطلوبة
//     final allAttachments = _getAllAttachments();
//     final displayContent = _getDisplayContent();
//     final hasRealContent = _hasRealContent(displayContent);
//
//     return GestureDetector(
//       onLongPress: () => _showMessageOptions(context),
//       child: Align(
//         alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
//         child: Container(
//           margin: EdgeInsets.symmetric(vertical: ManagerHeight.h6),
//           constraints: BoxConstraints(
//             maxWidth: MediaQuery.of(context).size.width * 0.75,
//           ),
//           decoration: BoxDecoration(
//             color: isMine ? ManagerColors.primaryColor : Colors.grey.shade100,
//             borderRadius: BorderRadius.only(
//               topLeft: const Radius.circular(16),
//               topRight: const Radius.circular(16),
//               bottomLeft: Radius.circular(isMine ? 16 : 4),
//               bottomRight: Radius.circular(isMine ? 4 : 16),
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.05),
//                 blurRadius: 4,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Column(
//             crossAxisAlignment:
//             isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//             children: [
//               // Reply Preview
//               if (message.replyTo != null) _buildReplyPreview(),
//
//               // ✅ الوسائط (مرة واحدة فقط)
//               if (allAttachments.isNotEmpty)
//                 _buildAttachments(allAttachments),
//
//               // ✅ المحتوى النصي (فقط إذا كان هناك نص حقيقي)
//               if (hasRealContent)
//                 Padding(
//                   padding: EdgeInsets.all(ManagerWidth.w12),
//                   child: _buildMessageContent(displayContent),
//                 ),
//
//               // Reactions
//               if (message.reactions != null && message.reactions!.isNotEmpty)
//                 _buildReactions(),
//
//               // Message Footer (Time + Status)
//               Padding(
//                 padding: EdgeInsets.only(
//                   left: ManagerWidth.w12,
//                   right: ManagerWidth.w12,
//                   bottom: ManagerHeight.h8,
//                 ),
//                 child: _buildMessageFooter(),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ================================
//   // ✅ الحل النهائي: جمع جميع الـ Attachments
//   // ================================
//   List<AttachmentModel> _getAllAttachments() {
//     final allAttachments = <AttachmentModel>[];
//
//     // إضافة الـ attachments الممررة مباشرة
//     if (attachments != null && attachments!.isNotEmpty) {
//       allAttachments.addAll(attachments!);
//     }
//
//     // استخراج الـ attachments من المحتوى النصي
//     final extractedAttachments = _extractAttachmentsFromContent();
//     allAttachments.addAll(extractedAttachments);
//
//     return allAttachments;
//   }
//
//   // ================================
//   // ✅ استخراج الـ Attachments من المحتوى
//   // ================================
//   List<AttachmentModel> _extractAttachmentsFromContent() {
//     final attachments = <AttachmentModel>[];
//     final content = message.content;
//
//     // البحث عن روابط Cloudinary
//     final cloudinaryPattern = RegExp(r'https://res\.cloudinary\.com/[^\s]+');
//     final matches = cloudinaryPattern.allMatches(content);
//
//     for (final match in matches) {
//       final url = match.group(0)!;
//       final type = _getMediaTypeFromUrl(url);
//
//       attachments.add(AttachmentModel(
//         id: '${message.id}_${attachments.length}',
//         url: url,
//         type: type,
//         fileName: _getFileNameFromUrl(url),
//         uploadProgress: 1.0,
//       ));
//     }
//
//     return attachments;
//   }
//
//   // ================================
//   // ✅ الحل النهائي: تنظيف المحتوى النصي
//   // ================================
//   String _getDisplayContent() {
//     String content = message.content;
//
//     // إذا كان هناك attachments مباشرة، نعيد المحتوى الأصلي (لأن الوسائط منفصلة)
//     if (attachments != null && attachments!.isNotEmpty) {
//       return content.trim();
//     }
//
//     // إزالة روابط Cloudinary من النص
//     final cloudinaryPattern = RegExp(r'https://res\.cloudinary\.com/[^\s]+');
//     content = content.replaceAll(cloudinaryPattern, '').trim();
//
//     // إزالة أيقونات الوسائط إذا كانت وحدها
//     final mediaIconsPattern = RegExp(r'^(📷|🎥|🎤|📎)\s*$');
//     if (mediaIconsPattern.hasMatch(content)) {
//       return '';
//     }
//
//     return content;
//   }
//
//   // ================================
//   // ✅ التحقق من وجود محتوى نصي حقيقي
//   // ================================
//   bool _hasRealContent(String content) {
//     if (content.isEmpty) return false;
//
//     // التحقق إذا كان المحتوى يحتوي فقط على مسافات أو رموز وسائط
//     final trimmedContent = content.trim();
//     if (trimmedContent.isEmpty) return false;
//
//     final mediaIconsPattern = RegExp(r'^(📷|🎥|🎤|📎)\s*$');
//     if (mediaIconsPattern.hasMatch(trimmedContent)) {
//       return false;
//     }
//
//     return true;
//   }
//
//   // ================================
//   // ✅ بناء الوسائط
//   // ================================
//   Widget _buildAttachments(List<AttachmentModel> attachments) {
//     return Padding(
//       padding: EdgeInsets.all(ManagerWidth.w8),
//       child: Column(
//         children: attachments.map((attachment) {
//           switch (attachment.type) {
//             case 'image':
//               return MessageImageWidget(
//                 attachment: attachment,
//                 isMine: isMine,
//               );
//             case 'video':
//               return MessageVideoWidget(
//                 attachment: attachment,
//                 isMine: isMine,
//               );
//             case 'audio':
//               return _buildWhatsAppVoiceMessage(attachment);
//             case 'file':
//               return MessageFileWidget(
//                 attachment: attachment,
//                 isMine: isMine,
//               );
//             default:
//               return const SizedBox.shrink();
//           }
//         }).toList(),
//       ),
//     );
//   }
//
//   // ================================
//   // ✅ تصميم الرسالة الصوتية مثل واتساب (محدث)
//   // ================================
//   Widget _buildWhatsAppVoiceMessage(AttachmentModel attachment) {
//     return Container(
//       margin: EdgeInsets.all(ManagerWidth.w8),
//       child: _WhatsAppVoiceMessagePlayer(
//         attachment: attachment,
//         isMine: isMine,
//       ),
//     );
//   }
//
//   // ================================
//   // ✅ المحتوى النصي
//   // ================================
//   Widget _buildMessageContent(String content) {
//     return Text(
//       _highlightMentions(content),
//       style: getRegularTextStyle(
//         fontSize: ManagerFontSize.s14,
//         color: isMine ? Colors.white : Colors.black87,
//       ),
//     );
//   }
//
//   // ================================
// // ✅ تحديد نوع الوسائط من الرابط (محدث)
// // ================================
//   String _getMediaTypeFromUrl(String url) {
//     final uri = Uri.parse(url);
//     final path = uri.path.toLowerCase();
//
//     // ✅ فحص المسار أولاً للتحديد الدقيق للنوع
//     if (path.contains('/image/') ||
//         path.contains('/upload/') && (
//             path.contains('.jpg') ||
//                 path.contains('.png') ||
//                 path.contains('.jpeg') ||
//                 path.contains('.webp') ||
//                 path.contains('/image/')
//         )) {
//       return 'image';
//     }
//     else if (path.contains('/video/') ||
//         path.contains('/upload/') && (
//             path.contains('.mp4') ||
//                 path.contains('.mov') ||
//                 path.contains('.avi')
//         )) {
//       return 'video';
//     }
//     else if (path.contains('/audio/') ||
//         path.contains('/upload/') && (
//             path.contains('.mp3') ||
//                 path.contains('.m4a') ||
//                 path.contains('.wav') ||
//                 path.contains('.aac')
//         )) {
//       return 'audio';
//     }
//     else if (path.contains('/file/') ||
//         path.contains('/upload/') && (
//             path.contains('.pdf') ||
//                 path.contains('.doc') ||
//                 path.contains('.docx') ||
//                 path.contains('.txt')
//         )) {
//       return 'file';
//     }
//
//     // ✅ إذا لم نتمكن من التحديد، نفحص محتوى الرسالة
//     return _getMediaTypeFromMessageContent();
//   }
// // ================================
// // ✅ تحديد النوع من محتوى الرسالة
// // ================================
//   String _getMediaTypeFromMessageContent() {
//     final content = message.content.toLowerCase();
//
//     if (content.contains('📷') || content.contains('صورة')) {
//       return 'image';
//     } else if (content.contains('🎥') || content.contains('فيديو')) {
//       return 'video';
//     } else if (content.contains('🎤') ||
//         content.contains('تسجيل صوتي') ||
//         content.contains('صوتي')) {
//       return 'audio';
//     } else if (content.contains('📎') || content.contains('ملف')) {
//       return 'file';
//     }
//
//     // ✅ الإفتراضي هو ملف إذا لم نتمكن من التحديد
//     return 'file';
//   }
//   // ================================
//   // ✅ دوال مساعدة
//   // ================================
//   String _getFileNameFromUrl(String url) {
//     final uri = Uri.parse(url);
//     final pathSegments = uri.pathSegments;
//     return pathSegments.isNotEmpty ? pathSegments.last : 'file';
//   }
//
//   String _highlightMentions(String content) {
//     // TODO: تنفيذ إبراز الإشارات
//     return content;
//   }
//
//   // ================================
//   // ✅ باقي الدوال (بدون تغيير)
//   // ================================
//   Widget _buildDeletedMessage() {
//     return Align(
//       alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: EdgeInsets.symmetric(vertical: ManagerHeight.h6),
//         padding: EdgeInsets.all(ManagerWidth.w12),
//         decoration: BoxDecoration(
//           color: Colors.grey.shade200,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(Icons.block, size: 16, color: Colors.grey.shade600),
//             SizedBox(width: ManagerWidth.w8),
//             Text(
//               'تم حذف هذه الرسالة',
//               style: getRegularTextStyle(
//                 fontSize: ManagerFontSize.s13,
//                 color: Colors.grey.shade600,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildReplyPreview() {
//     return Container(
//       margin: EdgeInsets.all(ManagerWidth.w8),
//       padding: EdgeInsets.all(ManagerWidth.w8),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(isMine ? 0.2 : 0.3),
//         borderRadius: BorderRadius.circular(8),
//         border: Border(
//           right: BorderSide(
//             color: isMine ? Colors.white : ManagerColors.primaryColor,
//             width: 3,
//           ),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(
//                 Icons.reply,
//                 size: 14,
//                 color: isMine
//                     ? Colors.white.withOpacity(0.9)
//                     : Colors.grey.shade700,
//               ),
//               SizedBox(width: ManagerWidth.w4),
//               Text(
//                 "ردًا على",
//                 style: getBoldTextStyle(
//                   fontSize: ManagerFontSize.s10,
//                   color: isMine
//                       ? Colors.white.withOpacity(0.9)
//                       : Colors.grey.shade700,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: ManagerHeight.h4),
//           Text(
//             message.replyTo ?? '',
//             style: getRegularTextStyle(
//               fontSize: ManagerFontSize.s12,
//               color: isMine
//                   ? Colors.white.withOpacity(0.8)
//                   : Colors.grey.shade600,
//             ),
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildReactions() {
//     final reactions = message.reactions!;
//     final reactionCounts = <String, int>{};
//
//     for (var emoji in reactions.values) {
//       reactionCounts[emoji.toString()] =
//           (reactionCounts[emoji.toString()] ?? 0) + 1;
//     }
//
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: ManagerWidth.w8),
//       padding: EdgeInsets.all(ManagerWidth.w6),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(isMine ? 0.2 : 0.8),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Wrap(
//         spacing: 4,
//         children: reactionCounts.entries.map((entry) {
//           return Container(
//             padding: EdgeInsets.symmetric(
//               horizontal: ManagerWidth.w6,
//               vertical: ManagerHeight.h2,
//             ),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.3),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(entry.key, style: const TextStyle(fontSize: 14)),
//                 if (entry.value > 1) ...[
//                   SizedBox(width: ManagerWidth.w2),
//                   Text(
//                     '${entry.value}',
//                     style: getBoldTextStyle(
//                       fontSize: ManagerFontSize.s10,
//                       color: isMine ? Colors.white : Colors.black87,
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }
//
//   Widget _buildMessageFooter() {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Text(
//           _formatTime(message.timestamp),
//           style: getRegularTextStyle(
//             fontSize: ManagerFontSize.s10,
//             color: isMine ? Colors.white.withOpacity(0.7) : Colors.grey,
//           ),
//         ),
//         if (isMine) ...[
//           SizedBox(width: ManagerWidth.w4),
//           GestureDetector(
//             onTap: onTapStatus,
//             child: _buildStatusIcon(),
//           ),
//         ],
//       ],
//     );
//   }
//
//   Widget _buildStatusIcon() {
//     IconData icon;
//     Color color;
//
//     if (message.isFailed) {
//       icon = Icons.error_outline;
//       color = Colors.red.shade300;
//     } else if (message.isFullySeen) {
//       icon = Icons.done_all;
//       color = Colors.blue.shade200;
//     } else if (message.isSeen) {
//       icon = Icons.done_all;
//       color = Colors.blue.shade200;
//     } else if (message.isFullyDelivered) {
//       icon = Icons.done_all;
//       color = Colors.white.withOpacity(0.7);
//     } else if (message.isDelivered) {
//       icon = Icons.done_all;
//       color = Colors.white.withOpacity(0.7);
//     } else {
//       icon = Icons.done;
//       color = Colors.white.withOpacity(0.7);
//     }
//
//     return Icon(
//       icon,
//       size: 16,
//       color: color,
//     );
//   }
//
//   void _showMessageOptions(BuildContext context) {
//     final controller = ChatGroupController.to;
//
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => SafeArea(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               margin: EdgeInsets.only(top: ManagerHeight.h8),
//               width: 40,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade300,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//             ListTile(
//               leading: Icon(Icons.reply, color: ManagerColors.primaryColor),
//               title: Text(
//                 'الرد على الرسالة',
//                 style: getRegularTextStyle(
//                   fontSize: ManagerFontSize.s14,
//                   color: Colors.black,
//                 ),
//               ),
//               onTap: () {
//                 Navigator.pop(context);
//                 onReply();
//               },
//             ),
//             ListTile(
//               leading: Icon(Icons.add_reaction, color: ManagerColors.primaryColor),
//               title: Text(
//                 'إضافة تفاعل',
//                 style: getRegularTextStyle(
//                   fontSize: ManagerFontSize.s14,
//                   color: Colors.black,
//                 ),
//               ),
//               onTap: () {
//                 Navigator.pop(context);
//                 _showReactionPicker(context);
//               },
//             ),
//             if (isMine && onTapStatus != null)
//               ListTile(
//                 leading: Icon(Icons.info_outline, color: ManagerColors.primaryColor),
//                 title: Text(
//                   'حالة الرسالة',
//                   style: getRegularTextStyle(
//                     fontSize: ManagerFontSize.s14,
//                     color: Colors.black,
//                   ),
//                 ),
//                 onTap: () {
//                   Navigator.pop(context);
//                   onTapStatus!();
//                 },
//               ),
//             ListTile(
//               leading: Icon(Icons.copy, color: ManagerColors.primaryColor),
//               title: Text(
//                 'نسخ النص',
//                 style: getRegularTextStyle(
//                   fontSize: ManagerFontSize.s14,
//                   color: Colors.black,
//                 ),
//               ),
//               onTap: () {
//                 Navigator.pop(context);
//                 Clipboard.setData(ClipboardData(text: message.content));
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text('تم نسخ النص'),
//                     duration: Duration(seconds: 1),
//                   ),
//                 );
//               },
//             ),
//             if (controller.canDeleteMessage(message))
//               ListTile(
//                 leading: const Icon(Icons.delete, color: Colors.red),
//                 title: Text(
//                   'حذف الرسالة',
//                   style: getRegularTextStyle(
//                     fontSize: ManagerFontSize.s14,
//                     color: Colors.red,
//                   ),
//                 ),
//                 onTap: () {
//                   Navigator.pop(context);
//                   _confirmDelete(context);
//                 },
//               ),
//             SizedBox(height: ManagerHeight.h8),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showReactionPicker(BuildContext context) {
//     final controller = ChatGroupController.to;
//     final reactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
//
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => Container(
//         padding: EdgeInsets.all(ManagerWidth.w20),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               'اختر تفاعلك',
//               style: getBoldTextStyle(
//                 fontSize: ManagerFontSize.s16,
//                 color: Colors.black,
//               ),
//             ),
//             SizedBox(height: ManagerHeight.h20),
//             Wrap(
//               spacing: 16,
//               runSpacing: 16,
//               children: reactions.map((emoji) {
//                 return GestureDetector(
//                   onTap: () {
//                     Navigator.pop(context);
//                     controller.addReaction(message, emoji);
//                   },
//                   child: Container(
//                     width: 50,
//                     height: 50,
//                     decoration: BoxDecoration(
//                       color: Colors.grey.shade100,
//                       borderRadius: BorderRadius.circular(25),
//                     ),
//                     child: Center(
//                       child: Text(
//                         emoji,
//                         style: const TextStyle(fontSize: 28),
//                       ),
//                     ),
//                   ),
//                 );
//               }).toList(),
//             ),
//             SizedBox(height: ManagerHeight.h20),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _confirmDelete(BuildContext context) {
//     final controller = ChatGroupController.to;
//
//     Get.dialog(
//       AlertDialog(
//         title: const Text('حذف الرسالة'),
//         content: const Text('هل أنت متأكد من حذف هذه الرسالة؟'),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(),
//             child: const Text('إلغاء'),
//           ),
//           TextButton(
//             onPressed: () {
//               Get.back();
//               controller.deleteMessage(message);
//             },
//             style: TextButton.styleFrom(foregroundColor: Colors.red),
//             child: const Text('حذف'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   String _formatTime(DateTime time) {
//     final hour = time.hour.toString().padLeft(2, '0');
//     final minute = time.minute.toString().padLeft(2, '0');
//     return "$hour:$minute";
//   }
// }
//
// // ================================
// // ✅ مشغل الرسائل الصوتية بتصميم واتساب مع الموجات المتذبذبة
// // ================================
// class _WhatsAppVoiceMessagePlayer extends StatefulWidget {
//   final AttachmentModel attachment;
//   final bool isMine;
//
//   const _WhatsAppVoiceMessagePlayer({
//     required this.attachment,
//     required this.isMine,
//   });
//
//   @override
//   State<_WhatsAppVoiceMessagePlayer> createState() => __WhatsAppVoiceMessagePlayerState();
// }
//
// class __WhatsAppVoiceMessagePlayerState extends State<_WhatsAppVoiceMessagePlayer>
//     with SingleTickerProviderStateMixin {
//   final AudioPlayer _audioPlayer = AudioPlayer();
//   late AnimationController _waveController;
//   late Animation<double> _waveAnimation;
//
//   bool _isPlaying = false;
//   bool _isLoading = false;
//   Duration _duration = Duration.zero;
//   Duration _position = Duration.zero;
//
//   // قيم الموجات (تتغير مع الصوت)
//   List<double> _waveHeights = [4, 8, 12, 16, 20, 16, 12, 8, 4];
//   List<double> _currentWaveHeights = [4, 8, 12, 16, 20, 16, 12, 8, 4];
//
//   @override
//   void initState() {
//     super.initState();
//
//     // تهيئة animation controller للموجات
//     _waveController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 800),
//     );
//
//     _waveAnimation = Tween<double>(begin: 0, end: 1).animate(_waveController)
//       ..addListener(() {
//         _updateWaveHeights();
//       });
//
//     _initAudioPlayer();
//   }
//
//   void _updateWaveHeights() {
//     if (_isPlaying) {
//       setState(() {
//         _currentWaveHeights = _waveHeights.map((height) {
//           // تأثير عشوائي للموجات أثناء التشغيل
//           final randomFactor = 0.7 + (0.3 * _waveAnimation.value);
//           return height * randomFactor;
//         }).toList();
//       });
//     } else {
//       setState(() {
//         _currentWaveHeights = _waveHeights;
//       });
//     }
//   }
//
//   Future<void> _initAudioPlayer() async {
//     try {
//       _audioPlayer.durationStream.listen((duration) {
//         if (mounted) {
//           setState(() {
//             _duration = duration ?? Duration.zero;
//           });
//         }
//       });
//
//       _audioPlayer.positionStream.listen((position) {
//         if (mounted) {
//           setState(() {
//             _position = position;
//           });
//         }
//       });
//
//       _audioPlayer.playerStateStream.listen((state) {
//         if (state.processingState == ProcessingState.completed) {
//           if (mounted) {
//             setState(() {
//               _isPlaying = false;
//               _position = Duration.zero;
//               _waveController.stop();
//             });
//           }
//           _audioPlayer.seek(Duration.zero);
//         }
//       });
//     } catch (e) {
//       print('❌ خطأ في تهيئة مشغل الصوت: $e');
//     }
//   }
//
//   Future<void> _togglePlayPause() async {
//     try {
//       if (_isLoading) return;
//
//       if (_isPlaying) {
//         await _audioPlayer.pause();
//         setState(() {
//           _isPlaying = false;
//           _waveController.stop();
//         });
//       } else {
//         setState(() {
//           _isLoading = true;
//         });
//
//         if (_audioPlayer.duration == null) {
//           if (widget.attachment.localPath != null) {
//             await _audioPlayer.setFilePath(widget.attachment.localPath!);
//           } else {
//             await _audioPlayer.setUrl(widget.attachment.url);
//           }
//         }
//
//         await _audioPlayer.play();
//         setState(() {
//           _isPlaying = true;
//           _isLoading = false;
//           _waveController.repeat();
//         });
//       }
//     } catch (e) {
//       print('❌ خطأ في تشغيل الصوت: $e');
//       setState(() {
//         _isLoading = false;
//         _isPlaying = false;
//         _waveController.stop();
//       });
//     }
//   }
//
//   @override
//   void dispose() {
//     _audioPlayer.dispose();
//     _waveController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 240, // عرض مناسب للموجات
//       padding: EdgeInsets.symmetric(horizontal: ManagerWidth.w12, vertical: ManagerHeight.h8),
//       decoration: BoxDecoration(
//         color: widget.isMine
//             ? ManagerColors.primaryColor.withOpacity(0.9)
//             : Colors.grey.shade200,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           // ✅ زر التشغيل/الإيقاف
//           GestureDetector(
//             onTap: _togglePlayPause,
//             child: Container(
//               width: 28,
//               height: 28,
//               decoration: BoxDecoration(
//                 color: widget.isMine ? Colors.white : ManagerColors.primaryColor,
//                 shape: BoxShape.circle,
//               ),
//               child: _isLoading
//                   ? Center(
//                 child: SizedBox(
//                   width: 14,
//                   height: 14,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     valueColor: AlwaysStoppedAnimation<Color>(
//                       widget.isMine ? ManagerColors.primaryColor : Colors.white,
//                     ),
//                   ),
//                 ),
//               )
//                   : Icon(
//                 _isPlaying ? Icons.pause : Icons.play_arrow,
//                 size: 16,
//                 color: widget.isMine ? ManagerColors.primaryColor : Colors.white,
//               ),
//             ),
//           ),
//
//           SizedBox(width: ManagerWidth.w8),
//
//           // ✅ الموجات المتذبذبة
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // شريط التقدم
//                 Container(
//                   height: 3,
//                   width: double.infinity,
//                   decoration: BoxDecoration(
//                     color: widget.isMine ? Colors.white.withOpacity(0.3) : Colors.grey.shade400,
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                   child: Stack(
//                     children: [
//                       // الجزء المكتمل من الشريط
//                       Container(
//                         height: 3,
//                         width: _duration.inMilliseconds > 0
//                             ? (_position.inMilliseconds / _duration.inMilliseconds) * (MediaQuery.of(context).size.width * 0.4)
//                             : 0,
//                         decoration: BoxDecoration(
//                           color: widget.isMine ? Colors.white : ManagerColors.primaryColor,
//                           borderRadius: BorderRadius.circular(2),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 SizedBox(height: ManagerHeight.h6),
//
//                 // الموجات الصوتية
//                 Container(
//                   height: 24,
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceAround,
//                     children: _currentWaveHeights.asMap().entries.map((entry) {
//                       final index = entry.key;
//                       final height = entry.value;
//
//                       return AnimatedContainer(
//                         duration: Duration(milliseconds: 200),
//                         width: 3,
//                         height: height,
//                         decoration: BoxDecoration(
//                           color: widget.isMine ? Colors.white : ManagerColors.primaryColor,
//                           borderRadius: BorderRadius.circular(2),
//                         ),
//                       );
//                     }).toList(),
//                   ),
//                 ),
//
//                 SizedBox(height: ManagerHeight.h4),
//
//                 // الوقت
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       _formatDuration(_position),
//                       style: TextStyle(
//                         fontSize: ManagerFontSize.s12,
//                         color: widget.isMine ? Colors.white.withOpacity(0.9) : Colors.grey.shade700,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     Text(
//                       _formatDuration(_duration),
//                       style: TextStyle(
//                         fontSize: ManagerFontSize.s12,
//                         color: widget.isMine ? Colors.white.withOpacity(0.7) : Colors.grey.shade500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//
//           SizedBox(width: ManagerWidth.w8),
//
//           // ✅ أيقونة الميكروفون
//           Icon(
//             Icons.mic,
//             size: 18,
//             color: widget.isMine ? Colors.white.withOpacity(0.8) : Colors.grey.shade600,
//           ),
//         ],
//       ),
//     );
//   }
//
//   String _formatDuration(Duration duration) {
//     String twoDigits(int n) => n.toString().padLeft(2, '0');
//     final minutes = twoDigits(duration.inMinutes.remainder(60));
//     final seconds = twoDigits(duration.inSeconds.remainder(60));
//
//     if (duration.inHours > 0) {
//       final hours = twoDigits(duration.inHours);
//       return '$hours:$minutes:$seconds';
//     }
//
//     return '$minutes:$seconds';
//   }
// }
// // المسار: lib/features/home/group_chat/presentation/widgets/message_bubble_updated.dart
//
// import 'package:app_mobile/features/home/group_chat/domain/models/attachment_model.dart';
// import 'package:app_mobile/features/home/group_chat/domain/models/message_model.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:app_mobile/core/resources/manager_colors.dart';
// import 'package:app_mobile/core/resources/manager_font_size.dart';
// import 'package:app_mobile/core/resources/manager_height.dart';
// import 'package:app_mobile/core/resources/manager_width.dart';
// import 'package:app_mobile/core/resources/manager_styles.dart';
// import 'package:just_audio/just_audio.dart';
// import '../controller/chat_group_controller.dart';
// import 'message_image_widget.dart';
// import 'message_audio_widget.dart';
// import 'message_file_widget.dart';
// import 'message_video_widget.dart';
//
// class MessageBubble extends StatelessWidget {
//   final MessageModel message;
//   final bool isMine;
//   final VoidCallback onReply;
//   final VoidCallback? onTapStatus;
//   final List<AttachmentModel>? attachments;
//
//   const MessageBubble({
//     super.key,
//     required this.message,
//     required this.isMine,
//     required this.onReply,
//     this.onTapStatus,
//     this.attachments,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     if (message.isDeleted) {
//       return _buildDeletedMessage();
//     }
//
//     // ✅ الحل النهائي: استخراج جميع البيانات المطلوبة
//     final allAttachments = _getAllAttachments();
//     final displayContent = _getDisplayContent();
//     final hasRealContent = _hasRealContent(displayContent);
//
//     return GestureDetector(
//       onLongPress: () => _showMessageOptions(context),
//       child: Align(
//         alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
//         child: Container(
//           margin: EdgeInsets.symmetric(vertical: ManagerHeight.h6),
//           constraints: BoxConstraints(
//             maxWidth: MediaQuery.of(context).size.width * 0.75,
//           ),
//           decoration: BoxDecoration(
//             color: isMine ? ManagerColors.primaryColor : Colors.grey.shade100,
//             borderRadius: BorderRadius.only(
//               topLeft: const Radius.circular(16),
//               topRight: const Radius.circular(16),
//               bottomLeft: Radius.circular(isMine ? 16 : 4),
//               bottomRight: Radius.circular(isMine ? 4 : 16),
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.05),
//                 blurRadius: 4,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Column(
//             crossAxisAlignment:
//             isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//             children: [
//               // Reply Preview
//               if (message.replyTo != null) _buildReplyPreview(),
//
//               // ✅ الوسائط (مرة واحدة فقط)
//               if (allAttachments.isNotEmpty)
//                 _buildAttachments(allAttachments),
//
//               // ✅ المحتوى النصي (فقط إذا كان هناك نص حقيقي)
//               if (hasRealContent)
//                 Padding(
//                   padding: EdgeInsets.all(ManagerWidth.w12),
//                   child: _buildMessageContent(displayContent),
//                 ),
//
//               // Reactions
//               if (message.reactions != null && message.reactions!.isNotEmpty)
//                 _buildReactions(),
//
//               // Message Footer (Time + Status)
//               Padding(
//                 padding: EdgeInsets.only(
//                   left: ManagerWidth.w12,
//                   right: ManagerWidth.w12,
//                   bottom: ManagerHeight.h8,
//                 ),
//                 child: _buildMessageFooter(),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ================================
//   // ✅ الحل النهائي: جمع جميع الـ Attachments
//   // ================================
//   List<AttachmentModel> _getAllAttachments() {
//     final allAttachments = <AttachmentModel>[];
//
//     // إضافة الـ attachments الممررة مباشرة
//     if (attachments != null && attachments!.isNotEmpty) {
//       allAttachments.addAll(attachments!);
//     }
//
//     // استخراج الـ attachments من المحتوى النصي
//     final extractedAttachments = _extractAttachmentsFromContent();
//     allAttachments.addAll(extractedAttachments);
//
//     return allAttachments;
//   }
//
//   // ================================
//   // ✅ استخراج الـ Attachments من المحتوى
//   // ================================
//   List<AttachmentModel> _extractAttachmentsFromContent() {
//     final attachments = <AttachmentModel>[];
//     final content = message.content;
//
//     // البحث عن روابط Cloudinary
//     final cloudinaryPattern = RegExp(r'https://res\.cloudinary\.com/[^\s]+');
//     final matches = cloudinaryPattern.allMatches(content);
//
//     for (final match in matches) {
//       final url = match.group(0)!;
//       final type = _getMediaTypeFromUrl(url);
//
//       attachments.add(AttachmentModel(
//         id: '${message.id}_${attachments.length}',
//         url: url,
//         type: type,
//         fileName: _getFileNameFromUrl(url),
//         uploadProgress: 1.0,
//       ));
//     }
//
//     return attachments;
//   }
//
//   // ================================
//   // ✅ الحل النهائي: تنظيف المحتوى النصي
//   // ================================
//   String _getDisplayContent() {
//     String content = message.content;
//
//     // إذا كان هناك attachments مباشرة، نعيد المحتوى الأصلي (لأن الوسائط منفصلة)
//     if (attachments != null && attachments!.isNotEmpty) {
//       return content.trim();
//     }
//
//     // إزالة روابط Cloudinary من النص
//     final cloudinaryPattern = RegExp(r'https://res\.cloudinary\.com/[^\s]+');
//     content = content.replaceAll(cloudinaryPattern, '').trim();
//
//     // إزالة أيقونات الوسائط إذا كانت وحدها
//     final mediaIconsPattern = RegExp(r'^(📷|🎥|🎤|📎)\s*$');
//     if (mediaIconsPattern.hasMatch(content)) {
//       return '';
//     }
//
//     return content;
//   }
//
//   // ================================
//   // ✅ التحقق من وجود محتوى نصي حقيقي
//   // ================================
//   bool _hasRealContent(String content) {
//     if (content.isEmpty) return false;
//
//     // التحقق إذا كان المحتوى يحتوي فقط على مسافات أو رموز وسائط
//     final trimmedContent = content.trim();
//     if (trimmedContent.isEmpty) return false;
//
//     final mediaIconsPattern = RegExp(r'^(📷|🎥|🎤|📎)\s*$');
//     if (mediaIconsPattern.hasMatch(trimmedContent)) {
//       return false;
//     }
//
//     return true;
//   }
//
//   // ================================
//   // ✅ بناء الوسائط
//   // ================================
//   Widget _buildAttachments(List<AttachmentModel> attachments) {
//     return Padding(
//       padding: EdgeInsets.all(ManagerWidth.w8),
//       child: Column(
//         children: attachments.map((attachment) {
//           switch (attachment.type) {
//             case 'image':
//               return MessageImageWidget(
//                 attachment: attachment,
//                 isMine: isMine,
//               );
//             case 'video':
//               return MessageVideoWidget(
//                 attachment: attachment,
//                 isMine: isMine,
//               );
//             case 'audio':
//               return _buildWhatsAppVoiceMessage(attachment);
//             case 'file':
//               return MessageFileWidget(
//                 attachment: attachment,
//                 isMine: isMine,
//               );
//             default:
//               return const SizedBox.shrink();
//           }
//         }).toList(),
//       ),
//     );
//   }
//
//   // ================================
//   // ✅ تصميم الرسالة الصوتية مثل واتساب (محدث)
//   // ================================
//   Widget _buildWhatsAppVoiceMessage(AttachmentModel attachment) {
//     return Container(
//       margin: EdgeInsets.all(ManagerWidth.w8),
//       child: _WhatsAppVoiceMessagePlayer(
//         attachment: attachment,
//         isMine: isMine,
//       ),
//     );
//   }
//
//   // ================================
//   // ✅ المحتوى النصي
//   // ================================
//   Widget _buildMessageContent(String content) {
//     return Text(
//       _highlightMentions(content),
//       style: getRegularTextStyle(
//         fontSize: ManagerFontSize.s14,
//         color: isMine ? Colors.white : Colors.black87,
//       ),
//     );
//   }
//
//   // ================================
//   // ✅ تحديد نوع الوسائط من الرابط
//   // ================================
//   String _getMediaTypeFromUrl(String url) {
//     if (url.contains('/image/') ||
//         url.contains('.jpg') ||
//         url.contains('.png') ||
//         url.contains('.jpeg') ||
//         url.contains('.webp')) {
//       return 'image';
//     } else if (url.contains('/video/') ||
//         url.contains('.mp4') ||
//         url.contains('.mov') ||
//         url.contains('.avi')) {
//       return 'video';
//     } else if (url.contains('/audio/') ||
//         url.contains('.mp3') ||
//         url.contains('.m4a') ||
//         url.contains('.wav')) {
//       return 'audio';
//     } else {
//       return 'file';
//     }
//   }
//
//   // ================================
//   // ✅ دوال مساعدة
//   // ================================
//   String _getFileNameFromUrl(String url) {
//     final uri = Uri.parse(url);
//     final pathSegments = uri.pathSegments;
//     return pathSegments.isNotEmpty ? pathSegments.last : 'file';
//   }
//
//   String _highlightMentions(String content) {
//     // TODO: تنفيذ إبراز الإشارات
//     return content;
//   }
//
//   // ================================
//   // ✅ باقي الدوال (بدون تغيير)
//   // ================================
//   Widget _buildDeletedMessage() {
//     return Align(
//       alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: EdgeInsets.symmetric(vertical: ManagerHeight.h6),
//         padding: EdgeInsets.all(ManagerWidth.w12),
//         decoration: BoxDecoration(
//           color: Colors.grey.shade200,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(Icons.block, size: 16, color: Colors.grey.shade600),
//             SizedBox(width: ManagerWidth.w8),
//             Text(
//               'تم حذف هذه الرسالة',
//               style: getRegularTextStyle(
//                 fontSize: ManagerFontSize.s13,
//                 color: Colors.grey.shade600,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildReplyPreview() {
//     return Container(
//       margin: EdgeInsets.all(ManagerWidth.w8),
//       padding: EdgeInsets.all(ManagerWidth.w8),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(isMine ? 0.2 : 0.3),
//         borderRadius: BorderRadius.circular(8),
//         border: Border(
//           right: BorderSide(
//             color: isMine ? Colors.white : ManagerColors.primaryColor,
//             width: 3,
//           ),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(
//                 Icons.reply,
//                 size: 14,
//                 color: isMine
//                     ? Colors.white.withOpacity(0.9)
//                     : Colors.grey.shade700,
//               ),
//               SizedBox(width: ManagerWidth.w4),
//               Text(
//                 "ردًا على",
//                 style: getBoldTextStyle(
//                   fontSize: ManagerFontSize.s10,
//                   color: isMine
//                       ? Colors.white.withOpacity(0.9)
//                       : Colors.grey.shade700,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: ManagerHeight.h4),
//           Text(
//             message.replyTo ?? '',
//             style: getRegularTextStyle(
//               fontSize: ManagerFontSize.s12,
//               color: isMine
//                   ? Colors.white.withOpacity(0.8)
//                   : Colors.grey.shade600,
//             ),
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildReactions() {
//     final reactions = message.reactions!;
//     final reactionCounts = <String, int>{};
//
//     for (var emoji in reactions.values) {
//       reactionCounts[emoji.toString()] =
//           (reactionCounts[emoji.toString()] ?? 0) + 1;
//     }
//
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: ManagerWidth.w8),
//       padding: EdgeInsets.all(ManagerWidth.w6),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(isMine ? 0.2 : 0.8),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Wrap(
//         spacing: 4,
//         children: reactionCounts.entries.map((entry) {
//           return Container(
//             padding: EdgeInsets.symmetric(
//               horizontal: ManagerWidth.w6,
//               vertical: ManagerHeight.h2,
//             ),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.3),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(entry.key, style: const TextStyle(fontSize: 14)),
//                 if (entry.value > 1) ...[
//                   SizedBox(width: ManagerWidth.w2),
//                   Text(
//                     '${entry.value}',
//                     style: getBoldTextStyle(
//                       fontSize: ManagerFontSize.s10,
//                       color: isMine ? Colors.white : Colors.black87,
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }
//
//   Widget _buildMessageFooter() {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Text(
//           _formatTime(message.timestamp),
//           style: getRegularTextStyle(
//             fontSize: ManagerFontSize.s10,
//             color: isMine ? Colors.white.withOpacity(0.7) : Colors.grey,
//           ),
//         ),
//         if (isMine) ...[
//           SizedBox(width: ManagerWidth.w4),
//           GestureDetector(
//             onTap: onTapStatus,
//             child: _buildStatusIcon(),
//           ),
//         ],
//       ],
//     );
//   }
//
//   Widget _buildStatusIcon() {
//     IconData icon;
//     Color color;
//
//     if (message.isFailed) {
//       icon = Icons.error_outline;
//       color = Colors.red.shade300;
//     } else if (message.isFullySeen) {
//       icon = Icons.done_all;
//       color = Colors.blue.shade200;
//     } else if (message.isSeen) {
//       icon = Icons.done_all;
//       color = Colors.blue.shade200;
//     } else if (message.isFullyDelivered) {
//       icon = Icons.done_all;
//       color = Colors.white.withOpacity(0.7);
//     } else if (message.isDelivered) {
//       icon = Icons.done_all;
//       color = Colors.white.withOpacity(0.7);
//     } else {
//       icon = Icons.done;
//       color = Colors.white.withOpacity(0.7);
//     }
//
//     return Icon(
//       icon,
//       size: 16,
//       color: color,
//     );
//   }
//
//   void _showMessageOptions(BuildContext context) {
//     final controller = ChatGroupController.to;
//
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => SafeArea(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               margin: EdgeInsets.only(top: ManagerHeight.h8),
//               width: 40,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade300,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//             ListTile(
//               leading: Icon(Icons.reply, color: ManagerColors.primaryColor),
//               title: Text(
//                 'الرد على الرسالة',
//                 style: getRegularTextStyle(
//                   fontSize: ManagerFontSize.s14,
//                   color: Colors.black,
//                 ),
//               ),
//               onTap: () {
//                 Navigator.pop(context);
//                 onReply();
//               },
//             ),
//             ListTile(
//               leading: Icon(Icons.add_reaction, color: ManagerColors.primaryColor),
//               title: Text(
//                 'إضافة تفاعل',
//                 style: getRegularTextStyle(
//                   fontSize: ManagerFontSize.s14,
//                   color: Colors.black,
//                 ),
//               ),
//               onTap: () {
//                 Navigator.pop(context);
//                 _showReactionPicker(context);
//               },
//             ),
//             if (isMine && onTapStatus != null)
//               ListTile(
//                 leading: Icon(Icons.info_outline, color: ManagerColors.primaryColor),
//                 title: Text(
//                   'حالة الرسالة',
//                   style: getRegularTextStyle(
//                     fontSize: ManagerFontSize.s14,
//                     color: Colors.black,
//                   ),
//                 ),
//                 onTap: () {
//                   Navigator.pop(context);
//                   onTapStatus!();
//                 },
//               ),
//             ListTile(
//               leading: Icon(Icons.copy, color: ManagerColors.primaryColor),
//               title: Text(
//                 'نسخ النص',
//                 style: getRegularTextStyle(
//                   fontSize: ManagerFontSize.s14,
//                   color: Colors.black,
//                 ),
//               ),
//               onTap: () {
//                 Navigator.pop(context);
//                 Clipboard.setData(ClipboardData(text: message.content));
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text('تم نسخ النص'),
//                     duration: Duration(seconds: 1),
//                   ),
//                 );
//               },
//             ),
//             if (controller.canDeleteMessage(message))
//               ListTile(
//                 leading: const Icon(Icons.delete, color: Colors.red),
//                 title: Text(
//                   'حذف الرسالة',
//                   style: getRegularTextStyle(
//                     fontSize: ManagerFontSize.s14,
//                     color: Colors.red,
//                   ),
//                 ),
//                 onTap: () {
//                   Navigator.pop(context);
//                   _confirmDelete(context);
//                 },
//               ),
//             SizedBox(height: ManagerHeight.h8),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showReactionPicker(BuildContext context) {
//     final controller = ChatGroupController.to;
//     final reactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
//
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => Container(
//         padding: EdgeInsets.all(ManagerWidth.w20),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               'اختر تفاعلك',
//               style: getBoldTextStyle(
//                 fontSize: ManagerFontSize.s16,
//                 color: Colors.black,
//               ),
//             ),
//             SizedBox(height: ManagerHeight.h20),
//             Wrap(
//               spacing: 16,
//               runSpacing: 16,
//               children: reactions.map((emoji) {
//                 return GestureDetector(
//                   onTap: () {
//                     Navigator.pop(context);
//                     controller.addReaction(message, emoji);
//                   },
//                   child: Container(
//                     width: 50,
//                     height: 50,
//                     decoration: BoxDecoration(
//                       color: Colors.grey.shade100,
//                       borderRadius: BorderRadius.circular(25),
//                     ),
//                     child: Center(
//                       child: Text(
//                         emoji,
//                         style: const TextStyle(fontSize: 28),
//                       ),
//                     ),
//                   ),
//                 );
//               }).toList(),
//             ),
//             SizedBox(height: ManagerHeight.h20),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _confirmDelete(BuildContext context) {
//     final controller = ChatGroupController.to;
//
//     Get.dialog(
//       AlertDialog(
//         title: const Text('حذف الرسالة'),
//         content: const Text('هل أنت متأكد من حذف هذه الرسالة؟'),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(),
//             child: const Text('إلغاء'),
//           ),
//           TextButton(
//             onPressed: () {
//               Get.back();
//               controller.deleteMessage(message);
//             },
//             style: TextButton.styleFrom(foregroundColor: Colors.red),
//             child: const Text('حذف'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   String _formatTime(DateTime time) {
//     final hour = time.hour.toString().padLeft(2, '0');
//     final minute = time.minute.toString().padLeft(2, '0');
//     return "$hour:$minute";
//   }
// }
//
// // ================================
// // ✅ مشغل الرسائل الصوتية بتصميم واتساب (محدث)
// // ================================
// class _WhatsAppVoiceMessagePlayer extends StatefulWidget {
//   final AttachmentModel attachment;
//   final bool isMine;
//
//   const _WhatsAppVoiceMessagePlayer({
//     required this.attachment,
//     required this.isMine,
//   });
//
//   @override
//   State<_WhatsAppVoiceMessagePlayer> createState() => __WhatsAppVoiceMessagePlayerState();
// }
//
// class __WhatsAppVoiceMessagePlayerState extends State<_WhatsAppVoiceMessagePlayer> {
//   final AudioPlayer _audioPlayer = AudioPlayer();
//   bool _isPlaying = false;
//   bool _isLoading = false;
//   Duration _duration = Duration.zero;
//   Duration _position = Duration.zero;
//
//   @override
//   void initState() {
//     super.initState();
//     _initAudioPlayer();
//   }
//
//   Future<void> _initAudioPlayer() async {
//     try {
//       _audioPlayer.durationStream.listen((duration) {
//         if (mounted) {
//           setState(() {
//             _duration = duration ?? Duration.zero;
//           });
//         }
//       });
//
//       _audioPlayer.positionStream.listen((position) {
//         if (mounted) {
//           setState(() {
//             _position = position;
//           });
//         }
//       });
//
//       _audioPlayer.playerStateStream.listen((state) {
//         if (state.processingState == ProcessingState.completed) {
//           if (mounted) {
//             setState(() {
//               _isPlaying = false;
//               _position = Duration.zero;
//             });
//           }
//           _audioPlayer.seek(Duration.zero);
//         }
//       });
//     } catch (e) {
//       print('❌ خطأ في تهيئة مشغل الصوت: $e');
//     }
//   }
//
//   Future<void> _togglePlayPause() async {
//     try {
//       if (_isLoading) return;
//
//       if (_isPlaying) {
//         await _audioPlayer.pause();
//         setState(() {
//           _isPlaying = false;
//         });
//       } else {
//         setState(() {
//           _isLoading = true;
//         });
//
//         if (_audioPlayer.duration == null) {
//           if (widget.attachment.localPath != null) {
//             await _audioPlayer.setFilePath(widget.attachment.localPath!);
//           } else {
//             await _audioPlayer.setUrl(widget.attachment.url);
//           }
//         }
//
//         await _audioPlayer.play();
//         setState(() {
//           _isPlaying = true;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       print('❌ خطأ في تشغيل الصوت: $e');
//       setState(() {
//         _isLoading = false;
//         _isPlaying = false;
//       });
//     }
//   }
//
//   @override
//   void dispose() {
//     _audioPlayer.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 220, // عرض ثابت يشبه واتساب
//       padding: EdgeInsets.symmetric(horizontal: ManagerWidth.w12, vertical: ManagerHeight.h8),
//       decoration: BoxDecoration(
//         color: widget.isMine
//             ? ManagerColors.primaryColor.withOpacity(0.9)
//             : Colors.grey.shade200,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           // ✅ زر التشغيل/الإيقاف مع الرمز
//           GestureDetector(
//             onTap: _togglePlayPause,
//             child: Container(
//               width: 28,
//               height: 28,
//               decoration: BoxDecoration(
//                 color: widget.isMine ? Colors.white : ManagerColors.primaryColor,
//                 shape: BoxShape.circle,
//               ),
//               child: _isLoading
//                   ? Center(
//                 child: SizedBox(
//                   width: 14,
//                   height: 14,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     valueColor: AlwaysStoppedAnimation<Color>(
//                       widget.isMine ? ManagerColors.primaryColor : Colors.white,
//                     ),
//                   ),
//                 ),
//               )
//                   : Icon(
//                 _isPlaying ? Icons.pause : Icons.play_arrow,
//                 size: 16,
//                 color: widget.isMine ? ManagerColors.primaryColor : Colors.white,
//               ),
//             ),
//           ),
//
//           // ✅ شريط التقدم (مبسط)
//           Expanded(
//             child: Padding(
//               padding: EdgeInsets.symmetric(horizontal: ManagerWidth.w8),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // شريط التقدم المبسط
//                   Container(
//                     height: 3,
//                     width: double.infinity,
//                     decoration: BoxDecoration(
//                       color: widget.isMine ? Colors.white.withOpacity(0.3) : Colors.grey.shade400,
//                       borderRadius: BorderRadius.circular(2),
//                     ),
//                     child: Stack(
//                       children: [
//                         // الجزء المكتمل من الشريط
//                         Container(
//                           height: 3,
//                           width: _duration.inMilliseconds > 0
//                               ? (_position.inMilliseconds / _duration.inMilliseconds) * MediaQuery.of(context).size.width * 0.5
//                               : 0,
//                           decoration: BoxDecoration(
//                             color: widget.isMine ? Colors.white : ManagerColors.primaryColor,
//                             borderRadius: BorderRadius.circular(2),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   SizedBox(height: ManagerHeight.h4),
//
//                   // الوقت
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         _formatDuration(_position),
//                         style: TextStyle(
//                           fontSize: ManagerFontSize.s12,
//                           color: widget.isMine ? Colors.white.withOpacity(0.8) : Colors.grey.shade700,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       Text(
//                         _formatDuration(_duration),
//                         style: TextStyle(
//                           fontSize: ManagerFontSize.s12,
//                           color: widget.isMine ? Colors.white.withOpacity(0.6) : Colors.grey.shade500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           // ✅ أيقونة الميكروفون
//           Icon(
//             Icons.mic,
//             size: 18,
//             color: widget.isMine ? Colors.white.withOpacity(0.7) : Colors.grey.shade600,
//           ),
//         ],
//       ),
//     );
//   }
//
//   String _formatDuration(Duration duration) {
//     String twoDigits(int n) => n.toString().padLeft(2, '0');
//     final minutes = twoDigits(duration.inMinutes.remainder(60));
//     final seconds = twoDigits(duration.inSeconds.remainder(60));
//
//     if (duration.inHours > 0) {
//       final hours = twoDigits(duration.inHours);
//       return '$hours:$minutes:$seconds';
//     }
//
//     return '$minutes:$seconds';
//   }
// }
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
// // // المسار: lib/features/home/group_chat/presentation/widgets/message_bubble_updated.dart
// //
// // import 'package:app_mobile/features/home/group_chat/domain/models/attachment_model.dart';
// // import 'package:app_mobile/features/home/group_chat/domain/models/message_model.dart';
// // import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart';
// // import 'package:get/get.dart';
// // import 'package:app_mobile/cWre/resources/manager_colors.dart';
// // import 'package:app_mobile/core/resources/manager_font_size.dart';
// // import 'package:app_mobile/core/resources/manager_height.dart';
// // import 'package:app_mobile/core/resources/manager_width.dart';
// // import 'package:app_mobile/core/resources/manager_styles.dart';
// // import 'package:just_audio/just_audio.dart';
// // import '../controller/chat_group_controller.dart';
// // import 'message_image_widget.dart';
// // import 'message_audio_widget.dart';
// // import 'message_file_widget.dart';
// // import 'message_video_widget.dart';
// //
// // class MessageBubble extends StatelessWidget {
// //   final MessageModel message;
// //   final bool isMine;
// //   final VoidCallback onReply;
// //   final VoidCallback? onTapStatus;
// //   final List<AttachmentModel>? attachments;
// //
// //   const MessageBubble({
// //     super.key,
// //     required this.message,
// //     required this.isMine,
// //     required this.onReply,
// //     this.onTapStatus,
// //     this.attachments,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     if (message.isDeleted) {
// //       return _buildDeletedMessage();
// //     }
// //
// //     // ✅ الحل النهائي: استخراج جميع البيانات المطلوبة
// //     final allAttachments = _getAllAttachments();
// //     final displayContent = _getDisplayContent();
// //     final hasRealContent = _hasRealContent(displayContent);
// //
// //     return GestureDetector(
// //       onLongPress: () => _showMessageOptions(context),
// //       child: Align(
// //         alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
// //         child: Container(
// //           margin: EdgeInsets.symmetric(vertical: ManagerHeight.h6),
// //           constraints: BoxConstraints(
// //             maxWidth: MediaQuery.of(context).size.width * 0.75,
// //           ),
// //           decoration: BoxDecoration(
// //             color: isMine ? ManagerColors.primaryColor : Colors.grey.shade100,
// //             borderRadius: BorderRadius.only(
// //               topLeft: const Radius.circular(16),
// //               topRight: const Radius.circular(16),
// //               bottomLeft: Radius.circular(isMine ? 16 : 4),
// //               bottomRight: Radius.circular(isMine ? 4 : 16),
// //             ),
// //             boxShadow: [
// //               BoxShadow(
// //                 color: Colors.black.withOpacity(0.05),
// //                 blurRadius: 4,
// //                 offset: const Offset(0, 2),
// //               ),
// //             ],
// //           ),
// //           child: Column(
// //             crossAxisAlignment:
// //             isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
// //             children: [
// //               // Reply Preview
// //               if (message.replyTo != null) _buildReplyPreview(),
// //
// //               // ✅ الوسائط (مرة واحدة فقط)
// //               if (allAttachments.isNotEmpty)
// //                 _buildAttachments(allAttachments),
// //
// //               // ✅ المحتوى النصي (فقط إذا كان هناك نص حقيقي)
// //               if (hasRealContent)
// //                 Padding(
// //                   padding: EdgeInsets.all(ManagerWidth.w12),
// //                   child: _buildMessageContent(displayContent),
// //                 ),
// //
// //               // Reactions
// //               if (message.reactions != null && message.reactions!.isNotEmpty)
// //                 _buildReactions(),
// //
// //               // Message Footer (Time + Status)
// //               Padding(
// //                 padding: EdgeInsets.only(
// //                   left: ManagerWidth.w12,
// //                   right: ManagerWidth.w12,
// //                   bottom: ManagerHeight.h8,
// //                 ),
// //                 child: _buildMessageFooter(),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // ================================
// //   // ✅ الحل النهائي: جمع جميع الـ Attachments
// //   // ================================
// //   List<AttachmentModel> _getAllAttachments() {
// //     final allAttachments = <AttachmentModel>[];
// //
// //     // إضافة الـ attachments الممررة مباشرة
// //     if (attachments != null && attachments!.isNotEmpty) {
// //       allAttachments.addAll(attachments!);
// //     }
// //
// //     // استخراج الـ attachments من المحتوى النصي
// //     final extractedAttachments = _extractAttachmentsFromContent();
// //     allAttachments.addAll(extractedAttachments);
// //
// //     return allAttachments;
// //   }
// //
// //   // ================================
// //   // ✅ استخراج الـ Attachments من المحتوى
// //   // ================================
// //   List<AttachmentModel> _extractAttachmentsFromContent() {
// //     final attachments = <AttachmentModel>[];
// //     final content = message.content;
// //
// //     // البحث عن روابط Cloudinary
// //     final cloudinaryPattern = RegExp(r'https://res\.cloudinary\.com/[^\s]+');
// //     final matches = cloudinaryPattern.allMatches(content);
// //
// //     for (final match in matches) {
// //       final url = match.group(0)!;
// //       final type = _getMediaTypeFromUrl(url);
// //
// //       attachments.add(AttachmentModel(
// //         id: '${message.id}_${attachments.length}',
// //         url: url,
// //         type: type,
// //         fileName: _getFileNameFromUrl(url),
// //         uploadProgress: 1.0,
// //       ));
// //     }
// //
// //     return attachments;
// //   }
// //
// //   // ================================
// //   // ✅ الحل النهائي: تنظيف المحتوى النصي
// //   // ================================
// //   String _getDisplayContent() {
// //     String content = message.content;
// //
// //     // إذا كان هناك attachments مباشرة، نعيد المحتوى الأصلي (لأن الوسائط منفصلة)
// //     if (attachments != null && attachments!.isNotEmpty) {
// //       return content.trim();
// //     }
// //
// //     // إزالة روابط Cloudinary من النص
// //     final cloudinaryPattern = RegExp(r'https://res\.cloudinary\.com/[^\s]+');
// //     content = content.replaceAll(cloudinaryPattern, '').trim();
// //
// //     // إزالة أيقونات الوسائط إذا كانت وحدها
// //     final mediaIconsPattern = RegExp(r'^(📷|🎥|🎤|📎)\s*$');
// //     if (mediaIconsPattern.hasMatch(content)) {
// //       return '';
// //     }
// //
// //     return content;
// //   }
// //
// //   // ================================
// //   // ✅ التحقق من وجود محتوى نصي حقيقي
// //   // ================================
// //   bool _hasRealContent(String content) {
// //     if (content.isEmpty) return false;
// //
// //     // التحقق إذا كان المحتوى يحتوي فقط على مسافات أو رموز وسائط
// //     final trimmedContent = content.trim();
// //     if (trimmedContent.isEmpty) return false;
// //
// //     final mediaIconsPattern = RegExp(r'^(📷|🎥|🎤|📎)\s*$');
// //     if (mediaIconsPattern.hasMatch(trimmedContent)) {
// //       return false;
// //     }
// //
// //     return true;
// //   }
// //
// //   // ================================
// //   // ✅ بناء الوسائط
// //   // ================================
// //   Widget _buildAttachments(List<AttachmentModel> attachments) {
// //     return Padding(
// //       padding: EdgeInsets.all(ManagerWidth.w8),
// //       child: Column(
// //         children: attachments.map((attachment) {
// //           switch (attachment.type) {
// //             case 'image':
// //               return MessageImageWidget(
// //                 attachment: attachment,
// //                 isMine: isMine,
// //               );
// //             case 'video':
// //               return MessageVideoWidget(
// //                 attachment: attachment,
// //                 isMine: isMine,
// //               );
// //             case 'audio':
// //               return Container(
// //                 padding: EdgeInsets.all(ManagerWidth.w8),
// //                 child: _buildWhatsAppStyleAudio(attachment),
// //               );
// //             case 'file':
// //               return MessageFileWidget(
// //                 attachment: attachment,
// //                 isMine: isMine,
// //               );
// //             default:
// //               return const SizedBox.shrink();
// //           }
// //         }).toList(),
// //       ),
// //     );
// //   }
// //
// //   // ================================
// //   // ✅ تصميم الصوت مثل واتساب
// //   // ================================
// //   Widget _buildWhatsAppStyleAudio(AttachmentModel attachment) {
// //     return _WhatsAppAudioPlayer(
// //       attachment: attachment,
// //       isMine: isMine,
// //     );
// //   }
// //
// //   // ================================
// //   // ✅ المحتوى النصي
// //   // ================================
// //   Widget _buildMessageContent(String content) {
// //     return Text(
// //       _highlightMentions(content),
// //       style: getRegularTextStyle(
// //         fontSize: ManagerFontSize.s14,
// //         color: isMine ? Colors.white : Colors.black87,
// //       ),
// //     );
// //   }
// //
// //   // ================================
// //   // ✅ تحديد نوع الوسائط من الرابط
// //   // ================================
// //   String _getMediaTypeFromUrl(String url) {
// //     if (url.contains('/image/') ||
// //         url.contains('.jpg') ||
// //         url.contains('.png') ||
// //         url.contains('.jpeg') ||
// //         url.contains('.webp')) {
// //       return 'image';
// //     } else if (url.contains('/video/') ||
// //         url.contains('.mp4') ||
// //         url.contains('.mov') ||
// //         url.contains('.avi')) {
// //       return 'video';
// //     } else if (url.contains('/audio/') ||
// //         url.contains('.mp3') ||
// //         url.contains('.m4a') ||
// //         url.contains('.wav')) {
// //       return 'audio';
// //     } else {
// //       return 'file';
// //     }
// //   }
// //
// //   // ================================
// //   // ✅ دوال مساعدة
// //   // ================================
// //   String _getFileNameFromUrl(String url) {
// //     final uri = Uri.parse(url);
// //     final pathSegments = uri.pathSegments;
// //     return pathSegments.isNotEmpty ? pathSegments.last : 'file';
// //   }
// //
// //   String _highlightMentions(String content) {
// //     // TODO: تنفيذ إبراز الإشارات
// //     return content;
// //   }
// //
// //   // ================================
// //   // ✅ باقي الدوال (بدون تغيير)
// //   // ================================
// //   Widget _buildDeletedMessage() {
// //     return Align(
// //       alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
// //       child: Container(
// //         margin: EdgeInsets.symmetric(vertical: ManagerHeight.h6),
// //         padding: EdgeInsets.all(ManagerWidth.w12),
// //         decoration: BoxDecoration(
// //           color: Colors.grey.shade200,
// //           borderRadius: BorderRadius.circular(12),
// //         ),
// //         child: Row(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Icon(Icons.block, size: 16, color: Colors.grey.shade600),
// //             SizedBox(width: ManagerWidth.w8),
// //             Text(
// //               'تم حذف هذه الرسالة',
// //               style: getRegularTextStyle(
// //                 fontSize: ManagerFontSize.s13,
// //                 color: Colors.grey.shade600,
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildReplyPreview() {
// //     return Container(
// //       margin: EdgeInsets.all(ManagerWidth.w8),
// //       padding: EdgeInsets.all(ManagerWidth.w8),
// //       decoration: BoxDecoration(
// //         color: Colors.white.withOpacity(isMine ? 0.2 : 0.3),
// //         borderRadius: BorderRadius.circular(8),
// //         border: Border(
// //           right: BorderSide(
// //             color: isMine ? Colors.white : ManagerColors.primaryColor,
// //             width: 3,
// //           ),
// //         ),
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Row(
// //             children: [
// //               Icon(
// //                 Icons.reply,
// //                 size: 14,
// //                 color: isMine
// //                     ? Colors.white.withOpacity(0.9)
// //                     : Colors.grey.shade700,
// //               ),
// //               SizedBox(width: ManagerWidth.w4),
// //               Text(
// //                 "ردًا على",
// //                 style: getBoldTextStyle(
// //                   fontSize: ManagerFontSize.s10,
// //                   color: isMine
// //                       ? Colors.white.withOpacity(0.9)
// //                       : Colors.grey.shade700,
// //                 ),
// //               ),
// //             ],
// //           ),
// //           SizedBox(height: ManagerHeight.h4),
// //           Text(
// //             message.replyTo ?? '',
// //             style: getRegularTextStyle(
// //               fontSize: ManagerFontSize.s12,
// //               color: isMine
// //                   ? Colors.white.withOpacity(0.8)
// //                   : Colors.grey.shade600,
// //             ),
// //             maxLines: 2,
// //             overflow: TextOverflow.ellipsis,
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _buildReactions() {
// //     final reactions = message.reactions!;
// //     final reactionCounts = <String, int>{};
// //
// //     for (var emoji in reactions.values) {
// //       reactionCounts[emoji.toString()] =
// //           (reactionCounts[emoji.toString()] ?? 0) + 1;
// //     }
// //
// //     return Container(
// //       margin: EdgeInsets.symmetric(horizontal: ManagerWidth.w8),
// //       padding: EdgeInsets.all(ManagerWidth.w6),
// //       decoration: BoxDecoration(
// //         color: Colors.white.withOpacity(isMine ? 0.2 : 0.8),
// //         borderRadius: BorderRadius.circular(12),
// //       ),
// //       child: Wrap(
// //         spacing: 4,
// //         children: reactionCounts.entries.map((entry) {
// //           return Container(
// //             padding: EdgeInsets.symmetric(
// //               horizontal: ManagerWidth.w6,
// //               vertical: ManagerHeight.h2,
// //             ),
// //             decoration: BoxDecoration(
// //               color: Colors.white.withOpacity(0.3),
// //               borderRadius: BorderRadius.circular(10),
// //             ),
// //             child: Row(
// //               mainAxisSize: MainAxisSize.min,
// //               children: [
// //                 Text(entry.key, style: const TextStyle(fontSize: 14)),
// //                 if (entry.value > 1) ...[
// //                   SizedBox(width: ManagerWidth.w2),
// //                   Text(
// //                     '${entry.value}',
// //                     style: getBoldTextStyle(
// //                       fontSize: ManagerFontSize.s10,
// //                       color: isMine ? Colors.white : Colors.black87,
// //                     ),
// //                   ),
// //                 ],
// //               ],
// //             ),
// //           );
// //         }).toList(),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildMessageFooter() {
// //     return Row(
// //       mainAxisSize: MainAxisSize.min,
// //       children: [
// //         Text(
// //           _formatTime(message.timestamp),
// //           style: getRegularTextStyle(
// //             fontSize: ManagerFontSize.s10,
// //             color: isMine ? Colors.white.withOpacity(0.7) : Colors.grey,
// //           ),
// //         ),
// //         if (isMine) ...[
// //           SizedBox(width: ManagerWidth.w4),
// //           GestureDetector(
// //             onTap: onTapStatus,
// //             child: _buildStatusIcon(),
// //           ),
// //         ],
// //       ],
// //     );
// //   }
// //
// //   Widget _buildStatusIcon() {
// //     IconData icon;
// //     Color color;
// //
// //     if (message.isFailed) {
// //       icon = Icons.error_outline;
// //       color = Colors.red.shade300;
// //     } else if (message.isFullySeen) {
// //       icon = Icons.done_all;
// //       color = Colors.blue.shade200;
// //     } else if (message.isSeen) {
// //       icon = Icons.done_all;
// //       color = Colors.blue.shade200;
// //     } else if (message.isFullyDelivered) {
// //       icon = Icons.done_all;
// //       color = Colors.white.withOpacity(0.7);
// //     } else if (message.isDelivered) {
// //       icon = Icons.done_all;
// //       color = Colors.white.withOpacity(0.7);
// //     } else {
// //       icon = Icons.done;
// //       color = Colors.white.withOpacity(0.7);
// //     }
// //
// //     return Icon(
// //       icon,
// //       size: 16,
// //       color: color,
// //     );
// //   }
// //
// //   void _showMessageOptions(BuildContext context) {
// //     final controller = ChatGroupController.to;
// //
// //     showModalBottomSheet(
// //       context: context,
// //       backgroundColor: Colors.white,
// //       shape: const RoundedRectangleBorder(
// //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
// //       ),
// //       builder: (context) => SafeArea(
// //         child: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Container(
// //               margin: EdgeInsets.only(top: ManagerHeight.h8),
// //               width: 40,
// //               height: 4,
// //               decoration: BoxDecoration(
// //                 color: Colors.grey.shade300,
// //                 borderRadius: BorderRadius.circular(2),
// //               ),
// //             ),
// //             ListTile(
// //               leading: Icon(Icons.reply, color: ManagerColors.primaryColor),
// //               title: Text(
// //                 'الرد على الرسالة',
// //                 style: getRegularTextStyle(
// //                   fontSize: ManagerFontSize.s14,
// //                   color: Colors.black,
// //                 ),
// //               ),
// //               onTap: () {
// //                 Navigator.pop(context);
// //                 onReply();
// //               },
// //             ),
// //             ListTile(
// //               leading: Icon(Icons.add_reaction, color: ManagerColors.primaryColor),
// //               title: Text(
// //                 'إضافة تفاعل',
// //                 style: getRegularTextStyle(
// //                   fontSize: ManagerFontSize.s14,
// //                   color: Colors.black,
// //                 ),
// //               ),
// //               onTap: () {
// //                 Navigator.pop(context);
// //                 _showReactionPicker(context);
// //               },
// //             ),
// //             if (isMine && onTapStatus != null)
// //               ListTile(
// //                 leading: Icon(Icons.info_outline, color: ManagerColors.primaryColor),
// //                 title: Text(
// //                   'حالة الرسالة',
// //                   style: getRegularTextStyle(
// //                     fontSize: ManagerFontSize.s14,
// //                     color: Colors.black,
// //                   ),
// //                 ),
// //                 onTap: () {
// //                   Navigator.pop(context);
// //                   onTapStatus!();
// //                 },
// //               ),
// //             ListTile(
// //               leading: Icon(Icons.copy, color: ManagerColors.primaryColor),
// //               title: Text(
// //                 'نسخ النص',
// //                 style: getRegularTextStyle(
// //                   fontSize: ManagerFontSize.s14,
// //                   color: Colors.black,
// //                 ),
// //               ),
// //               onTap: () {
// //                 Navigator.pop(context);
// //                 Clipboard.setData(ClipboardData(text: message.content));
// //                 ScaffoldMessenger.of(context).showSnackBar(
// //                   const SnackBar(
// //                     content: Text('تم نسخ النص'),
// //                     duration: Duration(seconds: 1),
// //                   ),
// //                 );
// //               },
// //             ),
// //             if (controller.canDeleteMessage(message))
// //               ListTile(
// //                 leading: const Icon(Icons.delete, color: Colors.red),
// //                 title: Text(
// //                   'حذف الرسالة',
// //                   style: getRegularTextStyle(
// //                     fontSize: ManagerFontSize.s14,
// //                     color: Colors.red,
// //                   ),
// //                 ),
// //                 onTap: () {
// //                   Navigator.pop(context);
// //                   _confirmDelete(context);
// //                 },
// //               ),
// //             SizedBox(height: ManagerHeight.h8),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   void _showReactionPicker(BuildContext context) {
// //     final controller = ChatGroupController.to;
// //     final reactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
// //
// //     showModalBottomSheet(
// //       context: context,
// //       backgroundColor: Colors.white,
// //       shape: const RoundedRectangleBorder(
// //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
// //       ),
// //       builder: (context) => Container(
// //         padding: EdgeInsets.all(ManagerWidth.w20),
// //         child: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Text(
// //               'اختر تفاعلك',
// //               style: getBoldTextStyle(
// //                 fontSize: ManagerFontSize.s16,
// //                 color: Colors.black,
// //               ),
// //             ),
// //             SizedBox(height: ManagerHeight.h20),
// //             Wrap(
// //               spacing: 16,
// //               runSpacing: 16,
// //               children: reactions.map((emoji) {
// //                 return GestureDetector(
// //                   onTap: () {
// //                     Navigator.pop(context);
// //                     controller.addReaction(message, emoji);
// //                   },
// //                   child: Container(
// //                     width: 50,
// //                     height: 50,
// //                     decoration: BoxDecoration(
// //                       color: Colors.grey.shade100,
// //                       borderRadius: BorderRadius.circular(25),
// //                     ),
// //                     child: Center(
// //                       child: Text(
// //                         emoji,
// //                         style: const TextStyle(fontSize: 28),
// //                       ),
// //                     ),
// //                   ),
// //                 );
// //               }).toList(),
// //             ),
// //             SizedBox(height: ManagerHeight.h20),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   void _confirmDelete(BuildContext context) {
// //     final controller = ChatGroupController.to;
// //
// //     Get.dialog(
// //       AlertDialog(
// //         title: const Text('حذف الرسالة'),
// //         content: const Text('هل أنت متأكد من حذف هذه الرسالة؟'),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Get.back(),
// //             child: const Text('إلغاء'),
// //           ),
// //           TextButton(
// //             onPressed: () {
// //               Get.back();
// //               controller.deleteMessage(message);
// //             },
// //             style: TextButton.styleFrom(foregroundColor: Colors.red),
// //             child: const Text('حذف'),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   String _formatTime(DateTime time) {
// //     final hour = time.hour.toString().padLeft(2, '0');
// //     final minute = time.minute.toString().padLeft(2, '0');
// //     return "$hour:$minute";
// //   }
// // }
// //
// // // ================================
// // // ✅ مشغل الصوت بتصميم واتساب
// // // ================================
// // class _WhatsAppAudioPlayer extends StatefulWidget {
// //   final AttachmentModel attachment;
// //   final bool isMine;
// //
// //   const _WhatsAppAudioPlayer({
// //     required this.attachment,
// //     required this.isMine,
// //   });
// //
// //   @override
// //   State<_WhatsAppAudioPlayer> createState() => __WhatsAppAudioPlayerState();
// // }
// //
// // class __WhatsAppAudioPlayerState extends State<_WhatsAppAudioPlayer> {
// //   final AudioPlayer _audioPlayer = AudioPlayer();
// //   bool _isPlaying = false;
// //   bool _isLoading = false;
// //   Duration _duration = Duration.zero;
// //   Duration _position = Duration.zero;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _initAudioPlayer();
// //   }
// //
// //   Future<void> _initAudioPlayer() async {
// //     try {
// //       _audioPlayer.durationStream.listen((duration) {
// //         if (mounted) {
// //           setState(() {
// //             _duration = duration ?? Duration.zero;
// //           });
// //         }
// //       });
// //
// //       _audioPlayer.positionStream.listen((position) {
// //         if (mounted) {
// //           setState(() {
// //             _position = position;
// //           });
// //         }
// //       });
// //
// //       _audioPlayer.playerStateStream.listen((state) {
// //         if (state.processingState == ProcessingState.completed) {
// //           if (mounted) {
// //             setState(() {
// //               _isPlaying = false;
// //               _position = Duration.zero;
// //             });
// //           }
// //           _audioPlayer.seek(Duration.zero);
// //         }
// //       });
// //     } catch (e) {
// //       print('❌ خطأ في تهيئة مشغل الصوت: $e');
// //     }
// //   }
// //
// //   Future<void> _togglePlayPause() async {
// //     try {
// //       if (_isLoading) return;
// //
// //       if (_isPlaying) {
// //         await _audioPlayer.pause();
// //         setState(() {
// //           _isPlaying = false;
// //         });
// //       } else {
// //         setState(() {
// //           _isLoading = true;
// //         });
// //
// //         if (_audioPlayer.duration == null) {
// //           if (widget.attachment.localPath != null) {
// //             await _audioPlayer.setFilePath(widget.attachment.localPath!);
// //           } else {
// //             await _audioPlayer.setUrl(widget.attachment.url);
// //           }
// //         }
// //
// //         await _audioPlayer.play();
// //         setState(() {
// //           _isPlaying = true;
// //           _isLoading = false;
// //         });
// //       }
// //     } catch (e) {
// //       print('❌ خطأ في تشغيل الصوت: $e');
// //       setState(() {
// //         _isLoading = false;
// //         _isPlaying = false;
// //       });
// //     }
// //   }
// //
// //   @override
// //   void dispose() {
// //     _audioPlayer.dispose();
// //     super.dispose();
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       width: 200,
// //       padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
// //       decoration: BoxDecoration(
// //         color: widget.isMine
// //             ? ManagerColors.primaryColor.withOpacity(0.9)
// //             : Colors.grey.shade300,
// //         borderRadius: BorderRadius.circular(20),
// //       ),
// //       child: Row(
// //         children: [
// //           // زر التشغيل/الإيقاف
// //           GestureDetector(
// //             onTap: _togglePlayPause,
// //             child: Container(
// //               width: 32,
// //               height: 32,
// //               decoration: BoxDecoration(
// //                 color: widget.isMine ? Colors.white : ManagerColors.primaryColor,
// //                 shape: BoxShape.circle,
// //               ),
// //               child: _isLoading
// //                   ? Center(
// //                 child: SizedBox(
// //                   width: 16,
// //                   height: 16,
// //                   child: CircularProgressIndicator(
// //                     strokeWidth: 2,
// //                     valueColor: AlwaysStoppedAnimation<Color>(
// //                       widget.isMine ? ManagerColors.primaryColor : Colors.white,
// //                     ),
// //                   ),
// //                 ),
// //               )
// //                   : Icon(
// //                 _isPlaying ? Icons.pause : Icons.play_arrow,
// //                 size: 18,
// //                 color: widget.isMine ? ManagerColors.primaryColor : Colors.white,
// //               ),
// //             ),
// //           ),
// //
// //           SizedBox(width: 12),
// //
// //           // شريط التقدم
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 // شريط التقدم
// //                 SliderTheme(
// //                   data: SliderThemeData(
// //                     trackHeight: 2,
// //                     thumbShape: RoundSliderThumbShape(
// //                       enabledThumbRadius: 6,
// //                     ),
// //                     overlayShape: RoundSliderOverlayShape(
// //                       overlayRadius: 12,
// //                     ),
// //                   ),
// //                   child: Slider(
// //                     value: _position.inMilliseconds.toDouble(),
// //                     max: _duration.inMilliseconds.toDouble() > 0
// //                         ? _duration.inMilliseconds.toDouble()
// //                         : 1.0,
// //                     onChanged: (value) {
// //                       _audioPlayer.seek(Duration(milliseconds: value.toInt()));
// //                     },
// //                     activeColor: widget.isMine ? Colors.white : ManagerColors.primaryColor,
// //                     inactiveColor: widget.isMine ? Colors.white.withOpacity(0.3) : Colors.grey.shade400,
// //                   ),
// //                 ),
// //
// //                 // الوقت
// //                 Text(
// //                   _formatDuration(_position),
// //                   style: TextStyle(
// //                     fontSize: 12,
// //                     color: widget.isMine ? Colors.white.withOpacity(0.8) : Colors.grey.shade600,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   String _formatDuration(Duration duration) {
// //     String twoDigits(int n) => n.toString().padLeft(2, '0');
// //     final minutes = twoDigits(duration.inMinutes.remainder(60));
// //     final seconds = twoDigits(duration.inSeconds.remainder(60));
// //     return '$minutes:$seconds';
// //   }
// // }
// // // المسار: lib/features/home/group_chat/presentation/widgets/message_bubble_updated.dart
// //
// // import 'package:app_mobile/features/home/group_chat/domain/models/attachment_model.dart';
// // import 'package:app_mobile/features/home/group_chat/domain/models/message_model.dart';
// // import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart';
// // import 'package:get/get.dart';
// // import 'package:app_mobile/core/resources/manager_colors.dart';
// // import 'package:app_mobile/core/resources/manager_font_size.dart';
// // import 'package:app_mobile/core/resources/manager_height.dart';
// // import 'package:app_mobile/core/resources/manager_width.dart';
// // import 'package:app_mobile/core/resources/manager_styles.dart';
// // import 'package:just_audio/just_audio.dart';
// // import '../controller/chat_group_controller.dart';
// // import 'message_image_widget.dart';
// // import 'message_audio_widget.dart';
// // import 'message_file_widget.dart';
// // import 'message_video_widget.dart';
// //
// // class MessageBubble extends StatelessWidget {
// //   final MessageModel message;
// //   final bool isMine;
// //   final VoidCallback onReply;
// //   final VoidCallback? onTapStatus;
// //   final List<AttachmentModel>? attachments;
// //
// //   const MessageBubble({
// //     super.key,
// //     required this.message,
// //     required this.isMine,
// //     required this.onReply,
// //     this.onTapStatus,
// //     this.attachments,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     if (message.isDeleted) {
// //       return _buildDeletedMessage();
// //     }
// //
// //     // ✅ الحل الجديد: تحديد نوع المحتوى بشكل دقيق
// //     final messageType = _getMessageType();
// //     final displayContent = _getCleanContent();
// //
// //     return GestureDetector(
// //       onLongPress: () => _showMessageOptions(context),
// //       child: Align(
// //         alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
// //         child: Container(
// //           margin: EdgeInsets.symmetric(vertical: ManagerHeight.h6),
// //           constraints: BoxConstraints(
// //             maxWidth: MediaQuery.of(context).size.width * 0.75,
// //           ),
// //           decoration: BoxDecoration(
// //             color: isMine ? ManagerColors.primaryColor : Colors.grey.shade100,
// //             borderRadius: BorderRadius.only(
// //               topLeft: const Radius.circular(16),
// //               topRight: const Radius.circular(16),
// //               bottomLeft: Radius.circular(isMine ? 16 : 4),
// //               bottomRight: Radius.circular(isMine ? 4 : 16),
// //             ),
// //             boxShadow: [
// //               BoxShadow(
// //                 color: Colors.black.withOpacity(0.05),
// //                 blurRadius: 4,
// //                 offset: const Offset(0, 2),
// //               ),
// //             ],
// //           ),
// //           child: Column(
// //             crossAxisAlignment:
// //             isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
// //             children: [
// //               // Reply Preview
// //               if (message.replyTo != null) _buildReplyPreview(),
// //
// //               // ✅ بناء المحتوى حسب النوع
// //               _buildContentByType(messageType, displayContent),
// //
// //               // Reactions
// //               if (message.reactions != null && message.reactions!.isNotEmpty)
// //                 _buildReactions(),
// //
// //               // Message Footer (Time + Status)
// //               Padding(
// //                 padding: EdgeInsets.only(
// //                   left: ManagerWidth.w12,
// //                   right: ManagerWidth.w12,
// //                   bottom: ManagerHeight.h8,
// //                 ),
// //                 child: _buildMessageFooter(),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // ================================
// //   // ✅ تحديد نوع الرسالة
// //   // ================================
// //   MessageType _getMessageType() {
// //     // إذا كان هناك attachments مباشرة
// //     if (attachments != null && attachments!.isNotEmpty) {
// //       final firstAttachment = attachments!.first;
// //       switch (firstAttachment.type) {
// //         case 'image':
// //           return MessageType.image;
// //         case 'video':
// //           return MessageType.video;
// //         case 'audio':
// //           return MessageType.audio;
// //         case 'file':
// //           return MessageType.file;
// //         default:
// //           return MessageType.text;
// //       }
// //     }
// //
// //     // إذا لم يكن هناك attachments، نفحص المحتوى
// //     final content = message.content;
// //
// //     // فحص إذا كان المحتوى يحتوي على روابط وسائط فقط
// //     final hasCloudinaryLinks = RegExp(r'https://res\.cloudinary\.com/').hasMatch(content);
// //     final hasOnlyMediaIcons = RegExp(r'^(📷|🎥|🎤|📎)\s*$').hasMatch(content.trim());
// //
// //     if (hasCloudinaryLinks) {
// //       if (content.contains('/image/') ||
// //           content.contains('.jpg') ||
// //           content.contains('.png') ||
// //           content.contains('.jpeg')) {
// //         return MessageType.image;
// //       } else if (content.contains('/video/') ||
// //           content.contains('.mp4') ||
// //           content.contains('.mov')) {
// //         return MessageType.video;
// //       } else if (content.contains('/audio/') ||
// //           content.contains('.mp3') ||
// //           content.contains('.m4a')) {
// //         return MessageType.audio;
// //       } else if (content.contains('/file/') ||
// //           content.contains('.pdf') ||
// //           content.contains('.doc')) {
// //         return MessageType.file;
// //       }
// //     }
// //
// //     // إذا كان نص عادي
// //     return MessageType.text;
// //   }
// //
// //   // ================================
// //   // ✅ بناء المحتوى حسب النوع
// //   // ================================
// //   Widget _buildContentByType(MessageType type, String content) {
// //     switch (type) {
// //       case MessageType.image:
// //         return _buildImageMessage();
// //       case MessageType.video:
// //         return _buildVideoMessage();
// //       case MessageType.audio:
// //         return _buildAudioMessage();
// //       case MessageType.file:
// //         return _buildFileMessage();
// //       case MessageType.text:
// //         return _buildTextMessage(content);
// //     }
// //   }
// //
// //   // ================================
// //   // ✅ رسالة صورة
// //   // ================================
// //   Widget _buildImageMessage() {
// //     // إنشاء attachment للصورة
// //     final imageAttachment = _createAttachmentFromContent('image');
// //
// //     return Column(
// //       children: [
// //         if (imageAttachment != null)
// //           MessageImageWidget(
// //             attachment: imageAttachment,
// //             isMine: isMine,
// //           ),
// //         if (_getCleanContent().isNotEmpty)
// //           Padding(
// //             padding: EdgeInsets.all(ManagerWidth.w12),
// //             child: _buildTextMessage(_getCleanContent()),
// //           ),
// //       ],
// //     );
// //   }
// //
// //   // ================================
// //   // ✅ رسالة فيديو
// //   // ================================
// //   Widget _buildVideoMessage() {
// //     final videoAttachment = _createAttachmentFromContent('video');
// //
// //     return Column(
// //       children: [
// //         if (videoAttachment != null)
// //           MessageVideoWidget(
// //             attachment: videoAttachment,
// //             isMine: isMine,
// //           ),
// //         if (_getCleanContent().isNotEmpty)
// //           Padding(
// //             padding: EdgeInsets.all(ManagerWidth.w12),
// //             child: _buildTextMessage(_getCleanContent()),
// //           ),
// //       ],
// //     );
// //   }
// //
// //   // ================================
// //   // ✅ رسالة صوتية (مثل واتساب)
// //   // ================================
// //   Widget _buildAudioMessage() {
// //     final audioAttachment = _createAttachmentFromContent('audio');
// //
// //     return Column(
// //       children: [
// //         if (audioAttachment != null)
// //           Container(
// //             padding: EdgeInsets.all(ManagerWidth.w12),
// //             child: _buildWhatsAppStyleAudio(audioAttachment),
// //           ),
// //         if (_getCleanContent().isNotEmpty)
// //           Padding(
// //             padding: EdgeInsets.all(ManagerWidth.w12),
// //             child: _buildTextMessage(_getCleanContent()),
// //           ),
// //       ],
// //     );
// //   }
// //
// //   // ================================
// //   // ✅ رسالة ملف
// //   // ================================
// //   Widget _buildFileMessage() {
// //     final fileAttachment = _createAttachmentFromContent('file');
// //
// //     return Column(
// //       children: [
// //         if (fileAttachment != null)
// //           MessageFileWidget(
// //             attachment: fileAttachment,
// //             isMine: isMine,
// //           ),
// //         if (_getCleanContent().isNotEmpty)
// //           Padding(
// //             padding: EdgeInsets.all(ManagerWidth.w12),
// //             child: _buildTextMessage(_getCleanContent()),
// //           ),
// //       ],
// //     );
// //   }
// //
// //   // ================================
// //   // ✅ رسالة نصية
// //   // ================================
// //   Widget _buildTextMessage(String content) {
// //     return Padding(
// //       padding: EdgeInsets.all(ManagerWidth.w12),
// //       child: Text(
// //         _highlightMentions(content),
// //         style: getRegularTextStyle(
// //           fontSize: ManagerFontSize.s14,
// //           color: isMine ? Colors.white : Colors.black87,
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // ================================
// //   // ✅ تصميم الصوت مثل واتساب
// //   // ================================
// //   Widget _buildWhatsAppStyleAudio(AttachmentModel attachment) {
// //     return _WhatsAppAudioPlayer(
// //       attachment: attachment,
// //       isMine: isMine,
// //     );
// //   }
// //
// //   // ================================
// //   // ✅ إنشاء attachment من المحتوى
// //   // ================================
// //   AttachmentModel? _createAttachmentFromContent(String type) {
// //     // إذا كان هناك attachments مباشرة، نستخدمها
// //     if (attachments != null && attachments!.isNotEmpty) {
// //       return attachments!.first;
// //     }
// //
// //     // إذا لم يكن، نستخرج من المحتوى
// //     final content = message.content;
// //     final cloudinaryPattern = RegExp(r'https://res\.cloudinary\.com/[^\s]+');
// //     final match = cloudinaryPattern.firstMatch(content);
// //
// //     if (match != null) {
// //       final url = match.group(0)!;
// //       return AttachmentModel(
// //         id: '${message.id}_0',
// //         url: url,
// //         type: type,
// //         fileName: _getFileNameFromUrl(url),
// //         uploadProgress: 1.0,
// //       );
// //     }
// //
// //     return null;
// //   }
// //
// //   // ================================
// //   // ✅ تنظيف المحتوى من الوسائط
// //   // ================================
// //   String _getCleanContent() {
// //     String content = message.content;
// //
// //     // إزالة روابط Cloudinary
// //     final cloudinaryPattern = RegExp(r'https://res\.cloudinary\.com/[^\s]+');
// //     content = content.replaceAll(cloudinaryPattern, '').trim();
// //
// //     // إزالة أيقونات الوسائط إذا كانت وحدها
// //     final mediaIconsPattern = RegExp(r'^(📷|🎥|🎤|📎)\s*$');
// //     if (mediaIconsPattern.hasMatch(content)) {
// //       return '';
// //     }
// //
// //     return content;
// //   }
// //
// //   // ================================
// //   // ✅ باقي الدوال (بدون تغيير)
// //   // ================================
// //   Widget _buildDeletedMessage() {
// //     return Align(
// //       alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
// //       child: Container(
// //         margin: EdgeInsets.symmetric(vertical: ManagerHeight.h6),
// //         padding: EdgeInsets.all(ManagerWidth.w12),
// //         decoration: BoxDecoration(
// //           color: Colors.grey.shade200,
// //           borderRadius: BorderRadius.circular(12),
// //         ),
// //         child: Row(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Icon(Icons.block, size: 16, color: Colors.grey.shade600),
// //             SizedBox(width: ManagerWidth.w8),
// //             Text(
// //               'تم حذف هذه الرسالة',
// //               style: getRegularTextStyle(
// //                 fontSize: ManagerFontSize.s13,
// //                 color: Colors.grey.shade600,
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildReplyPreview() {
// //     return Container(
// //       margin: EdgeInsets.all(ManagerWidth.w8),
// //       padding: EdgeInsets.all(ManagerWidth.w8),
// //       decoration: BoxDecoration(
// //         color: Colors.white.withOpacity(isMine ? 0.2 : 0.3),
// //         borderRadius: BorderRadius.circular(8),
// //         border: Border(
// //           right: BorderSide(
// //             color: isMine ? Colors.white : ManagerColors.primaryColor,
// //             width: 3,
// //           ),
// //         ),
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Row(
// //             children: [
// //               Icon(
// //                 Icons.reply,
// //                 size: 14,
// //                 color: isMine
// //                     ? Colors.white.withOpacity(0.9)
// //                     : Colors.grey.shade700,
// //               ),
// //               SizedBox(width: ManagerWidth.w4),
// //               Text(
// //                 "ردًا على",
// //                 style: getBoldTextStyle(
// //                   fontSize: ManagerFontSize.s10,
// //                   color: isMine
// //                       ? Colors.white.withOpacity(0.9)
// //                       : Colors.grey.shade700,
// //                 ),
// //               ),
// //             ],
// //           ),
// //           SizedBox(height: ManagerHeight.h4),
// //           Text(
// //             message.replyTo ?? '',
// //             style: getRegularTextStyle(
// //               fontSize: ManagerFontSize.s12,
// //               color: isMine
// //                   ? Colors.white.withOpacity(0.8)
// //                   : Colors.grey.shade600,
// //             ),
// //             maxLines: 2,
// //             overflow: TextOverflow.ellipsis,
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   String _getFileNameFromUrl(String url) {
// //     final uri = Uri.parse(url);
// //     final pathSegments = uri.pathSegments;
// //     return pathSegments.isNotEmpty ? pathSegments.last : 'file';
// //   }
// //
// //   String _highlightMentions(String content) {
// //     return content;
// //   }
// //
// //   Widget _buildReactions() {
// //     final reactions = message.reactions!;
// //     final reactionCounts = <String, int>{};
// //
// //     for (var emoji in reactions.values) {
// //       reactionCounts[emoji.toString()] =
// //           (reactionCounts[emoji.toString()] ?? 0) + 1;
// //     }
// //
// //     return Container(
// //       margin: EdgeInsets.symmetric(horizontal: ManagerWidth.w8),
// //       padding: EdgeInsets.all(ManagerWidth.w6),
// //       decoration: BoxDecoration(
// //         color: Colors.white.withOpacity(isMine ? 0.2 : 0.8),
// //         borderRadius: BorderRadius.circular(12),
// //       ),
// //       child: Wrap(
// //         spacing: 4,
// //         children: reactionCounts.entries.map((entry) {
// //           return Container(
// //             padding: EdgeInsets.symmetric(
// //               horizontal: ManagerWidth.w6,
// //               vertical: ManagerHeight.h2,
// //             ),
// //             decoration: BoxDecoration(
// //               color: Colors.white.withOpacity(0.3),
// //               borderRadius: BorderRadius.circular(10),
// //             ),
// //             child: Row(
// //               mainAxisSize: MainAxisSize.min,
// //               children: [
// //                 Text(entry.key, style: const TextStyle(fontSize: 14)),
// //                 if (entry.value > 1) ...[
// //                   SizedBox(width: ManagerWidth.w2),
// //                   Text(
// //                     '${entry.value}',
// //                     style: getBoldTextStyle(
// //                       fontSize: ManagerFontSize.s10,
// //                       color: isMine ? Colors.white : Colors.black87,
// //                     ),
// //                   ),
// //                 ],
// //               ],
// //             ),
// //           );
// //         }).toList(),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildMessageFooter() {
// //     return Row(
// //       mainAxisSize: MainAxisSize.min,
// //       children: [
// //         Text(
// //           _formatTime(message.timestamp),
// //           style: getRegularTextStyle(
// //             fontSize: ManagerFontSize.s10,
// //             color: isMine ? Colors.white.withOpacity(0.7) : Colors.grey,
// //           ),
// //         ),
// //         if (isMine) ...[
// //           SizedBox(width: ManagerWidth.w4),
// //           GestureDetector(
// //             onTap: onTapStatus,
// //             child: _buildStatusIcon(),
// //           ),
// //         ],
// //       ],
// //     );
// //   }
// //
// //   Widget _buildStatusIcon() {
// //     IconData icon;
// //     Color color;
// //
// //     if (message.isFailed) {
// //       icon = Icons.error_outline;
// //       color = Colors.red.shade300;
// //     } else if (message.isFullySeen) {
// //       icon = Icons.done_all;
// //       color = Colors.blue.shade200;
// //     } else if (message.isSeen) {
// //       icon = Icons.done_all;
// //       color = Colors.blue.shade200;
// //     } else if (message.isFullyDelivered) {
// //       icon = Icons.done_all;
// //       color = Colors.white.withOpacity(0.7);
// //     } else if (message.isDelivered) {
// //       icon = Icons.done_all;
// //       color = Colors.white.withOpacity(0.7);
// //     } else {
// //       icon = Icons.done;
// //       color = Colors.white.withOpacity(0.7);
// //     }
// //
// //     return Icon(
// //       icon,
// //       size: 16,
// //       color: color,
// //     );
// //   }
// //
// //   void _showMessageOptions(BuildContext context) {
// //     final controller = ChatGroupController.to;
// //
// //     showModalBottomSheet(
// //       context: context,
// //       backgroundColor: Colors.white,
// //       shape: const RoundedRectangleBorder(
// //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
// //       ),
// //       builder: (context) => SafeArea(
// //         child: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Container(
// //               margin: EdgeInsets.only(top: ManagerHeight.h8),
// //               width: 40,
// //               height: 4,
// //               decoration: BoxDecoration(
// //                 color: Colors.grey.shade300,
// //                 borderRadius: BorderRadius.circular(2),
// //               ),
// //             ),
// //             ListTile(
// //               leading: Icon(Icons.reply, color: ManagerColors.primaryColor),
// //               title: Text(
// //                 'الرد على الرسالة',
// //                 style: getRegularTextStyle(
// //                   fontSize: ManagerFontSize.s14,
// //                   color: Colors.black,
// //                 ),
// //               ),
// //               onTap: () {
// //                 Navigator.pop(context);
// //                 onReply();
// //               },
// //             ),
// //             ListTile(
// //               leading: Icon(Icons.add_reaction, color: ManagerColors.primaryColor),
// //               title: Text(
// //                 'إضافة تفاعل',
// //                 style: getRegularTextStyle(
// //                   fontSize: ManagerFontSize.s14,
// //                   color: Colors.black,
// //                 ),
// //               ),
// //               onTap: () {
// //                 Navigator.pop(context);
// //                 _showReactionPicker(context);
// //               },
// //             ),
// //             if (isMine && onTapStatus != null)
// //               ListTile(
// //                 leading: Icon(Icons.info_outline, color: ManagerColors.primaryColor),
// //                 title: Text(
// //                   'حالة الرسالة',
// //                   style: getRegularTextStyle(
// //                     fontSize: ManagerFontSize.s14,
// //                     color: Colors.black,
// //                   ),
// //                 ),
// //                 onTap: () {
// //                   Navigator.pop(context);
// //                   onTapStatus!();
// //                 },
// //               ),
// //             ListTile(
// //               leading: Icon(Icons.copy, color: ManagerColors.primaryColor),
// //               title: Text(
// //                 'نسخ النص',
// //                 style: getRegularTextStyle(
// //                   fontSize: ManagerFontSize.s14,
// //                   color: Colors.black,
// //                 ),
// //               ),
// //               onTap: () {
// //                 Navigator.pop(context);
// //                 Clipboard.setData(ClipboardData(text: message.content));
// //                 ScaffoldMessenger.of(context).showSnackBar(
// //                   const SnackBar(
// //                     content: Text('تم نسخ النص'),
// //                     duration: Duration(seconds: 1),
// //                   ),
// //                 );
// //               },
// //             ),
// //             if (controller.canDeleteMessage(message))
// //               ListTile(
// //                 leading: const Icon(Icons.delete, color: Colors.red),
// //                 title: Text(
// //                   'حذف الرسالة',
// //                   style: getRegularTextStyle(
// //                     fontSize: ManagerFontSize.s14,
// //                     color: Colors.red,
// //                   ),
// //                 ),
// //                 onTap: () {
// //                   Navigator.pop(context);
// //                   _confirmDelete(context);
// //                 },
// //               ),
// //             SizedBox(height: ManagerHeight.h8),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   void _showReactionPicker(BuildContext context) {
// //     final controller = ChatGroupController.to;
// //     final reactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
// //
// //     showModalBottomSheet(
// //       context: context,
// //       backgroundColor: Colors.white,
// //       shape: const RoundedRectangleBorder(
// //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
// //       ),
// //       builder: (context) => Container(
// //         padding: EdgeInsets.all(ManagerWidth.w20),
// //         child: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Text(
// //               'اختر تفاعلك',
// //               style: getBoldTextStyle(
// //                 fontSize: ManagerFontSize.s16,
// //                 color: Colors.black,
// //               ),
// //             ),
// //             SizedBox(height: ManagerHeight.h20),
// //             Wrap(
// //               spacing: 16,
// //               runSpacing: 16,
// //               children: reactions.map((emoji) {
// //                 return GestureDetector(
// //                   onTap: () {
// //                     Navigator.pop(context);
// //                     controller.addReaction(message, emoji);
// //                   },
// //                   child: Container(
// //                     width: 50,
// //                     height: 50,
// //                     decoration: BoxDecoration(
// //                       color: Colors.grey.shade100,
// //                       borderRadius: BorderRadius.circular(25),
// //                     ),
// //                     child: Center(
// //                       child: Text(
// //                         emoji,
// //                         style: const TextStyle(fontSize: 28),
// //                       ),
// //                     ),
// //                   ),
// //                 );
// //               }).toList(),
// //             ),
// //             SizedBox(height: ManagerHeight.h20),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   void _confirmDelete(BuildContext context) {
// //     final controller = ChatGroupController.to;
// //
// //     Get.dialog(
// //       AlertDialog(
// //         title: const Text('حذف الرسالة'),
// //         content: const Text('هل أنت متأكد من حذف هذه الرسالة؟'),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Get.back(),
// //             child: const Text('إلغاء'),
// //           ),
// //           TextButton(
// //             onPressed: () {
// //               Get.back();
// //               controller.deleteMessage(message);
// //             },
// //             style: TextButton.styleFrom(foregroundColor: Colors.red),
// //             child: const Text('حذف'),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   String _formatTime(DateTime time) {
// //     final hour = time.hour.toString().padLeft(2, '0');
// //     final minute = time.minute.toString().padLeft(2, '0');
// //     return "$hour:$minute";
// //   }
// // }
// //
// // // ================================
// // // ✅ أنواع الرسائل
// // // ================================
// // enum MessageType {
// //   text,
// //   image,
// //   video,
// //   audio,
// //   file,
// // }
// //
// // // ================================
// // // ✅ مشغل الصوت بتصميم واتساب
// // // ================================
// // class _WhatsAppAudioPlayer extends StatefulWidget {
// //   final AttachmentModel attachment;
// //   final bool isMine;
// //
// //   const _WhatsAppAudioPlayer({
// //     required this.attachment,
// //     required this.isMine,
// //   });
// //
// //   @override
// //   State<_WhatsAppAudioPlayer> createState() => __WhatsAppAudioPlayerState();
// // }
// //
// // class __WhatsAppAudioPlayerState extends State<_WhatsAppAudioPlayer> {
// //   final AudioPlayer _audioPlayer = AudioPlayer();
// //   bool _isPlaying = false;
// //   bool _isLoading = false;
// //   Duration _duration = Duration.zero;
// //   Duration _position = Duration.zero;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _initAudioPlayer();
// //   }
// //
// //   Future<void> _initAudioPlayer() async {
// //     try {
// //       _audioPlayer.durationStream.listen((duration) {
// //         if (mounted) {
// //           setState(() {
// //             _duration = duration ?? Duration.zero;
// //           });
// //         }
// //       });
// //
// //       _audioPlayer.positionStream.listen((position) {
// //         if (mounted) {
// //           setState(() {
// //             _position = position;
// //           });
// //         }
// //       });
// //
// //       _audioPlayer.playerStateStream.listen((state) {
// //         if (state.processingState == ProcessingState.completed) {
// //           if (mounted) {
// //             setState(() {
// //               _isPlaying = false;
// //               _position = Duration.zero;
// //             });
// //           }
// //           _audioPlayer.seek(Duration.zero);
// //         }
// //       });
// //     } catch (e) {
// //       print('❌ خطأ في تهيئة مشغل الصوت: $e');
// //     }
// //   }
// //
// //   Future<void> _togglePlayPause() async {
// //     try {
// //       if (_isLoading) return;
// //
// //       if (_isPlaying) {
// //         await _audioPlayer.pause();
// //         setState(() {
// //           _isPlaying = false;
// //         });
// //       } else {
// //         setState(() {
// //           _isLoading = true;
// //         });
// //
// //         if (_audioPlayer.duration == null) {
// //           if (widget.attachment.localPath != null) {
// //             await _audioPlayer.setFilePath(widget.attachment.localPath!);
// //           } else {
// //             await _audioPlayer.setUrl(widget.attachment.url);
// //           }
// //         }
// //
// //         await _audioPlayer.play();
// //         setState(() {
// //           _isPlaying = true;
// //           _isLoading = false;
// //         });
// //       }
// //     } catch (e) {
// //       print('❌ خطأ في تشغيل الصوت: $e');
// //       setState(() {
// //         _isLoading = false;
// //         _isPlaying = false;
// //       });
// //     }
// //   }
// //
// //   @override
// //   void dispose() {
// //     _audioPlayer.dispose();
// //     super.dispose();
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       width: 200,
// //       padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
// //       decoration: BoxDecoration(
// //         color: widget.isMine
// //             ? ManagerColors.primaryColor.withOpacity(0.9)
// //             : Colors.grey.shade300,
// //         borderRadius: BorderRadius.circular(20),
// //       ),
// //       child: Row(
// //         children: [
// //           // زر التشغيل/الإيقاف
// //           GestureDetector(
// //             onTap: _togglePlayPause,
// //             child: Container(
// //               width: 32,
// //               height: 32,
// //               decoration: BoxDecoration(
// //                 color: widget.isMine ? Colors.white : ManagerColors.primaryColor,
// //                 shape: BoxShape.circle,
// //               ),
// //               child: _isLoading
// //                   ? Center(
// //                 child: SizedBox(
// //                   width: 16,
// //                   height: 16,
// //                   child: CircularProgressIndicator(
// //                     strokeWidth: 2,
// //                     valueColor: AlwaysStoppedAnimation<Color>(
// //                       widget.isMine ? ManagerColors.primaryColor : Colors.white,
// //                     ),
// //                   ),
// //                 ),
// //               )
// //                   : Icon(
// //                 _isPlaying ? Icons.pause : Icons.play_arrow,
// //                 size: 18,
// //                 color: widget.isMine ? ManagerColors.primaryColor : Colors.white,
// //               ),
// //             ),
// //           ),
// //
// //           SizedBox(width: 12),
// //
// //           // شريط التقدم
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 // شريط التقدم
// //                 SliderTheme(
// //                   data: SliderThemeData(
// //                     trackHeight: 2,
// //                     thumbShape: RoundSliderThumbShape(
// //                       enabledThumbRadius: 6,
// //                     ),
// //                     overlayShape: RoundSliderOverlayShape(
// //                       overlayRadius: 12,
// //                     ),
// //                   ),
// //                   child: Slider(
// //                     value: _position.inMilliseconds.toDouble(),
// //                     max: _duration.inMilliseconds.toDouble() > 0
// //                         ? _duration.inMilliseconds.toDouble()
// //                         : 1.0,
// //                     onChanged: (value) {
// //                       _audioPlayer.seek(Duration(milliseconds: value.toInt()));
// //                     },
// //                     activeColor: widget.isMine ? Colors.white : ManagerColors.primaryColor,
// //                     inactiveColor: widget.isMine ? Colors.white.withOpacity(0.3) : Colors.grey.shade400,
// //                   ),
// //                 ),
// //
// //                 // الوقت
// //                 Text(
// //                   _formatDuration(_position),
// //                   style: TextStyle(
// //                     fontSize: 12,
// //                     color: widget.isMine ? Colors.white.withOpacity(0.8) : Colors.grey.shade600,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   String _formatDuration(Duration duration) {
// //     String twoDigits(int n) => n.toString().padLeft(2, '0');
// //     final minutes = twoDigits(duration.inMinutes.remainder(60));
// //     final seconds = twoDigits(duration.inSeconds.remainder(60));
// //     return '$minutes:$seconds';
// //   }
// // }
// // // المسار: lib/features/home/group_chat/presentation/widgets/message_bubble_updated.dart
// //
// // import 'package:app_mobile/features/home/group_chat/domain/models/attachment_model.dart';
// // import 'package:app_mobile/features/home/group_chat/domain/models/message_model.dart';
// // import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart';
// // import 'package:get/get.dart';
// // import 'package:app_mobile/core/resources/manager_colors.dart';
// // import 'package:app_mobile/core/resources/manager_font_size.dart';
// // import 'package:app_mobile/core/resources/manager_height.dart';
// // import 'package:app_mobile/core/resources/manager_width.dart';
// // import 'package:app_mobile/core/resources/manager_styles.dart';
// // import '../controller/chat_group_controller.dart';
// // import 'message_image_widget.dart';
// // import 'message_audio_widget.dart';
// // import 'message_file_widget.dart';
// // import 'message_video_widget.dart';
// //
// // class MessageBubble extends StatelessWidget {
// //   final MessageModel message;
// //   final bool isMine;
// //   final VoidCallback onReply;
// //   final VoidCallback? onTapStatus;
// //   final List<AttachmentModel>? attachments;
// //
// //   const MessageBubble({
// //     super.key,
// //     required this.message,
// //     required this.isMine,
// //     required this.onReply,
// //     this.onTapStatus,
// //     this.attachments,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     if (message.isDeleted) {
// //       return _buildDeletedMessage();
// //     }
// //
// //     // ✅ الحل: استخدام attachments الممررة أولاً، إذا لم توجد نستخرج من المحتوى
// //     final allAttachments = attachments ?? _extractAttachmentsFromMessage();
// //     final displayContent = _getDisplayContent();
// //
// //     return GestureDetector(
// //       onLongPress: () => _showMessageOptions(context),
// //       child: Align(
// //         alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
// //         child: Container(
// //           margin: EdgeInsets.symmetric(vertical: ManagerHeight.h6),
// //           constraints: BoxConstraints(
// //             maxWidth: MediaQuery.of(context).size.width * 0.75,
// //           ),
// //           decoration: BoxDecoration(
// //             color: isMine ? ManagerColors.primaryColor : Colors.grey.shade100,
// //             borderRadius: BorderRadius.only(
// //               topLeft: const Radius.circular(16),
// //               topRight: const Radius.circular(16),
// //               bottomLeft: Radius.circular(isMine ? 16 : 4),
// //               bottomRight: Radius.circular(isMine ? 4 : 16),
// //             ),
// //             boxShadow: [
// //               BoxShadow(
// //                 color: Colors.black.withOpacity(0.05),
// //                 blurRadius: 4,
// //                 offset: const Offset(0, 2),
// //               ),
// //             ],
// //           ),
// //           child: Column(
// //             crossAxisAlignment:
// //             isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
// //             children: [
// //               // Reply Preview
// //               if (message.replyTo != null) _buildReplyPreview(),
// //
// //               // ✅ Attachments (مرة واحدة فقط)
// //               if (allAttachments.isNotEmpty)
// //                 _buildAttachments(allAttachments),
// //
// //               // Message Content (إذا فيه نص حقيقي)
// //               if (displayContent.isNotEmpty)
// //                 Padding(
// //                   padding: EdgeInsets.all(ManagerWidth.w12),
// //                   child: _buildMessageContent(displayContent),
// //                 ),
// //
// //               // Reactions
// //               if (message.reactions != null && message.reactions!.isNotEmpty)
// //                 _buildReactions(),
// //
// //               // Message Footer (Time + Status)
// //               Padding(
// //                 padding: EdgeInsets.only(
// //                   left: ManagerWidth.w12,
// //                   right: ManagerWidth.w12,
// //                   bottom: ManagerHeight.h8,
// //                 ),
// //                 child: _buildMessageFooter(),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // ================================
// //   // ✅ BUILD ATTACHMENTS
// //   // ================================
// //   Widget _buildAttachments(List<AttachmentModel> attachments) {
// //     return Padding(
// //       padding: EdgeInsets.all(ManagerWidth.w8),
// //       child: Column(
// //         children: attachments.map((attachment) {
// //           switch (attachment.type) {
// //             case 'image':
// //               return MessageImageWidget(
// //                 attachment: attachment,
// //                 isMine: isMine,
// //               );
// //             case 'video':
// //               return MessageVideoWidget(
// //                 attachment: attachment,
// //                 isMine: isMine,
// //               );
// //             case 'audio':
// //               return MessageAudioWidget(
// //                 attachment: attachment,
// //                 isMine: isMine,
// //               );
// //             case 'file':
// //               return MessageFileWidget(
// //                 attachment: attachment,
// //                 isMine: isMine,
// //               );
// //             default:
// //               return const SizedBox.shrink();
// //           }
// //         }).toList(),
// //       ),
// //     );
// //   }
// //
// //   // ================================
// //   // ✅ DELETED MESSAGE
// //   // ================================
// //   Widget _buildDeletedMessage() {
// //     return Align(
// //       alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
// //       child: Container(
// //         margin: EdgeInsets.symmetric(vertical: ManagerHeight.h6),
// //         padding: EdgeInsets.all(ManagerWidth.w12),
// //         decoration: BoxDecoration(
// //           color: Colors.grey.shade200,
// //           borderRadius: BorderRadius.circular(12),
// //         ),
// //         child: Row(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Icon(Icons.block, size: 16, color: Colors.grey.shade600),
// //             SizedBox(width: ManagerWidth.w8),
// //             Text(
// //               'تم حذف هذه الرسالة',
// //               style: getRegularTextStyle(
// //                 fontSize: ManagerFontSize.s13,
// //                 color: Colors.grey.shade600,
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // ================================
// //   // ✅ REPLY PREVIEW
// //   // ================================
// //   Widget _buildReplyPreview() {
// //     return Container(
// //       margin: EdgeInsets.all(ManagerWidth.w8),
// //       padding: EdgeInsets.all(ManagerWidth.w8),
// //       decoration: BoxDecoration(
// //         color: Colors.white.withOpacity(isMine ? 0.2 : 0.3),
// //         borderRadius: BorderRadius.circular(8),
// //         border: Border(
// //           right: BorderSide(
// //             color: isMine ? Colors.white : ManagerColors.primaryColor,
// //             width: 3,
// //           ),
// //         ),
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Row(
// //             children: [
// //               Icon(
// //                 Icons.reply,
// //                 size: 14,
// //                 color: isMine
// //                     ? Colors.white.withOpacity(0.9)
// //                     : Colors.grey.shade700,
// //               ),
// //               SizedBox(width: ManagerWidth.w4),
// //               Text(
// //                 "ردًا على",
// //                 style: getBoldTextStyle(
// //                   fontSize: ManagerFontSize.s10,
// //                   color: isMine
// //                       ? Colors.white.withOpacity(0.9)
// //                       : Colors.grey.shade700,
// //                 ),
// //               ),
// //             ],
// //           ),
// //           SizedBox(height: ManagerHeight.h4),
// //           Text(
// //             message.replyTo ?? '',
// //             style: getRegularTextStyle(
// //               fontSize: ManagerFontSize.s12,
// //               color: isMine
// //                   ? Colors.white.withOpacity(0.8)
// //                   : Colors.grey.shade600,
// //             ),
// //             maxLines: 2,
// //             overflow: TextOverflow.ellipsis,
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   // ================================
// //   // ✅ MESSAGE CONTENT
// //   // ================================
// //   Widget _buildMessageContent(String content) {
// //     return Text(
// //       _highlightMentions(content),
// //       style: getRegularTextStyle(
// //         fontSize: ManagerFontSize.s14,
// //         color: isMine ? Colors.white : Colors.black87,
// //       ),
// //     );
// //   }
// //
// //   // ================================
// //   // ✅ EXTRACT ATTACHMENTS AND CONTENT
// //   // ================================
// //   List<AttachmentModel> _extractAttachmentsFromMessage() {
// //     final attachments = <AttachmentModel>[];
// //     final content = message.content;
// //
// //     // أنماط للتعرف على الوسائط المختلفة
// //     final cloudinaryPattern = RegExp(r'https://res\.cloudinary\.com/[^\s]+');
// //     final matches = cloudinaryPattern.allMatches(content);
// //
// //     for (final match in matches) {
// //       final url = match.group(0)!;
// //       final type = _getMediaTypeFromUrl(url);
// //
// //       attachments.add(AttachmentModel(
// //         id: '${message.id}_${attachments.length}',
// //         url: url,
// //         type: type,
// //         fileName: _getFileNameFromUrl(url),
// //         uploadProgress: 1.0,
// //       ));
// //     }
// //
// //     return attachments;
// //   }
// //
// //   String _getDisplayContent() {
// //     final content = message.content;
// //
// //     // إذا كان هناك attachments، نزيل الروابط من النص
// //     final hasAttachments = attachments != null && attachments!.isNotEmpty;
// //
// //     if (hasAttachments) {
// //       // إزالة جميع روابط Cloudinary من النص
// //       final cloudinaryPattern = RegExp(r'https://res\.cloudinary\.com/[^\s]+');
// //       final cleanedContent = content.replaceAll(cloudinaryPattern, '').trim();
// //
// //       // إزالة أيقونات الوسائط إذا كانت وحدها
// //       final mediaIconsPattern = RegExp(r'^(📷|🎥|🎤|📎)\s*$');
// //       if (mediaIconsPattern.hasMatch(cleanedContent)) {
// //         return '';
// //       }
// //
// //       return cleanedContent;
// //     }
// //
// //     return content.trim();
// //   }
// //
// //   String _getMediaTypeFromUrl(String url) {
// //     if (url.contains('/image/') ||
// //         url.contains('.jpg') ||
// //         url.contains('.png') ||
// //         url.contains('.jpeg') ||
// //         url.contains('.webp')) {
// //       return 'image';
// //     } else if (url.contains('/video/') ||
// //         url.contains('.mp4') ||
// //         url.contains('.mov') ||
// //         url.contains('.avi')) {
// //       return 'video';
// //     } else if (url.contains('/audio/') ||
// //         url.contains('.mp3') ||
// //         url.contains('.m4a') ||
// //         url.contains('.wav')) {
// //       return 'audio';
// //     } else {
// //       return 'file';
// //     }
// //   }
// //
// //   String _getFileNameFromUrl(String url) {
// //     final uri = Uri.parse(url);
// //     final pathSegments = uri.pathSegments;
// //     return pathSegments.isNotEmpty ? pathSegments.last : 'file';
// //   }
// //
// //   String _highlightMentions(String content) {
// //     // TODO: Implement mention highlighting
// //     return content;
// //   }
// //
// //   // ================================
// //   // ✅ REACTIONS
// //   // ================================
// //   Widget _buildReactions() {
// //     final reactions = message.reactions!;
// //     final reactionCounts = <String, int>{};
// //
// //     for (var emoji in reactions.values) {
// //       reactionCounts[emoji.toString()] =
// //           (reactionCounts[emoji.toString()] ?? 0) + 1;
// //     }
// //
// //     return Container(
// //       margin: EdgeInsets.symmetric(horizontal: ManagerWidth.w8),
// //       padding: EdgeInsets.all(ManagerWidth.w6),
// //       decoration: BoxDecoration(
// //         color: Colors.white.withOpacity(isMine ? 0.2 : 0.8),
// //         borderRadius: BorderRadius.circular(12),
// //       ),
// //       child: Wrap(
// //         spacing: 4,
// //         children: reactionCounts.entries.map((entry) {
// //           return Container(
// //             padding: EdgeInsets.symmetric(
// //               horizontal: ManagerWidth.w6,
// //               vertical: ManagerHeight.h2,
// //             ),
// //             decoration: BoxDecoration(
// //               color: Colors.white.withOpacity(0.3),
// //               borderRadius: BorderRadius.circular(10),
// //             ),
// //             child: Row(
// //               mainAxisSize: MainAxisSize.min,
// //               children: [
// //                 Text(entry.key, style: const TextStyle(fontSize: 14)),
// //                 if (entry.value > 1) ...[
// //                   SizedBox(width: ManagerWidth.w2),
// //                   Text(
// //                     '${entry.value}',
// //                     style: getBoldTextStyle(
// //                       fontSize: ManagerFontSize.s10,
// //                       color: isMine ? Colors.white : Colors.black87,
// //                     ),
// //                   ),
// //                 ],
// //               ],
// //             ),
// //           );
// //         }).toList(),
// //       ),
// //     );
// //   }
// //
// //   // ================================
// //   // ✅ MESSAGE FOOTER
// //   // ================================
// //   Widget _buildMessageFooter() {
// //     return Row(
// //       mainAxisSize: MainAxisSize.min,
// //       children: [
// //         Text(
// //           _formatTime(message.timestamp),
// //           style: getRegularTextStyle(
// //             fontSize: ManagerFontSize.s10,
// //             color: isMine ? Colors.white.withOpacity(0.7) : Colors.grey,
// //           ),
// //         ),
// //         if (isMine) ...[
// //           SizedBox(width: ManagerWidth.w4),
// //           GestureDetector(
// //             onTap: onTapStatus,
// //             child: _buildStatusIcon(),
// //           ),
// //         ],
// //       ],
// //     );
// //   }
// //
// //   Widget _buildStatusIcon() {
// //     IconData icon;
// //     Color color;
// //
// //     if (message.isFailed) {
// //       icon = Icons.error_outline;
// //       color = Colors.red.shade300;
// //     } else if (message.isFullySeen) {
// //       icon = Icons.done_all;
// //       color = Colors.blue.shade200;
// //     } else if (message.isSeen) {
// //       icon = Icons.done_all;
// //       color = Colors.blue.shade200;
// //     } else if (message.isFullyDelivered) {
// //       icon = Icons.done_all;
// //       color = Colors.white.withOpacity(0.7);
// //     } else if (message.isDelivered) {
// //       icon = Icons.done_all;
// //       color = Colors.white.withOpacity(0.7);
// //     } else {
// //       icon = Icons.done;
// //       color = Colors.white.withOpacity(0.7);
// //     }
// //
// //     return Icon(
// //       icon,
// //       size: 16,
// //       color: color,
// //     );
// //   }
// //
// //   // ================================
// //   // ✅ MESSAGE OPTIONS
// //   // ================================
// //   void _showMessageOptions(BuildContext context) {
// //     final controller = ChatGroupController.to;
// //
// //     showModalBottomSheet(
// //       context: context,
// //       backgroundColor: Colors.white,
// //       shape: const RoundedRectangleBorder(
// //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
// //       ),
// //       builder: (context) => SafeArea(
// //         child: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Container(
// //               margin: EdgeInsets.only(top: ManagerHeight.h8),
// //               width: 40,
// //               height: 4,
// //               decoration: BoxDecoration(
// //                 color: Colors.grey.shade300,
// //                 borderRadius: BorderRadius.circular(2),
// //               ),
// //             ),
// //             ListTile(
// //               leading: Icon(Icons.reply, color: ManagerColors.primaryColor),
// //               title: Text(
// //                 'الرد على الرسالة',
// //                 style: getRegularTextStyle(
// //                   fontSize: ManagerFontSize.s14,
// //                   color: Colors.black,
// //                 ),
// //               ),
// //               onTap: () {
// //                 Navigator.pop(context);
// //                 onReply();
// //               },
// //             ),
// //             ListTile(
// //               leading: Icon(Icons.add_reaction, color: ManagerColors.primaryColor),
// //               title: Text(
// //                 'إضافة تفاعل',
// //                 style: getRegularTextStyle(
// //                   fontSize: ManagerFontSize.s14,
// //                   color: Colors.black,
// //                 ),
// //               ),
// //               onTap: () {
// //                 Navigator.pop(context);
// //                 _showReactionPicker(context);
// //               },
// //             ),
// //             if (isMine && onTapStatus != null)
// //               ListTile(
// //                 leading: Icon(Icons.info_outline, color: ManagerColors.primaryColor),
// //                 title: Text(
// //                   'حالة الرسالة',
// //                   style: getRegularTextStyle(
// //                     fontSize: ManagerFontSize.s14,
// //                     color: Colors.black,
// //                   ),
// //                 ),
// //                 onTap: () {
// //                   Navigator.pop(context);
// //                   onTapStatus!();
// //                 },
// //               ),
// //             ListTile(
// //               leading: Icon(Icons.copy, color: ManagerColors.primaryColor),
// //               title: Text(
// //                 'نسخ النص',
// //                 style: getRegularTextStyle(
// //                   fontSize: ManagerFontSize.s14,
// //                   color: Colors.black,
// //                 ),
// //               ),
// //               onTap: () {
// //                 Navigator.pop(context);
// //                 Clipboard.setData(ClipboardData(text: message.content));
// //                 ScaffoldMessenger.of(context).showSnackBar(
// //                   const SnackBar(
// //                     content: Text('تم نسخ النص'),
// //                     duration: Duration(seconds: 1),
// //                   ),
// //                 );
// //               },
// //             ),
// //             if (controller.canDeleteMessage(message))
// //               ListTile(
// //                 leading: const Icon(Icons.delete, color: Colors.red),
// //                 title: Text(
// //                   'حذف الرسالة',
// //                   style: getRegularTextStyle(
// //                     fontSize: ManagerFontSize.s14,
// //                     color: Colors.red,
// //                   ),
// //                 ),
// //                 onTap: () {
// //                   Navigator.pop(context);
// //                   _confirmDelete(context);
// //                 },
// //               ),
// //             SizedBox(height: ManagerHeight.h8),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   void _showReactionPicker(BuildContext context) {
// //     final controller = ChatGroupController.to;
// //     final reactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
// //
// //     showModalBottomSheet(
// //       context: context,
// //       backgroundColor: Colors.white,
// //       shape: const RoundedRectangleBorder(
// //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
// //       ),
// //       builder: (context) => Container(
// //         padding: EdgeInsets.all(ManagerWidth.w20),
// //         child: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Text(
// //               'اختر تفاعلك',
// //               style: getBoldTextStyle(
// //                 fontSize: ManagerFontSize.s16,
// //                 color: Colors.black,
// //               ),
// //             ),
// //             SizedBox(height: ManagerHeight.h20),
// //             Wrap(
// //               spacing: 16,
// //               runSpacing: 16,
// //               children: reactions.map((emoji) {
// //                 return GestureDetector(
// //                   onTap: () {
// //                     Navigator.pop(context);
// //                     controller.addReaction(message, emoji);
// //                   },
// //                   child: Container(
// //                     width: 50,
// //                     height: 50,
// //                     decoration: BoxDecoration(
// //                       color: Colors.grey.shade100,
// //                       borderRadius: BorderRadius.circular(25),
// //                     ),
// //                     child: Center(
// //                       child: Text(
// //                         emoji,
// //                         style: const TextStyle(fontSize: 28),
// //                       ),
// //                     ),
// //                   ),
// //                 );
// //               }).toList(),
// //             ),
// //             SizedBox(height: ManagerHeight.h20),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   void _confirmDelete(BuildContext context) {
// //     final controller = ChatGroupController.to;
// //
// //     Get.dialog(
// //       AlertDialog(
// //         title: const Text('حذف الرسالة'),
// //         content: const Text('هل أنت متأكد من حذف هذه الرسالة؟'),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Get.back(),
// //             child: const Text('إلغاء'),
// //           ),
// //           TextButton(
// //             onPressed: () {
// //               Get.back();
// //               controller.deleteMessage(message);
// //             },
// //             style: TextButton.styleFrom(foregroundColor: Colors.red),
// //             child: const Text('حذف'),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   String _formatTime(DateTime time) {
// //     final hour = time.hour.toString().padLeft(2, '0');
// //     final minute = time.minute.toString().padLeft(2, '0');
// //     return "$hour:$minute";
// //   }
// // }
// // // المسار: lib/features/home/group_chat/presentation/widgets/message_bubble_updated.dart
// //
// // import 'package:app_mobile/features/home/group_chat/domain/models/attachment_model.dart';
// // import 'package:app_mobile/features/home/group_chat/domain/models/message_model.dart';
// // import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart';
// // import 'package:get/get.dart';
// // import 'package:app_mobile/core/resources/manager_colors.dart';
// // import 'package:app_mobile/core/resources/manager_font_size.dart';
// // import 'package:app_mobile/core/resources/manager_height.dart';
// // import 'package:app_mobile/core/resources/manager_width.dart';
// // import 'package:app_mobile/core/resources/manager_styles.dart';
// // import '../controller/chat_group_controller.dart';
// // import 'message_image_widget.dart';
// // import 'message_audio_widget.dart';
// // import 'message_file_widget.dart';
// // import 'message_video_widget.dart';
// //
// // class MessageBubble extends StatelessWidget {
// //   final MessageModel message;
// //   final bool isMine;
// //   final VoidCallback onReply;
// //   final VoidCallback? onTapStatus;
// //   final List<AttachmentModel>? attachments;
// //
// //   const MessageBubble({
// //     super.key,
// //     required this.message,
// //     required this.isMine,
// //     required this.onReply,
// //     this.onTapStatus,
// //     this.attachments,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     if (message.isDeleted) {
// //       return _buildDeletedMessage();
// //     }
// //
// //     // استخراج الـ attachments من محتوى الرسالة
// //     final extractedAttachments = _extractAttachmentsFromMessage();
// //     final allAttachments = attachments ?? extractedAttachments;
// //     final displayContent = _getDisplayContent();
// //
// //     return GestureDetector(
// //       onLongPress: () => _showMessageOptions(context),
// //       child: Align(
// //         alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
// //         child: Container(
// //           margin: EdgeInsets.symmetric(vertical: ManagerHeight.h6),
// //           constraints: BoxConstraints(
// //             maxWidth: MediaQuery.of(context).size.width * 0.75,
// //           ),
// //           decoration: BoxDecoration(
// //             color: isMine ? ManagerColors.primaryColor : Colors.grey.shade100,
// //             borderRadius: BorderRadius.only(
// //               topLeft: const Radius.circular(16),
// //               topRight: const Radius.circular(16),
// //               bottomLeft: Radius.circular(isMine ? 16 : 4),
// //               bottomRight: Radius.circular(isMine ? 4 : 16),
// //             ),
// //             boxShadow: [
// //               BoxShadow(
// //                 color: Colors.black.withOpacity(0.05),
// //                 blurRadius: 4,
// //                 offset: const Offset(0, 2),
// //               ),
// //             ],
// //           ),
// //           child: Column(
// //             crossAxisAlignment:
// //             isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
// //             children: [
// //               // Reply Preview
// //               if (message.replyTo != null) _buildReplyPreview(),
// //
// //               // ✅ Attachments
// //               if (allAttachments.isNotEmpty)
// //                 _buildAttachments(allAttachments),
// //
// //               // Message Content (إذا فيه نص حقيقي)
// //               if (displayContent.isNotEmpty)
// //                 Padding(
// //                   padding: EdgeInsets.all(ManagerWidth.w12),
// //                   child: _buildMessageContent(displayContent),
// //                 ),
// //
// //               // Reactions
// //               if (message.reactions != null && message.reactions!.isNotEmpty)
// //                 _buildReactions(),
// //
// //               // Message Footer (Time + Status)
// //               Padding(
// //                 padding: EdgeInsets.only(
// //                   left: ManagerWidth.w12,
// //                   right: ManagerWidth.w12,
// //                   bottom: ManagerHeight.h8,
// //                 ),
// //                 child: _buildMessageFooter(),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // ================================
// //   // ✅ BUILD ATTACHMENTS
// //   // ================================
// //   Widget _buildAttachments(List<AttachmentModel> attachments) {
// //     return Padding(
// //       padding: EdgeInsets.all(ManagerWidth.w8),
// //       child: Column(
// //         children: attachments.map((attachment) {
// //           switch (attachment.type) {
// //             case 'image':
// //               return MessageImageWidget(
// //                 attachment: attachment,
// //                 isMine: isMine,
// //               );
// //             case 'video':
// //               return MessageVideoWidget(
// //                 attachment: attachment,
// //                 isMine: isMine,
// //               );
// //             case 'audio':
// //               return MessageAudioWidget(
// //                 attachment: attachment,
// //                 isMine: isMine,
// //               );
// //             case 'file':
// //               return MessageFileWidget(
// //                 attachment: attachment,
// //                 isMine: isMine,
// //               );
// //             default:
// //               return const SizedBox.shrink();
// //           }
// //         }).toList(),
// //       ),
// //     );
// //   }
// //
// //   // ================================
// //   // ✅ DELETED MESSAGE
// //   // ================================
// //   Widget _buildDeletedMessage() {
// //     return Align(
// //       alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
// //       child: Container(
// //         margin: EdgeInsets.symmetric(vertical: ManagerHeight.h6),
// //         padding: EdgeInsets.all(ManagerWidth.w12),
// //         decoration: BoxDecoration(
// //           color: Colors.grey.shade200,
// //           borderRadius: BorderRadius.circular(12),
// //         ),
// //         child: Row(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Icon(Icons.block, size: 16, color: Colors.grey.shade600),
// //             SizedBox(width: ManagerWidth.w8),
// //             Text(
// //               'تم حذف هذه الرسالة',
// //               style: getRegularTextStyle(
// //                 fontSize: ManagerFontSize.s13,
// //                 color: Colors.grey.shade600,
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // ================================
// //   // ✅ REPLY PREVIEW
// //   // ================================
// //   Widget _buildReplyPreview() {
// //     return Container(
// //       margin: EdgeInsets.all(ManagerWidth.w8),
// //       padding: EdgeInsets.all(ManagerWidth.w8),
// //       decoration: BoxDecoration(
// //         color: Colors.white.withOpacity(isMine ? 0.2 : 0.3),
// //         borderRadius: BorderRadius.circular(8),
// //         border: Border(
// //           right: BorderSide(
// //             color: isMine ? Colors.white : ManagerColors.primaryColor,
// //             width: 3,
// //           ),
// //         ),
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Row(
// //             children: [
// //               Icon(
// //                 Icons.reply,
// //                 size: 14,
// //                 color: isMine
// //                     ? Colors.white.withOpacity(0.9)
// //                     : Colors.grey.shade700,
// //               ),
// //               SizedBox(width: ManagerWidth.w4),
// //               Text(
// //                 "ردًا على",
// //                 style: getBoldTextStyle(
// //                   fontSize: ManagerFontSize.s10,
// //                   color: isMine
// //                       ? Colors.white.withOpacity(0.9)
// //                       : Colors.grey.shade700,
// //                 ),
// //               ),
// //             ],
// //           ),
// //           SizedBox(height: ManagerHeight.h4),
// //           Text(
// //             message.replyTo ?? '',
// //             style: getRegularTextStyle(
// //               fontSize: ManagerFontSize.s12,
// //               color: isMine
// //                   ? Colors.white.withOpacity(0.8)
// //                   : Colors.grey.shade600,
// //             ),
// //             maxLines: 2,
// //             overflow: TextOverflow.ellipsis,
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   // ================================
// //   // ✅ MESSAGE CONTENT
// //   // ================================
// //   Widget _buildMessageContent(String content) {
// //     return Text(
// //       _highlightMentions(content),
// //       style: getRegularTextStyle(
// //         fontSize: ManagerFontSize.s14,
// //         color: isMine ? Colors.white : Colors.black87,
// //       ),
// //     );
// //   }
// //
// //   // ================================
// //   // ✅ EXTRACT ATTACHMENTS AND CONTENT
// //   // ================================
// //   List<AttachmentModel> _extractAttachmentsFromMessage() {
// //     final attachments = <AttachmentModel>[];
// //     final content = message.content;
// //
// //     // أنماط للتعرف على الوسائط المختلفة
// //     final cloudinaryPattern = RegExp(r'https://res\.cloudinary\.com/[^\s]+');
// //     final matches = cloudinaryPattern.allMatches(content);
// //
// //     for (final match in matches) {
// //       final url = match.group(0)!;
// //       final type = _getMediaTypeFromUrl(url);
// //
// //       attachments.add(AttachmentModel(
// //         id: '${message.id}_${attachments.length}',
// //         url: url,
// //         type: type,
// //         fileName: _getFileNameFromUrl(url),
// //         uploadProgress: 1.0,
// //       ));
// //     }
// //
// //     return attachments;
// //   }
// //
// //   String _getDisplayContent() {
// //     final content = message.content;
// //
// //     // إذا كان المحتوى يحتوي فقط على روابط وسائط، نعيد نص فارغ
// //     final mediaUrlPattern = RegExp(
// //       r'^(?:https?://res\.cloudinary\.com/[^\s]+\s*)+(📷|🎥|🎤|📎)?\s*$',
// //     );
// //
// //     if (mediaUrlPattern.hasMatch(content.trim())) {
// //       return '';
// //     }
// //
// //     // إزالة روابط الوسائط من النص لعرض الباقي
// //     final cloudinaryPattern = RegExp(r'https://res\.cloudinary\.com/[^\s]+');
// //     final cleanedContent = content.replaceAll(cloudinaryPattern, '').trim();
// //
// //     // إزالة أيقونات الوسائط إذا كانت وحدها
// //     final mediaIconsPattern = RegExp(r'^(📷|🎥|🎤|📎)\s*$');
// //     if (mediaIconsPattern.hasMatch(cleanedContent)) {
// //       return '';
// //     }
// //
// //     return cleanedContent;
// //   }
// //
// //   String _getMediaTypeFromUrl(String url) {
// //     if (url.contains('/image/') ||
// //         url.contains('.jpg') ||
// //         url.contains('.png') ||
// //         url.contains('.jpeg') ||
// //         url.contains('.webp')) {
// //       return 'image';
// //     } else if (url.contains('/video/') ||
// //         url.contains('.mp4') ||
// //         url.contains('.mov') ||
// //         url.contains('.avi')) {
// //       return 'video';
// //     } else if (url.contains('/audio/') ||
// //         url.contains('.mp3') ||
// //         url.contains('.m4a') ||
// //         url.contains('.wav')) {
// //       return 'audio';
// //     } else {
// //       return 'file';
// //     }
// //   }
// //
// //   String _getFileNameFromUrl(String url) {
// //     final uri = Uri.parse(url);
// //     final pathSegments = uri.pathSegments;
// //     return pathSegments.isNotEmpty ? pathSegments.last : 'file';
// //   }
// //
// //   String _highlightMentions(String content) {
// //     // TODO: Implement mention highlighting
// //     return content;
// //   }
// //
// //   // ================================
// //   // ✅ REACTIONS
// //   // ================================
// //   Widget _buildReactions() {
// //     final reactions = message.reactions!;
// //     final reactionCounts = <String, int>{};
// //
// //     for (var emoji in reactions.values) {
// //       reactionCounts[emoji.toString()] =
// //           (reactionCounts[emoji.toString()] ?? 0) + 1;
// //     }
// //
// //     return Container(
// //       margin: EdgeInsets.symmetric(horizontal: ManagerWidth.w8),
// //       padding: EdgeInsets.all(ManagerWidth.w6),
// //       decoration: BoxDecoration(
// //         color: Colors.white.withOpacity(isMine ? 0.2 : 0.8),
// //         borderRadius: BorderRadius.circular(12),
// //       ),
// //       child: Wrap(
// //         spacing: 4,
// //         children: reactionCounts.entries.map((entry) {
// //           return Container(
// //             padding: EdgeInsets.symmetric(
// //               horizontal: ManagerWidth.w6,
// //               vertical: ManagerHeight.h2,
// //             ),
// //             decoration: BoxDecoration(
// //               color: Colors.white.withOpacity(0.3),
// //               borderRadius: BorderRadius.circular(10),
// //             ),
// //             child: Row(
// //               mainAxisSize: MainAxisSize.min,
// //               children: [
// //                 Text(entry.key, style: const TextStyle(fontSize: 14)),
// //                 if (entry.value > 1) ...[
// //                   SizedBox(width: ManagerWidth.w2),
// //                   Text(
// //                     '${entry.value}',
// //                     style: getBoldTextStyle(
// //                       fontSize: ManagerFontSize.s10,
// //                       color: isMine ? Colors.white : Colors.black87,
// //                     ),
// //                   ),
// //                 ],
// //               ],
// //             ),
// //           );
// //         }).toList(),
// //       ),
// //     );
// //   }
// //
// //   // ================================
// //   // ✅ MESSAGE FOOTER
// //   // ================================
// //   Widget _buildMessageFooter() {
// //     return Row(
// //       mainAxisSize: MainAxisSize.min,
// //       children: [
// //         Text(
// //           _formatTime(message.timestamp),
// //           style: getRegularTextStyle(
// //             fontSize: ManagerFontSize.s10,
// //             color: isMine ? Colors.white.withOpacity(0.7) : Colors.grey,
// //           ),
// //         ),
// //         if (isMine) ...[
// //           SizedBox(width: ManagerWidth.w4),
// //           GestureDetector(
// //             onTap: onTapStatus,
// //             child: _buildStatusIcon(),
// //           ),
// //         ],
// //       ],
// //     );
// //   }
// //
// //   Widget _buildStatusIcon() {
// //     IconData icon;
// //     Color color;
// //
// //     if (message.isFailed) {
// //       icon = Icons.error_outline;
// //       color = Colors.red.shade300;
// //     } else if (message.isFullySeen) {
// //       icon = Icons.done_all;
// //       color = Colors.blue.shade200;
// //     } else if (message.isSeen) {
// //       icon = Icons.done_all;
// //       color = Colors.blue.shade200;
// //     } else if (message.isFullyDelivered) {
// //       icon = Icons.done_all;
// //       color = Colors.white.withOpacity(0.7);
// //     } else if (message.isDelivered) {
// //       icon = Icons.done_all;
// //       color = Colors.white.withOpacity(0.7);
// //     } else {
// //       icon = Icons.done;
// //       color = Colors.white.withOpacity(0.7);
// //     }
// //
// //     return Icon(
// //       icon,
// //       size: 16,
// //       color: color,
// //     );
// //   }
// //
// //   // ================================
// //   // ✅ MESSAGE OPTIONS
// //   // ================================
// //   void _showMessageOptions(BuildContext context) {
// //     final controller = ChatGroupController.to;
// //
// //     showModalBottomSheet(
// //       context: context,
// //       backgroundColor: Colors.white,
// //       shape: const RoundedRectangleBorder(
// //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
// //       ),
// //       builder: (context) => SafeArea(
// //         child: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Container(
// //               margin: EdgeInsets.only(top: ManagerHeight.h8),
// //               width: 40,
// //               height: 4,
// //               decoration: BoxDecoration(
// //                 color: Colors.grey.shade300,
// //                 borderRadius: BorderRadius.circular(2),
// //               ),
// //             ),
// //             ListTile(
// //               leading: Icon(Icons.reply, color: ManagerColors.primaryColor),
// //               title: Text(
// //                 'الرد على الرسالة',
// //                 style: getRegularTextStyle(
// //                   fontSize: ManagerFontSize.s14,
// //                   color: Colors.black,
// //                 ),
// //               ),
// //               onTap: () {
// //                 Navigator.pop(context);
// //                 onReply();
// //               },
// //             ),
// //             ListTile(
// //               leading: Icon(Icons.add_reaction, color: ManagerColors.primaryColor),
// //               title: Text(
// //                 'إضافة تفاعل',
// //                 style: getRegularTextStyle(
// //                   fontSize: ManagerFontSize.s14,
// //                   color: Colors.black,
// //                 ),
// //               ),
// //               onTap: () {
// //                 Navigator.pop(context);
// //                 _showReactionPicker(context);
// //               },
// //             ),
// //             if (isMine && onTapStatus != null)
// //               ListTile(
// //                 leading: Icon(Icons.info_outline, color: ManagerColors.primaryColor),
// //                 title: Text(
// //                   'حالة الرسالة',
// //                   style: getRegularTextStyle(
// //                     fontSize: ManagerFontSize.s14,
// //                     color: Colors.black,
// //                   ),
// //                 ),
// //                 onTap: () {
// //                   Navigator.pop(context);
// //                   onTapStatus!();
// //                 },
// //               ),
// //             ListTile(
// //               leading: Icon(Icons.copy, color: ManagerColors.primaryColor),
// //               title: Text(
// //                 'نسخ النص',
// //                 style: getRegularTextStyle(
// //                   fontSize: ManagerFontSize.s14,
// //                   color: Colors.black,
// //                 ),
// //               ),
// //               onTap: () {
// //                 Navigator.pop(context);
// //                 Clipboard.setData(ClipboardData(text: message.content));
// //                 ScaffoldMessenger.of(context).showSnackBar(
// //                   const SnackBar(
// //                     content: Text('تم نسخ النص'),
// //                     duration: Duration(seconds: 1),
// //                   ),
// //                 );
// //               },
// //             ),
// //             if (controller.canDeleteMessage(message))
// //               ListTile(
// //                 leading: const Icon(Icons.delete, color: Colors.red),
// //                 title: Text(
// //                   'حذف الرسالة',
// //                   style: getRegularTextStyle(
// //                     fontSize: ManagerFontSize.s14,
// //                     color: Colors.red,
// //                   ),
// //                 ),
// //                 onTap: () {
// //                   Navigator.pop(context);
// //                   _confirmDelete(context);
// //                 },
// //               ),
// //             SizedBox(height: ManagerHeight.h8),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   void _showReactionPicker(BuildContext context) {
// //     final controller = ChatGroupController.to;
// //     final reactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
// //
// //     showModalBottomSheet(
// //       context: context,
// //       backgroundColor: Colors.white,
// //       shape: const RoundedRectangleBorder(
// //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
// //       ),
// //       builder: (context) => Container(
// //         padding: EdgeInsets.all(ManagerWidth.w20),
// //         child: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Text(
// //               'اختر تفاعلك',
// //               style: getBoldTextStyle(
// //                 fontSize: ManagerFontSize.s16,
// //                 color: Colors.black,
// //               ),
// //             ),
// //             SizedBox(height: ManagerHeight.h20),
// //             Wrap(
// //               spacing: 16,
// //               runSpacing: 16,
// //               children: reactions.map((emoji) {
// //                 return GestureDetector(
// //                   onTap: () {
// //                     Navigator.pop(context);
// //                     controller.addReaction(message, emoji);
// //                   },
// //                   child: Container(
// //                     width: 50,
// //                     height: 50,
// //                     decoration: BoxDecoration(
// //                       color: Colors.grey.shade100,
// //                       borderRadius: BorderRadius.circular(25),
// //                     ),
// //                     child: Center(
// //                       child: Text(
// //                         emoji,
// //                         style: const TextStyle(fontSize: 28),
// //                       ),
// //                     ),
// //                   ),
// //                 );
// //               }).toList(),
// //             ),
// //             SizedBox(height: ManagerHeight.h20),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   void _confirmDelete(BuildContext context) {
// //     final controller = ChatGroupController.to;
// //
// //     Get.dialog(
// //       AlertDialog(
// //         title: const Text('حذف الرسالة'),
// //         content: const Text('هل أنت متأكد من حذف هذه الرسالة؟'),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Get.back(),
// //             child: const Text('إلغاء'),
// //           ),
// //           TextButton(
// //             onPressed: () {
// //               Get.back();
// //               controller.deleteMessage(message);
// //             },
// //             style: TextButton.styleFrom(foregroundColor: Colors.red),
// //             child: const Text('حذف'),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   String _formatTime(DateTime time) {
// //     final hour = time.hour.toString().padLeft(2, '0');
// //     final minute = time.minute.toString().padLeft(2, '0');
// //     return "$hour:$minute";
// //   }
// // }
// // // المسار: lib/features/home/group_chat/presentation/widgets/message_bubble_updated.dart
// // // ✅ نسخة محدثة من MessageBubble - استبدل بها القديمة
// //
// // import 'package:app_mobile/features/home/group_chat/domain/models/attachment_model.dart';
// // import 'package:app_mobile/features/home/group_chat/domain/models/message_model.dart';
// // import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart';
// // import 'package:get/get.dart';
// // import 'package:app_mobile/core/resources/manager_colors.dart';
// // import 'package:app_mobile/core/resources/manager_font_size.dart';
// // import 'package:app_mobile/core/resources/manager_height.dart';
// // import 'package:app_mobile/core/resources/manager_width.dart';
// // import 'package:app_mobile/core/resources/manager_styles.dart';
// // import '../controller/chat_group_controller.dart';
// // import 'message_image_widget.dart';
// // import 'message_audio_widget.dart';
// // import 'message_file_widget.dart';
// // import 'message_video_widget.dart';
// //
// // class MessageBubble extends StatelessWidget {
// //   final MessageModel message;
// //   final bool isMine;
// //   final VoidCallback onReply;
// //   final VoidCallback? onTapStatus;
// //   final List<AttachmentModel>? attachments; // ✅ إضافة دعم Attachments
// //
// //   const MessageBubble({
// //     super.key,
// //     required this.message,
// //     required this.isMine,
// //     required this.onReply,
// //     this.onTapStatus,
// //     this.attachments,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     // Check if deleted
// //     if (message.isDeleted) {
// //       return _buildDeletedMessage();
// //     }
// //
// //     return GestureDetector(
// //       onLongPress: () => _showMessageOptions(context),
// //       child: Align(
// //         alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
// //         child: Container(
// //           margin: EdgeInsets.symmetric(vertical: ManagerHeight.h6),
// //           constraints: BoxConstraints(
// //             maxWidth: MediaQuery.of(context).size.width * 0.75,
// //           ),
// //           decoration: BoxDecoration(
// //             color: isMine ? ManagerColors.primaryColor : Colors.grey.shade100,
// //             borderRadius: BorderRadius.only(
// //               topLeft: const Radius.circular(16),
// //               topRight: const Radius.circular(16),
// //               bottomLeft: Radius.circular(isMine ? 16 : 4),
// //               bottomRight: Radius.circular(isMine ? 4 : 16),
// //             ),
// //             boxShadow: [
// //               BoxShadow(
// //                 color: Colors.black.withOpacity(0.05),
// //                 blurRadius: 4,
// //                 offset: const Offset(0, 2),
// //               ),
// //             ],
// //           ),
// //           child: Column(
// //             crossAxisAlignment:
// //             isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
// //             children: [
// //               // Reply Preview
// //               if (message.replyTo != null) _buildReplyPreview(),
// //
// //               // ✅ Attachments (الصور، الفيديو، الصوت، الملفات)
// //               if (attachments != null && attachments!.isNotEmpty)
// //                 _buildAttachments(),
// //
// //               // Message Content (إذا فيه نص)
// //               if (message.content.isNotEmpty)
// //                 Padding(
// //                   padding: EdgeInsets.all(ManagerWidth.w12),
// //                   child: _buildMessageContent(),
// //                 ),
// //
// //               // Reactions
// //               if (message.reactions != null && message.reactions!.isNotEmpty)
// //                 _buildReactions(),
// //
// //               // Message Footer (Time + Status)
// //               Padding(
// //                 padding: EdgeInsets.only(
// //                   left: ManagerWidth.w12,
// //                   right: ManagerWidth.w12,
// //                   bottom: ManagerHeight.h8,
// //                 ),
// //                 child: _buildMessageFooter(),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // ================================
// //   // ✅ BUILD ATTACHMENTS
// //   // ================================
// //   Widget _buildAttachments() {
// //     return Padding(
// //       padding: EdgeInsets.all(ManagerWidth.w8),
// //       child: Column(
// //         children: attachments!.map((attachment) {
// //           switch (attachment.type) {
// //             case 'image':
// //               return MessageImageWidget(
// //                 attachment: attachment,
// //                 isMine: isMine,
// //               );
// //             case 'video':
// //               return MessageVideoWidget(
// //                 attachment: attachment,
// //                 isMine: isMine,
// //               );
// //             case 'audio':
// //               return MessageAudioWidget(
// //                 attachment: attachment,
// //                 isMine: isMine,
// //               );
// //             case 'file':
// //               return MessageFileWidget(
// //                 attachment: attachment,
// //                 isMine: isMine,
// //               );
// //             default:
// //               return SizedBox.shrink();
// //           }
// //         }).toList(),
// //       ),
// //     );
// //   }
// //
// //   // ================================
// //   // ✅ DELETED MESSAGE
// //   // ================================
// //   Widget _buildDeletedMessage() {
// //     return Align(
// //       alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
// //       child: Container(
// //         margin: EdgeInsets.symmetric(vertical: ManagerHeight.h6),
// //         padding: EdgeInsets.all(ManagerWidth.w12),
// //         decoration: BoxDecoration(
// //           color: Colors.grey.shade200,
// //           borderRadius: BorderRadius.circular(12),
// //         ),
// //         child: Row(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Icon(Icons.block, size: 16, color: Colors.grey.shade600),
// //             SizedBox(width: ManagerWidth.w8),
// //             Text(
// //               'تم حذف هذه الرسالة',
// //               style: getRegularTextStyle(
// //                 fontSize: ManagerFontSize.s13,
// //                 color: Colors.grey.shade600,
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // ================================
// //   // ✅ REPLY PREVIEW
// //   // ================================
// //   Widget _buildReplyPreview() {
// //     return Container(
// //       margin: EdgeInsets.all(ManagerWidth.w8),
// //       padding: EdgeInsets.all(ManagerWidth.w8),
// //       decoration: BoxDecoration(
// //         color: Colors.white.withOpacity(isMine ? 0.2 : 0.3),
// //         borderRadius: BorderRadius.circular(8),
// //         border: Border(
// //           right: BorderSide(
// //             color: isMine ? Colors.white : ManagerColors.primaryColor,
// //             width: 3,
// //           ),
// //         ),
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Row(
// //             children: [
// //               Icon(
// //                 Icons.reply,
// //                 size: 14,
// //                 color: isMine
// //                     ? Colors.white.withOpacity(0.9)
// //                     : Colors.grey.shade700,
// //               ),
// //               SizedBox(width: ManagerWidth.w4),
// //               Text(
// //                 "ردًا على",
// //                 style: getBoldTextStyle(
// //                   fontSize: ManagerFontSize.s10,
// //                   color: isMine
// //                       ? Colors.white.withOpacity(0.9)
// //                       : Colors.grey.shade700,
// //                 ),
// //               ),
// //             ],
// //           ),
// //           SizedBox(height: ManagerHeight.h4),
// //           Text(
// //             message.replyTo ?? '',
// //             style: getRegularTextStyle(
// //               fontSize: ManagerFontSize.s12,
// //               color: isMine
// //                   ? Colors.white.withOpacity(0.8)
// //                   : Colors.grey.shade600,
// //             ),
// //             maxLines: 2,
// //             overflow: TextOverflow.ellipsis,
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   // ================================
// //   // ✅ MESSAGE CONTENT
// //   // ================================
// //   // Widget _buildMessageContent() {
// //   //   return Text(
// //   //     _highlightMentions(message.content),
// //   //     style: getRegularTextStyle(
// //   //       fontSize: ManagerFontSize.s14,
// //   //       color: isMine ? Colors.white : Colors.black87,
// //   //     ),
// //   //   );
// //   // }
// // // استبدل الدالة _buildMessageContent بـ هذا الكود:
// //
// //   Widget _buildMessageContent() {
// //     // إذا كان هناك رابط وسائط، لا تعرضه كنص
// //     final content = _removeMediaUrls(message.content);
// //
// //     if (content.isEmpty) {
// //       return const SizedBox.shrink();
// //     }
// //
// //     return Text(
// //       _highlightMentions(content),
// //       style: getRegularTextStyle(
// //         fontSize: ManagerFontSize.s14,
// //         color: isMine ? Colors.white : Colors.black87,
// //       ),
// //     );
// //   }
// //
// // // دالة لإزالة روابط الوسائط من النص
// //   String _removeMediaUrls(String content) {
// //     // نمط للتعرف على روابط Cloudinary أو وسائط
// //     final mediaUrlPattern = RegExp(
// //       r'https?://res\.cloudinary\.com/[^\s]+|(📷|🎥|🎤|📎)[^\n]*\n?',
// //     );
// //
// //     return content.replaceAll(mediaUrlPattern, '').trim();
// //   }
// //
// // // وفي الدالة _buildAttachments، أضف تحليل الروابط:
// // //   Widget _buildAttachments() {
// // //     // إذا لم يكن هناك attachments معرفة، نحاول استخراجها من محتوى الرسالة
// // //     final extractedAttachments = _extractAttachmentsFromMessage();
// // //
// // //     if (extractedAttachments.isEmpty) {
// // //       return const SizedBox.shrink();
// // //     }
// // //
// // //     return Padding(
// // //       padding: EdgeInsets.all(ManagerWidth.w8),
// // //       child: Column(
// // //         children: extractedAttachments.map((attachment) {
// // //           switch (attachment.type) {
// // //             case 'image':
// // //               return MessageImageWidget(
// // //                 attachment: attachment,
// // //                 isMine: isMine,
// // //               );
// // //             case 'video':
// // //               return MessageVideoWidget(
// // //                 attachment: attachment,
// // //                 isMine: isMine,
// // //               );
// // //             case 'audio':
// // //               return MessageAudioWidget(
// // //                 attachment: attachment,
// // //                 isMine: isMine,
// // //               );
// // //             case 'file':
// // //               return MessageFileWidget(
// // //                 attachment: attachment,
// // //                 isMine: isMine,
// // //               );
// // //             default:
// // //               return const SizedBox.shrink();
// // //           }
// // //         }).toList(),
// // //       ),
// // //     );
// // //   }
// //
// //   List<AttachmentModel> _extractAttachmentsFromMessage() {
// //     final attachments = <AttachmentModel>[];
// //     final content = message.content;
// //
// //     // نمط للتعرف على روابط Cloudinary
// //     final cloudinaryPattern = RegExp(r'https://res\.cloudinary\.com/[^\s]+');
// //     final matches = cloudinaryPattern.allMatches(content);
// //
// //     for (final match in matches) {
// //       final url = match.group(0)!;
// //       final type = _getMediaTypeFromUrl(url);
// //
// //       attachments.add(AttachmentModel(
// //         id: 'temp_${DateTime.now().millisecondsSinceEpoch}_${attachments.length}',
// //         url: url,
// //         type: type,
// //         fileName: _getFileNameFromUrl(url),
// //       ));
// //     }
// //
// //     return attachments;
// //   }
// //
// //   String _getMediaTypeFromUrl(String url) {
// //     if (url.contains('/image/') || url.contains('.jpg') || url.contains('.png') || url.contains('.jpeg')) {
// //       return 'image';
// //     } else if (url.contains('/video/') || url.contains('.mp4') || url.contains('.mov')) {
// //       return 'video';
// //     } else if (url.contains('/audio/') || url.contains('.mp3') || url.contains('.m4a')) {
// //       return 'audio';
// //     } else {
// //       return 'file';
// //     }
// //   }
// //
// //   String _getFileNameFromUrl(String url) {
// //     final uri = Uri.parse(url);
// //     final pathSegments = uri.pathSegments;
// //     return pathSegments.isNotEmpty ? pathSegments.last : 'file';
// //   }
// //   String _highlightMentions(String content) {
// //     // TODO: Implement mention highlighting
// //     return content;
// //   }
// //
// //   // ================================
// //   // ✅ REACTIONS
// //   // ================================
// //   Widget _buildReactions() {
// //     final reactions = message.reactions!;
// //     final reactionCounts = <String, int>{};
// //
// //     // Count reactions
// //     for (var emoji in reactions.values) {
// //       reactionCounts[emoji.toString()] =
// //           (reactionCounts[emoji.toString()] ?? 0) + 1;
// //     }
// //
// //     return Container(
// //       margin: EdgeInsets.symmetric(horizontal: ManagerWidth.w8),
// //       padding: EdgeInsets.all(ManagerWidth.w6),
// //       decoration: BoxDecoration(
// //         color: Colors.white.withOpacity(isMine ? 0.2 : 0.8),
// //         borderRadius: BorderRadius.circular(12),
// //       ),
// //       child: Wrap(
// //         spacing: 4,
// //         children: reactionCounts.entries.map((entry) {
// //           return Container(
// //             padding: EdgeInsets.symmetric(
// //               horizontal: ManagerWidth.w6,
// //               vertical: ManagerHeight.h2,
// //             ),
// //             decoration: BoxDecoration(
// //               color: Colors.white.withOpacity(0.3),
// //               borderRadius: BorderRadius.circular(10),
// //             ),
// //             child: Row(
// //               mainAxisSize: MainAxisSize.min,
// //               children: [
// //                 Text(entry.key, style: const TextStyle(fontSize: 14)),
// //                 if (entry.value > 1) ...[
// //                   SizedBox(width: ManagerWidth.w2),
// //                   Text(
// //                     '${entry.value}',
// //                     style: getBoldTextStyle(
// //                       fontSize: ManagerFontSize.s10,
// //                       color: isMine ? Colors.white : Colors.black87,
// //                     ),
// //                   ),
// //                 ],
// //               ],
// //             ),
// //           );
// //         }).toList(),
// //       ),
// //     );
// //   }
// //
// //   // ================================
// //   // ✅ MESSAGE FOOTER
// //   // ================================
// //   Widget _buildMessageFooter() {
// //     return Row(
// //       mainAxisSize: MainAxisSize.min,
// //       children: [
// //         Text(
// //           _formatTime(message.timestamp),
// //           style: getRegularTextStyle(
// //             fontSize: ManagerFontSize.s10,
// //             color: isMine ? Colors.white.withOpacity(0.7) : Colors.grey,
// //           ),
// //         ),
// //         if (isMine) ...[
// //           SizedBox(width: ManagerWidth.w4),
// //           GestureDetector(
// //             onTap: onTapStatus,
// //             child: _buildStatusIcon(),
// //           ),
// //         ],
// //       ],
// //     );
// //   }
// //
// //   Widget _buildStatusIcon() {
// //     IconData icon;
// //     Color color;
// //
// //     if (message.isFailed) {
// //       icon = Icons.error_outline;
// //       color = Colors.red.shade300;
// //     } else if (message.isFullySeen) {
// //       icon = Icons.done_all;
// //       color = Colors.blue.shade200;
// //     } else if (message.isSeen) {
// //       icon = Icons.done_all;
// //       color = Colors.blue.shade200;
// //     } else if (message.isFullyDelivered) {
// //       icon = Icons.done_all;
// //       color = Colors.white.withOpacity(0.7);
// //     } else if (message.isDelivered) {
// //       icon = Icons.done_all;
// //       color = Colors.white.withOpacity(0.7);
// //     } else {
// //       icon = Icons.done;
// //       color = Colors.white.withOpacity(0.7);
// //     }
// //
// //     return Icon(
// //       icon,
// //       size: 16,
// //       color: color,
// //     );
// //   }
// //
// //   // ================================
// //   // ✅ MESSAGE OPTIONS (نفس الكود القديم - بدون تغيير)
// //   // ================================
// //   void _showMessageOptions(BuildContext context) {
// //     final controller = ChatGroupController.to;
// //
// //     showModalBottomSheet(
// //       context: context,
// //       backgroundColor: Colors.white,
// //       shape: const RoundedRectangleBorder(
// //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
// //       ),
// //       builder: (context) => SafeArea(
// //         child: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Container(
// //               margin: EdgeInsets.only(top: ManagerHeight.h8),
// //               width: 40,
// //               height: 4,
// //               decoration: BoxDecoration(
// //                 color: Colors.grey.shade300,
// //                 borderRadius: BorderRadius.circular(2),
// //               ),
// //             ),
// //             ListTile(
// //               leading: Icon(Icons.reply, color: ManagerColors.primaryColor),
// //               title: Text(
// //                 'الرد على الرسالة',
// //                 style: getRegularTextStyle(
// //                   fontSize: ManagerFontSize.s14,
// //                   color: Colors.black,
// //                 ),
// //               ),
// //               onTap: () {
// //                 Navigator.pop(context);
// //                 onReply();
// //               },
// //             ),
// //             ListTile(
// //               leading:
// //               Icon(Icons.add_reaction, color: ManagerColors.primaryColor),
// //               title: Text(
// //                 'إضافة تفاعل',
// //                 style: getRegularTextStyle(
// //                   fontSize: ManagerFontSize.s14,
// //                   color: Colors.black,
// //                 ),
// //               ),
// //               onTap: () {
// //                 Navigator.pop(context);
// //                 _showReactionPicker(context);
// //               },
// //             ),
// //             if (isMine && onTapStatus != null)
// //               ListTile(
// //                 leading:
// //                 Icon(Icons.info_outline, color: ManagerColors.primaryColor),
// //                 title: Text(
// //                   'حالة الرسالة',
// //                   style: getRegularTextStyle(
// //                     fontSize: ManagerFontSize.s14,
// //                     color: Colors.black,
// //                   ),
// //                 ),
// //                 onTap: () {
// //                   Navigator.pop(context);
// //                   onTapStatus!();
// //                 },
// //               ),
// //             ListTile(
// //               leading: Icon(Icons.copy, color: ManagerColors.primaryColor),
// //               title: Text(
// //                 'نسخ النص',
// //                 style: getRegularTextStyle(
// //                   fontSize: ManagerFontSize.s14,
// //                   color: Colors.black,
// //                 ),
// //               ),
// //               onTap: () {
// //                 Navigator.pop(context);
// //                 Clipboard.setData(ClipboardData(text: message.content));
// //                 ScaffoldMessenger.of(context).showSnackBar(
// //                   const SnackBar(
// //                     content: Text('تم نسخ النص'),
// //                     duration: Duration(seconds: 1),
// //                   ),
// //                 );
// //               },
// //             ),
// //             if (controller.canDeleteMessage(message))
// //               ListTile(
// //                 leading: const Icon(Icons.delete, color: Colors.red),
// //                 title: Text(
// //                   'حذف الرسالة',
// //                   style: getRegularTextStyle(
// //                     fontSize: ManagerFontSize.s14,
// //                     color: Colors.red,
// //                   ),
// //                 ),
// //                 onTap: () {
// //                   Navigator.pop(context);
// //                   _confirmDelete(context);
// //                 },
// //               ),
// //             SizedBox(height: ManagerHeight.h8),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   void _showReactionPicker(BuildContext context) {
// //     final controller = ChatGroupController.to;
// //     final reactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
// //
// //     showModalBottomSheet(
// //       context: context,
// //       backgroundColor: Colors.white,
// //       shape: const RoundedRectangleBorder(
// //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
// //       ),
// //       builder: (context) => Container(
// //         padding: EdgeInsets.all(ManagerWidth.w20),
// //         child: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Text(
// //               'اختر تفاعلك',
// //               style: getBoldTextStyle(
// //                 fontSize: ManagerFontSize.s16,
// //                 color: Colors.black,
// //               ),
// //             ),
// //             SizedBox(height: ManagerHeight.h20),
// //             Wrap(
// //               spacing: 16,
// //               runSpacing: 16,
// //               children: reactions.map((emoji) {
// //                 return GestureDetector(
// //                   onTap: () {
// //                     Navigator.pop(context);
// //                     controller.addReaction(message, emoji);
// //                   },
// //                   child: Container(
// //                     width: 50,
// //                     height: 50,
// //                     decoration: BoxDecoration(
// //                       color: Colors.grey.shade100,
// //                       borderRadius: BorderRadius.circular(25),
// //                     ),
// //                     child: Center(
// //                       child: Text(
// //                         emoji,
// //                         style: const TextStyle(fontSize: 28),
// //                       ),
// //                     ),
// //                   ),
// //                 );
// //               }).toList(),
// //             ),
// //             SizedBox(height: ManagerHeight.h20),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   void _confirmDelete(BuildContext context) {
// //     final controller = ChatGroupController.to;
// //
// //     Get.dialog(
// //       AlertDialog(
// //         title: const Text('حذف الرسالة'),
// //         content: const Text('هل أنت متأكد من حذف هذه الرسالة؟'),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Get.back(),
// //             child: const Text('إلغاء'),
// //           ),
// //           TextButton(
// //             onPressed: () {
// //               Get.back();
// //               controller.deleteMessage(message);
// //             },
// //             style: TextButton.styleFrom(foregroundColor: Colors.red),
// //             child: const Text('حذف'),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   String _formatTime(DateTime time) {
// //     final hour = time.hour.toString().padLeft(2, '0');
// //     final minute = time.minute.toString().padLeft(2, '0');
// //     return "$hour:$minute";
// //   }
// // }
// //
// // // // المسار: lib/features/home/group_chat/presentation/widgets/message_bubble.dart
// // //
// // // import 'package:app_mobile/features/home/group_chat/domain/models/message_model.dart';
// // // import 'package:flutter/material.dart';
// // // import 'package:flutter/services.dart';
// // // import 'package:get/get.dart';
// // // import 'package:app_mobile/core/resources/manager_colors.dart';
// // // import 'package:app_mobile/core/resources/manager_font_size.dart';
// // // import 'package:app_mobile/core/resources/manager_height.dart';
// // // import 'package:app_mobile/core/resources/manager_width.dart';
// // // import 'package:app_mobile/core/resources/manager_styles.dart';
// // // import '../controller/chat_group_controller.dart';
// // //
// // // class MessageBubble extends StatelessWidget {
// // //   final MessageModel message;
// // //   final bool isMine;
// // //   final VoidCallback onReply;
// // //   final VoidCallback? onTapStatus;
// // //
// // //   const MessageBubble({
// // //     super.key,
// // //     required this.message,
// // //     required this.isMine,
// // //     required this.onReply,
// // //     this.onTapStatus,
// // //   });
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     // Check if deleted
// // //     if (message.isDeleted) {
// // //       return _buildDeletedMessage();
// // //     }
// // //
// // //     return GestureDetector(
// // //       onLongPress: () => _showMessageOptions(context),
// // //       child: Align(
// // //         alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
// // //         child: Container(
// // //           margin: EdgeInsets.symmetric(vertical: ManagerHeight.h6),
// // //           constraints: BoxConstraints(
// // //             maxWidth: MediaQuery.of(context).size.width * 0.75,
// // //           ),
// // //           decoration: BoxDecoration(
// // //             color: isMine ? ManagerColors.primaryColor : Colors.grey.shade100,
// // //             borderRadius: BorderRadius.only(
// // //               topLeft: const Radius.circular(16),
// // //               topRight: const Radius.circular(16),
// // //               bottomLeft: Radius.circular(isMine ? 16 : 4),
// // //               bottomRight: Radius.circular(isMine ? 4 : 16),
// // //             ),
// // //             boxShadow: [
// // //               BoxShadow(
// // //                 color: Colors.black.withOpacity(0.05),
// // //                 blurRadius: 4,
// // //                 offset: const Offset(0, 2),
// // //               ),
// // //             ],
// // //           ),
// // //           child: Column(
// // //             crossAxisAlignment:
// // //             isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
// // //             children: [
// // //               // Reply Preview
// // //               if (message.replyTo != null) _buildReplyPreview(),
// // //
// // //               // Message Content
// // //               Padding(
// // //                 padding: EdgeInsets.all(ManagerWidth.w12),
// // //                 child: _buildMessageContent(),
// // //               ),
// // //
// // //               // Reactions
// // //               if (message.reactions != null && message.reactions!.isNotEmpty)
// // //                 _buildReactions(),
// // //
// // //               // Message Footer (Time + Status)
// // //               Padding(
// // //                 padding: EdgeInsets.only(
// // //                   left: ManagerWidth.w12,
// // //                   right: ManagerWidth.w12,
// // //                   bottom: ManagerHeight.h8,
// // //                 ),
// // //                 child: _buildMessageFooter(),
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   // ================================
// // //   // ✅ DELETED MESSAGE
// // //   // ================================
// // //
// // //   Widget _buildDeletedMessage() {
// // //     return Align(
// // //       alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
// // //       child: Container(
// // //         margin: EdgeInsets.symmetric(vertical: ManagerHeight.h6),
// // //         padding: EdgeInsets.all(ManagerWidth.w12),
// // //         decoration: BoxDecoration(
// // //           color: Colors.grey.shade200,
// // //           borderRadius: BorderRadius.circular(12),
// // //         ),
// // //         child: Row(
// // //           mainAxisSize: MainAxisSize.min,
// // //           children: [
// // //             Icon(Icons.block, size: 16, color: Colors.grey.shade600),
// // //             SizedBox(width: ManagerWidth.w8),
// // //             Text(
// // //               'تم حذف هذه الرسالة',
// // //               style: getRegularTextStyle(
// // //                 fontSize: ManagerFontSize.s13,
// // //                 color: Colors.grey.shade600,
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   // ================================
// // //   // ✅ REPLY PREVIEW
// // //   // ================================
// // //
// // //   Widget _buildReplyPreview() {
// // //     return Container(
// // //       margin: EdgeInsets.all(ManagerWidth.w8),
// // //       padding: EdgeInsets.all(ManagerWidth.w8),
// // //       decoration: BoxDecoration(
// // //         color: Colors.white.withOpacity(isMine ? 0.2 : 0.3),
// // //         borderRadius: BorderRadius.circular(8),
// // //         border: Border(
// // //           right: BorderSide(
// // //             color: isMine ? Colors.white : ManagerColors.primaryColor,
// // //             width: 3,
// // //           ),
// // //         ),
// // //       ),
// // //       child: Column(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         children: [
// // //           Row(
// // //             children: [
// // //               Icon(
// // //                 Icons.reply,
// // //                 size: 14,
// // //                 color: isMine
// // //                     ? Colors.white.withOpacity(0.9)
// // //                     : Colors.grey.shade700,
// // //               ),
// // //               SizedBox(width: ManagerWidth.w4),
// // //               Text(
// // //                 "ردًا على",
// // //                 style: getBoldTextStyle(
// // //                   fontSize: ManagerFontSize.s10,
// // //                   color: isMine
// // //                       ? Colors.white.withOpacity(0.9)
// // //                       : Colors.grey.shade700,
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //           SizedBox(height: ManagerHeight.h4),
// // //           Text(
// // //             message.replyTo ?? '',
// // //             style: getRegularTextStyle(
// // //               fontSize: ManagerFontSize.s12,
// // //               color: isMine
// // //                   ? Colors.white.withOpacity(0.8)
// // //                   : Colors.grey.shade600,
// // //             ),
// // //             maxLines: 2,
// // //             overflow: TextOverflow.ellipsis,
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // //
// // //   // ================================
// // //   // ✅ MESSAGE CONTENT
// // //   // ================================
// // //
// // //   Widget _buildMessageContent() {
// // //     return Text(
// // //       _highlightMentions(message.content),
// // //       style: getRegularTextStyle(
// // //         fontSize: ManagerFontSize.s14,
// // //         color: isMine ? Colors.white : Colors.black87,
// // //       ),
// // //     );
// // //   }
// // //
// // //   String _highlightMentions(String content) {
// // //     // TODO: Implement mention highlighting
// // //     return content;
// // //   }
// // //
// // //   // ================================
// // //   // ✅ REACTIONS
// // //   // ================================
// // //
// // //   Widget _buildReactions() {
// // //     final reactions = message.reactions!;
// // //     final reactionCounts = <String, int>{};
// // //
// // //     // Count reactions
// // //     for (var emoji in reactions.values) {
// // //       reactionCounts[emoji.toString()] =
// // //           (reactionCounts[emoji.toString()] ?? 0) + 1;
// // //     }
// // //
// // //     return Container(
// // //       margin: EdgeInsets.symmetric(horizontal: ManagerWidth.w8),
// // //       padding: EdgeInsets.all(ManagerWidth.w6),
// // //       decoration: BoxDecoration(
// // //         color: Colors.white.withOpacity(isMine ? 0.2 : 0.8),
// // //         borderRadius: BorderRadius.circular(12),
// // //       ),
// // //       child: Wrap(
// // //         spacing: 4,
// // //         children: reactionCounts.entries.map((entry) {
// // //           return Container(
// // //             padding: EdgeInsets.symmetric(
// // //               horizontal: ManagerWidth.w6,
// // //               vertical: ManagerHeight.h2,
// // //             ),
// // //             decoration: BoxDecoration(
// // //               color: Colors.white.withOpacity(0.3),
// // //               borderRadius: BorderRadius.circular(10),
// // //             ),
// // //             child: Row(
// // //               mainAxisSize: MainAxisSize.min,
// // //               children: [
// // //                 Text(entry.key, style: const TextStyle(fontSize: 14)),
// // //                 if (entry.value > 1) ...[
// // //                   SizedBox(width: ManagerWidth.w2),
// // //                   Text(
// // //                     '${entry.value}',
// // //                     style: getBoldTextStyle(
// // //                       fontSize: ManagerFontSize.s10,
// // //                       color: isMine ? Colors.white : Colors.black87,
// // //                     ),
// // //                   ),
// // //                 ],
// // //               ],
// // //             ),
// // //           );
// // //         }).toList(),
// // //       ),
// // //     );
// // //   }
// // //
// // //   // ================================
// // //   // ✅ MESSAGE FOOTER
// // //   // ================================
// // //
// // //   Widget _buildMessageFooter() {
// // //     return Row(
// // //       mainAxisSize: MainAxisSize.min,
// // //       children: [
// // //         Text(
// // //           _formatTime(message.timestamp),
// // //           style: getRegularTextStyle(
// // //             fontSize: ManagerFontSize.s10,
// // //             color: isMine ? Colors.white.withOpacity(0.7) : Colors.grey,
// // //           ),
// // //         ),
// // //         if (isMine) ...[
// // //           SizedBox(width: ManagerWidth.w4),
// // //           GestureDetector(
// // //             onTap: onTapStatus,
// // //             child: _buildStatusIcon(),
// // //           ),
// // //         ],
// // //       ],
// // //     );
// // //   }
// // //
// // //   Widget _buildStatusIcon() {
// // //     IconData icon;
// // //     Color color;
// // //
// // //     if (message.isFailed) {
// // //       icon = Icons.error_outline;
// // //       color = Colors.red.shade300;
// // //     } else if (message.isFullySeen) {
// // //       icon = Icons.done_all;
// // //       color = Colors.blue.shade200;
// // //     } else if (message.isSeen) {
// // //       icon = Icons.done_all;
// // //       color = Colors.blue.shade200;
// // //     } else if (message.isFullyDelivered) {
// // //       icon = Icons.done_all;
// // //       color = Colors.white.withOpacity(0.7);
// // //     } else if (message.isDelivered) {
// // //       icon = Icons.done_all;
// // //       color = Colors.white.withOpacity(0.7);
// // //     } else {
// // //       icon = Icons.done;
// // //       color = Colors.white.withOpacity(0.7);
// // //     }
// // //
// // //     return Icon(
// // //       icon,
// // //       size: 16,
// // //       color: color,
// // //     );
// // //   }
// // //
// // //   // ================================
// // //   // ✅ MESSAGE OPTIONS
// // //   // ================================
// // //
// // //   void _showMessageOptions(BuildContext context) {
// // //     final controller = ChatGroupController.to;
// // //
// // //     showModalBottomSheet(
// // //       context: context,
// // //       backgroundColor: Colors.white,
// // //       shape: const RoundedRectangleBorder(
// // //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
// // //       ),
// // //       builder: (context) => SafeArea(
// // //         child: Column(
// // //           mainAxisSize: MainAxisSize.min,
// // //           children: [
// // //             // Handle bar
// // //             Container(
// // //               margin: EdgeInsets.only(top: ManagerHeight.h8),
// // //               width: 40,
// // //               height: 4,
// // //               decoration: BoxDecoration(
// // //                 color: Colors.grey.shade300,
// // //                 borderRadius: BorderRadius.circular(2),
// // //               ),
// // //             ),
// // //
// // //             // Reply
// // //             ListTile(
// // //               leading: Icon(Icons.reply, color: ManagerColors.primaryColor),
// // //               title: Text(
// // //                 'الرد على الرسالة',
// // //                 style: getRegularTextStyle(
// // //                   fontSize: ManagerFontSize.s14,
// // //                   color: Colors.black,
// // //                 ),
// // //               ),
// // //               onTap: () {
// // //                 Navigator.pop(context);
// // //                 onReply();
// // //               },
// // //             ),
// // //
// // //             // React
// // //             ListTile(
// // //               leading:
// // //               Icon(Icons.add_reaction, color: ManagerColors.primaryColor),
// // //               title: Text(
// // //                 'إضافة تفاعل',
// // //                 style: getRegularTextStyle(
// // //                   fontSize: ManagerFontSize.s14,
// // //                   color: Colors.black,
// // //                 ),
// // //               ),
// // //               onTap: () {
// // //                 Navigator.pop(context);
// // //                 _showReactionPicker(context);
// // //               },
// // //             ),
// // //
// // //             // Status (for sender only)
// // //             if (isMine && onTapStatus != null)
// // //               ListTile(
// // //                 leading:
// // //                 Icon(Icons.info_outline, color: ManagerColors.primaryColor),
// // //                 title: Text(
// // //                   'حالة الرسالة',
// // //                   style: getRegularTextStyle(
// // //                     fontSize: ManagerFontSize.s14,
// // //                     color: Colors.black,
// // //                   ),
// // //                 ),
// // //                 onTap: () {
// // //                   Navigator.pop(context);
// // //                   onTapStatus!();
// // //                 },
// // //               ),
// // //
// // //             // Copy
// // //             ListTile(
// // //               leading: Icon(Icons.copy, color: ManagerColors.primaryColor),
// // //               title: Text(
// // //                 'نسخ النص',
// // //                 style: getRegularTextStyle(
// // //                   fontSize: ManagerFontSize.s14,
// // //                   color: Colors.black,
// // //                 ),
// // //               ),
// // //               onTap: () {
// // //                 Navigator.pop(context);
// // //                 Clipboard.setData(ClipboardData(text: message.content));
// // //                 ScaffoldMessenger.of(context).showSnackBar(
// // //                   const SnackBar(
// // //                     content: Text('تم نسخ النص'),
// // //                     duration: Duration(seconds: 1),
// // //                   ),
// // //                 );
// // //               },
// // //             ),
// // //
// // //             // Delete (for sender or admin)
// // //             if (controller.canDeleteMessage(message))
// // //               ListTile(
// // //                 leading: const Icon(Icons.delete, color: Colors.red),
// // //                 title: Text(
// // //                   'حذف الرسالة',
// // //                   style: getRegularTextStyle(
// // //                     fontSize: ManagerFontSize.s14,
// // //                     color: Colors.red,
// // //                   ),
// // //                 ),
// // //                 onTap: () {
// // //                   Navigator.pop(context);
// // //                   _confirmDelete(context);
// // //                 },
// // //               ),
// // //
// // //             SizedBox(height: ManagerHeight.h8),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   // ================================
// // //   // ✅ REACTION PICKER
// // //   // ================================
// // //
// // //   void _showReactionPicker(BuildContext context) {
// // //     final controller = ChatGroupController.to;
// // //     final reactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
// // //
// // //     showModalBottomSheet(
// // //       context: context,
// // //       backgroundColor: Colors.white,
// // //       shape: const RoundedRectangleBorder(
// // //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
// // //       ),
// // //       builder: (context) => Container(
// // //         padding: EdgeInsets.all(ManagerWidth.w20),
// // //         child: Column(
// // //           mainAxisSize: MainAxisSize.min,
// // //           children: [
// // //             Text(
// // //               'اختر تفاعلك',
// // //               style: getBoldTextStyle(
// // //                 fontSize: ManagerFontSize.s16,
// // //                 color: Colors.black,
// // //               ),
// // //             ),
// // //             SizedBox(height: ManagerHeight.h20),
// // //             Wrap(
// // //               spacing: 16,
// // //               runSpacing: 16,
// // //               children: reactions.map((emoji) {
// // //                 return GestureDetector(
// // //                   onTap: () {
// // //                     Navigator.pop(context);
// // //                     controller.addReaction(message, emoji);
// // //                   },
// // //                   child: Container(
// // //                     width: 50,
// // //                     height: 50,
// // //                     decoration: BoxDecoration(
// // //                       color: Colors.grey.shade100,
// // //                       borderRadius: BorderRadius.circular(25),
// // //                     ),
// // //                     child: Center(
// // //                       child: Text(
// // //                         emoji,
// // //                         style: const TextStyle(fontSize: 28),
// // //                       ),
// // //                     ),
// // //                   ),
// // //                 );
// // //               }).toList(),
// // //             ),
// // //             SizedBox(height: ManagerHeight.h20),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   // ================================
// // //   // ✅ DELETE CONFIRMATION
// // //   // ================================
// // //
// // //   void _confirmDelete(BuildContext context) {
// // //     final controller = ChatGroupController.to;
// // //
// // //     Get.dialog(
// // //       AlertDialog(
// // //         title: const Text('حذف الرسالة'),
// // //         content: const Text('هل أنت متأكد من حذف هذه الرسالة؟'),
// // //         actions: [
// // //           TextButton(
// // //             onPressed: () => Get.back(),
// // //             child: const Text('إلغاء'),
// // //           ),
// // //           TextButton(
// // //             onPressed: () {
// // //               Get.back();
// // //               controller.deleteMessage(message);
// // //             },
// // //             style: TextButton.styleFrom(foregroundColor: Colors.red),
// // //             child: const Text('حذف'),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // //
// // //   // ================================
// // //   // ✅ HELPERS
// // //   // ================================
// // //
// // //   String _formatTime(DateTime time) {
// // //     final hour = time.hour.toString().padLeft(2, '0');
// // //     final minute = time.minute.toString().padLeft(2, '0');
// // //     return "$hour:$minute";
// // //   }
// // // }