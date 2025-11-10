// المسار: lib/core/services/cache_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // Cache Managers
  static final imageCacheManager = CacheManager(
    Config(
      'chat_images',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 200,
    ),
  );

  static final videoCacheManager = CacheManager(
    Config(
      'chat_videos',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 50,
    ),
  );

  static final audioCacheManager = CacheManager(
    Config(
      'chat_audio',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 100,
    ),
  );

  // ================================
  // ✅ 1. CACHE IMAGE
  // ================================
  Future<File?> cacheImage(String url) async {
    try {
      final file = await imageCacheManager.getSingleFile(url);
      return file;
    } catch (e) {
      print('❌ خطأ في cache الصورة: $e');
      return null;
    }
  }

  // ================================
  // ✅ 2. CACHE VIDEO
  // ================================
  Future<File?> cacheVideo(String url) async {
    try {
      final file = await videoCacheManager.getSingleFile(url);
      return file;
    } catch (e) {
      print('❌ خطأ في cache الفيديو: $e');
      return null;
    }
  }

  // ================================
  // ✅ 3. CACHE AUDIO
  // ================================
  Future<File?> cacheAudio(String url) async {
    try {
      final file = await audioCacheManager.getSingleFile(url);
      return file;
    } catch (e) {
      print('❌ خطأ في cache الصوت: $e');
      return null;
    }
  }

  // ================================
  // ✅ 4. GET CACHED FILE
  // ================================
  Future<File?> getCachedFile(String url, String type) async {
    try {
      CacheManager manager;
      switch (type) {
        case 'image':
          manager = imageCacheManager;
          break;
        case 'video':
          manager = videoCacheManager;
          break;
        case 'audio':
          manager = audioCacheManager;
          break;
        default:
          return null;
      }

      final fileInfo = await manager.getFileFromCache(url);
      return fileInfo?.file;
    } catch (e) {
      print('❌ خطأ في جلب الملف المحفوظ: $e');
      return null;
    }
  }

  // ================================
  // ✅ 5. CHECK IF FILE IS CACHED
  // ================================
  Future<bool> isFileCached(String url, String type) async {
    try {
      final file = await getCachedFile(url, type);
      return file != null && await file.exists();
    } catch (e) {
      return false;
    }
  }

  // ================================
  // ✅ 6. CLEAR ALL CACHE
  // ================================
  Future<void> clearAllCache() async {
    try {
      await imageCacheManager.emptyCache();
      await videoCacheManager.emptyCache();
      await audioCacheManager.emptyCache();
      print('✅ تم مسح جميع الـ Cache');
    } catch (e) {
      print('❌ خطأ في مسح الـ Cache: $e');
    }
  }

  // ================================
  // ✅ 7. CLEAR IMAGE CACHE
  // ================================
  Future<void> clearImageCache() async {
    try {
      await imageCacheManager.emptyCache();
      print('✅ تم مسح cache الصور');
    } catch (e) {
      print('❌ خطأ في مسح cache الصور: $e');
    }
  }

  // ================================
  // ✅ 8. GET CACHE SIZE
  // ================================
  Future<String> getCacheSize() async {
    try {
      final dir = await getTemporaryDirectory();
      int totalSize = 0;

      if (await dir.exists()) {
        await for (var entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }

      return _formatBytes(totalSize);
    } catch (e) {
      print('❌ خطأ في حساب حجم الـ Cache: $e');
      return '0 MB';
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  // ================================
  // ✅ 9. CACHE MESSAGES (للعمل Offline)
  // ================================
  Future<void> cacheMessages(String chatId, List<Map<String, dynamic>> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'cached_messages_$chatId';
      final jsonString = json.encode(messages);
      await prefs.setString(key, jsonString);
      print('✅ تم حفظ ${messages.length} رسالة للمحادثة $chatId');
    } catch (e) {
      print('❌ خطأ في حفظ الرسائل: $e');
    }
  }

  // ================================
  // ✅ 10. GET CACHED MESSAGES
  // ================================
  Future<List<Map<String, dynamic>>?> getCachedMessages(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'cached_messages_$chatId';
      final jsonString = prefs.getString(key);

      if (jsonString == null) return null;

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('❌ خطأ في جلب الرسائل المحفوظة: $e');
      return null;
    }
  }

  // ================================
  // ✅ 11. CACHE CHAT LIST
  // ================================
  Future<void> cacheChatList(List<Map<String, dynamic>> chats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(chats);
      await prefs.setString('cached_chat_list', jsonString);
      print('✅ تم حفظ ${chats.length} محادثة');
    } catch (e) {
      print('❌ خطأ في حفظ قائمة المحادثات: $e');
    }
  }

  // ================================
  // ✅ 12. GET CACHED CHAT LIST
  // ================================
  Future<List<Map<String, dynamic>>?> getCachedChatList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('cached_chat_list');

      if (jsonString == null) return null;

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('❌ خطأ في جلب قائمة المحادثات المحفوظة: $e');
      return null;
    }
  }

  // ================================
  // ✅ 13. CLEAR CHAT CACHE
  // ================================
  Future<void> clearChatCache(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'cached_messages_$chatId';
      await prefs.remove(key);
      print('✅ تم مسح cache المحادثة $chatId');
    } catch (e) {
      print('❌ خطأ في مسح cache المحادثة: $e');
    }
  }

  // ================================
  // ✅ 14. REMOVE FILE FROM CACHE
  // ================================
  Future<void> removeFileFromCache(String url, String type) async {
    try {
      CacheManager manager;
      switch (type) {
        case 'image':
          manager = imageCacheManager;
          break;
        case 'video':
          manager = videoCacheManager;
          break;
        case 'audio':
          manager = audioCacheManager;
          break;
        default:
          return;
      }

      await manager.removeFile(url);
      print('✅ تم حذف الملف من الـ Cache');
    } catch (e) {
      print('❌ خطأ في حذف الملف من الـ Cache: $e');
    }
  }
}