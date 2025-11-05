// المسار: lib/core/widgets/cloudinary_image.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../../core/service/cloudinart_service.dart';

/// Widget لعرض الصور من Cloudinary مع Thumbnail وCache
class CloudinaryImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool useThumbnail;
  final int thumbnailWidth;
  final int thumbnailHeight;

  const CloudinaryImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.useThumbnail = true,
    this.thumbnailWidth = 300,
    this.thumbnailHeight = 300,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    // استخدام Thumbnail من Cloudinary
    final displayUrl = useThumbnail
        ? CloudinaryService.thumb(
      imageUrl!,
      w: thumbnailWidth,
      h: thumbnailHeight,
    )
        : imageUrl!;

    return CachedNetworkImage(
      imageUrl: displayUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) =>
      placeholder ?? _buildLoadingPlaceholder(),
      errorWidget: (context, url, error) =>
      errorWidget ?? _buildErrorWidget(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: Icon(
        Icons.image,
        color: Colors.grey.shade400,
        size: (width != null && width! < 100) ? 30 : 50,
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade100,
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: Icon(
        Icons.broken_image,
        color: Colors.grey.shade400,
        size: (width != null && width! < 100) ? 30 : 50,
      ),
    );
  }
}

/// Widget لعرض صورة المجموعة أو جهة الاتصال
class CloudinaryAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fallbackText;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;

  const CloudinaryAvatar({
    super.key,
    required this.imageUrl,
    required this.fallbackText,
    this.radius = 28,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor:
        backgroundColor ?? Theme.of(context).primaryColor.withOpacity(0.1),
        child: Text(
          fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: radius * 0.6,
            fontWeight: FontWeight.bold,
            color: textColor ?? Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    // استخدام Thumbnail من Cloudinary
    final thumbnailUrl = CloudinaryService.thumb(
      imageUrl!,
      w: (radius * 2).toInt(),
      h: (radius * 2).toInt(),
    );

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade200,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: thumbnailUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey.shade100,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: backgroundColor ??
                Theme.of(context).primaryColor.withOpacity(0.1),
            child: Center(
              child: Text(
                fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: radius * 0.6,
                  fontWeight: FontWeight.bold,
                  color: textColor ?? Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget لعرض بوستر الفيديو من Cloudinary
class CloudinaryVideoPoster extends StatelessWidget {
  final String videoUrl;
  final double? width;
  final double? height;
  final int secondPosition;
  final BoxFit fit;

  const CloudinaryVideoPoster({
    super.key,
    required this.videoUrl,
    this.width,
    this.height,
    this.secondPosition = 0,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    // الحصول على بوستر الفيديو من Cloudinary
    final posterUrl = CloudinaryService.videoPoster(
      videoUrl,
      sec: secondPosition,
      w: width?.toInt() ?? 480,
      h: height?.toInt(),
    );

    return CachedNetworkImage(
      imageUrl: posterUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: Colors.black,
        child: const Icon(
          Icons.video_library,
          color: Colors.white,
          size: 50,
        ),
      ),
    );
  }
}