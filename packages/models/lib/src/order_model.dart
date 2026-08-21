import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item_model.dart';
import 'address_model.dart';

enum OrderStatus {
  pending,
  accepted,
  processing,
  shipped,
  outForDelivery,
  delivered,
  cancelled,
}

class OrderModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final List<CartItemModel> items;
  final AddressModel deliveryAddress;
  final OrderStatus status;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final String? couponCode;
  final String paymentMethod;
  final bool isPaid;
  final String? deliveryPartnerId;
  final String? deliveryPartnerName;
  final String? deliveryPartnerPhone;
  final String? dealerId;
  final String? dealerName;
  final String? cancellationReason;
  final String? notes;
  final String? deliveryOtp;
  final String? digitalSignatureUrl;
  final String? idempotencyKey;
  final List<String> deliveryInstructions;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deliveredAt;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.items,
    required this.deliveryAddress,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    this.couponCode,
    required this.paymentMethod,
    this.isPaid = false,
    this.deliveryPartnerId,
    this.deliveryPartnerName,
    this.deliveryPartnerPhone,
    this.dealerId,
    this.dealerName,
    this.cancellationReason,
    this.notes,
    this.deliveryOtp,
    this.digitalSignatureUrl,
    this.idempotencyKey,
    this.deliveryInstructions = const [],
    required this.createdAt,
    this.updatedAt,
    this.deliveredAt,
  });

  String get statusString => status.name;
  int get itemCount => items.fold(0, (acc, item) => acc + item.quantity);

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userPhone: data['userPhone'] ?? '',
      items: (data['items'] as List<dynamic>? ?? [])
          .map((e) => CartItemModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      deliveryAddress: AddressModel.fromMap(
          data['deliveryAddress'] as Map<String, dynamic>? ?? {}),
      status: OrderStatus.values.firstWhere(
        (s) => s.name == (data['status'] ?? 'pending'),
        orElse: () => OrderStatus.pending,
      ),
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (data['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      discount: (data['discount'] as num?)?.toDouble() ?? 0.0,
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      couponCode: data['couponCode'],
      paymentMethod: data['paymentMethod'] ?? 'Cash on Delivery',
      isPaid: data['isPaid'] ?? false,
      deliveryPartnerId: data['deliveryPartnerId'],
      deliveryPartnerName: data['deliveryPartnerName'],
      deliveryPartnerPhone: data['deliveryPartnerPhone'],
      dealerId: data['dealerId'],
      dealerName: data['dealerName'],
      cancellationReason: data['cancellationReason'],
      notes: data['notes'],
      deliveryOtp: data['deliveryOtp'],
      digitalSignatureUrl: data['digitalSignatureUrl'],
      idempotencyKey: data['idempotencyKey'],
      deliveryInstructions: (data['deliveryInstructions'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      deliveredAt: (data['deliveredAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'userName': userName,
    'userEmail': userEmail,
    'userPhone': userPhone,
    'items': items.map((e) => e.toMap()).toList(),
    'deliveryAddress': deliveryAddress.toMap(),
    'status': status.name,
    'subtotal': subtotal,
    'deliveryFee': deliveryFee,
    'discount': discount,
    'total': total,
    'couponCode': couponCode,
    'paymentMethod': paymentMethod,
    'isPaid': isPaid,
    'deliveryPartnerId': deliveryPartnerId,
    'deliveryPartnerName': deliveryPartnerName,
    'deliveryPartnerPhone': deliveryPartnerPhone,
    'dealerId': dealerId,
    'dealerName': dealerName,
    'cancellationReason': cancellationReason,
    'notes': notes,
    'deliveryOtp': deliveryOtp,
    'digitalSignatureUrl': digitalSignatureUrl,
    'idempotencyKey': idempotencyKey,
    'deliveryInstructions': deliveryInstructions,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': FieldValue.serverTimestamp(),
    'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
  };

  OrderModel copyWith({
    OrderStatus? status,
    String? deliveryPartnerId,
    String? deliveryPartnerName,
    String? deliveryPartnerPhone,
    bool? isPaid,
    String? cancellationReason,
    DateTime? deliveredAt,
    String? idempotencyKey,
    List<String>? deliveryInstructions,
  }) {
    return OrderModel(
      id: id,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      userPhone: userPhone,
      items: items,
      deliveryAddress: deliveryAddress,
      status: status ?? this.status,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      discount: discount,
      total: total,
      couponCode: couponCode,
      paymentMethod: paymentMethod,
      isPaid: isPaid ?? this.isPaid,
      deliveryPartnerId: deliveryPartnerId ?? this.deliveryPartnerId,
      deliveryPartnerName: deliveryPartnerName ?? this.deliveryPartnerName,
      deliveryPartnerPhone: deliveryPartnerPhone ?? this.deliveryPartnerPhone,
      dealerId: dealerId,
      dealerName: dealerName,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      notes: notes,
      deliveryOtp: deliveryOtp,
      digitalSignatureUrl: digitalSignatureUrl,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }
}
