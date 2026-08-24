class CartItemModel {
  final String productId;
  final String productName;
  final String? imageUrl;
  final double price;
  final double? discountPrice;
  final String unit;
  final int quantity;
  final String dealerId;
  final String? dealerName;
  final String? offerType;
  final String? offerLabel;
  final bool isWaterCan;
  final bool canExchange;
  final double depositAmount;

  const CartItemModel({
    required this.productId,
    required this.productName,
    this.imageUrl,
    required this.price,
    this.discountPrice,
    required this.unit,
    required this.quantity,
    required this.dealerId,
    this.dealerName,
    this.offerType,
    this.offerLabel,
    this.isWaterCan = false,
    this.canExchange = false,
    this.depositAmount = 0.0,
  });

  double get effectivePrice => discountPrice ?? price;
  double get totalPrice {
    // If BOGO is active: every 2nd unit is free
    if (offerType == 'bogo' && quantity >= 2) {
      final payableCount = (quantity / 2).ceil();
      return (effectivePrice * payableCount) + (depositAmount * quantity);
    }
    // If Buy 2 Get 1 is active: every 3rd unit is free
    if (offerType == 'buy2get1' && quantity >= 3) {
      final freeUnits = quantity ~/ 3;
      return (effectivePrice * (quantity - freeUnits)) + (depositAmount * quantity);
    }
    return (effectivePrice * quantity) + (depositAmount * quantity);
  }

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'productName': productName,
    'imageUrl': imageUrl,
    'price': price,
    'discountPrice': discountPrice,
    'unit': unit,
    'quantity': quantity,
    'dealerId': dealerId,
    'dealerName': dealerName,
    'offerType': offerType,
    'offerLabel': offerLabel,
    'isWaterCan': isWaterCan,
    'canExchange': canExchange,
    'depositAmount': depositAmount,
  };

  factory CartItemModel.fromMap(Map<String, dynamic> map) => CartItemModel(
    productId: map['productId'] ?? '',
    productName: map['productName'] ?? '',
    imageUrl: map['imageUrl'],
    price: (map['price'] as num?)?.toDouble() ?? 0.0,
    discountPrice: (map['discountPrice'] as num?)?.toDouble(),
    unit: map['unit'] ?? 'piece',
    quantity: map['quantity'] ?? 1,
    dealerId: map['dealerId'] ?? '',
    dealerName: map['dealerName'],
    offerType: map['offerType'],
    offerLabel: map['offerLabel'],
    isWaterCan: map['isWaterCan'] ?? false,
    canExchange: map['canExchange'] ?? false,
    depositAmount: (map['depositAmount'] as num?)?.toDouble() ?? 0.0,
  );

  CartItemModel copyWith({
    int? quantity,
    bool? isWaterCan,
    bool? canExchange,
    double? depositAmount,
  }) {
    return CartItemModel(
      productId: productId,
      productName: productName,
      imageUrl: imageUrl,
      price: price,
      discountPrice: discountPrice,
      unit: unit,
      quantity: quantity ?? this.quantity,
      dealerId: dealerId,
      dealerName: dealerName,
      offerType: offerType,
      offerLabel: offerLabel,
      isWaterCan: isWaterCan ?? this.isWaterCan,
      canExchange: canExchange ?? this.canExchange,
      depositAmount: depositAmount ?? this.depositAmount,
    );
  }
}

