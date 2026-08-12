import 'package:cloud_firestore/cloud_firestore.dart';

class PayoutRequestModel {
  final String id;
  final String partnerId;
  final String partnerName;
  final String partnerPhone;
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String? upiId;
  final String payoutMethod; // 'bank' or 'upi'
  final double amount;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;
  final DateTime? processedAt;

  const PayoutRequestModel({
    required this.id,
    required this.partnerId,
    required this.partnerName,
    required this.partnerPhone,
    this.bankName = '',
    this.accountNumber = '',
    this.ifscCode = '',
    this.upiId,
    this.payoutMethod = 'bank',
    required this.amount,
    this.status = 'pending',
    required this.createdAt,
    this.processedAt,
  });

  factory PayoutRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PayoutRequestModel(
      id: doc.id,
      partnerId: data['partnerId'] ?? '',
      partnerName: data['partnerName'] ?? '',
      partnerPhone: data['partnerPhone'] ?? '',
      bankName: data['bankName'] ?? '',
      accountNumber: data['accountNumber'] ?? '',
      ifscCode: data['ifscCode'] ?? '',
      upiId: data['upiId'],
      payoutMethod: data['payoutMethod'] ?? 'bank',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      processedAt: (data['processedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'partnerId': partnerId,
      'partnerName': partnerName,
      'partnerPhone': partnerPhone,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'upiId': upiId,
      'payoutMethod': payoutMethod,
      'amount': amount,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
    };
  }
}
