import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:models/models.dart';

class ChatRepository {
  final _db = FirebaseFirestore.instance;

  // Collection: support_chats/{userId}/messages/{messageId}
  // Thread metadata: support_chats/{userId} (document)

  CollectionReference get _threads => _db.collection('support_chats');

  CollectionReference _messages(String userId) =>
      _threads.doc(userId).collection('messages');

  /// User sends a message to admin
  Future<void> sendMessage({
    required String userId,
    required String userName,
    required String userEmail,
    String? userPhotoUrl,
    required String text,
  }) async {
    final now = DateTime.now();
    final batch = _db.batch();

    // Add message to subcollection
    final msgRef = _messages(userId).doc();
    final message = ChatMessageModel(
      id: msgRef.id,
      text: text,
      sender: ChatSender.user,
      createdAt: now,
      isRead: false,
    );
    batch.set(msgRef, message.toFirestore());

    // Update thread metadata
    batch.set(
      _threads.doc(userId),
      {
        'userName': userName,
        'userEmail': userEmail,
        'userPhotoUrl': userPhotoUrl,
        'lastMessage': text,
        'lastMessageAt': Timestamp.fromDate(now),
        'lastSender': 'user',
        'unreadCount': FieldValue.increment(1),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  /// Admin replies to a user
  Future<void> adminReply({
    required String userId,
    required String text,
  }) async {
    final now = DateTime.now();
    final batch = _db.batch();

    final msgRef = _messages(userId).doc();
    final message = ChatMessageModel(
      id: msgRef.id,
      text: text,
      sender: ChatSender.admin,
      createdAt: now,
      isRead: false,
    );
    batch.set(msgRef, message.toFirestore());

    // Update thread metadata — admin reply resets unread count for admin
    batch.set(
      _threads.doc(userId),
      {
        'lastMessage': text,
        'lastMessageAt': Timestamp.fromDate(now),
        'lastSender': 'admin',
        'unreadCount': 0,
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  /// Stream of all chat threads for admin (sorted by latest message)
  Stream<List<ChatThreadModel>> streamAllThreads() {
    return _threads
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ChatThreadModel.fromFirestore(d)).toList());
  }

  /// Stream of messages for a specific user thread
  Stream<List<ChatMessageModel>> streamMessages(String userId) {
    return _messages(userId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ChatMessageModel.fromFirestore(d)).toList());
  }

  /// Mark all unread messages in thread as read (for admin)
  Future<void> markThreadReadByAdmin(String userId) async {
    await _threads.doc(userId).update({'unreadCount': 0});
  }

  /// Mark admin's reply messages as read by user
  Future<void> markAdminMessagesRead(String userId) async {
    final unread = await _messages(userId)
        .where('sender', isEqualTo: 'admin')
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    if (unread.docs.isNotEmpty) await batch.commit();
  }

  /// Get unread count for user (admin messages unread by user)
  Stream<int> streamUserUnreadCount(String userId) {
    return _messages(userId)
        .where('sender', isEqualTo: 'admin')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}
