class AddressModel {
  final String id;
  final String userId;
  final String label; // Home, Work, Other
  final String fullName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.userId,
    required this.label,
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  String get fullAddress =>
      '$addressLine1${addressLine2 != null ? ', $addressLine2' : ''}, $city, $state - $pincode';

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'label': label,
    'fullName': fullName,
    'phone': phone,
    'addressLine1': addressLine1,
    'addressLine2': addressLine2,
    'city': city,
    'state': state,
    'pincode': pincode,
    'latitude': latitude,
    'longitude': longitude,
    'isDefault': isDefault,
  };

  factory AddressModel.fromMap(Map<String, dynamic> map) => AddressModel(
    id: map['id'] ?? '',
    userId: map['userId'] ?? '',
    label: map['label'] ?? 'Home',
    fullName: map['fullName'] ?? '',
    phone: map['phone'] ?? '',
    addressLine1: map['addressLine1'] ?? '',
    addressLine2: map['addressLine2'],
    city: map['city'] ?? '',
    state: map['state'] ?? '',
    pincode: map['pincode'] ?? '',
    latitude: (map['latitude'] as num?)?.toDouble(),
    longitude: (map['longitude'] as num?)?.toDouble(),
    isDefault: map['isDefault'] ?? false,
  );

  AddressModel copyWith({
    String? label,
    String? fullName,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? pincode,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id,
      userId: userId,
      label: label ?? this.label,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      latitude: latitude,
      longitude: longitude,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
