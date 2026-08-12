import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatSender { user, admin }

class ChatMessageModel {
  final String id;
  final String text;
  final ChatSender sender;
  final DateTime createdAt;
  final bool isRead;

  const ChatMessageModel({
    required this.id,
    required this.text,
    required this.sender,
    required this.createdAt,
    this.isRead = false,
  });

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatMessageModel(
      id: doc.id,
      text: d['text'] as String? ?? '',
      sender: (d['sender'] as String?) == 'admin'
          ? ChatSender.admin
          : ChatSender.user,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: d['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'text': text,
        'sender': sender == ChatSender.admin ? 'admin' : 'user',
        'createdAt': Timestamp.fromDate(createdAt),
        'isRead': isRead,
      };

  ChatMessageModel copyWith({bool? isRead}) => ChatMessageModel(
        id: id,
        text: text,
        sender: sender,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
      );
}

class ChatThreadModel {
  final String userId;
  final String userName;
  final String userEmail;
  final String? userPhotoUrl;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount; // unread by admin
  final ChatSender lastSender;

  const ChatThreadModel({
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userPhotoUrl,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
    required this.lastSender,
  });

  factory ChatThreadModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatThreadModel(
      userId: doc.id,
      userName: d['userName'] as String? ?? 'Unknown User',
      userEmail: d['userEmail'] as String? ?? '',
      userPhotoUrl: d['userPhotoUrl'] as String?,
      lastMessage: d['lastMessage'] as String? ?? '',
      lastMessageAt:
          (d['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: d['unreadCount'] as int? ?? 0,
      lastSender: (d['lastSender'] as String?) == 'admin'
          ? ChatSender.admin
          : ChatSender.user,
    );
  }
}
