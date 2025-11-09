// lib/core/services/cloudinary_service.dart
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // ✅ قيَم حسابك (بدون تغيير)
  static const String cloudName = 'dtceqefa9';
  static const String unsignedPreset = 'chat_media';

  // ================================
  // ✅ 1. دالتك الأصلية (upload) - بدون تغيير
  // ================================
  /// رفع (صورة/فيديو/صوت) ويُرجع secure_url
  /// ملاحظة: الصوت نرفعه عبر resourceType=video (افتراضي Cloudinary)
  static Future<String> upload({
    required File file,
    required String type,   // 'image' | 'video' | 'audio'
    String? folder,         // مثال: chat_media/{roomId}/{messageId}
  }) async {
    final resourceType = (type == 'image') ? 'image' : 'video';
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload');

    final req = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = unsignedPreset;
    if (folder != null && folder.isNotEmpty) {
      req.fields['folder'] = folder;
    }
    req.files.add(await http.MultipartFile.fromPath('file', file.path));

    final res = await req.send();
    final body = await http.Response.fromStream(res);

    if (body.statusCode != 200) {
      throw Exception('Cloudinary upload failed: ${body.statusCode} ${body.body}');
    }

    final m = RegExp(r'"secure_url"\s*:\s*"([^"]+)"').firstMatch(body.body)
        ?? RegExp(r'"url"\s*:\s*"([^"]+)"').firstMatch(body.body);
    final url = m?.group(1);
    if (url == null) throw Exception('secure_url not found');
    return url;
  }

  // ================================
  // ✅ 2. دوالك الأصلية (Helpers) - بدون تغيير
  // ================================

  /// يضيف تحويلات بعد مقطع /upload/ بأمان (سواء resource_type صورة أو فيديو).
  /// يحافظ على باقي المسار كما هو (version/folder/filename).
  static String _injectTransform(String secureUrl, String transform) {
    final uri = Uri.parse(secureUrl);
    const pivots = ['/image/upload/', '/video/upload/', '/upload/'];
    String path = uri.path;
    int idx = -1;
    String pivot = '';

    for (final p in pivots) {
      final i = path.indexOf(p);
      if (i >= 0) {
        idx = i;
        pivot = p;
        break;
      }
    }
    if (idx < 0) return secureUrl; // fallback

    final before = path.substring(0, idx + pivot.length);
    final after  = path.substring(idx + pivot.length);

    final newPath = '$before$transform/$after';
    return uri.replace(path: newPath).toString();
  }

  /// صورة مصغّرة لأي **صورة** من Cloudinary
  /// تضيف f_auto,q_auto وحجم (w,h) مع c_fill لتعبئة الإطار
  static String thumb(String secureUrl, {int w = 300, int h = 300}) {
    final t = 'f_auto,q_auto,c_fill,w_$w,h_$h';
    return _injectTransform(secureUrl, t);
  }

  /// إرجاع **JPG** لبوستر فيديو (secure_url للفيديو).
  /// - sec: الثانية المطلوبة من الفيديو (افتراضي 0 = أول فريم)
  /// - w/h: أبعاد اختيارية (لو وضعت h يتم استخدام c_fill للحفاظ على نسبة العرض)
  static String videoPoster(String secureVideoUrl, {int sec = 0, int w = 480, int? h}) {
    final uri = Uri.parse(secureVideoUrl);
    final path = uri.path;

    // نتأكد أنه فيديو
    if (!path.contains('/video/upload/')) {
      // لو مش واضح إنه فيديو، سنحاول على أي حال ونُرجع .jpg
    }

    // تحضير التحويلات
    final sizePart = (h != null) ? 'c_fill,w_$w,h_$h' : 'w_$w';
    final transform = 'so_$sec,$sizePart,f_auto,q_auto';

    // نحقن التحويلات بعد /upload/
    String withTransform = _injectTransform(secureVideoUrl, transform);

    // نُجبر الامتداد على jpg (Cloudinary سيُرجع صورة ثابتة)
    withTransform = withTransform.replaceFirst(RegExp(r'\.[^./?]+($|\?)'), '.jpg');

    return withTransform;
  }

  // ================================
  // ✅ 3. دوال إضافية للتكامل مع التطبيق (جديدة)
  // ================================

  /// دالة مساعدة لرفع صورة وإرجاع تفاصيل كاملة
  static Future<Map<String, dynamic>> uploadImage({
    required File file,
    String? folder,
  }) async {
    try {
      final url = await upload(
        file: file,
        type: 'image',
        folder: folder ?? 'chat_images',
      );

      // استخراج معلومات إضافية من الـ URL
      final fileName = file.path.split('/').last;
      final fileSize = await file.length();

      return {
        'success': true,
        'url': url,
        'thumbnailUrl': thumb(url, w: 300, h: 300), // استخدام دالتك thumb
        'fileName': fileName,
        'fileSize': fileSize,
      };
    } catch (e) {
      print('❌ خطأ في رفع الصورة: $e');
      return {
        'success': false,
        'error': 'فشل رفع الصورة: $e',
      };
    }
  }

  /// دالة مساعدة لرفع فيديو وإرجاع تفاصيل كاملة (مع بوستر تلقائي)
  static Future<Map<String, dynamic>> uploadVideo({
    required File file,
    String? folder,
  }) async {
    try {
      final url = await upload(
        file: file,
        type: 'video',
        folder: folder ?? 'chat_videos',
      );

      final fileName = file.path.split('/').last;
      final fileSize = await file.length();

      return {
        'success': true,
        'url': url,
        'thumbnailUrl': videoPoster(url, sec: 0, w: 480, h: 360), // استخدام دالتك videoPoster
        'fileName': fileName,
        'fileSize': fileSize,
      };
    } catch (e) {
      print('❌ خطأ في رفع الفيديو: $e');
      return {
        'success': false,
        'error': 'فشل رفع الفيديو: $e',
      };
    }
  }

  /// دالة مساعدة لرفع صوت وإرجاع تفاصيل كاملة
  static Future<Map<String, dynamic>> uploadAudio({
    required File file,
    String? folder,
    int? durationInSeconds,
  }) async {
    try {
      final url = await upload(
        file: file,
        type: 'audio',
        folder: folder ?? 'chat_audio',
      );

      final fileName = file.path.split('/').last;
      final fileSize = await file.length();

      return {
        'success': true,
        'url': url,
        'fileName': fileName,
        'fileSize': fileSize,
        'duration': durationInSeconds,
      };
    } catch (e) {
      print('❌ خطأ في رفع الصوت: $e');
      return {
        'success': false,
        'error': 'فشل رفع الصوت: $e',
      };
    }
  }

  /// دالة مساعدة لرفع ملف (PDF, Word, إلخ)
  static Future<Map<String, dynamic>> uploadFile({
    required File file,
    String? folder,
  }) async {
    try {
      // للملفات نستخدم resource_type=raw
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/raw/upload');

      final req = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = unsignedPreset;

      if (folder != null && folder.isNotEmpty) {
        req.fields['folder'] = folder;
      } else {
        req.fields['folder'] = 'chat_files';
      }

      req.files.add(await http.MultipartFile.fromPath('file', file.path));

      final res = await req.send();
      final body = await http.Response.fromStream(res);

      if (body.statusCode != 200) {
        throw Exception('Cloudinary upload failed: ${body.statusCode}');
      }

      final m = RegExp(r'"secure_url"\s*:\s*"([^"]+)"').firstMatch(body.body);
      final url = m?.group(1);
      if (url == null) throw Exception('secure_url not found');

      final fileName = file.path.split('/').last;
      final fileSize = await file.length();

      return {
        'success': true,
        'url': url,
        'fileName': fileName,
        'fileSize': fileSize,
      };
    } catch (e) {
      print('❌ خطأ في رفع الملف: $e');
      return {
        'success': false,
        'error': 'فشل رفع الملف: $e',
      };
    }
  }

  /// دالة مساعدة للحصول على URL محسّن للصورة
  static String getOptimizedImageUrl(String url, {int? width, int? height}) {
    if (width != null && height != null) {
      return thumb(url, w: width, h: height);
    } else if (width != null) {
      return thumb(url, w: width, h: width);
    }
    return thumb(url); // افتراضي 300x300
  }

  /// دالة مساعدة للحصول على thumbnail للفيديو
  static String getVideoThumbnail(String videoUrl, {int sec = 0}) {
    return videoPoster(videoUrl, sec: sec, w: 480, h: 360);
  }
}