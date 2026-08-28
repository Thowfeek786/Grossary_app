import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionCadence {
  daily,
  alternateDays,
  every3Days,
  weekly,
  customDays;

  String get displayName {
    switch (this) {
      case SubscriptionCadence.daily:
        return 'Daily (Everyday)';
      case SubscriptionCadence.alternateDays:
        return 'Alternate Days (Every 2 Days)';
      case SubscriptionCadence.every3Days:
        return 'Every 3 Days';
      case SubscriptionCadence.weekly:
        return 'Weekly (Once a Week)';
      case SubscriptionCadence.customDays:
        return 'Custom Selected Days';
    }
  }

  static SubscriptionCadence fromString(String? val) {
    return SubscriptionCadence.values.firstWhere(
      (e) => e.name == val,
      orElse: () => SubscriptionCadence.alternateDays,
    );
  }
}

enum SubscriptionStatus {
  active,
  paused,
  cancelled;

  String get displayName {
    switch (this) {
      case SubscriptionStatus.active:
        return 'Active';
      case SubscriptionStatus.paused:
        return 'Paused (Vacation)';
      case SubscriptionStatus.cancelled:
        return 'Cancelled';
    }
  }

  static SubscriptionStatus fromString(String? val) {
    return SubscriptionStatus.values.firstWhere(
      (e) => e.name == val,
      orElse: () => SubscriptionStatus.active,
    );
  }
}

class WaterSubscriptionModel {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String deliveryAddress;
  final String? deliveryInstructions;
  final String dealerId;
  final String dealerName;
  final int quantityPerDelivery;
  final SubscriptionCadence cadence;
  final List<int> customDays; // 1 = Mon, 2 = Tue, ..., 7 = Sun
  final String timeSlot; // "5:30 AM - 7:30 AM" or "7:00 AM - 9:00 AM"
  final bool autoExchangeCan;
  final double pricePerCan;
  final String paymentType; // wallet_auto_debit, card_mandate, cash_on_delivery
  final SubscriptionStatus status;
  final DateTime? pauseStartDate;
  final DateTime? pauseEndDate;
  final DateTime nextScheduledDelivery;
  final int totalDeliveriesCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  WaterSubscriptionModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.deliveryAddress,
    this.deliveryInstructions,
    required this.dealerId,
    required this.dealerName,
    this.quantityPerDelivery = 1,
    this.cadence = SubscriptionCadence.alternateDays,
    this.customDays = const [],
    this.timeSlot = '5:30 AM - 7:30 AM (Silent Doorstep Drop)',
    this.autoExchangeCan = true,
    this.pricePerCan = 50.0,
    this.paymentType = 'wallet_auto_debit',
    this.status = SubscriptionStatus.active,
    this.pauseStartDate,
    this.pauseEndDate,
    required this.nextScheduledDelivery,
    this.totalDeliveriesCompleted = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isPaused =>
      status == SubscriptionStatus.paused ||
      (pauseStartDate != null &&
          pauseEndDate != null &&
          DateTime.now().isAfter(pauseStartDate!) &&
          DateTime.now().isBefore(pauseEndDate!));

  factory WaterSubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return WaterSubscriptionModel.fromMap(data, doc.id);
  }

  factory WaterSubscriptionModel.fromMap(Map<String, dynamic> data, [String? id]) {
    return WaterSubscriptionModel(
      id: id ?? data['id'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhone: data['userPhone'] ?? '',
      deliveryAddress: data['deliveryAddress'] ?? '',
      deliveryInstructions: data['deliveryInstructions'],
      dealerId: data['dealerId'] ?? '',
      dealerName: data['dealerName'] ?? '',
      quantityPerDelivery: (data['quantityPerDelivery'] ?? 1) as int,
      cadence: SubscriptionCadence.fromString(data['cadence']),
      customDays: (data['customDays'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? [],
      timeSlot: data['timeSlot'] ?? '5:30 AM - 7:30 AM (Silent Doorstep Drop)',
      autoExchangeCan: data['autoExchangeCan'] ?? true,
      pricePerCan: ((data['pricePerCan'] ?? 50.0) as num).toDouble(),
      paymentType: data['paymentType'] ?? 'wallet_auto_debit',
      status: SubscriptionStatus.fromString(data['status']),
      pauseStartDate: (data['pauseStartDate'] is Timestamp)
          ? (data['pauseStartDate'] as Timestamp).toDate()
          : null,
      pauseEndDate: (data['pauseEndDate'] is Timestamp)
          ? (data['pauseEndDate'] as Timestamp).toDate()
          : null,
      nextScheduledDelivery: (data['nextScheduledDelivery'] is Timestamp)
          ? (data['nextScheduledDelivery'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(days: 1)),
      totalDeliveriesCompleted: (data['totalDeliveriesCompleted'] ?? 0) as int,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'deliveryAddress': deliveryAddress,
      'deliveryInstructions': deliveryInstructions,
      'dealerId': dealerId,
      'dealerName': dealerName,
      'quantityPerDelivery': quantityPerDelivery,
      'cadence': cadence.name,
      'customDays': customDays,
      'timeSlot': timeSlot,
      'autoExchangeCan': autoExchangeCan,
      'pricePerCan': pricePerCan,
      'paymentType': paymentType,
      'status': status.name,
      'pauseStartDate': pauseStartDate != null ? Timestamp.fromDate(pauseStartDate!) : null,
      'pauseEndDate': pauseEndDate != null ? Timestamp.fromDate(pauseEndDate!) : null,
      'nextScheduledDelivery': Timestamp.fromDate(nextScheduledDelivery),
      'totalDeliveriesCompleted': totalDeliveriesCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  WaterSubscriptionModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhone,
    String? deliveryAddress,
    String? deliveryInstructions,
    String? dealerId,
    String? dealerName,
    int? quantityPerDelivery,
    SubscriptionCadence? cadence,
    List<int>? customDays,
    String? timeSlot,
    bool? autoExchangeCan,
    double? pricePerCan,
    String? paymentType,
    SubscriptionStatus? status,
    DateTime? pauseStartDate,
    DateTime? pauseEndDate,
    DateTime? nextScheduledDelivery,
    int? totalDeliveriesCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WaterSubscriptionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      dealerId: dealerId ?? this.dealerId,
      dealerName: dealerName ?? this.dealerName,
      quantityPerDelivery: quantityPerDelivery ?? this.quantityPerDelivery,
      cadence: cadence ?? this.cadence,
      customDays: customDays ?? this.customDays,
      timeSlot: timeSlot ?? this.timeSlot,
      autoExchangeCan: autoExchangeCan ?? this.autoExchangeCan,
      pricePerCan: pricePerCan ?? this.pricePerCan,
      paymentType: paymentType ?? this.paymentType,
      status: status ?? this.status,
      pauseStartDate: pauseStartDate ?? this.pauseStartDate,
      pauseEndDate: pauseEndDate ?? this.pauseEndDate,
      nextScheduledDelivery: nextScheduledDelivery ?? this.nextScheduledDelivery,
      totalDeliveriesCompleted: totalDeliveriesCompleted ?? this.totalDeliveriesCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
