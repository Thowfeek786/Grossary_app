import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { credit, debit, cashback, refund }

class WalletTransaction {
  final String id;
  final double amount;
  final TransactionType type;
  final String description;
  final String? orderId;
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    this.orderId,
    required this.createdAt,
  });

  factory WalletTransaction.fromMap(Map<String, dynamic> map) {
    return WalletTransaction(
      id: map['id'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: TransactionType.values.firstWhere(
        (t) => t.name == (map['type'] ?? 'credit'),
        orElse: () => TransactionType.credit,
      ),
      description: map['description'] ?? '',
      orderId: map['orderId'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'type': type.name,
        'description': description,
        'orderId': orderId,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

typedef WalletTransactionModel = WalletTransaction;

class WalletModel {
  final String userId;
  final double balance;
  final List<WalletTransaction> transactions;
  final DateTime updatedAt;

  const WalletModel({
    required this.userId,
    required this.balance,
    required this.transactions,
    required this.updatedAt,
  });

  double get totalCashback => transactions
      .where((t) => t.type == TransactionType.cashback)
      .fold(0.0, (sum, t) => sum + t.amount);

  factory WalletModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return WalletModel(
      userId: doc.id,
      balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
      transactions: (data['transactions'] as List<dynamic>? ?? [])
          .map((e) => WalletTransaction.fromMap(e as Map<String, dynamic>))
          .toList(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'balance': balance,
        'transactions': transactions.map((t) => t.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
