import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:app_mobile/core/resources/manager_colors.dart';
import 'package:app_mobile/core/resources/manager_font_size.dart';
import 'package:app_mobile/core/resources/manager_height.dart';
import 'package:app_mobile/core/resources/manager_width.dart';
import 'package:app_mobile/core/resources/manager_styles.dart';
import 'voice_recorder_widget.dart';

class MessageInputField extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSend;
  final Function(File, String)? onFileSelected;
  final bool isSending;

  const MessageInputField({
    super.key,
    required this.controller,
    required this.onSend,
    this.onFileSelected,
    this.isSending = false,
  });

  @override
  State<MessageInputField> createState() => _MessageInputFieldState();
}

class _MessageInputFieldState extends State<MessageInputField> {
  bool _isRecording = false;
  bool _hasText = false; // ✅ لتتبع وجود نص بشكل ديناميكي
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // ✅ الاستماع لتغييرات النص في الـ TextField
    widget.controller.addListener(_onTextChanged);
    _hasText = widget.controller.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    // ✅ إزالة الاستماع لمنع Memory Leak
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  // ✅ دالة تُنفذ تلقائياً عند أي تغيير في النص
  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    // فقط نعمل setState إذا تغيرت الحالة فعلياً (تحسين الأداء)
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // إذا كان يسجل صوت، يظهر واجهة التسجيل
    if (_isRecording) {
      return VoiceRecorderWidget(
        onRecordComplete: (path, duration) {
          setState(() {
            _isRecording = false;
          });
          if (widget.onFileSelected != null) {
            widget.onFileSelected!(File(path), 'audio');
          }
        },
        onCancel: () {
          setState(() {
            _isRecording = false;
          });
        },
      );
    }

    // الواجهة العادية
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ManagerWidth.w12,
        vertical: ManagerHeight.h8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment Button
            IconButton(
              icon: Icon(
                Icons.add_circle_outline,
                color: Colors.grey.shade600,
                size: 26,
              ),
              onPressed: widget.isSending ? null : _showAttachmentOptions,
            ),

