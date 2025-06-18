import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  audio,
  system, // For system messages like "Chat cleared"
}

enum UserRole {
  seeker,
  provider,
}

class ChatUser {
  final String id;
  final String name;
  final String imageUrl;
  final UserRole role;

  ChatUser({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.role,
  });

  factory ChatUser.fromMap(Map<String, dynamic> map, String id, UserRole role) {
    return ChatUser(
      id: id,
      name: map['fullName'] ?? 'User',
      imageUrl: map['profileImageUrl'] ?? map['imageUrl'] ?? '',
      role: role,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': name,
      'imageUrl': imageUrl,
      'role': role.toString().split('.').last,
    };
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String? receiverId;
  final String? text;
  final String? imageUrl;
  final String? audioUrl;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderId,
    this.receiverId,
    this.text,
    this.imageUrl,
    this.audioUrl,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    MessageType getType() {
      if (data['audioUrl'] != null) return MessageType.audio;
      if (data['imageUrl'] != null) return MessageType.image;
      if (data['type'] == 'system') return MessageType.system;
      return MessageType.text;
    }

    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'],
      text: data['text'],
      imageUrl: data['imageUrl'],
      audioUrl: data['audioUrl'],
      type: data['type'] != null
          ? MessageType.values.firstWhere(
              (e) => e.toString() == 'MessageType.${data['type']}',
              orElse: () => getType(),
            )
          : getType(),
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'type': type.toString().split('.').last,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': isRead,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? text,
    String? imageUrl,
    String? audioUrl,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

class Chat {
  final String id;
  final String seekerId;
  final String providerId;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final DateTime createdAt;
  final List<String> participants;
  final int unreadCount;

  // Computed properties
  ChatUser? seeker;
  ChatUser? provider;

  Chat({
    required this.id,
    required this.seekerId,
    required this.providerId,
    required this.lastMessage,
    this.lastMessageTime,
    required this.createdAt,
    required this.participants,
    this.unreadCount = 0,
    this.seeker,
    this.provider,
  });

  factory Chat.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Chat(
      id: doc.id,
      seekerId: data['seekerId'] ?? '',
      providerId: data['providerId'] ?? '',
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: data['lastMessageTime'] != null
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      participants: List<String>.from(data['participants'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'seekerId': seekerId,
      'providerId': providerId,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : FieldValue.serverTimestamp(),
      'createdAt': Timestamp.fromDate(createdAt),
      'participants': participants,
    };
  }

  String getOtherUserId(String currentUserId) {
    return currentUserId == seekerId ? providerId : seekerId;
  }

  UserRole getUserRole(String currentUserId) {
    return currentUserId == seekerId ? UserRole.seeker : UserRole.provider;
  }

  ChatUser? getOtherUser(String currentUserId) {
    if (currentUserId == seekerId) return provider;
    if (currentUserId == providerId) return seeker;
    return null;
  }

  Chat copyWith({
    String? id,
    String? seekerId,
    String? providerId,
    String? lastMessage,
    DateTime? lastMessageTime,
    DateTime? createdAt,
    List<String>? participants,
    int? unreadCount,
    ChatUser? seeker,
    ChatUser? provider,
  }) {
    return Chat(
      id: id ?? this.id,
      seekerId: seekerId ?? this.seekerId,
      providerId: providerId ?? this.providerId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      createdAt: createdAt ?? this.createdAt,
      participants: participants ?? this.participants,
      unreadCount: unreadCount ?? this.unreadCount,
      seeker: seeker ?? this.seeker,
      provider: provider ?? this.provider,
    );
  }
}

class TemporaryMessage {
  final String tempId;
  final String senderId;
  final String text;
  final MessageType type;
  final DateTime timestamp;
  final String? filePath; // For temporary files (audio, images)
  final bool isUploading;
  final String? error;

  TemporaryMessage({
    required this.tempId,
    required this.senderId,
    required this.text,
    required this.type,
    required this.timestamp,
    this.filePath,
    this.isUploading = false,
    this.error,
  });

  TemporaryMessage copyWith({
    String? tempId,
    String? senderId,
    String? text,
    MessageType? type,
    DateTime? timestamp,
    String? filePath,
    bool? isUploading,
    String? error,
  }) {
    return TemporaryMessage(
      tempId: tempId ?? this.tempId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      filePath: filePath ?? this.filePath,
      isUploading: isUploading ?? this.isUploading,
      error: error ?? this.error,
    );
  }
}

// Helper class for creating chat IDs
class ChatHelper {
  static String createChatId(String userId1, String userId2) {
    final List<String> ids = [userId1, userId2];
    ids.sort(); // Sort alphabetically to ensure consistent chat ID
    return ids.join('_');
  }

  static String formatChatTime(DateTime? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      // Today, show time
      return _formatTime(timestamp);
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // Within a week, show day name
      return _formatDayName(timestamp);
    } else {
      // Older, show date
      return _formatDate(timestamp);
    }
  }

  static String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  static String _formatDayName(DateTime dateTime) {
    const days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    return days[dateTime.weekday % 7];
  }

  static String _formatDate(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final year = dateTime.year.toString().substring(2);
    return '$month/$day/$year';
  }
}
