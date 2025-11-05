// المسار: lib/features/groups/domain/models/group_model.dart

class GroupModel {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String createdBy;
  final List<String> admins;
  final List<String> participants;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? lastMessage;
  final String? lastMessageSender;
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCount; // userId: count
  final GroupSettings settings;

  GroupModel({
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
    this.lastMessageTime,
    this.unreadCount = const {},
    required this.settings,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      imageUrl: json['imageUrl'],
      createdBy: json['createdBy'] ?? '',
      admins: List<String>.from(json['admins'] ?? []),
      participants: List<String>.from(json['participants'] ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      lastMessage: json['last_message'],
      lastMessageSender: json['last_message_sender'],
      lastMessageTime: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : null,
      unreadCount: Map<String, int>.from(json['unread_by'] ?? {}),
      settings: GroupSettings.fromJson(json['settings'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'imageUrl': imageUrl,
    'createdBy': createdBy,
    'admins': admins,
    'participants': participants,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'last_message': lastMessage,
    'last_message_sender': lastMessageSender,
    'timestamp': lastMessageTime?.toIso8601String(),
    'unread_by': unreadCount,
    'settings': settings.toJson(),
  };

  int get participantsCount => participants.length;

  bool isAdmin(String userId) => admins.contains(userId);

  bool isMember(String userId) => participants.contains(userId);
}

class GroupSettings {
  final bool onlyAdminsCanSend;
  final bool onlyAdminsCanEdit;
  final bool allowMembersToAddOthers;
  final bool showMembersList;

  GroupSettings({
    this.onlyAdminsCanSend = false,
    this.onlyAdminsCanEdit = true,
    this.allowMembersToAddOthers = false,
    this.showMembersList = true,
  });

  factory GroupSettings.fromJson(Map<String, dynamic> json) {
    return GroupSettings(
      onlyAdminsCanSend: json['onlyAdminsCanSend'] ?? false,
      onlyAdminsCanEdit: json['onlyAdminsCanEdit'] ?? true,
      allowMembersToAddOthers: json['allowMembersToAddOthers'] ?? false,
      showMembersList: json['showMembersList'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'onlyAdminsCanSend': onlyAdminsCanSend,
    'onlyAdminsCanEdit': onlyAdminsCanEdit,
    'allowMembersToAddOthers': allowMembersToAddOthers,
    'showMembersList': showMembersList,
  };
}