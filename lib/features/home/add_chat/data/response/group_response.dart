import 'package:cloud_firestore/cloud_firestore.dart';

class GroupResponse {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String createdBy;
  final List<String> admins;
  final List<String> participants;
  final String createdAt;
  final String? updatedAt;
  final String? lastMessage;
  final String? lastMessageSender;
  final String? timestamp;
  final Map<String, dynamic>? unreadBy;
  final Map<String, dynamic>? settings;

  GroupResponse({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.createdBy,
    required this.admins,
    required this.participants,
    required this.createdAt,
    this.updatedAt,
    this.lastMessage,
    this.lastMessageSender,
    this.timestamp,
    this.unreadBy,
    this.settings,
  });

  factory GroupResponse.fromJson(String id, Map<String, dynamic> json) {
    return GroupResponse(
      id: id,
      name: json['name'] ?? '',
      description: json['description'],
      imageUrl: json['imageUrl'],
      createdBy: json['createdBy'] ?? '',
      admins: List<String>.from(json['admins'] ?? []),
      participants: List<String>.from(json['participants'] ?? []),
      createdAt: json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      updatedAt: json['updatedAt']?.toString(),
      lastMessage: json['last_message'],
      lastMessageSender: json['last_message_sender'],
      timestamp: json['timestamp']?.toString(),
      unreadBy: json['unread_by'] != null
          ? Map<String, dynamic>.from(json['unread_by'])
          : {},
      settings: json['settings'] != null
          ? Map<String, dynamic>.from(json['settings'])
          : {},
    );
  }

  /// ✅ دالة خاصة لبناء الكائن من Firestore DocumentSnapshot
  factory GroupResponse.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return GroupResponse.fromJson(doc.id, data);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'imageUrl': imageUrl,
    'createdBy': createdBy,
    'admins': admins,
    'participants': participants,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'last_message': lastMessage,
    'last_message_sender': lastMessageSender,
    'timestamp': timestamp,
    'unread_by': unreadBy,
    'settings': settings,
  };
}