            // Text Field
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ManagerWidth.w12,
                  vertical: ManagerHeight.h4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: widget.controller,
                  style: getRegularTextStyle(
                    fontSize: ManagerFontSize.s14,
                    color: ManagerColors.black,
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  enabled: !widget.isSending,
                  decoration: InputDecoration(
                    hintText: widget.isSending ? "جاري الإرسال..." : "اكتب رسالتك...",
                    hintStyle: getRegularTextStyle(
                      fontSize: ManagerFontSize.s14,
                      color: Colors.grey.shade400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: ManagerHeight.h10,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(width: ManagerWidth.w4),

            // ✅ زر ديناميكي: إرسال أو ميكروفون
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  // ✅ الزر الديناميكي الذي يتغير حسب وجود النص
  Widget _buildActionButton() {
    // إذا فيه نص → زر الإرسال
    if (_hasText) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: Container(
          key: const ValueKey('send_button'),
          decoration: BoxDecoration(
            color: widget.isSending
                ? Colors.grey.shade400
                : ManagerColors.primaryColor,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: widget.isSending
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Icon(
              Icons.send_rounded,
              color: Colors.white,
              size: 22,
            ),
            onPressed: widget.isSending
                ? null
                : () {
              if (widget.controller.text.trim().isNotEmpty) {
                widget.onSend(widget.controller.text.trim());
              }
            },
          ),
        ),
      );
    }

    // إذا مافيش نص → زر الميكروفون
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) {
        return ScaleTransition(scale: animation, child: child);
      },
      child: GestureDetector(
        key: const ValueKey('mic_button'),
        onLongPress: widget.isSending
            ? null
            : () {
          setState(() {
            _isRecording = true;
          });
        },
        onTap: widget.isSending
            ? null
            : () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('اضغط مطولاً لتسجيل الصوت'),
              duration: Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: widget.isSending
                ? Colors.grey.shade400
                : ManagerColors.primaryColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mic,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: ManagerHeight.h8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: ManagerHeight.h8),
            Padding(
              padding: EdgeInsets.all(ManagerWidth.w16),
              child: Column(
                children: [
                  _attachmentOption(
                    'صورة',
                    Icons.image,
                    Colors.purple,
                    _pickImage,
                  ),
                  _attachmentOption(
                    'فيديو',
                    Icons.videocam,
                    Colors.red,
                    _pickVideo,
                  ),
                  _attachmentOption(
                    'ملف',
                    Icons.insert_drive_file,
                    Colors.blue,
                    _pickFile,
                  ),
                  _attachmentOption(
                    'منشن للجميع',
                    Icons.alternate_email,
                    Colors.orange,
                        () {
                      Navigator.pop(context);
                      final currentText = widget.controller.text;
                      final cursorPos = widget.controller.selection.baseOffset;

                      if (cursorPos >= 0) {
                        final newText = currentText.substring(0, cursorPos) +
                            '@الكل ' +
                            currentText.substring(cursorPos);
                        widget.controller.text = newText;
                        widget.controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: cursorPos + 6),
                        );
                      } else {
                        widget.controller.text += '@الكل ';
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _attachmentOption(
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(ManagerWidth.w10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: getRegularTextStyle(
          fontSize: ManagerFontSize.s14,
          color: Colors.black,
        ),
      ),
      onTap: onTap,
    );
  }

  // ================================
  // ✅ PICK IMAGE
  // ================================
  Future<void> _pickImage() async {
    Navigator.pop(context);

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null && widget.onFileSelected != null) {
        widget.onFileSelected!(File(image.path), 'image');
      }
    } catch (e) {
      print('❌ خطأ في اختيار الصورة: $e');
    }
  }

  // ================================
  // ✅ PICK VIDEO
  // ================================
  Future<void> _pickVideo() async {
    Navigator.pop(context);

    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (video != null && widget.onFileSelected != null) {
        widget.onFileSelected!(File(video.path), 'video');
      }
    } catch (e) {
      print('❌ خطأ في اختيار الفيديو: $e');
    }
  }

  // ================================
  // ✅ PICK FILE
  // ================================
  Future<void> _pickFile() async {
    Navigator.pop(context);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'zip'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        if (widget.onFileSelected != null) {
          widget.onFileSelected!(file, 'file');
        }
      }
    } catch (e) {
      print('❌ خطأ في اختيار الملف: $e');
    }
  }
}
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:app_mobile/core/resources/manager_colors.dart';
// import 'package:app_mobile/core/resources/manager_font_size.dart';
// import 'package:app_mobile/core/resources/manager_height.dart';
// import 'package:app_mobile/core/resources/manager_width.dart';
// import 'package:app_mobile/core/resources/manager_styles.dart';
// import 'voice_recorder_widget.dart';
//
// class MessageInputField extends StatefulWidget {
//   final TextEditingController controller;
//   final Function(String) onSend;
//   final Function(File, String)? onFileSelected;
//   final bool isSending;
//
//   const MessageInputField({
//     super.key,
//     required this.controller,
//     required this.onSend,
//     this.onFileSelected,
//     this.isSending = false,
//   });
//
//   @override
//   State<MessageInputField> createState() => _MessageInputFieldState();
// }
//
// class _MessageInputFieldState extends State<MessageInputField> {
//   bool _isRecording = false;
//   bool _hasText = false; // ✅ لتتبع وجود نص بشكل ديناميكي
//   final _imagePicker = ImagePicker();
//
//   @override
//   void initState() {
//     super.initState();
//     // ✅ الاستماع لتغييرات النص في الـ TextField
//     widget.controller.addListener(_onTextChanged);
//     _hasText = widget.controller.text.trim().isNotEmpty;
//   }
//
//   @override
//   void dispose() {
//     // ✅ إزالة الاستماع لمنع Memory Leak
//     widget.controller.removeListener(_onTextChanged);
//     super.dispose();
//   }
//
//   // ✅ دالة تُنفذ تلقائياً عند أي تغيير في النص
//   void _onTextChanged() {
//     final hasText = widget.controller.text.trim().isNotEmpty;
//     // فقط نعمل setState إذا تغيرت الحالة فعلياً (تحسين الأداء)
//     if (hasText != _hasText) {
//       setState(() {
//         _hasText = hasText;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // إذا كان يسجل صوت، يظهر واجهة التسجيل
//     if (_isRecording) {
//       return VoiceRecorderWidget(
//         onRecordComplete: (path, duration) {
//           setState(() {
//             _isRecording = false;
//           });
//           if (widget.onFileSelected != null) {
//             widget.onFileSelected!(File(path), 'audio');
//           }
//         },
//         onCancel: () {
//           setState(() {
//             _isRecording = false;
//           });
//         },
//       );
//     }
//
//     // الواجهة العادية
//     return Container(
//       padding: EdgeInsets.symmetric(
//         horizontal: ManagerWidth.w12,
//         vertical: ManagerHeight.h8,
//       ),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: SafeArea(
//         child: Row(
//           children: [
//             // Attachment Button
//             IconButton(
//               icon: Icon(
//                 Icons.add_circle_outline,
//                 color: Colors.grey.shade600,
//                 size: 26,
//               ),
//               onPressed: widget.isSending ? null : _showAttachmentOptions,
//             ),
//
//             // Text Field
//             Expanded(
//               child: Container(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: ManagerWidth.w12,
//                   vertical: ManagerHeight.h4,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade100,
//                   borderRadius: BorderRadius.circular(24),
//                 ),
//                 child: TextField(
//                   controller: widget.controller,
//                   style: getRegularTextStyle(
//                     fontSize: ManagerFontSize.s14,
//                     color: ManagerColors.black,
//                   ),
//                   maxLines: null,
//                   textInputAction: TextInputAction.newline,
//                   enabled: !widget.isSending,
//                   decoration: InputDecoration(
//                     hintText: widget.isSending ? "جاري الإرسال..." : "اكتب رسالتك...",
//                     hintStyle: getRegularTextStyle(
//                       fontSize: ManagerFontSize.s14,
//                       color: Colors.grey.shade400,
//                     ),
//                     border: InputBorder.none,
//                     isDense: true,
//                     contentPadding: EdgeInsets.symmetric(
//                       vertical: ManagerHeight.h10,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//
//             SizedBox(width: ManagerWidth.w4),
//
//             // ✅ زر ديناميكي: إرسال أو ميكروفون
//             _buildActionButton(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ✅ الزر الديناميكي الذي يتغير حسب وجود النص
//   Widget _buildActionButton() {
//     // إذا فيه نص → زر الإرسال
//     if (_hasText) {
//       return AnimatedSwitcher(
//         duration: const Duration(milliseconds: 200),
//         transitionBuilder: (child, animation) {
//           return ScaleTransition(scale: animation, child: child);
//         },
//         child: Container(
//           key: const ValueKey('send_button'),
//           decoration: BoxDecoration(
//             color: widget.isSending
//                 ? Colors.grey.shade400
//                 : ManagerColors.primaryColor,
//             shape: BoxShape.circle,
//           ),
//           child: IconButton(
//             icon: widget.isSending
//                 ? const SizedBox(
//               width: 22,
//               height: 22,
//               child: CircularProgressIndicator(
//                 strokeWidth: 2,
//                 valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//               ),
//             )
//                 : const Icon(
//               Icons.send_rounded,
//               color: Colors.white,
//               size: 22,
//             ),
//             onPressed: widget.isSending
//                 ? null
//                 : () {
//               if (widget.controller.text.trim().isNotEmpty) {
//                 widget.onSend(widget.controller.text.trim());
//               }
//             },
//           ),
//         ),
//       );
//     }
//
//     // إذا مافيش نص → زر الميكروفون
//     return AnimatedSwitcher(
//       duration: const Duration(milliseconds: 200),
//       transitionBuilder: (child, animation) {
//         return ScaleTransition(scale: animation, child: child);
//       },
//       child: GestureDetector(
//         key: const ValueKey('mic_button'),
//         onLongPress: widget.isSending
//             ? null
//             : () {
//           setState(() {
//             _isRecording = true;
//           });
//         },
//         onTap: widget.isSending
//             ? null
//             : () {
//           // نصيحة للمستخدم عند الضغط العادي
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('اضغط مطولاً لتسجيل الصوت 🎤'),
//               duration: Duration(seconds: 1),
//               behavior: SnackBarBehavior.floating,
//             ),
//           );
//         },
//         child: Container(
//           width: 50,
//           height: 50,
//           decoration: BoxDecoration(
//             color: widget.isSending
//                 ? Colors.grey.shade400
//                 : ManagerColors.primaryColor,
//             shape: BoxShape.circle,
//           ),
//           child: const Icon(
//             Icons.mic,
//             color: Colors.white,
//             size: 24,
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _showAttachmentOptions() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => SafeArea(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               margin: EdgeInsets.only(top: ManagerHeight.h8),
//               width: 40,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade300,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//             SizedBox(height: ManagerHeight.h8),
//             Padding(
//               padding: EdgeInsets.all(ManagerWidth.w16),
//               child: Column(
//                 children: [
//                   _attachmentOption(
//                     'صورة',
//                     Icons.image,
//                     Colors.purple,
//                     _pickImage,
//                   ),
//                   _attachmentOption(
//                     'فيديو',
//                     Icons.videocam,
//                     Colors.red,
//                     _pickVideo,
//                   ),
//                   _attachmentOption(
//                     'ملف',
//                     Icons.insert_drive_file,
//                     Colors.blue,
//                     _pickFile,
//                   ),
//                   _attachmentOption(
//                     'منشن للجميع',
//                     Icons.alternate_email,
//                     Colors.orange,
//                         () {
//                       Navigator.pop(context);
//                       // ✅ إدراج المنشن في موضع الكيرسور
//                       final currentText = widget.controller.text;
//                       final cursorPos = widget.controller.selection.baseOffset;
//
//                       if (cursorPos >= 0) {
//                         final newText = currentText.substring(0, cursorPos) +
//                             '@الكل ' +
//                             currentText.substring(cursorPos);
//                         widget.controller.text = newText;
//                         widget.controller.selection = TextSelection.fromPosition(
//                           TextPosition(offset: cursorPos + 6),
//                         );
//                       } else {
//                         widget.controller.text += '@الكل ';
//                       }
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _attachmentOption(
//       String title,
//       IconData icon,
//       Color color,
//       VoidCallback onTap,
//       ) {
//     return ListTile(
//       leading: Container(
//         padding: EdgeInsets.all(ManagerWidth.w10),
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Icon(icon, color: color, size: 24),
//       ),
//       title: Text(
//         title,
//         style: getRegularTextStyle(
//           fontSize: ManagerFontSize.s14,
//           color: Colors.black,
//         ),
//       ),
//       onTap: onTap,
//     );
//   }
//
//   // ================================
//   // ✅ PICK IMAGE
//   // ================================
//   Future<void> _pickImage() async {
//     Navigator.pop(context);
//
//     try {
//       final XFile? image = await _imagePicker.pickImage(
//         source: ImageSource.gallery,
//         maxWidth: 1920,
//         maxHeight: 1920,
//         imageQuality: 85,
//       );
//
//       if (image != null && widget.onFileSelected != null) {
//         widget.onFileSelected!(File(image.path), 'image');
//       }
//     } catch (e) {
//       print('❌ خطأ في اختيار الصورة: $e');
//     }
//   }
//
//   // ================================
//   // ✅ PICK VIDEO
//   // ================================
//   Future<void> _pickVideo() async {
//     Navigator.pop(context);
//
//     try {
//       final XFile? video = await _imagePicker.pickVideo(
//         source: ImageSource.gallery,
//         maxDuration: const Duration(minutes: 5),
//       );
//
//       if (video != null && widget.onFileSelected != null) {
//         widget.onFileSelected!(File(video.path), 'video');
//       }
//     } catch (e) {
//       print('❌ خطأ في اختيار الفيديو: $e');
//     }
//   }
//
//   // ================================
//   // ✅ PICK FILE
//   // ================================
//   Future<void> _pickFile() async {
//     Navigator.pop(context);
//
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'zip'],
//       );
//
//       if (result != null && result.files.single.path != null) {
//         final file = File(result.files.single.path!);
//         if (widget.onFileSelected != null) {
//           widget.onFileSelected!(file, 'file');
//         }
//       }
//     } catch (e) {
//       print('❌ خطأ في اختيار الملف: $e');
//     }
//   }
// }
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:app_mobile/core/resources/manager_colors.dart';
// import 'package:app_mobile/core/resources/manager_font_size.dart';
// import 'package:app_mobile/core/resources/manager_height.dart';
// import 'package:app_mobile/core/resources/manager_width.dart';
// import 'package:app_mobile/core/resources/manager_styles.dart';
// import 'voice_recorder_widget.dart';
//
// class MessageInputField extends StatefulWidget {
//   final TextEditingController controller;
//   final Function(String) onSend;
//   final Function(File, String)? onFileSelected; // نوع الملف: image, video, audio, file
//   final bool isSending;
//
//   const MessageInputField({
//     super.key,
//     required this.controller,
//     required this.onSend,
//     this.onFileSelected,
//     this.isSending = false,
//   });
//
//   @override
//   State<MessageInputField> createState() => _MessageInputFieldState();
// }
//
// class _MessageInputFieldState extends State<MessageInputField> {
//   bool _isRecording = false;
//   final _imagePicker = ImagePicker();
//
//   @override
//   Widget build(BuildContext context) {
//     // إذا كان يسجل صوت، يظهر واجهة التسجيل
//     if (_isRecording) {
//       return VoiceRecorderWidget(
//         onRecordComplete: (path, duration) {
//           setState(() {
//             _isRecording = false;
//           });
//           if (widget.onFileSelected != null) {
//             widget.onFileSelected!(File(path), 'audio');
//           }
//         },
//         onCancel: () {
//           setState(() {
//             _isRecording = false;
//           });
//         },
//       );
//     }
//
//     // الواجهة العادية
//     return Container(
//       padding: EdgeInsets.symmetric(
//         horizontal: ManagerWidth.w12,
//         vertical: ManagerHeight.h8,
//       ),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: SafeArea(
//         child: Row(
//           children: [
//             // Attachment Button
//             IconButton(
//               icon: Icon(
//                 Icons.add_circle_outline,
//                 color: Colors.grey.shade600,
//                 size: 26,
//               ),
//               onPressed: widget.isSending ? null : _showAttachmentOptions,
//             ),
//
//             // Text Field
//             Expanded(
//               child: Container(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: ManagerWidth.w12,
//                   vertical: ManagerHeight.h4,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade100,
//                   borderRadius: BorderRadius.circular(24),
//                 ),
//                 child: TextField(
//                   controller: widget.controller,
//                   style: getRegularTextStyle(
//                     fontSize: ManagerFontSize.s14,
//                     color: ManagerColors.black,
//                   ),
//                   maxLines: null,
//                   textInputAction: TextInputAction.newline,
//                   enabled: !widget.isSending,
//                   decoration: InputDecoration(
//                     hintText: widget.isSending ? "جاري الإرسال..." : "اكتب رسالتك...",
//                     hintStyle: getRegularTextStyle(
//                       fontSize: ManagerFontSize.s14,
//                       color: Colors.grey.shade400,
//                     ),
//                     border: InputBorder.none,
//                     isDense: true,
//                     contentPadding: EdgeInsets.symmetric(
//                       vertical: ManagerHeight.h10,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//
//             SizedBox(width: ManagerWidth.w4),
//
//             // Send Button أو Microphone Button
//             _buildActionButton(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildActionButton() {
//     // إذا فيه نص، اعرض زر الإرسال
//     if (widget.controller.text.trim().isNotEmpty) {
//       return Container(
//         decoration: BoxDecoration(
//           color: widget.isSending
//               ? Colors.grey.shade400
//               : ManagerColors.primaryColor,
//           shape: BoxShape.circle,
//         ),
//         child: IconButton(
//           icon: widget.isSending
//               ? const SizedBox(
//             width: 22,
//             height: 22,
//             child: CircularProgressIndicator(
//               strokeWidth: 2,
//               valueColor:
//               AlwaysStoppedAnimation<Color>(Colors.white),
//             ),
//           )
//               : const Icon(
//             Icons.send_rounded,
//             color: Colors.white,
//             size: 22,
//           ),
//           onPressed: widget.isSending
//               ? null
//               : () {
//             if (widget.controller.text.trim().isNotEmpty) {
//               widget.onSend(widget.controller.text.trim());
//             }
//           },
//         ),
//       );
//     }
//
//     // إذا مافيش نص، اعرض زر الميكروفون
//     return GestureDetector(
//       onLongPress: () {
//         setState(() {
//           _isRecording = true;
//         });
//       },
//       child: Container(
//         width: 50,
//         height: 50,
//         decoration: BoxDecoration(
//           color: ManagerColors.primaryColor,
//           shape: BoxShape.circle,
//         ),
//         child: Icon(
//           Icons.mic,
//           color: Colors.white,
//           size: 24,
//         ),
//       ),
//     );
//   }
//
//   void _showAttachmentOptions() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => SafeArea(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               margin: EdgeInsets.only(top: ManagerHeight.h8),
//               width: 40,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade300,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//             SizedBox(height: ManagerHeight.h8),
//             Padding(
//               padding: EdgeInsets.all(ManagerWidth.w16),
//               child: Column(
//                 children: [
//                   _attachmentOption(
//                     'صورة',
//                     Icons.image,
//                     Colors.purple,
//                     _pickImage,
//                   ),
//                   _attachmentOption(
//                     'فيديو',
//                     Icons.videocam,
//                     Colors.red,
//                     _pickVideo,
//                   ),
//                   _attachmentOption(
//                     'ملف',
//                     Icons.insert_drive_file,
//                     Colors.blue,
//                     _pickFile,
//                   ),
//                   _attachmentOption(
//                     'منشن للجميع',
//                     Icons.alternate_email,
//                     Colors.orange,
//                         () {
//                       Navigator.pop(context);
//                       widget.controller.text += '@الكل ';
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _attachmentOption(
//       String title,
//       IconData icon,
//       Color color,
//       VoidCallback onTap,
//       ) {
//     return ListTile(
//       leading: Container(
//         padding: EdgeInsets.all(ManagerWidth.w10),
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Icon(icon, color: color, size: 24),
//       ),
//       title: Text(
//         title,
//         style: getRegularTextStyle(
//           fontSize: ManagerFontSize.s14,
//           color: Colors.black,
//         ),
//       ),
//       onTap: onTap,
//     );
//   }
//
//   // ================================
//   // ✅ PICK IMAGE
//   // ================================
//   Future<void> _pickImage() async {
//     Navigator.pop(context);
//
//     try {
//       final XFile? image = await _imagePicker.pickImage(
//         source: ImageSource.gallery,
//         maxWidth: 1920,
//         maxHeight: 1920,
//         imageQuality: 85,
//       );
//
//       if (image != null && widget.onFileSelected != null) {
//         widget.onFileSelected!(File(image.path), 'image');
//       }
//     } catch (e) {
//       print('❌ خطأ في اختيار الصورة: $e');
//     }
//   }
//
//   // ================================
//   // ✅ PICK VIDEO
//   // ================================
//   Future<void> _pickVideo() async {
//     Navigator.pop(context);
//
//     try {
//       final XFile? video = await _imagePicker.pickVideo(
//         source: ImageSource.gallery,
//         maxDuration: const Duration(minutes: 5),
//       );
//
//       if (video != null && widget.onFileSelected != null) {
//         widget.onFileSelected!(File(video.path), 'video');
//       }
//     } catch (e) {
//       print('❌ خطأ في اختيار الفيديو: $e');
//     }
//   }
//
//   // ================================
//   // ✅ PICK FILE
//   // ================================
//   Future<void> _pickFile() async {
//     Navigator.pop(context);
//
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'zip'],
//       );
//
//       if (result != null && result.files.single.path != null) {
//         final file = File(result.files.single.path!);
//         if (widget.onFileSelected != null) {
//           widget.onFileSelected!(file, 'file');
//         }
//       }
//     } catch (e) {
//       print('❌ خطأ في اختيار الملف: $e');
//     }
//   }
// }
// // المسار: lib/features/home/group_chat/presentation/widgets/message_input_field.dart
//
// import 'package:flutter/material.dart';
// import 'package:app_mobile/core/resources/manager_colors.dart';
// import 'package:app_mobile/core/resources/manager_font_size.dart';
// import 'package:app_mobile/core/resources/manager_height.dart';
// import 'package:app_mobile/core/resources/manager_width.dart';
// import 'package:app_mobile/core/resources/manager_styles.dart';
//
// class MessageInputField extends StatelessWidget {
//   final TextEditingController controller;
//   final Function(String) onSend;
//   final bool isSending;
//
//   const MessageInputField({
//     super.key,
//     required this.controller,
//     required this.onSend,
//     this.isSending = false,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.symmetric(
//         horizontal: ManagerWidth.w12,
//         vertical: ManagerHeight.h8,
//       ),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: SafeArea(
//         child: Row(
//           children: [
//             // Attachment Button
//             IconButton(
//               icon: Icon(
//                 Icons.add_circle_outline,
//                 color: Colors.grey.shade600,
//                 size: 26,
//               ),
//               onPressed: isSending ? null : () {
//                 _showAttachmentOptions(context);
//               },
//             ),
//
//             // Text Field
//             Expanded(
//               child: Container(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: ManagerWidth.w12,
//                   vertical: ManagerHeight.h4,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade100,
//                   borderRadius: BorderRadius.circular(24),
//                 ),
//                 child: TextField(
//                   controller: controller,
//                   style: getRegularTextStyle(
//                     fontSize: ManagerFontSize.s14,
//                     color: ManagerColors.black,
//                   ),
//                   maxLines: null,
//                   textInputAction: TextInputAction.newline,
//                   enabled: !isSending,
//                   decoration: InputDecoration(
//                     hintText: isSending ? "جاري الإرسال..." : "اكتب رسالتك...",
//                     hintStyle: getRegularTextStyle(
//                       fontSize: ManagerFontSize.s14,
//                       color: Colors.grey.shade400,
//                     ),
//                     border: InputBorder.none,
//                     isDense: true,
//                     contentPadding: EdgeInsets.symmetric(
//                       vertical: ManagerHeight.h10,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//
//             SizedBox(width: ManagerWidth.w4),
//
//             // Send Button
//             Container(
//               decoration: BoxDecoration(
//                 color: isSending
//                     ? Colors.grey.shade400
//                     : ManagerColors.primaryColor,
//                 shape: BoxShape.circle,
//               ),
//               child: IconButton(
//                 icon: isSending
//                     ? const SizedBox(
//                   width: 22,
//                   height: 22,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     valueColor:
//                     AlwaysStoppedAnimation<Color>(Colors.white),
//                   ),
//                 )
//                     : const Icon(
//                   Icons.send_rounded,
//                   color: Colors.white,
//                   size: 22,
//                 ),
//                 onPressed: isSending
//                     ? null
//                     : () {
//                   if (controller.text.trim().isNotEmpty) {
//                     onSend(controller.text.trim());
//                   }
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showAttachmentOptions(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => SafeArea(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               margin: EdgeInsets.only(top: ManagerHeight.h8),
//               width: 40,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade300,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//             SizedBox(height: ManagerHeight.h8),
//             Padding(
//               padding: EdgeInsets.all(ManagerWidth.w16),
//               child: Column(
//                 children: [
//                   _attachmentOption(
//                     context,
//                     'صورة',
//                     Icons.image,
//                     Colors.purple,
//                         () {
//                       Navigator.pop(context);
//                       // TODO: اختيار صورة
//                     },
//                   ),
//                   _attachmentOption(
//                     context,
//                     'فيديو',
//                     Icons.videocam,
//                     Colors.red,
//                         () {
//                       Navigator.pop(context);
//                       // TODO: اختيار فيديو
//                     },
//                   ),
//                   _attachmentOption(
//                     context,
//                     'ملف',
//                     Icons.insert_drive_file,
//                     Colors.blue,
//                         () {
//                       Navigator.pop(context);
//                       // TODO: اختيار ملف
//                     },
//                   ),
//                   _attachmentOption(
//                     context,
//                     'منشن للجميع',
//                     Icons.alternate_email,
//                     Colors.orange,
//                         () {
//                       Navigator.pop(context);
//                       controller.text += '@الكل ';
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _attachmentOption(
//       BuildContext context,
//       String title,
//       IconData icon,
//       Color color,
//       VoidCallback onTap,
//       ) {
//     return ListTile(
//       leading: Container(
//         padding: EdgeInsets.all(ManagerWidth.w10),
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Icon(icon, color: color, size: 24),
//       ),
//       title: Text(
//         title,
//         style: getRegularTextStyle(
//           fontSize: ManagerFontSize.s14,
//           color: Colors.black,
//         ),
//       ),
//       onTap: onTap,
//     );
//   }
// }