import 'package:cloud_firestore/cloud_firestore.dart';

enum CanExchangeType { refill, newCan, returnOnly, walkInReturn }

class CanTransactionModel {
  final String id;
  final String orderId;
  final String userId;
  final String userName;
  final String userPhone;
  final String dealerId;
  final String? dealerName;
  final String? deliveryPartnerId;
  final String? deliveryPartnerName;
  final int fullDelivered;
  final int emptyCollected;
  final double depositAmount;
  final CanExchangeType exchangeType;
  final String notes;
  final DateTime createdAt;

  const CanTransactionModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.userName,
    this.userPhone = '',
    required this.dealerId,
    this.dealerName,
    this.deliveryPartnerId,
    this.deliveryPartnerName,
    required this.fullDelivered,
    required this.emptyCollected,
    this.depositAmount = 0.0,
    required this.exchangeType,
    this.notes = '',
    required this.createdAt,
  });

  int get canBalanceChange => fullDelivered - emptyCollected;

  factory CanTransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CanTransactionModel(
      id: doc.id,
      orderId: data['orderId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhone: data['userPhone'] ?? '',
      dealerId: data['dealerId'] ?? '',
      dealerName: data['dealerName'],
      deliveryPartnerId: data['deliveryPartnerId'],
      deliveryPartnerName: data['deliveryPartnerName'],
      fullDelivered: (data['fullDelivered'] as num?)?.toInt() ?? 0,
      emptyCollected: (data['emptyCollected'] as num?)?.toInt() ?? 0,
      depositAmount: (data['depositAmount'] as num?)?.toDouble() ?? 0.0,
      exchangeType: CanExchangeType.values.firstWhere(
        (e) => e.name == (data['exchangeType'] ?? 'refill'),
        orElse: () => CanExchangeType.refill,
      ),
      notes: data['notes'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'orderId': orderId,
    'userId': userId,
    'userName': userName,
    'userPhone': userPhone,
    'dealerId': dealerId,
    'dealerName': dealerName,
    'deliveryPartnerId': deliveryPartnerId,
    'deliveryPartnerName': deliveryPartnerName,
    'fullDelivered': fullDelivered,
    'emptyCollected': emptyCollected,
    'depositAmount': depositAmount,
    'exchangeType': exchangeType.name,
    'notes': notes,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

class UserCanSummaryModel {
  final String userId;
  final int fullDelivered;
  final int emptyCollected;
  final int canBalance;
  final double totalDepositHeld;

  const UserCanSummaryModel({
    required this.userId,
    required this.fullDelivered,
    required this.emptyCollected,
    required this.canBalance,
    required this.totalDepositHeld,
  });

  factory UserCanSummaryModel.empty(String userId) => UserCanSummaryModel(
    userId: userId,
    fullDelivered: 0,
    emptyCollected: 0,
    canBalance: 0,
    totalDepositHeld: 0.0,
  );
}

class DealerCanSummaryModel {
  final String dealerId;
  final int totalDelivered;
  final int totalCollected;
  final int todayDelivered;
  final int todayCollected;
  final int canBalance;
  final int activeCustomersCount;

  const DealerCanSummaryModel({
    required this.dealerId,
    required this.totalDelivered,
    required this.totalCollected,
    required this.todayDelivered,
    required this.todayCollected,
    required this.canBalance,
    this.activeCustomersCount = 0,
  });

  factory DealerCanSummaryModel.empty(String dealerId) => DealerCanSummaryModel(
    dealerId: dealerId,
    totalDelivered: 0,
    totalCollected: 0,
    todayDelivered: 0,
    todayCollected: 0,
    canBalance: 0,
    activeCustomersCount: 0,
  );
}

class PlatformCanSummaryModel {
  final int totalCansInCirculation;
  final int totalDispatchedToday;
  final int totalCollectedToday;
  final double totalDepositLiability;
  final int activeCustomersWithCans;

  const PlatformCanSummaryModel({
    required this.totalCansInCirculation,
    required this.totalDispatchedToday,
    required this.totalCollectedToday,
    required this.totalDepositLiability,
    required this.activeCustomersWithCans,
  });

  factory PlatformCanSummaryModel.empty() => const PlatformCanSummaryModel(
    totalCansInCirculation: 0,
    totalDispatchedToday: 0,
    totalCollectedToday: 0,
    totalDepositLiability: 0.0,
    activeCustomersWithCans: 0,
  );
}
