// المسار: lib/features/home/group_chat/presentation/widgets/voice_recorder_widget.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';
import 'package:app_mobile/core/resources/manager_width.dart';

import '../../../../../core/service/audio_recorder_service.dart';

class VoiceRecorderWidget extends StatefulWidget {
  final Function(String path, Duration duration) onRecordComplete;
  final VoidCallback onCancel;

  const VoiceRecorderWidget({
    super.key,
    required this.onRecordComplete,
    required this.onCancel,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget>
    with SingleTickerProviderStateMixin {
  final _audioService = AudioRecorderService();
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _timer;
  late AnimationController _animationController;
  double _slidePosition = 0;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _startRecording();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final success = await _audioService.startRecording();
    if (success) {
      setState(() {
        _isRecording = true;
      });
      _startTimer();
    } else {
      Get.snackbar(
        'خطأ',
        'فشل بدء التسجيل - تحقق من صلاحيات الميكروفون',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      widget.onCancel();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordingDuration += Duration(seconds: 1);
        });
      }
    });
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    final path = await _audioService.stopRecording();
    _timer?.cancel();

    if (path != null && path.isNotEmpty) {
      widget.onRecordComplete(path, _recordingDuration);
    } else {
      Get.snackbar(
        'خطأ',
        'فشل حفظ التسجيل',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      widget.onCancel();
    }
  }

  Future<void> _cancelRecording() async {
    await _audioService.cancelRecording();
    _timer?.cancel();
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(horizontal: ManagerWidth.w16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // زر الإلغاء/القفل
          GestureDetector(
            onTap: _isLocked ? null : _cancelRecording,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _isLocked
                    ? Colors.grey.shade300
                    : Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isLocked ? Icons.lock : Icons.delete,
                color: _isLocked ? Colors.grey : Colors.red,
                size: 24,
              ),
            ),
          ),

          SizedBox(width: ManagerWidth.w16),

          // مؤشر التسجيل والمدة
          Expanded(
            child: Row(
              children: [
                // نقطة حمراء متحركة
                FadeTransition(
                  opacity: _animationController,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                SizedBox(width: ManagerWidth.w12),

                // المدة
                Text(
                  _formatDuration(_recordingDuration),
                  style: getBoldTextStyle(
                    fontSize: ManagerFontSize.s16,
                    color: Colors.black,
                  ),
                ),

                SizedBox(width: ManagerWidth.w16),

                // موجات الصوت
                Expanded(
                  child: _buildWaveform(),
                ),
              ],
            ),
          ),

          SizedBox(width: ManagerWidth.w16),

          // زر الإرسال
          GestureDetector(
            onTap: _stopRecording,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: ManagerColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveform() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        20,
            (index) => AnimatedContainer(
          duration: Duration(milliseconds: 300),
          width: 3,
          height: _getBarHeight(index),
          decoration: BoxDecoration(
            color: ManagerColors.primaryColor.withOpacity(0.7),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  double _getBarHeight(int index) {
    // محاكاة موجات صوتية عشوائية
    final baseHeight = 10.0;
    final maxHeight = 40.0;
    final random = (index + _recordingDuration.inMilliseconds) % 10;
    return baseHeight + (random / 10) * (maxHeight - baseHeight);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

// ================================
// ✅ VOICE RECORDER BUTTON (للضغط المطول)
// ================================
class VoiceRecorderButton extends StatefulWidget {
  final Function(String path, Duration duration) onRecordComplete;

  const VoiceRecorderButton({
    super.key,
    required this.onRecordComplete,
  });

  @override
  State<VoiceRecorderButton> createState() => _VoiceRecorderButtonState();
}

class _VoiceRecorderButtonState extends State<VoiceRecorderButton> {
  bool _isRecording = false;

  @override
  Widget build(BuildContext context) {
    if (_isRecording) {
      return VoiceRecorderWidget(
        onRecordComplete: (path, duration) {
          setState(() {
            _isRecording = false;
          });
          widget.onRecordComplete(path, duration);
        },
        onCancel: () {
          setState(() {
            _isRecording = false;
          });
        },
      );
    }

    return GestureDetector(
      onLongPress: () {
        setState(() {
          _isRecording = true;
        });
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: ManagerColors.primaryColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.mic,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}