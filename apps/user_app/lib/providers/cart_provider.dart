import 'package:flutter/foundation.dart';
import 'package:models/models.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItemModel> _items = [];

  List<CartItemModel> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);
  bool get isEmpty => _items.isEmpty;

  double get subtotal => _items.fold(0, (sum, i) => sum + i.totalPrice);
  double get deliveryFee => subtotal > 500 ? 0 : 40;
  double get total => subtotal + deliveryFee;

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
    notifyListeners();
  }
}
