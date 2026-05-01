import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String? imageUrl;
  final String? description;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;

  const CategoryModel({
    required this.id,
    required this.name,
    this.imageUrl,
    this.description,
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'],
      description: data['description'],
      sortOrder: data['sortOrder'] ?? 0,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'imageUrl': imageUrl,
    'description': description,
    'sortOrder': sortOrder,
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  CategoryModel copyWith({
    String? name,
    String? imageUrl,
    String? description,
    int? sortOrder,
    bool? isActive,
  }) {
    return CategoryModel(
      id: id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
