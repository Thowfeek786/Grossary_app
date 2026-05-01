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
  });

  double get effectivePrice => discountPrice ?? price;
  double get totalPrice => effectivePrice * quantity;

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
  );

  CartItemModel copyWith({int? quantity}) {
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
    );
  }
}
