import 'package:cloud_firestore/cloud_firestore.dart';

enum DriverEmploymentType {
  dedicatedMonthly,
  dedicatedPerDrop,
  freelance;

  String get displayName {
    switch (this) {
      case DriverEmploymentType.dedicatedMonthly:
        return 'Monthly Fixed Salary';
      case DriverEmploymentType.dedicatedPerDrop:
        return 'Per-Drop / Per-Can Rate';
      case DriverEmploymentType.freelance:
        return 'Freelance On-Demand';
    }
  }

  static DriverEmploymentType fromString(String? val) {
    return DriverEmploymentType.values.firstWhere(
      (e) => e.name == val,
      orElse: () => DriverEmploymentType.dedicatedPerDrop,
    );
  }
}

enum DriverWorkStatus {
  availableAtStore,
  onRoute,
  offDuty;

  String get displayName {
    switch (this) {
      case DriverWorkStatus.availableAtStore:
        return 'Available at Store';
      case DriverWorkStatus.onRoute:
        return 'On Route / Delivering';
      case DriverWorkStatus.offDuty:
        return 'Off Duty / Offline';
    }
  }

  static DriverWorkStatus fromString(String? val) {
    return DriverWorkStatus.values.firstWhere(
      (e) => e.name == val,
      orElse: () => DriverWorkStatus.availableAtStore,
    );
  }
}

class DealerDriverModel {
  final String id;
  final String driverId;
  final String driverName;
  final String driverPhone;
  final String vehicleType;
  final String vehicleNumber;
  final String dealerId;
  final String dealerName;
  final DriverEmploymentType employmentType;
  final double payoutRate;
  final DriverWorkStatus workStatus;
  final int totalDropsCompleted;
  final int totalCansDelivered;
  final double pendingPayout;
  final DateTime hiredAt;
  final bool isActive;

  const DealerDriverModel({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    this.vehicleType = 'Bike / Two-Wheeler',
    this.vehicleNumber = '',
    required this.dealerId,
    required this.dealerName,
    this.employmentType = DriverEmploymentType.dedicatedPerDrop,
    this.payoutRate = 25.0,
    this.workStatus = DriverWorkStatus.availableAtStore,
    this.totalDropsCompleted = 0,
    this.totalCansDelivered = 0,
    this.pendingPayout = 0.0,
    required this.hiredAt,
    this.isActive = true,
  });

  factory DealerDriverModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DealerDriverModel(
      id: doc.id,
      driverId: data['driverId'] ?? '',
      driverName: data['driverName'] ?? '',
      driverPhone: data['driverPhone'] ?? '',
      vehicleType: data['vehicleType'] ?? 'Bike / Two-Wheeler',
      vehicleNumber: data['vehicleNumber'] ?? '',
      dealerId: data['dealerId'] ?? '',
      dealerName: data['dealerName'] ?? '',
      employmentType: DriverEmploymentType.fromString(data['employmentType']),
      payoutRate: (data['payoutRate'] as num?)?.toDouble() ?? 25.0,
      workStatus: DriverWorkStatus.fromString(data['workStatus']),
      totalDropsCompleted: (data['totalDropsCompleted'] as num?)?.toInt() ?? 0,
      totalCansDelivered: (data['totalCansDelivered'] as num?)?.toInt() ?? 0,
      pendingPayout: (data['pendingPayout'] as num?)?.toDouble() ?? 0.0,
      hiredAt: (data['hiredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'driverId': driverId,
    'driverName': driverName,
    'driverPhone': driverPhone,
    'vehicleType': vehicleType,
    'vehicleNumber': vehicleNumber,
    'dealerId': dealerId,
    'dealerName': dealerName,
    'employmentType': employmentType.name,
    'payoutRate': payoutRate,
    'workStatus': workStatus.name,
    'totalDropsCompleted': totalDropsCompleted,
    'totalCansDelivered': totalCansDelivered,
    'pendingPayout': pendingPayout,
    'hiredAt': Timestamp.fromDate(hiredAt),
    'isActive': isActive,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  DealerDriverModel copyWith({
    String? id,
    String? driverId,
    String? driverName,
    String? driverPhone,
    String? vehicleType,
    String? vehicleNumber,
    String? dealerId,
    String? dealerName,
    DriverEmploymentType? employmentType,
    double? payoutRate,
    DriverWorkStatus? workStatus,
    int? totalDropsCompleted,
    int? totalCansDelivered,
    double? pendingPayout,
    DateTime? hiredAt,
    bool? isActive,
  }) {
    return DealerDriverModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      dealerId: dealerId ?? this.dealerId,
      dealerName: dealerName ?? this.dealerName,
      employmentType: employmentType ?? this.employmentType,
      payoutRate: payoutRate ?? this.payoutRate,
      workStatus: workStatus ?? this.workStatus,
      totalDropsCompleted: totalDropsCompleted ?? this.totalDropsCompleted,
      totalCansDelivered: totalCansDelivered ?? this.totalCansDelivered,
      pendingPayout: pendingPayout ?? this.pendingPayout,
      hiredAt: hiredAt ?? this.hiredAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
