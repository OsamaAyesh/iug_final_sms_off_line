// المسار: lib/features/home/group_chat/presentation/widgets/message_audio_widget.dart

import 'dart:io';
import 'dart:math'; // ✅ إضافة هذه المكتبة
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../../core/resources/manager_colors.dart';
import '../../../../../core/resources/manager_font_size.dart';
import '../../../../../core/resources/manager_height.dart';
import '../../../../../core/resources/manager_styles.dart';
import '../../../../../core/resources/manager_width.dart';
import '../../../../../core/service/cache_service.dart' show CacheService;
import '../../domain/models/attachment_model.dart';

class MessageAudioWidget extends StatefulWidget {
  final AttachmentModel attachment;
  final bool isMine;

  const MessageAudioWidget({
    super.key,
    required this.attachment,
    this.isMine = false,
  });

  @override
  State<MessageAudioWidget> createState() => _MessageAudioWidgetState();
}

class _MessageAudioWidgetState extends State<MessageAudioWidget> with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  late AnimationController _waveformController;
  List<double> _waveformHeights = [];

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
    _initWaveformAnimation();
    _generateWaveform();
  }

  void _initWaveformAnimation() {
    _waveformController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  void _generateWaveform() {
    // توليد أطوال عشوائية للموجات الصوتية (مثل واتساب/تليجرام)
    _waveformHeights = List.generate(40, (index) {
      return (20 + (index % 10) * 3).toDouble();
    });
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
          _waveformController.stop();
        });
      } else {
        setState(() {
          _isLoading = true;
        });

        // إذا لم يتم تحميل الصوت بعد
        if (_audioPlayer.duration == null) {
          if (widget.attachment.localPath != null) {
            await _audioPlayer.setFilePath(widget.attachment.localPath!);
          } else {
            // محاولة جلب من الـ Cache
            final cachedFile = await CacheService().getCachedFile(
              widget.attachment.url,
              'audio',
            );

            if (cachedFile != null) {
              await _audioPlayer.setFilePath(cachedFile.path);
            } else {
              await _audioPlayer.setUrl(widget.attachment.url);
            }
          }
        }

        await _audioPlayer.play();
        setState(() {
          _isPlaying = true;
          _isLoading = false;
        });
        _waveformController.repeat(reverse: true);
      }
    } catch (e) {
      print('❌ خطأ في تشغيل الصوت: $e');
      setState(() {
        _isLoading = false;
        _isPlaying = false;
      });
      Get.snackbar(
        'خطأ',
        'فشل تشغيل الملف الصوتي',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _waveformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: ManagerWidth.w16,
        vertical: ManagerHeight.h12,
      ),
      decoration: BoxDecoration(
        color: widget.isMine
            ? ManagerColors.primaryColor.withOpacity(0.9)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause Button
          GestureDetector(
            onTap: widget.attachment.isUploading ? null : _togglePlayPause,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.isMine
                    ? Colors.white.withOpacity(0.9)
                    : ManagerColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: _buildPlayButton(),
            ),
          ),

          SizedBox(width: ManagerWidth.w12),

          // Waveform and Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Waveform (موجات صوتية متذبذبة)
                Container(
                  height: 30,
                  child: _buildWaveform(),
                ),

                SizedBox(height: ManagerHeight.h4),

                // Progress and Duration
                Row(
                  children: [
                    // Current Time
                    Text(
                      _formatDuration(_position),
                      style: getRegularTextStyle(
                        fontSize: ManagerFontSize.s10,
                        color: widget.isMine
                            ? Colors.white.withOpacity(0.8)
                            : Colors.grey.shade600,
                      ),
                    ),

                    Spacer(),

                    // Total Duration
                    Text(
                      _formatDuration(_duration),
                      style: getRegularTextStyle(
                        fontSize: ManagerFontSize.s10,
                        color: widget.isMine
                            ? Colors.white.withOpacity(0.8)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton() {
    if (_isLoading) {
      return Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.isMine ? ManagerColors.primaryColor : Colors.white,
            ),
          ),
        ),
      );
    }

    if (widget.attachment.isUploading) {
      return Icon(
        Icons.hourglass_empty,
        color: widget.isMine ? ManagerColors.primaryColor : Colors.white,
        size: 20,
      );
    }

    return Icon(
      _isPlaying ? Icons.pause : Icons.play_arrow,
      color: widget.isMine ? ManagerColors.primaryColor : Colors.white,
      size: 24,
    );
  }

  Widget _buildWaveform() {
    return AnimatedBuilder(
      animation: _waveformController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_waveformHeights.length, (index) {
            // حساب التذبذب بناءً على التشغيل والرسوم المتحركة
            double baseHeight = _waveformHeights[index];
            double animatedHeight = baseHeight;

            if (_isPlaying) {
              // تأثير التموج أثناء التشغيل - الإصلاح هنا
              double animationValue = _waveformController.value;
              int waveIndex = index % 10;
              double waveOffset = (waveIndex / 10) * 2 * pi; // ✅ استخدام pi من dart:math
              double wave = sin(animationValue * 2 * pi + waveOffset).abs(); // ✅ استخدام sin من dart:math
              animatedHeight = baseHeight * (0.7 + 0.3 * wave);
            } else {
              // ارتفاع ثابت عند التوقف
              animatedHeight = baseHeight * 0.7;
            }

            // حساب العرض بناءً على التقدم
            double progress = _duration.inMilliseconds > 0
                ? _position.inMilliseconds / _duration.inMilliseconds
                : 0.0;
            bool isPlayed = index < (_waveformHeights.length * progress);

            return Container(
              width: 2,
              height: animatedHeight,
              decoration: BoxDecoration(
                color: isPlayed
                    ? (widget.isMine ? Colors.white : ManagerColors.primaryColor)
                    : (widget.isMine ? Colors.white.withOpacity(0.5) : Colors.grey.shade500),
                borderRadius: BorderRadius.circular(1),
              ),
            );
          }),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}