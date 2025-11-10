// المسار: lib/features/home/group_chat/presentation/widgets/message_image_widget.dart

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import '../../../../../core/resources/manager_colors.dart';
import '../../../../../core/resources/manager_width.dart';
import '../../../../../core/service/cache_service.dart' show CacheService;
import '../../../../../core/widgets/shimmer_loading.dart';
import '../../domain/models/attachment_model.dart';

class MessageImageWidget extends StatelessWidget {
  final AttachmentModel attachment;
  final bool isMine;

  const MessageImageWidget({
    super.key,
    required this.attachment,
    this.isMine = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullImage(context),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
          maxHeight: 300,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade200,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // الصورة
              _buildImage(),

              // Progress Indicator (أثناء الرفع)
              if (attachment.isUploading) _buildUploadProgress(),

              // زر التكبير
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.zoom_in,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    // إذا كان محلي (لم يرفع بعد)
    if (attachment.localPath != null && attachment.localPath!.isNotEmpty) {
      final file = File(attachment.localPath!);
      return Image.file(
        file,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }

    // إذا كان مرفوع على الإنترنت
    return CachedNetworkImage(
      imageUrl: attachment.url,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (context, url) => ShimmerLoading.imageShimmer(
        height: 200,
        borderRadius: BorderRadius.circular(12),
      ),
      errorWidget: (context, url, error) => Container(
        height: 200,
        color: Colors.grey.shade300,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 50, color: Colors.grey.shade600),
            SizedBox(height: 8),
            Text(
              'فشل تحميل الصورة',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
      cacheManager: CacheService.imageCacheManager,
    );
  }

  Widget _buildUploadProgress() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                value: attachment.uploadProgress,
                color: Colors.white,
                strokeWidth: 3,
              ),
              SizedBox(height: 8),
              Text(
                '${(attachment.uploadProgress * 100).toInt()}%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFullImage(BuildContext context) {
    Get.to(
          () => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.download, color: Colors.white),
              onPressed: () {
                // TODO: تنزيل الصورة
                Get.snackbar(
                  'قريباً',
                  'ميزة التنزيل ستكون متاحة قريباً',
                  backgroundColor: Colors.white.withOpacity(0.2),
                  colorText: Colors.white,
                );
              },
            ),
          ],
        ),
        body: PhotoView(
          imageProvider: attachment.localPath != null
              ? FileImage(File(attachment.localPath!))
              : CachedNetworkImageProvider(attachment.url) as ImageProvider,
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
          backgroundDecoration: BoxDecoration(color: Colors.black),
          loadingBuilder: (context, event) => Center(
            child: CircularProgressIndicator(
              value: event == null
                  ? null
                  : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
            ),
          ),
        ),
      ),
      transition: Transition.fadeIn,
    );
  }
}