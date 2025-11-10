// المسار: lib/features/home/group_chat/domain/models/attachment_model.dart

class AttachmentModel {
  final String id;
  final String type; // image, video, audio, file
  final String url;
  final String? thumbnailUrl; // للفيديو
  final String? fileName; // للملفات
  final int? fileSize; // بالبايت
  final int? duration; // للصوت والفيديو (بالثواني)
  final int? width; // للصور والفيديو
  final int? height; // للصور والفيديو
  final String? localPath; // للملفات المحلية قبل الرفع
  final bool isUploading;
  final double uploadProgress;

  AttachmentModel({
    required this.id,
    required this.type,
    required this.url,
    this.thumbnailUrl,
    this.fileName,
    this.fileSize,
    this.duration,
    this.width,
    this.height,
    this.localPath,
    this.isUploading = false,
    this.uploadProgress = 0.0,
  });

  // ✅ نسخ مع تحديث
  AttachmentModel copyWith({
    String? id,
    String? type,
    String? url,
    String? thumbnailUrl,
    String? fileName,
    int? fileSize,
    int? duration,
    int? width,
    int? height,
    String? localPath,
    bool? isUploading,
    double? uploadProgress,
  }) {
    return AttachmentModel(
      id: id ?? this.id,
      type: type ?? this.type,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      duration: duration ?? this.duration,
      width: width ?? this.width,
      height: height ?? this.height,
      localPath: localPath ?? this.localPath,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }

  // ✅ تحويل إلى JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'url': url,
    'thumbnailUrl': thumbnailUrl,
    'fileName': fileName,
    'fileSize': fileSize,
    'duration': duration,
    'width': width,
    'height': height,
  };

  // ✅ من JSON
  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      id: json['id'] ?? '',
      type: json['type'] ?? 'file',
      url: json['url'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      duration: json['duration'],
      width: json['width'],
      height: json['height'],
    );
  }

  // ✅ حساب حجم الملف بشكل قابل للقراءة
  String get formattedSize {
    if (fileSize == null) return '';

    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    }
    if (fileSize! < 1024 * 1024 * 1024) {
      return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSize! / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // ✅ تنسيق المدة
  String get formattedDuration {
    if (duration == null) return '';

    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // ✅ التحقق من النوع
  bool get isImage => type == 'image';
  bool get isVideo => type == 'video';
  bool get isAudio => type == 'audio';
  bool get isFile => type == 'file';
}