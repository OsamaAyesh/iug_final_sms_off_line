// المسار: lib/features/home/group_chat/presentation/widgets/message_file_widget.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import '../../../../../core/resources/manager_colors.dart';
import '../../../../../core/resources/manager_font_size.dart';
import '../../../../../core/resources/manager_height.dart';
import '../../../../../core/resources/manager_styles.dart';
import '../../../../../core/resources/manager_width.dart';
import '../../domain/models/attachment_model.dart';

class MessageFileWidget extends StatelessWidget {
  final AttachmentModel attachment;
  final bool isMine;

  const MessageFileWidget({
    super.key,
    required this.attachment,
    this.isMine = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFile(),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        padding: EdgeInsets.all(ManagerWidth.w12),
        decoration: BoxDecoration(
          color: isMine
              ? Colors.white.withOpacity(0.2)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMine
                ? Colors.white.withOpacity(0.3)
                : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // File Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getFileColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getFileIcon(),
                    color: _getFileColor(),
                    size: 28,
                  ),
                ),
                SizedBox(width: ManagerWidth.w12),

                // File Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attachment.fileName ?? 'ملف',
                        style: getBoldTextStyle(
                          fontSize: ManagerFontSize.s14,
                          color: isMine ? Colors.white : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: ManagerHeight.h4),
                      Text(
                        attachment.formattedSize,
                        style: getRegularTextStyle(
                          fontSize: ManagerFontSize.s12,
                          color: isMine
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Download/Open Icon
                if (!attachment.isUploading)
                  Icon(
                    Icons.file_download,
                    color: isMine ? Colors.white : ManagerColors.primaryColor,
                    size: 24,
                  ),
              ],
            ),

            // Upload Progress
            if (attachment.isUploading)
              Padding(
                padding: EdgeInsets.only(top: ManagerHeight.h12),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: attachment.uploadProgress,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isMine ? Colors.white : ManagerColors.primaryColor,
                      ),
                    ),
                    SizedBox(height: ManagerHeight.h6),
                    Text(
                      'جاري الرفع ${(attachment.uploadProgress * 100).toInt()}%',
                      style: getRegularTextStyle(
                        fontSize: ManagerFontSize.s11,
                        color: isMine
                            ? Colors.white.withOpacity(0.8)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon() {
    final fileName = attachment.fileName?.toLowerCase() ?? '';

    if (fileName.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) {
      return Icons.description;
    }
    if (fileName.endsWith('.xls') || fileName.endsWith('.xlsx')) {
      return Icons.table_chart;
    }
    if (fileName.endsWith('.txt')) return Icons.text_snippet;
    if (fileName.endsWith('.zip') || fileName.endsWith('.rar')) {
      return Icons.folder_zip;
    }

    return Icons.insert_drive_file;
  }

  Color _getFileColor() {
    final fileName = attachment.fileName?.toLowerCase() ?? '';

    if (fileName.endsWith('.pdf')) return Colors.red;
    if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) {
      return Colors.blue;
    }
    if (fileName.endsWith('.xls') || fileName.endsWith('.xlsx')) {
      return Colors.green;
    }
    if (fileName.endsWith('.txt')) return Colors.grey;
    if (fileName.endsWith('.zip') || fileName.endsWith('.rar')) {
      return Colors.orange;
    }

    return Colors.grey;
  }

  Future<void> _openFile() async {
    if (attachment.isUploading) return;

    try {
      // محاولة فتح الملف
      if (attachment.localPath != null) {
        await OpenFile.open(attachment.localPath!);
      } else {
        // TODO: تنزيل الملف من URL ثم فتحه
        Get.snackbar(
          'قريباً',
          'ميزة تنزيل الملفات ستكون متاحة قريباً',
          backgroundColor: Colors.blue.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('❌ خطأ في فتح الملف: $e');
      Get.snackbar(
        'خطأ',
        'فشل فتح الملف',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }
}