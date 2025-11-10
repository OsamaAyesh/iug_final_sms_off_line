// المسار: lib/core/services/audio_recorder_service.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart' as just_audio;

class AudioRecorderService {
  static final AudioRecorderService _instance = AudioRecorderService._internal();
  factory AudioRecorderService() => _instance;
  AudioRecorderService._internal();

  final _audioRecorder = AudioRecorder();
  final _audioPlayer = just_audio.AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isPaused = false;

  String? _currentRecordingPath;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;

  // Getters
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  Duration get recordingDuration => _recordingDuration;
  String? get currentRecordingPath => _currentRecordingPath;

  // Streams
  final _recordingStateController = StreamController<bool>.broadcast();
  final _recordingDurationController = StreamController<Duration>.broadcast();
  final _playingStateController = StreamController<bool>.broadcast();

  Stream<bool> get recordingStateStream => _recordingStateController.stream;
  Stream<Duration> get recordingDurationStream => _recordingDurationController.stream;
  Stream<bool> get playingStateStream => _playingStateController.stream;

  // ================================
  // ✅ 1. CHECK MICROPHONE PERMISSION
  // ================================
  Future<bool> checkPermission() async {
    try {
      final status = await Permission.microphone.request();
      return status.isGranted;
    } catch (e) {
      print('❌ خطأ في التحقق من صلاحية الميكروفون: $e');
      return false;
    }
  }

  // ================================
  // ✅ 2. START RECORDING
  // ================================
  Future<bool> startRecording() async {
    try {
      // التحقق من الصلاحية
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        print('❌ لا توجد صلاحية للميكروفون');
        return false;
      }

      // إنشاء مسار الملف
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/audio_$timestamp.m4a';

      // بدء التسجيل
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      _recordingDuration = Duration.zero;
      _recordingStateController.add(true);

      // بدء المؤقت
      _startTimer();

      print('✅ بدأ التسجيل: $_currentRecordingPath');
      return true;
    } catch (e) {
      print('❌ خطأ في بدء التسجيل: $e');
      return false;
    }
  }

  // ================================
  // ✅ 3. STOP RECORDING
  // ================================
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;

      final path = await _audioRecorder.stop();

      _isRecording = false;
      _recordingStateController.add(false);
      _stopTimer();

      print('✅ تم إيقاف التسجيل: $path');
      print('⏱️ مدة التسجيل: ${_recordingDuration.inSeconds} ثانية');

      return path;
    } catch (e) {
      print('❌ خطأ في إيقاف التسجيل: $e');
      return null;
    }
  }

  // ================================
  // ✅ 4. CANCEL RECORDING
  // ================================
  Future<void> cancelRecording() async {
    try {
      if (!_isRecording) return;

      await _audioRecorder.stop();

      _isRecording = false;
      _recordingStateController.add(false);
      _stopTimer();

      // حذف الملف
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      _currentRecordingPath = null;
      _recordingDuration = Duration.zero;

      print('✅ تم إلغاء التسجيل');
    } catch (e) {
      print('❌ خطأ في إلغاء التسجيل: $e');
    }
  }

  // ================================
  // ✅ 5. PAUSE RECORDING
  // ================================
  Future<void> pauseRecording() async {
    try {
      if (!_isRecording || _isPaused) return;

      await _audioRecorder.pause();
      _isPaused = true;
      _stopTimer();

      print('⏸️ تم إيقاف التسجيل مؤقتاً');
    } catch (e) {
      print('❌ خطأ في إيقاف التسجيل مؤقتاً: $e');
    }
  }

  // ================================
  // ✅ 6. RESUME RECORDING
  // ================================
  Future<void> resumeRecording() async {
    try {
      if (!_isRecording || !_isPaused) return;

      await _audioRecorder.resume();
      _isPaused = false;
      _startTimer();

      print('▶️ تم استئناف التسجيل');
    } catch (e) {
      print('❌ خطأ في استئناف التسجيل: $e');
    }
  }

  // ================================
  // ✅ 7. PLAY AUDIO
  // ================================
  Future<void> playAudio(String path) async {
    try {
      if (_isPlaying) {
        await stopPlayback();
      }

      await _audioPlayer.setFilePath(path);
      await _audioPlayer.play();

      _isPlaying = true;
      _playingStateController.add(true);

      // الاستماع لانتهاء التشغيل
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == just_audio.ProcessingState.completed) {
          stopPlayback();
        }
      });

      print('▶️ بدأ تشغيل الصوت: $path');
    } catch (e) {
      print('❌ خطأ في تشغيل الصوت: $e');
    }
  }

  // ================================
  // ✅ 8. PAUSE PLAYBACK
  // ================================
  Future<void> pausePlayback() async {
    try {
      if (!_isPlaying) return;

      await _audioPlayer.pause();
      _isPlaying = false;
      _playingStateController.add(false);

      print('⏸️ تم إيقاف تشغيل الصوت مؤقتاً');
    } catch (e) {
      print('❌ خطأ في إيقاف التشغيل مؤقتاً: $e');
    }
  }

  // ================================
  // ✅ 9. STOP PLAYBACK
  // ================================
  Future<void> stopPlayback() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      _playingStateController.add(false);

      print('⏹️ تم إيقاف تشغيل الصوت');
    } catch (e) {
      print('❌ خطأ في إيقاف التشغيل: $e');
    }
  }

  // ================================
  // ✅ 10. GET AUDIO DURATION
  // ================================
  Future<Duration?> getAudioDuration(String path) async {
    try {
      await _audioPlayer.setFilePath(path);
      return _audioPlayer.duration;
    } catch (e) {
      print('❌ خطأ في الحصول على مدة الصوت: $e');
      return null;
    }
  }

  // ================================
  // ✅ 11. FORMAT DURATION
  // ================================
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  // ================================
  // ✅ 12. TIMER MANAGEMENT
  // ================================
  void _startTimer() {
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _recordingDuration += const Duration(seconds: 1);
      _recordingDurationController.add(_recordingDuration);
    });
  }

  void _stopTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  // ================================
  // ✅ 13. DISPOSE
  // ================================
  Future<void> dispose() async {
    await _audioRecorder.dispose();
    await _audioPlayer.dispose();
    _stopTimer();
    await _recordingStateController.close();
    await _recordingDurationController.close();
    await _playingStateController.close();
  }
}