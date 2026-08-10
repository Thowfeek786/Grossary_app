import 'package:cloud_firestore/cloud_firestore.dart';

class FlashSaleModel {
  final String id;
  final String title;
  final String subtitle;
  final DateTime endTime;
  final List<String> productIds;
  final bool isActive;
  final double discountPercentage;

  FlashSaleModel({
    this.id = 'active',
    this.title = 'FLASH SALE ⚡',
    this.subtitle = 'Limited Time Offers & Big Savings',
    required this.endTime,
    this.productIds = const [],
    this.isActive = true,
    this.discountPercentage = 20.0,
  });

  factory FlashSaleModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime end = DateTime.now().add(const Duration(hours: 4));
    if (map['endTime'] != null) {
      if (map['endTime'] is Timestamp) {
        end = (map['endTime'] as Timestamp).toDate();
      } else if (map['endTime'] is String) {
        end = DateTime.tryParse(map['endTime']) ?? end;
      }
    }

    return FlashSaleModel(
      id: docId,
      title: map['title'] ?? 'FLASH SALE ⚡',
      subtitle: map['subtitle'] ?? 'Limited Time Offers & Big Savings',
      endTime: end,
      productIds: List<String>.from(map['productIds'] ?? []),
      isActive: map['isActive'] ?? true,
      discountPercentage: (map['discountPercentage'] as num?)?.toDouble() ?? 20.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'endTime': Timestamp.fromDate(endTime),
      'productIds': productIds,
      'isActive': isActive,
      'discountPercentage': discountPercentage,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  FlashSaleModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    DateTime? endTime,
    List<String>? productIds,
    bool? isActive,
    double? discountPercentage,
  }) {
    return FlashSaleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      endTime: endTime ?? this.endTime,
      productIds: productIds ?? this.productIds,
      isActive: isActive ?? this.isActive,
      discountPercentage: discountPercentage ?? this.discountPercentage,
    );
  }
}
