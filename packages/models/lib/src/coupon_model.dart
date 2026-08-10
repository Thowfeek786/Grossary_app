import 'package:cloud_firestore/cloud_firestore.dart';

enum DiscountType { percentage, fixed }

class CouponModel {
  final String id;
  final String code;
  final String description;
  final DiscountType discountType;
  final double discountAmount; // e.g. 20 for 20% or 100 for ₹100
  final double minSubtotal;
  final double? maxDiscount; // Max discount cap for percentage discounts
  final DateTime expiryDate;
  final bool isActive;
  final int usageCount;
  final int? maxUsage;

  const CouponModel({
    required this.id,
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountAmount,
    this.minSubtotal = 0,
    this.maxDiscount,
    required this.expiryDate,
    this.isActive = true,
    this.usageCount = 0,
    this.maxUsage,
  });

  factory CouponModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CouponModel(
      id: doc.id,
      code: data['code'] ?? '',
      description: data['description'] ?? '',
      discountType: data['discountType'] == 'fixed'
          ? DiscountType.fixed
          : DiscountType.percentage,
      discountAmount: (data['discountAmount'] as num?)?.toDouble() ?? 0.0,
      minSubtotal: (data['minSubtotal'] as num?)?.toDouble() ?? 0.0,
      maxDiscount: (data['maxDiscount'] as num?)?.toDouble(),
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      usageCount: (data['usageCount'] as num?)?.toInt() ?? 0,
      maxUsage: (data['maxUsage'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'code': code.toUpperCase(),
        'description': description,
        'discountType': discountType.name,
        'discountAmount': discountAmount,
        'minSubtotal': minSubtotal,
        'maxDiscount': maxDiscount,
        'expiryDate': Timestamp.fromDate(expiryDate),
        'isActive': isActive,
        'usageCount': usageCount,
        'maxUsage': maxUsage,
      };

  double calculateDiscount(double subtotal) {
    if (subtotal < minSubtotal) return 0.0;
    if (discountType == DiscountType.fixed) {
      return discountAmount > subtotal ? subtotal : discountAmount;
    } else {
      double discount = (subtotal * discountAmount) / 100.0;
      if (maxDiscount != null && discount > maxDiscount!) {
        discount = maxDiscount!;
      }
      return discount;
    }
  }

  bool get isExpired => DateTime.now().isAfter(expiryDate);
  bool get isLimitReached => maxUsage != null && usageCount >= maxUsage!;
  bool get isValid => isActive && !isExpired && !isLimitReached;
}
