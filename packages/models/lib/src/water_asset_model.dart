import 'package:cloud_firestore/cloud_firestore.dart';

enum CanAssetStatus {
  inStore,
  dispatched,
  withCustomer,
  returnedEmpty,
  sanitization,
  retired;

  String get displayName {
    switch (this) {
      case CanAssetStatus.inStore:
        return 'In Dark Store (Filled)';
      case CanAssetStatus.dispatched:
        return 'Out for Delivery';
      case CanAssetStatus.withCustomer:
        return 'With Customer';
      case CanAssetStatus.returnedEmpty:
        return 'Returned (Empty)';
      case CanAssetStatus.sanitization:
        return 'Under QC & Sanitization';
      case CanAssetStatus.retired:
        return 'Retired (End of Life)';
    }
  }

  static CanAssetStatus fromString(String? val) {
    return CanAssetStatus.values.firstWhere(
      (e) => e.name == val,
      orElse: () => CanAssetStatus.inStore,
    );
  }
}

class CanEventLog {
  final DateTime timestamp;
  final String eventType; // fill, dispatch, delivered, collected, sanitized, retired
  final String actorId;
  final String actorName;
  final String? orderId;
  final String? notes;

  CanEventLog({
    required this.timestamp,
    required this.eventType,
    required this.actorId,
    required this.actorName,
    this.orderId,
    this.notes,
  });

  factory CanEventLog.fromMap(Map<String, dynamic> map) {
    return CanEventLog(
      timestamp: (map['timestamp'] is Timestamp)
          ? (map['timestamp'] as Timestamp).toDate()
          : (map['timestamp'] != null
              ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
              : DateTime.now()),
      eventType: map['eventType'] ?? 'scan',
      actorId: map['actorId'] ?? '',
      actorName: map['actorName'] ?? '',
      orderId: map['orderId'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'eventType': eventType,
      'actorId': actorId,
      'actorName': actorName,
      'orderId': orderId,
      'notes': notes,
    };
  }
}

class WaterAssetModel {
  final String canSerialId; // e.g. "CAN-GG-20L-10928"
  final String qrCodeUrl;
  final String manufacturer;
  final double capacityLiters;
  final CanAssetStatus status;
  final String currentOwnerType; // dealer, delivery_partner, customer
  final String currentOwnerId;
  final String currentOwnerName;
  final String dealerId;
  final String? currentOrderId;
  final int fillCount; // Max 50 cycles
  final DateTime? lastSanitizedAt;
  final double lastTestedTds;
  final double lastTestedPh;
  final DateTime manufacturedAt;
  final DateTime expiresAt;
  final List<CanEventLog> history;
  final DateTime createdAt;
  final DateTime updatedAt;

  WaterAssetModel({
    required this.canSerialId,
    this.qrCodeUrl = '',
    this.manufacturer = 'Food Grade Virgin Polycarbonate (BPA Free)',
    this.capacityLiters = 20.0,
    this.status = CanAssetStatus.inStore,
    this.currentOwnerType = 'dealer',
    required this.currentOwnerId,
    required this.currentOwnerName,
    required this.dealerId,
    this.currentOrderId,
    this.fillCount = 0,
    this.lastSanitizedAt,
    this.lastTestedTds = 95.0,
    this.lastTestedPh = 7.2,
    DateTime? manufacturedAt,
    DateTime? expiresAt,
    this.history = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : manufacturedAt = manufacturedAt ?? DateTime.now(),
        expiresAt = expiresAt ?? DateTime.now().add(const Duration(days: 540)), // ~18 months
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isNearRetirement => fillCount >= 40;
  bool get isExpired => DateTime.now().isAfter(expiresAt) || fillCount >= 50;

  factory WaterAssetModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return WaterAssetModel.fromMap(data, doc.id);
  }

  factory WaterAssetModel.fromMap(Map<String, dynamic> data, [String? id]) {
    final historyList = (data['history'] as List<dynamic>?)
            ?.map((e) => CanEventLog.fromMap(Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    return WaterAssetModel(
      canSerialId: id ?? data['canSerialId'] ?? '',
      qrCodeUrl: data['qrCodeUrl'] ?? '',
      manufacturer: data['manufacturer'] ?? 'Food Grade Virgin Polycarbonate (BPA Free)',
      capacityLiters: ((data['capacityLiters'] ?? 20.0) as num).toDouble(),
      status: CanAssetStatus.fromString(data['status']),
      currentOwnerType: data['currentOwnerType'] ?? 'dealer',
      currentOwnerId: data['currentOwnerId'] ?? '',
      currentOwnerName: data['currentOwnerName'] ?? '',
      dealerId: data['dealerId'] ?? '',
      currentOrderId: data['currentOrderId'],
      fillCount: (data['fillCount'] ?? 0) as int,
      lastSanitizedAt: (data['lastSanitizedAt'] is Timestamp)
          ? (data['lastSanitizedAt'] as Timestamp).toDate()
          : null,
      lastTestedTds: ((data['lastTestedTds'] ?? 95.0) as num).toDouble(),
      lastTestedPh: ((data['lastTestedPh'] ?? 7.2) as num).toDouble(),
      manufacturedAt: (data['manufacturedAt'] is Timestamp)
          ? (data['manufacturedAt'] as Timestamp).toDate()
          : DateTime.now(),
      expiresAt: (data['expiresAt'] is Timestamp)
          ? (data['expiresAt'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(days: 540)),
      history: historyList,
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
      'canSerialId': canSerialId,
      'qrCodeUrl': qrCodeUrl,
      'manufacturer': manufacturer,
      'capacityLiters': capacityLiters,
      'status': status.name,
      'currentOwnerType': currentOwnerType,
      'currentOwnerId': currentOwnerId,
      'currentOwnerName': currentOwnerName,
      'dealerId': dealerId,
      'currentOrderId': currentOrderId,
      'fillCount': fillCount,
      'lastSanitizedAt': lastSanitizedAt != null ? Timestamp.fromDate(lastSanitizedAt!) : null,
      'lastTestedTds': lastTestedTds,
      'lastTestedPh': lastTestedPh,
      'manufacturedAt': Timestamp.fromDate(manufacturedAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'history': history.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  WaterAssetModel copyWith({
    String? canSerialId,
    String? qrCodeUrl,
    String? manufacturer,
    double? capacityLiters,
    CanAssetStatus? status,
    String? currentOwnerType,
    String? currentOwnerId,
    String? currentOwnerName,
    String? dealerId,
    String? currentOrderId,
    int? fillCount,
    DateTime? lastSanitizedAt,
    double? lastTestedTds,
    double? lastTestedPh,
    DateTime? manufacturedAt,
    DateTime? expiresAt,
    List<CanEventLog>? history,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WaterAssetModel(
      canSerialId: canSerialId ?? this.canSerialId,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      manufacturer: manufacturer ?? this.manufacturer,
      capacityLiters: capacityLiters ?? this.capacityLiters,
      status: status ?? this.status,
      currentOwnerType: currentOwnerType ?? this.currentOwnerType,
      currentOwnerId: currentOwnerId ?? this.currentOwnerId,
      currentOwnerName: currentOwnerName ?? this.currentOwnerName,
      dealerId: dealerId ?? this.dealerId,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      fillCount: fillCount ?? this.fillCount,
      lastSanitizedAt: lastSanitizedAt ?? this.lastSanitizedAt,
      lastTestedTds: lastTestedTds ?? this.lastTestedTds,
      lastTestedPh: lastTestedPh ?? this.lastTestedPh,
      manufacturedAt: manufacturedAt ?? this.manufacturedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      history: history ?? this.history,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
