import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? discountPrice;
  final String categoryId;
  final String categoryName;
  final List<String> imageUrls;
  final String unit; // e.g. kg, litre, piece
  final double stockQuantity;
  final String? dealerId;
  final String? dealerName;
  final bool isActive;
  final bool isFeatured;
  final double rating;
  final int reviewCount;
  final List<String> tags;
  final String? offerType; // 'none', 'bogo', 'buy2get1', 'percent', 'flat'
  final String? offerLabel; // e.g. 'BUY 1 GET 1 FREE', 'BUY 2 GET 1', '20% OFF'
  final double? offerValue; // discount value (e.g. 20 for 20% or 30 for ₹30 flat)
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.discountPrice,
    required this.categoryId,
    required this.categoryName,
    required this.imageUrls,
    required this.unit,
    required this.stockQuantity,
    this.dealerId,
    this.dealerName,
    this.isActive = true,
    this.isFeatured = false,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.tags = const [],
    this.offerType,
    this.offerLabel,
    this.offerValue,
    required this.createdAt,
    this.updatedAt,
  });

  double get effectivePrice => discountPrice ?? price;
  bool get hasDiscount => discountPrice != null && discountPrice! < price;
  double get discountPercentage => hasDiscount
      ? ((price - discountPrice!) / price * 100)
      : 0;
  bool get inStock => stockQuantity > 0;
  bool get hasSpecialOffer => offerType != null && offerType != 'none' && (offerLabel?.isNotEmpty ?? false);

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      discountPrice: (data['discountPrice'] as num?)?.toDouble(),
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      unit: data['unit'] ?? 'piece',
      stockQuantity: (data['stockQuantity'] as num?)?.toDouble() ?? 0.0,
      dealerId: data['dealerId'],
      dealerName: data['dealerName'],
      isActive: data['isActive'] ?? true,
      isFeatured: data['isFeatured'] ?? false,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['reviewCount'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
      offerType: data['offerType'] as String?,
      offerLabel: data['offerLabel'] as String?,
      offerValue: (data['offerValue'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'description': description,
    'price': price,
    'discountPrice': discountPrice,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'imageUrls': imageUrls,
    'unit': unit,
    'stockQuantity': stockQuantity,
    'dealerId': dealerId,
    'dealerName': dealerName,
    'isActive': isActive,
    'isFeatured': isFeatured,
    'rating': rating,
    'reviewCount': reviewCount,
    'tags': tags,
    'offerType': offerType,
    'offerLabel': offerLabel,
    'offerValue': offerValue,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  ProductModel copyWith({
    String? name,
    String? description,
    double? price,
    double? discountPrice,
    String? categoryId,
    String? categoryName,
    List<String>? imageUrls,
    String? unit,
    double? stockQuantity,
    String? dealerId,
    String? dealerName,
    bool? isActive,
    bool? isFeatured,
    String? offerType,
    String? offerLabel,
    double? offerValue,
  }) {
    return ProductModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      imageUrls: imageUrls ?? this.imageUrls,
      unit: unit ?? this.unit,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      dealerId: dealerId ?? this.dealerId,
      dealerName: dealerName ?? this.dealerName,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      rating: rating,
      reviewCount: reviewCount,
      tags: tags,
      offerType: offerType ?? this.offerType,
      offerLabel: offerLabel ?? this.offerLabel,
      offerValue: offerValue ?? this.offerValue,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
