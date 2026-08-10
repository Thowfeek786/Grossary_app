import 'package:cloud_firestore/cloud_firestore.dart';

class StoreSettingsModel {
  final String id; // 'global' for Admin or dealerId for Dealer
  final double baseDeliveryFee;
  final double freeDeliveryThreshold;
  final bool isFreeDeliveryEnabled;

  const StoreSettingsModel({
    required this.id,
    this.baseDeliveryFee = 40.0,
    this.freeDeliveryThreshold = 500.0,
    this.isFreeDeliveryEnabled = true,
  });

  factory StoreSettingsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StoreSettingsModel(
      id: doc.id,
      baseDeliveryFee: (data['baseDeliveryFee'] as num?)?.toDouble() ?? 40.0,
      freeDeliveryThreshold: (data['freeDeliveryThreshold'] as num?)?.toDouble() ?? 500.0,
      isFreeDeliveryEnabled: data['isFreeDeliveryEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'baseDeliveryFee': baseDeliveryFee,
        'freeDeliveryThreshold': freeDeliveryThreshold,
        'isFreeDeliveryEnabled': isFreeDeliveryEnabled,
      };

  StoreSettingsModel copyWith({
    String? id,
    double? baseDeliveryFee,
    double? freeDeliveryThreshold,
    bool? isFreeDeliveryEnabled,
  }) {
    return StoreSettingsModel(
      id: id ?? this.id,
      baseDeliveryFee: baseDeliveryFee ?? this.baseDeliveryFee,
      freeDeliveryThreshold: freeDeliveryThreshold ?? this.freeDeliveryThreshold,
      isFreeDeliveryEnabled: isFreeDeliveryEnabled ?? this.isFreeDeliveryEnabled,
    );
  }
}
