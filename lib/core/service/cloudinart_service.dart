// lib/services/cloudinary_service.dart
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // قيَم حسابك:
  static const String cloudName = 'dtceqefa9';           // من لوحة Cloudinary
  static const String unsignedPreset = 'chat_media';  // اسم الـ Upload preset

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

  // --------------------------
  // Helpers for transformed URLs
  // --------------------------

  /// يضيف تحويلات بعد مقطع /upload/ بأمان (سواء resource_type صورة أو فيديو).
  /// يحافظ على باقي المسار كما هو (version/folder/filename).
  static String _injectTransform(String secureUrl, String transform) {
    final uri = Uri.parse(secureUrl);
    // نحاول العثور على /image/upload/ أو /video/upload/
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

    final before = path.substring(0, idx + pivot.length); // حتى نهاية 'upload/'
    final after  = path.substring(idx + pivot.length);     // الباقي (قد يبدأ بـ v123/...)

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
      // لكن الأفضل أن يكون المصدر من Cloudinary فيديو.
    }

    // تحضير التحويلات
    final sizePart = (h != null) ? 'c_fill,w_$w,h_$h' : 'w_$w';
    final transform = 'so_$sec,$sizePart,f_auto,q_auto';

    // نحقن التحويلات بعد /upload/
    String withTransform = _injectTransform(secureVideoUrl, transform);

    // نُجبر الامتداد على jpg (Cloudinary سيُرجع صورة ثابتة)
    // أمثلة تنتهي بـ .mp4 أو .mov ... نستبدلها بـ .jpg
    withTransform = withTransform.replaceFirst(RegExp(r'\.[^./?]+($|\?)'), '.jpg');

    return withTransform;
  }
}
