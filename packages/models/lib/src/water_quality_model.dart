import 'package:cloud_firestore/cloud_firestore.dart';

class WaterQualityModel {
  final String id;
  final String dealerId;
  final String batchNumber; // e.g. "BATCH-20260825-01"
  final double tdsValue; // Ideal: 80 - 120 ppm
  final double phValue; // Ideal: 6.8 - 7.5
  final double turbidityNtu; // < 1.0 NTU
  final List<String> purificationStages;
  final String certifiedBy;
  final String fssaiNumber;
  final String? labCertificateUrl;
  final DateTime testedAt;
  final String status; // approved, under_review, rejected
  final DateTime createdAt;

  WaterQualityModel({
    required this.id,
    required this.dealerId,
    required this.batchNumber,
    this.tdsValue = 95.0,
    this.phValue = 7.2,
    this.turbidityNtu = 0.2,
    this.purificationStages = const [
      'Dual Micron Sand Filter',
      'Activated Carbon Filtration',
      'Advanced Reverse Osmosis (RO)',
      'Ultraviolet (UV) Sterilization',
      'Ozonation & Mineral Rebalancing',
    ],
    this.certifiedBy = 'Quality Assurance Lab, GroceryGo PureWater',
    this.fssaiNumber = '10020042000189',
    this.labCertificateUrl,
    DateTime? testedAt,
    this.status = 'approved',
    DateTime? createdAt,
  })  : testedAt = testedAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  factory WaterQualityModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return WaterQualityModel.fromMap(data, doc.id);
  }

  factory WaterQualityModel.fromMap(Map<String, dynamic> data, [String? id]) {
    return WaterQualityModel(
      id: id ?? data['id'] ?? '',
      dealerId: data['dealerId'] ?? '',
      batchNumber: data['batchNumber'] ?? 'BATCH-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}-01',
      tdsValue: ((data['tdsValue'] ?? 95.0) as num).toDouble(),
      phValue: ((data['phValue'] ?? 7.2) as num).toDouble(),
      turbidityNtu: ((data['turbidityNtu'] ?? 0.2) as num).toDouble(),
      purificationStages: (data['purificationStages'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const [
            'Dual Micron Sand Filter',
            'Activated Carbon Filtration',
            'Advanced Reverse Osmosis (RO)',
            'Ultraviolet (UV) Sterilization',
            'Ozonation & Mineral Rebalancing',
          ],
      certifiedBy: data['certifiedBy'] ?? 'Quality Assurance Lab, GroceryGo PureWater',
      fssaiNumber: data['fssaiNumber'] ?? '10020042000189',
      labCertificateUrl: data['labCertificateUrl'],
      testedAt: (data['testedAt'] is Timestamp)
          ? (data['testedAt'] as Timestamp).toDate()
          : DateTime.now(),
      status: data['status'] ?? 'approved',
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dealerId': dealerId,
      'batchNumber': batchNumber,
      'tdsValue': tdsValue,
      'phValue': phValue,
      'turbidityNtu': turbidityNtu,
      'purificationStages': purificationStages,
      'certifiedBy': certifiedBy,
      'fssaiNumber': fssaiNumber,
      'labCertificateUrl': labCertificateUrl,
      'testedAt': Timestamp.fromDate(testedAt),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
