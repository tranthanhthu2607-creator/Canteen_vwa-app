// ============================================================
// CART SCREEN — Giỏ hàng (Đã fix triệt để lỗi tràn viền & cú pháp)
// ============================================================
import 'package:flutter/material.dart';
import 'cart_provider.dart';
import 'checkout_screen.dart';
import 'custom_app_bar.dart';
import 'placeholder_screens.dart';

const Color kBlue = Color(0xFF2563EB);
const Color kBg = Color(0xFFF9FAFB);
const Color kTextPrimary = Color(0xFF172033);
const Color kTextMuted = Color(0xFF64748B);
const Color kBorder = Color(0xFFE5E9EF);
const Color kRed = Color(0xFFEF4444);
const Color kGreen = Color(0xFF18A967);

class CartScreen extends StatefulWidget {
  final VoidCallback? onNavigateToMenu;

  const CartScreen({super.key, this.onNavigateToMenu});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Set<String> _selectedItemIds = {};

  @override
  void initState() {
    super.initState();
    // Tự động chọn tất cả món khi vào giỏ hàng
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cart = CartScope.of(context);
      setState(() {
        _selectedItemIds.addAll(cart.items.map((item) => item.id));
      });
    });
  }

  String _fmt(int v) {
    final s = v.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${v < 0 ? '-' : ''}${buf.toString()}đ';
  }

  void _toggleSelectAll(bool? value, CartProvider cart) {
    setState(() {
      if (value == true) {
        _selectedItemIds.addAll(cart.items.map((item) => item.id));
      } else {
        _selectedItemIds.clear();
      }
    });
  }

  void _toggleItem(String id, bool? value) {
    setState(() {
      if (value == true) {
        _selectedItemIds.add(id);
      } else {
        _selectedItemIds.remove(id);
      }
    });
  }

  void _removeSelected(CartProvider cart) {
    final itemsToRemove = _selectedItemIds.toList();
    for (var id in itemsToRemove) {
      cart.removeItem(id);
    }
    setState(() {
      _selectedItemIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartScope.of(context);
    final allItems = cart.items;
    final selectedItems = allItems.where((it) => _selectedItemIds.contains(it.id)).toList();
    
    // Tính tổng tiền chỉ dựa trên các món ĐÃ CHỌN
    final totalPrice = selectedItems.fold<int>(0, (sum, item) => sum + item.unitPrice * item.quantity);

    final isAllSelected = allItems.isNotEmpty && _selectedItemIds.length == allItems.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBar(title: 'Giỏ hàng', showBackButton: false),
      body: allItems.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // ==========================================
                // HEADER: CHỌN TẤT CẢ & XÓA
                // ==========================================
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Theme.of(context).cardColor,
                  child: Row(
                    children: [
                      // Checkbox chọn tất cả
                      SizedBox(
                        width: 24, height: 24,
                        child: Checkbox(
                          value: isAllSelected,
                          onChanged: (val) => _toggleSelectAll(val ?? false, cart),
                          activeColor: kBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Chữ "Chọn tất cả"
                      GestureDetector(
                        onTap: () => _toggleSelectAll(!isAllSelected, cart),
                        child: Text(
                          'Chọn tất cả (${allItems.length})',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Nút Xóa
                      if (_selectedItemIds.isNotEmpty)
                        GestureDetector(
                          onTap: () => _removeSelected(cart),
                          child: const Row(
                            children: [
                              Icon(Icons.delete_outline, color: kRed, size: 18),
                              SizedBox(width: 4),
                              Text('Xóa', style: TextStyle(color: kRed, fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // ==========================================
                // DANH SÁCH MÓN
                // ==========================================
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: allItems.length,
                    itemBuilder: (context, index) {
                      final item = allItems[index];
                      final isSelected = _selectedItemIds.contains(item.id);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? kBlue : kBorder, width: isSelected ? 1.5 : 1),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Checkbox
                            SizedBox(
                              width: 24, height: 24,
                              child: Checkbox(
                                value: isSelected,
                                onChanged: (bool? val) {
                                  _toggleItem(item.id, val ?? false);
                                },
                                activeColor: kBlue,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Ảnh
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 70, height: 70,
                                child: item.image.isNotEmpty
                                    ? Image.network(item.image, fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(color: kBorder, child: const Icon(Icons.fastfood, color: Colors.grey)))
                                    : Container(color: kBorder, child: const Icon(Icons.fastfood, color: Colors.grey)),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Thông tin
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.name,
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      // Nút Xóa từng món
                                      GestureDetector(
                                        onTap: () {
                                          cart.removeItem(item.id);
                                          setState(() => _selectedItemIds.remove(item.id));
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.only(left: 8, bottom: 8),
                                          child: Icon(Icons.close, color: Colors.grey, size: 18),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _fmt(item.unitPrice),
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kRed),
                                  ),
                                  const SizedBox(height: 8),

                                  // Bộ điều khiển số lượng & Nút Sửa
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Nút tăng giảm
                                      Container(
                                        height: 28,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: kBorder),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                if (item.quantity > 1) {
                                                  cart.decreaseQuantity(item.id);
                                                }
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                child: Icon(Icons.remove, size: 14),
                                              ),
                                            ),
                                            Container(
                                              alignment: Alignment.center,
                                              width: 26,
                                              child: Text('${item.quantity}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                cart.increaseQuantity(item.id);
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                child: Icon(Icons.add, size: 14),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // Nút Sửa (Đã fix lỗi cú pháp)
                                      GestureDetector(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => FoodDetailScreen(
                                              food: {
                                                '_id': item.id,
                                                'name': item.name,
                                                'price': item.unitPrice,
                                                'image': item.image,
                                                'size': item.size,
                                                'toppings': item.toppings,
                                              },
                                              // Đã xóa isEditMode: true ở đây để không bị lỗi
                                            ),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: kBlue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(Icons.edit, color: kBlue, size: 14),
                                              SizedBox(width: 4),
                                              Text('Sửa', style: TextStyle(color: kBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // ==========================================
                // BOTTOM BAR: TỔNG TIỀN & NÚT ĐẶT HÀNG
                // ==========================================
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tạm tính', style: TextStyle(fontSize: 14, color: kTextMuted)),
                            Text(_fmt(totalPrice), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Phí dịch vụ', style: TextStyle(fontSize: 14, color: kTextMuted)),
                            Text(_fmt(0), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: kBorder),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('TỔNG CỘNG', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                            Text(_fmt(totalPrice), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBlue)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Đã bao gồm VAT', style: TextStyle(fontSize: 11, color: kTextMuted)),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: selectedItems.isEmpty
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kBlue,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              disabledBackgroundColor: kBorder,
                            ),
                            child: Text(
                              'ĐẶT HÀNG (${_selectedItemIds.length})',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: kBorder),
          const SizedBox(height: 16),
          const Text('Giỏ hàng của bạn đang trống', style: TextStyle(fontSize: 16, color: kTextMuted)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: widget.onNavigateToMenu,
            style: ElevatedButton.styleFrom(backgroundColor: kBlue),
            child: const Text('Tiếp tục mua sắm'),
          ),
        ],
      ),
    );
  }
}