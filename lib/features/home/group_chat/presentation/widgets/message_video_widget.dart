// المسار: lib/features/home/group_chat/presentation/widgets/message_video_widget.dart

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';
import 'package:app_mobile/core/resources/manager_width.dart';
import 'package:app_mobile/core/widgets/shimmer_loading.dart';
import 'package:app_mobile/features/home/group_chat/domain/models/attachment_model.dart';

import '../../../../../core/service/cache_service.dart';

class MessageVideoWidget extends StatelessWidget {
  final AttachmentModel attachment;
  final bool isMine;

  const MessageVideoWidget({
    super.key,
    required this.attachment,
    this.isMine = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openVideoPlayer(context),
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
              // Thumbnail
              _buildThumbnail(),

              // Play Button
              if (!attachment.isUploading)
                Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),

              // Duration Badge
              if (attachment.duration != null && !attachment.isUploading)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ManagerWidth.w8,
                      vertical: ManagerHeight.h4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      attachment.formattedDuration,
                      style: getRegularTextStyle(
                        fontSize: ManagerFontSize.s11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // Upload Progress
              if (attachment.isUploading) _buildUploadProgress(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (attachment.thumbnailUrl != null && attachment.thumbnailUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: attachment.thumbnailUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => ShimmerLoading.imageShimmer(
          height: 200,
          borderRadius: BorderRadius.circular(12),
        ),
        errorWidget: (context, url, error) => _buildPlaceholder(),
        cacheManager: CacheService.imageCacheManager,
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade300,
      child: Center(
        child: Icon(
          Icons.videocam,
          size: 60,
          color: Colors.grey.shade600,
        ),
      ),
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

  void _openVideoPlayer(BuildContext context) {
    if (attachment.isUploading) return;

    Get.to(
          () => VideoPlayerScreen(attachment: attachment),
      transition: Transition.fadeIn,
    );
  }
}

// ================================
// ✅ VIDEO PLAYER SCREEN - الإصلاح
// ================================
class VideoPlayerScreen extends StatefulWidget {
  final AttachmentModel attachment;

  const VideoPlayerScreen({super.key, required this.attachment});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      if (widget.attachment.localPath != null && File(widget.attachment.localPath!).existsSync()) {
        _controller = VideoPlayerController.file(File(widget.attachment.localPath!));
      } else {
        // استخدام الرابط المباشر
        _controller = VideoPlayerController.network(widget.attachment.url);
      }

      await _controller.initialize();

      setState(() {
        _isInitialized = true;
      });

      // التشغيل التلقائي
      _controller.play();
      _controller.setLooping(false);

    } catch (e) {
      print('❌ خطأ في تشغيل الفيديو: $e');
      setState(() {
        _hasError = true;
      });
    }
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _controller.play();
    } else {
      _controller.pause();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
        },
        child: Center(
          child: _buildVideoContent(),
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    if (_hasError) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.white),
          SizedBox(height: 16),
          Text(
            'فشل تشغيل الفيديو',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'تأكد من اتصال الإنترنت',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      );
    }

    if (!_isInitialized) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'جاري تحميل الفيديو...',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
        if (_showControls) _buildControls(),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        children: [
          // Spacer
          Expanded(child: Container()),

          // Bottom Controls
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Play/Pause Button
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),

                SizedBox(width: 16),

                // Progress Bar
                Expanded(
                  child: VideoProgressIndicator(
                    _controller,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: ManagerColors.primaryColor,
                      bufferedColor: Colors.grey.shade600,
                      backgroundColor: Colors.grey.shade300,
                    ),
                  ),
                ),

                SizedBox(width: 16),

                // Duration
                Text(
                  _formatDuration(_controller.value.position),
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}