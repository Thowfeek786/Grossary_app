import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // order_update, promo, general
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      title: d['title'] ?? '',
      body: d['body'] ?? '',
      type: d['type'] ?? 'general',
      data: d['data'] as Map<String, dynamic>?,
      isRead: d['isRead'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'title': title,
    'body': body,
    'type': type,
    'data': data,
    'isRead': isRead,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
    id: id,
    userId: userId,
    title: title,
    body: body,
    type: type,
    data: data,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
  );
}
