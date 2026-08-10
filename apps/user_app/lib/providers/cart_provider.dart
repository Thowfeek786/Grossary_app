import 'package:flutter/foundation.dart';
import 'package:models/models.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItemModel> _items = [];
  CouponModel? _appliedCoupon;

  double _baseDeliveryFee = 40.0;
  double _freeDeliveryThreshold = 500.0;
  bool _isFreeDeliveryEnabled = true;

  List<CartItemModel> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);
  bool get isEmpty => _items.isEmpty;

  CouponModel? get appliedCoupon => _appliedCoupon;
  double get subtotal => _items.fold(0, (sum, i) => sum + i.totalPrice);

  double get baseDeliveryFee => _baseDeliveryFee;
  double get freeDeliveryThreshold => _freeDeliveryThreshold;
  bool get isFreeDeliveryEnabled => _isFreeDeliveryEnabled;

  double get deliveryFee {
    if (subtotal == 0) return 0.0;
    if (_isFreeDeliveryEnabled && subtotal >= _freeDeliveryThreshold) return 0.0;
    return _baseDeliveryFee;
  }

  double get discountAmount => _appliedCoupon?.calculateDiscount(subtotal) ?? 0.0;
  double get total => (subtotal + deliveryFee - discountAmount).clamp(0.0, double.infinity);

  void updateDeliverySettings(StoreSettingsModel settings) {
    _baseDeliveryFee = settings.baseDeliveryFee;
    _freeDeliveryThreshold = settings.freeDeliveryThreshold;
    _isFreeDeliveryEnabled = settings.isFreeDeliveryEnabled;
    notifyListeners();
  }

  void applyCoupon(CouponModel coupon) {
    _appliedCoupon = coupon;
    notifyListeners();
  }

  void removeCoupon() {
    _appliedCoupon = null;
    notifyListeners();
  }

  bool containsProduct(String productId) =>
      _items.any((i) => i.productId == productId);

  int quantityOf(String productId) =>
      _items.firstWhere((i) => i.productId == productId,
          orElse: () => const CartItemModel(
              productId: '', productName: '', price: 0, unit: '', quantity: 0, dealerId: ''))
          .quantity;

  void addItem(ProductModel product) {
    if (_items.isNotEmpty && _items.first.dealerId != product.dealerId) {
      // Different dealer, clear cart first
      _items.clear();
    }
    final idx = _items.indexWhere((i) => i.productId == product.id);
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(quantity: _items[idx].quantity + 1);
    } else {
      _items.add(CartItemModel(
        productId: product.id,
        productName: product.name,
        imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : null,
        price: product.price,
        discountPrice: product.discountPrice,
        unit: product.unit,
        quantity: 1,
        dealerId: product.dealerId ?? '',
        dealerName: product.dealerName,
      ));
    }
    notifyListeners();
  }

  void addItemById(CartItemModel item) {
    final idx = _items.indexWhere((i) => i.productId == item.productId);
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(quantity: _items[idx].quantity + 1);
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    final idx = _items.indexWhere((i) => i.productId == productId);
    if (idx < 0) return;
    if (_items[idx].quantity > 1) {
      _items[idx] = _items[idx].copyWith(quantity: _items[idx].quantity - 1);
    } else {
      _items.removeAt(idx);
    }
    notifyListeners();
  }

  void deleteItem(String productId) {
    _items.removeWhere((i) => i.productId == productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _appliedCoupon = null;
    notifyListeners();
  }
}
