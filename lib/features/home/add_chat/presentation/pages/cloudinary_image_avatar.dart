// المسار: lib/core/widgets/cloudinary_image.dart

import 'package:app_mobile/core/resources/manager_colors.dart';
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
  final String defaultImagePath; // ✅ مسار الصورة الافتراضية

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
    this.defaultImagePath = 'assets/images/default_image.png', // ✅ الصورة الافتراضية
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildDefaultImage(); // ✅ استخدام الصورة الافتراضية
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
      errorWidget ?? _buildDefaultImage(), // ✅ استخدام الصورة الافتراضية عند الخطأ
    );
  }

  // ✅ بناء الصورة الافتراضية
  Widget _buildDefaultImage() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Image.asset(
          defaultImagePath,
          width: width != null ? width! * 0.6 : 60,
          height: height != null ? height! * 0.6 : 60,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // ✅ إذا فشل تحميل الصورة الافتراضية، نعرض أيقونة
            return Icon(
              Icons.image,
              color: Colors.grey.shade400,
              size: (width != null && width! < 100) ? 30 : 50,
            );
          },
        ),
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
}

/// Widget لعرض صورة المجموعة أو جهة الاتصال
class CloudinaryAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fallbackText;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final String defaultAvatarPath; // ✅ مسار الصورة الافتراضية للبروفايل

  const CloudinaryAvatar({
    super.key,
    required this.imageUrl,
    required this.fallbackText,
    this.radius = 28,
    this.backgroundColor,
    this.textColor,
    this.defaultAvatarPath = 'assets/images/default_avatar.png', // ✅ صورة البروفايل الافتراضية
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildDefaultAvatar(); // ✅ استخدام الصورة الافتراضية
    }

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
          placeholder: (context, url) => _buildDefaultAvatar(), // ✅ استخدام الصورة الافتراضية أثناء التحميل
          errorWidget: (context, url, error) => _buildDefaultAvatar(), // ✅ استخدام الصورة الافتراضية عند الخطأ
        ),
      ),
    );
  }

  // ✅ بناء الصورة الافتراضية للبروفايل
  Widget _buildDefaultAvatar() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? ManagerColors.primaryColor.withOpacity(0.1),
      child: ClipOval(
        child: Image.asset(
          defaultAvatarPath,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // ✅ إذا فشل تحميل الصورة الافتراضية، نعرض الحرف الأول من الاسم
            return Container(
              width: radius * 2,
              height: radius * 2,
              decoration: BoxDecoration(
                color: ManagerColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: radius * 0.6,
                    fontWeight: FontWeight.bold,
                    color: ManagerColors.white,
                  ),
                ),
              ),
            );
          },
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
  final String defaultVideoPosterPath; // ✅ مسار الصورة الافتراضية للفيديو

  const CloudinaryVideoPoster({
    super.key,
    required this.videoUrl,
    this.width,
    this.height,
    this.secondPosition = 0,
    this.fit = BoxFit.cover,
    this.defaultVideoPosterPath = 'assets/images/default_video_poster.png', // ✅ صورة الفيديو الافتراضية
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
      placeholder: (context, url) => _buildDefaultVideoPoster(), // ✅ استخدام الصورة الافتراضية أثناء التحميل
      errorWidget: (context, url, error) => _buildDefaultVideoPoster(), // ✅ استخدام الصورة الافتراضية عند الخطأ
    );
  }

  // ✅ بناء الصورة الافتراضية للفيديو
  Widget _buildDefaultVideoPoster() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Image.asset(
          defaultVideoPosterPath,
          width: width != null ? width! * 0.4 : 80,
          height: height != null ? height! * 0.4 : 80,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // ✅ إذا فشل تحميل الصورة الافتراضية، نعرض أيقونة فيديو
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam,
                  color: Colors.white.withOpacity(0.7),
                  size: (width != null && width! < 100) ? 30 : 50,
                ),
                SizedBox(height: 8),
                Text(
                  'فيديو',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// ✅ Widget جديد للصورة الافتراضية فقط
class DefaultImageWidget extends StatelessWidget {
  final double? width;
  final double? height;
  final String imagePath;
  final BoxFit fit;

  const DefaultImageWidget({
    super.key,
    this.width,
    this.height,
    this.imagePath = 'assets/images/default_image.png',
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Image.asset(
          imagePath,
          width: width != null ? width! * 0.6 : 60,
          height: height != null ? height! * 0.6 : 60,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.image,
              color: Colors.grey.shade400,
              size: (width != null && width! < 100) ? 30 : 50,
            );
          },
        ),
      ),
    );
  }
}

/// ✅ Widget جديد لأفاتار افتراضي فقط
class DefaultAvatarWidget extends StatelessWidget {
  final double radius;
  final String fallbackText;
  final String avatarPath;

