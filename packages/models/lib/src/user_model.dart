import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { customer, admin, deliveryPartner, dealer }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final UserRole role;
  final bool isActive;
  final bool isApproved;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime? updatedAt;
  // Dealer/Delivery specific
  final String? shopName;
  final String? shopAddress;
  final double? latitude;
  final double? longitude;
  final double? rating;
  final int totalDeliveries;
  final double totalEarnings;
  final String? bankName;
  final String? accountHolder;
  final String? accountNumber;
  final String? ifscCode;
  final String? upiId;
  final String? vehicleType;
  final String? dlNumber;
  final String? rcNumber;
  final String? docVerificationStatus; // 'pending', 'approved', 'rejected'

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
    required this.role,
    this.isActive = true,
    this.isApproved = false,
    this.fcmToken,
    required this.createdAt,
    this.updatedAt,
    this.shopName,
    this.shopAddress,
    this.latitude,
    this.longitude,
    this.rating,
    this.totalDeliveries = 0,
    this.totalEarnings = 0.0,
    this.bankName,
    this.accountHolder,
    this.accountNumber,
    this.ifscCode,
    this.upiId,
    this.vehicleType,
    this.dlNumber,
    this.rcNumber,
    this.docVerificationStatus,
  });

  String get roleString => role.name;

  bool get isDealer => role == UserRole.dealer;
  bool get isAdmin => role == UserRole.admin;
  bool get isDeliveryPartner => role == UserRole.deliveryPartner;
  bool get isCustomer => role == UserRole.customer;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      photoUrl: data['photoUrl'],
      role: UserRole.values.firstWhere(
        (r) => r.name == (data['role'] ?? 'customer'),
        orElse: () => UserRole.customer,
      ),
      isActive: data['isActive'] ?? true,
      isApproved: data['isApproved'] ?? false,
      fcmToken: data['fcmToken'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      shopName: data['shopName'],
      shopAddress: data['shopAddress'],
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      rating: (data['rating'] as num?)?.toDouble(),
      totalDeliveries: data['totalDeliveries'] ?? 0,
      totalEarnings: (data['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      bankName: data['bankName'],
      accountHolder: data['accountHolder'],
      accountNumber: data['accountNumber'],
      ifscCode: data['ifscCode'],
      upiId: data['upiId'],
      vehicleType: data['vehicleType'],
      dlNumber: data['dlNumber'],
      rcNumber: data['rcNumber'],
      docVerificationStatus: data['docVerificationStatus'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'role': role.name,
      'isActive': isActive,
      'isApproved': isApproved,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
      'shopName': shopName,
      'shopAddress': shopAddress,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'totalDeliveries': totalDeliveries,
      'totalEarnings': totalEarnings,
      'bankName': bankName,
      'accountHolder': accountHolder,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'upiId': upiId,
      'vehicleType': vehicleType,
      'dlNumber': dlNumber,
      'rcNumber': rcNumber,
      'docVerificationStatus': docVerificationStatus,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    UserRole? role,
    bool? isActive,
    bool? isApproved,
    String? fcmToken,
    String? shopName,
    String? shopAddress,
    double? latitude,
    double? longitude,
    double? rating,
    int? totalDeliveries,
    double? totalEarnings,
    String? bankName,
    String? accountHolder,
    String? accountNumber,
    String? ifscCode,
    String? upiId,
    String? vehicleType,
    String? dlNumber,
    String? rcNumber,
    String? docVerificationStatus,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      isApproved: isApproved ?? this.isApproved,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      shopName: shopName ?? this.shopName,
      shopAddress: shopAddress ?? this.shopAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      bankName: bankName ?? this.bankName,
      accountHolder: accountHolder ?? this.accountHolder,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      upiId: upiId ?? this.upiId,
      vehicleType: vehicleType ?? this.vehicleType,
      dlNumber: dlNumber ?? this.dlNumber,
      rcNumber: rcNumber ?? this.rcNumber,
      docVerificationStatus: docVerificationStatus ?? this.docVerificationStatus,
    );
  }
}
