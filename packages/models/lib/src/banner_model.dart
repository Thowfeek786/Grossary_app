import 'package:cloud_firestore/cloud_firestore.dart';

class BannerModel {
  final String id;
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String? actionUrl;
  final String? categoryId;
  final String? productId;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;

  const BannerModel({
    required this.id,
    required this.title,
    this.subtitle,
    required this.imageUrl,
    this.actionUrl,
    this.categoryId,
    this.productId,
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
  });

  factory BannerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BannerModel(
      id: doc.id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'],
      imageUrl: data['imageUrl'] ?? '',
      actionUrl: data['actionUrl'],
      categoryId: data['categoryId'],
      productId: data['productId'],
      sortOrder: data['sortOrder'] ?? 0,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'subtitle': subtitle,
    'imageUrl': imageUrl,
    'actionUrl': actionUrl,
    'categoryId': categoryId,
    'productId': productId,
    'sortOrder': sortOrder,
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