  const DefaultAvatarWidget({
    super.key,
    this.radius = 28,
    required this.fallbackText,
    this.avatarPath = 'assets/images/default_avatar.png',
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: ManagerColors.primaryColor.withOpacity(0.1),
      child: ClipOval(
        child: Image.asset(
          avatarPath,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: radius * 2,
              height: radius * 2,
              decoration: BoxDecoration(
                color: ManagerColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: radius * 0.6,
                    fontWeight: FontWeight.bold,
                    color: ManagerColors.white,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
// // المسار: lib/core/widgets/cloudinary_image.dart
//
// import 'package:app_mobile/core/resources/manager_colors.dart';
// import 'package:flutter/material.dart';
// import 'package:cached_network_image/cached_network_image.dart';
//
// import '../../../../../core/service/cloudinart_service.dart';
//
// /// Widget لعرض الصور من Cloudinary مع Thumbnail وCache
// class CloudinaryImage extends StatelessWidget {
//   final String? imageUrl;
//   final double? width;
//   final double? height;
//   final BoxFit fit;
//   final Widget? placeholder;
//   final Widget? errorWidget;
//   final bool useThumbnail;
//   final int thumbnailWidth;
//   final int thumbnailHeight;
//
//   const CloudinaryImage({
//     super.key,
//     required this.imageUrl,
//     this.width,
//     this.height,
//     this.fit = BoxFit.cover,
//     this.placeholder,
//     this.errorWidget,
//     this.useThumbnail = true,
//     this.thumbnailWidth = 300,
//     this.thumbnailHeight = 300,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     if (imageUrl == null || imageUrl!.isEmpty) {
//       return _buildPlaceholder();
//     }
//
//     // استخدام Thumbnail من Cloudinary
//     final displayUrl = useThumbnail
//         ? CloudinaryService.thumb(
//       imageUrl!,
//       w: thumbnailWidth,
//       h: thumbnailHeight,
//     )
//         : imageUrl!;
//
//     return CachedNetworkImage(
//       imageUrl: displayUrl,
//       width: width,
//       height: height,
//       fit: fit,
//       placeholder: (context, url) =>
//       placeholder ?? _buildLoadingPlaceholder(),
//       errorWidget: (context, url, error) =>
//       errorWidget ?? _buildErrorWidget(),
//     );
//   }
//
//   Widget _buildPlaceholder() {
//     return Container(
//       width: width,
//       height: height,
//       color: Colors.grey.shade200,
//       child: Icon(
//         Icons.image,
//         color: Colors.grey.shade400,
//         size: (width != null && width! < 100) ? 30 : 50,
//       ),
//     );
//   }
//
//   Widget _buildLoadingPlaceholder() {
//     return Container(
//       width: width,
//       height: height,
//       color: Colors.grey.shade100,
//       child: const Center(
//         child: CircularProgressIndicator(
//           strokeWidth: 2,
//         ),
//       ),
//     );
//   }
//
//   Widget _buildErrorWidget() {
//     return Container(
//       width: width,
//       height: height,
//       color: Colors.grey.shade200,
//       child: Icon(
//         Icons.broken_image,
//         color: Colors.grey.shade400,
//         size: (width != null && width! < 100) ? 30 : 50,
//       ),
//     );
//   }
// }
//
// /// Widget لعرض صورة المجموعة أو جهة الاتصال
// class CloudinaryAvatar extends StatelessWidget {
//   final String? imageUrl;
//   final String fallbackText;
//   final double radius;
//   final Color? backgroundColor;
//   final Color? textColor;
//
//   const CloudinaryAvatar({
//     super.key,
//     required this.imageUrl,
//     required this.fallbackText,
//     this.radius = 28,
//     this.backgroundColor,
//     this.textColor,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     if (imageUrl == null || imageUrl!.isEmpty) {
//       return CircleAvatar(
//         radius: radius,
//         backgroundColor:
//         backgroundColor ?? ManagerColors.white.withOpacity(0.1),
//         child: Text(
//           fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : '?',
//           style: TextStyle(
//             fontSize: radius * 0.6,
//             fontWeight: FontWeight.bold,
//             color: ManagerColors.white,
//           ),
//         ),
//       );
//     }
//
//     final thumbnailUrl = CloudinaryService.thumb(
//       imageUrl!,
//       w: (radius * 2).toInt(),
//       h: (radius * 2).toInt(),
//     );
//
//     return CircleAvatar(
//       radius: radius,
//       backgroundColor: Colors.grey.shade200,
//       child: ClipOval(
//         child: CachedNetworkImage(
//           imageUrl: thumbnailUrl,
//           width: radius * 2,
//           height: radius * 2,
//           fit: BoxFit.cover,
//           placeholder: (context, url) => Container(
//             color: Colors.grey.shade100,
//             child: const Center(
//               child: SizedBox(
//                 width: 20,
//                 height: 20,
//                 child: CircularProgressIndicator(strokeWidth: 2),
//               ),
//             ),
//           ),
//           errorWidget: (context, url, error) => Container(
//             color: backgroundColor ??
//                 Theme.of(context).primaryColor.withOpacity(0.1),
//             child: Center(
//               child: Text(
//                 fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : '?',
//                 style: TextStyle(
//                   fontSize: radius * 0.6,
//                   fontWeight: FontWeight.bold,
//                   color: textColor ?? Theme.of(context).primaryColor,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// /// Widget لعرض بوستر الفيديو من Cloudinary
// class CloudinaryVideoPoster extends StatelessWidget {
//   final String videoUrl;
//   final double? width;
//   final double? height;
//   final int secondPosition;
//   final BoxFit fit;
//
//   const CloudinaryVideoPoster({
//     super.key,
//     required this.videoUrl,
//     this.width,
//     this.height,
//     this.secondPosition = 0,
//     this.fit = BoxFit.cover,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     // الحصول على بوستر الفيديو من Cloudinary
//     final posterUrl = CloudinaryService.videoPoster(
//       videoUrl,
//       sec: secondPosition,
//       w: width?.toInt() ?? 480,
//       h: height?.toInt(),
//     );
//
//     return CachedNetworkImage(
//       imageUrl: posterUrl,
//       width: width,
//       height: height,
//       fit: fit,
//       placeholder: (context, url) => Container(
//         width: width,
//         height: height,
//         color: Colors.black,
//         child: const Center(
//           child: CircularProgressIndicator(
//             strokeWidth: 2,
//             valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//           ),
//         ),
//       ),
//       errorWidget: (context, url, error) => Container(
//         width: width,
//         height: height,
//         color: Colors.black,
//         child: const Icon(
//           Icons.video_library,
//           color: Colors.white,
//           size: 50,
//         ),
//       ),
//     );
//   }
// }