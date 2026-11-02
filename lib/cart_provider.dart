// ============================================================
// CART PROVIDER — Quản lý giỏ hàng
// ============================================================
import 'package:flutter/material.dart';

class CartItem {
  final String id;
  final String name;
  final int unitPrice;
  final String image;
  final int quantity;
  final String size;
  final List<dynamic> toppings;

  CartItem({
    required this.id,
    required this.name,
    required this.unitPrice,
    required this.image,
    required this.quantity,
    required this.size,
    required this.toppings,
  });

  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      name: name,
      unitPrice: unitPrice,
      image: image,
      quantity: quantity ?? this.quantity,
      size: size,
      toppings: toppings,
    );
  }
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);
  int get totalPrice => _items.fold(0, (sum, item) => sum + item.unitPrice * item.quantity);

  void addItem(CartItem item) {
    final index = _items.indexWhere((e) => e.id == item.id && e.size == item.size);
    if (index != -1) {
      _items[index] = _items[index].copyWith(quantity: _items[index].quantity + item.quantity);
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  // 🔥 HÀM TĂNG SỐ LƯỢNG
  void increaseQuantity(String id) {
    final index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(quantity: _items[index].quantity + 1);
      notifyListeners();
    }
  }

  // 🔥 HÀM GIẢM SỐ LƯỢNG
  void decreaseQuantity(String id) {
    final index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      if (_items[index].quantity > 1) {
        _items[index] = _items[index].copyWith(quantity: _items[index].quantity - 1);
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}

class CartScope extends InheritedNotifier<CartProvider> {
  const CartScope({super.key, required CartProvider provider, required super.child}) : super(notifier: provider);

  static CartProvider of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CartScope>();
    assert(scope != null, 'CartScope not found in context');
    return scope!.notifier!;
  }
}