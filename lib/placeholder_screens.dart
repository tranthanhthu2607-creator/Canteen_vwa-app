// ============================================================
// PLACEHOLDER SCREENS + FOOD DETAIL SCREEN
// ============================================================
import 'package:flutter/material.dart';
import 'cart_provider.dart';
import 'custom_success_toast.dart';

// ============================================================
// MÀU SẮC
// ============================================================
const Color kBlue = Color(0xFF2563EB);
const Color kBlueDark = Color(0xFF1D4ED8);
const Color kBg = Color(0xFFF9FAFB);
const Color kTextPrimary = Color(0xFF172033);
const Color kTextMuted = Color(0xFF64748B);
const Color kGreen = Color(0xFF18A967);
const Color kBorder = Color(0xFFE5E9EF);

// ============================================================
// CLASS TOPPING — Định nghĩa topping (NẰM NGOÀI CÙNG)
// ============================================================
class Topping {
  final String id;
  final String name;
  final int price;

  Topping({
    required this.id,
    required this.name,
    required this.price,
  });
}

// ============================================================
// HELPER — Format giá
// ============================================================
String formatPrice(dynamic price) {
  if (price == null) return '0đ';
  final num = int.tryParse(price.toString()) ?? 0;
  return '${num.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  )}đ';
}

// ============================================================
// HELPER — Tạo placeholder screen
// ============================================================
Widget buildPlaceholderScreen({
  required BuildContext context,
  required String title,
  required IconData icon,
  String subtitle = 'Màn hình này sẽ được phát triển',
  Color? iconColor,
}) {
  return Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    appBar: AppBar(
      backgroundColor: kBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: (iconColor ?? kBlue).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 60,
                color: iconColor ?? kBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: kBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: kBlue.withValues(alpha: 0.3), width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.construction, color: kBlue, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Đang phát triển',
                    style: TextStyle(color: kBlue, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ============================================================
// CÁC PLACEHOLDER SCREENS KHÁC
// ============================================================
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});
  @override
  Widget build(BuildContext context) => buildPlaceholderScreen(
        context: context,
        title: 'Chat với Canteen',
        icon: Icons.chat_bubble,
        subtitle: 'Nhắn tin với nhân viên',
      );
}

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});
  @override
  Widget build(BuildContext context) => buildPlaceholderScreen(
        context: context,
        title: 'Đăng ký',
        icon: Icons.person_add,
        subtitle: 'Tạo tài khoản mới',
      );
}

// ============================================================
// FOOD DETAIL SCREEN — MODAL với Size + Topping
// ============================================================
class FoodDetailScreen extends StatefulWidget {
  final Map<String, dynamic> food;
  final bool isEditMode;

  const FoodDetailScreen({
    super.key,
    required this.food,
    this.isEditMode = false,
  });

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  int quantity = 1;
  String selectedSize = 'Nhỏ';
  final Set<String> selectedToppings = {};

  // ===== KÍCH CỠ =====
  final List<Map<String, dynamic>> sizes = [
    {'name': 'Nhỏ', 'extra': 0, 'code': 'S'},
    {'name': 'Vừa', 'extra': 5000, 'code': 'M'},
    {'name': 'Lớn', 'extra': 10000, 'code': 'L'},
  ];

  // ===== TOPPING ĐỒ ĂN =====
  final List<Map<String, dynamic>> foodToppings = [
    {'id': '1', 'name': 'Trứng ốp la', 'price': 8000},
    {'id': '2', 'name': 'Trứng chiên', 'price': 8000},
    {'id': '3', 'name': 'Thêm cơm', 'price': 5000},
    {'id': '4', 'name': 'Thêm rau', 'price': 5000},
    {'id': '5', 'name': 'Thêm thịt', 'price': 15000},
    {'id': '6', 'name': 'Chả cá thêm', 'price': 10000},
    {'id': '7', 'name': 'Canh thêm', 'price': 8000},
    {'id': '8', 'name': 'Không hành', 'price': 0},
    {'id': '9', 'name': 'Ít cay', 'price': 0},
    {'id': '10', 'name': 'Nước sốt thêm', 'price': 5000},
  ];

  // ===== TOPPING NƯỚC UỐNG =====
  final List<Map<String, dynamic>> drinkToppings = [
    {'id': '11', 'name': 'Trân châu đen', 'price': 5000},
    {'id': '12', 'name': 'Trân châu trắng', 'price': 5000},
    {'id': '13', 'name': 'Thạch dừa', 'price': 5000},
    {'id': '14', 'name': 'Pudding trứng', 'price': 7000},
    {'id': '15', 'name': 'Kem phô mai', 'price': 10000},
    {'id': '16', 'name': 'Shot espresso', 'price': 8000},
    {'id': '17', 'name': 'Sữa đặc thêm', 'price': 5000},
    {'id': '18', 'name': 'Đá riêng', 'price': 0},
    {'id': '19', 'name': 'Ít đường', 'price': 0},
    {'id': '20', 'name': 'Không đường', 'price': 0},
  ];

  // ===== XÁC ĐỊNH ĐỒ UỐNG HAY ĐỒ ĂN =====
  bool get _isDrink {
    final category = widget.food['category']?.toString().toLowerCase() ?? '';
    final name = widget.food['name']?.toString().toLowerCase() ?? '';
    final description = widget.food['description']?.toString().toLowerCase() ?? '';

    if (category.contains('coffee') ||
        category.contains('tea') ||
        category.contains('nước') ||
        category.contains('sinh tố') ||
        category.contains('trà') ||
        category.contains('đồ uống') ||
        category.contains('drink') ||
        category.contains('juice') ||
        category.contains('smoothie')) {
      return true;
    }

    if (name.contains('trà') ||
        name.contains('cà phê') ||
        name.contains('sinh tố') ||
        name.contains('nước') ||
        name.contains('coca') ||
        name.contains('pepsi') ||
        name.contains('sting') ||
        name.contains('red bull') ||
        name.contains('sữa') ||
        name.contains('đá') ||
        name.contains('cam') ||
        name.contains('chanh') ||
        name.contains('dừa') ||
        name.contains('soda') ||
        name.contains('espresso') ||
        name.contains('latte') ||
        name.contains('cappuccino') ||
        name.contains('mocha')) {
      return true;
    }

    if (description.contains('trà') ||
        description.contains('cà phê') ||
        description.contains('nước uống') ||
        description.contains('giải khát') ||
        description.contains('refreshing drink')) {
      return true;
    }

    return false;
  }

  // ===== DANH SÁCH TOPPING PHÙ HỢP =====
  List<Map<String, dynamic>> get _availableToppings {
    return _isDrink ? drinkToppings : foodToppings;
  }

  // ===== TÍNH GIÁ =====
  int _getSizePrice() {
    final size = sizes.firstWhere(
      (s) => s['name'] == selectedSize,
      orElse: () => sizes[0],
    );
    return size['extra'] as int;
  }

  int _getToppingsPrice() {
    int total = 0;
    for (final t in _availableToppings) {
      if (selectedToppings.contains(t['name'])) {
        total += t['price'] as int;
      }
    }
    return total;
  }

  int _getTotalPrice() {
    final basePrice = int.tryParse(widget.food['price'].toString()) ?? 0;
    return (basePrice + _getSizePrice() + _getToppingsPrice()) * quantity;
  }

  // ===== LẤY DANH SÁCH TOPPING ĐÃ CHỌN =====
  List<Topping> _getSelectedToppingObjects() {
    final result = <Topping>[];
    for (final t in _availableToppings) {
      if (selectedToppings.contains(t['name'])) {
        result.add(Topping(
          id: t['id'].toString(),
          name: t['name'] as String,
          price: t['price'] as int,
        ));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final basePrice = int.tryParse(food['price'].toString()) ?? 0;
    final toppings = _availableToppings;

    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 450,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // === 1. HEADER ===
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      food['name'] ?? 'Không tên',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.1) ?? kBorder,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // === 2. NỘI DUNG SCROLL ===
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ẢNH
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 180,
                          width: double.infinity,
                          child: (food['image'] != null && food['image'].toString().isNotEmpty)
                              ? Image.network(
                                  food['image'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: kBorder,
                                    child: Icon(Icons.restaurant, color: Theme.of(context).textTheme.bodyMedium?.color, size: 60),
                                  ),
                                )
                              : Container(
                                  color: kBorder,
                                  child: Icon(Icons.restaurant, color: Theme.of(context).textTheme.bodyMedium?.color, size: 60),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // MÔ TẢ
                          Text(
                            food['description'] ?? 'Món ăn ngon, đậm đà hương vị.',
                            style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color, height: 1.5),
                          ),
                          const SizedBox(height: 12),

                          // GIÁ + STOCK
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                formatPrice(basePrice),
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kGreen),
                              ),
                              Text(
                                'Còn ${food['stock'] ?? 21} phần',
                                style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // RATING
                          Row(
                            children: [
                              const Icon(Icons.star, color: Color(0xFFFBBF24), size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${food['rating'] ?? 4.8}',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.bodyLarge?.color),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${food['review_count'] ?? 11} đánh giá)',
                                style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1, color: kBorder),
                          const SizedBox(height: 12),

                          // CHỌN KÍCH CỠ
                          Text(
                            'Chọn kích cỡ',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.bodyLarge?.color),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: sizes.asMap().entries.map((entry) {
                              final index = entry.key;
                              final size = entry.value;
                              final isSelected = selectedSize == size['name'];
                              final extra = size['extra'] as int;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(right: index < sizes.length - 1 ? 8 : 0),
                                  child: GestureDetector(
                                    onTap: () => setState(() => selectedSize = size['name']),
                                    child: Container(
                                      height: 60,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isSelected ? kBlue : Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: isSelected ? kBlue : kBorder, width: 1.5),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            size['name'],
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color),
                                          ),
                                          if (extra > 0) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              '+${formatPrice(extra)}',
                                              style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : Theme.of(context).textTheme.bodyMedium?.color),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          // TOPPING
                          Row(
                            children: [
                              Text(
                                _isDrink ? 'Thêm topping cho nước' : 'Thêm topping cho món',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.bodyLarge?.color),
                              ),
                              const SizedBox(width: 6),
                              Icon(_isDrink ? Icons.local_cafe : Icons.restaurant, size: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
                            ],
                          ),
                          const SizedBox(height: 10),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 3.2,
                            ),
                            itemCount: toppings.length,
                            itemBuilder: (context, index) {
                              final top = toppings[index];
                              final name = top['name'] as String;
                              final price = top['price'] as int;
                              final isSelected = selectedToppings.contains(name);

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      selectedToppings.remove(name);
                                    } else {
                                      selectedToppings.add(name);
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? kBlue.withValues(alpha: 0.08) : Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: isSelected ? kBlue : kBorder, width: 1.2),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: isSelected ? kBlue : Colors.transparent,
                                          borderRadius: BorderRadius.circular(5),
                                          border: Border.all(
                                            color: isSelected ? kBlue : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5) ?? kBorder,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 12) : null,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        price > 0 ? '+${formatPrice(price)}' : '+0đ',
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: kGreen),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1, color: kBorder),
                          const SizedBox(height: 12),

                          // SỐ LƯỢNG
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Số lượng:',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.bodyLarge?.color),
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (quantity > 1) setState(() => quantity--);
                                    },
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: quantity > 1 ? kBlue.withValues(alpha: 0.1) : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.1) ?? kBorder,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: quantity > 1 ? kBlue : kBorder, width: 1.2),
                                      ),
                                      child: Icon(
                                        Icons.remove,
                                        color: quantity > 1 ? kBlue : Theme.of(context).textTheme.bodyMedium?.color,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    '$quantity',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.bodyLarge?.color),
                                  ),
                                  const SizedBox(width: 16),
                                  GestureDetector(
                                    onTap: () => setState(() => quantity++),
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: kBlue,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.add, color: Colors.white, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // TỔNG CỘNG
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tổng:',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.bodyLarge?.color),
                              ),
                              Text(
                                formatPrice(_getTotalPrice()),
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kGreen),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // === 3. NÚT THÊM VÀO GIỎ (CỐ ĐỊNH Ở DƯỚI) ===
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: () {
                  final cart = CartScope.of(context);
                  final sizeCode = sizes.firstWhere((s) => s['name'] == selectedSize)['code'] as String;

                  cart.addItem(
                    CartItem(
                      id: food['_id']?.toString() ?? food['id']?.toString() ?? '0',
                      name: food['name']?.toString() ?? 'Món ăn',
                      image: food['image']?.toString() ?? '',
                      unitPrice: _getTotalPrice() ~/ quantity,
                      size: sizeCode,
                      toppings: _getSelectedToppingObjects(),
                      quantity: quantity,
                    ),
                  );

                  CustomSuccessToast.show(context, 'Đã thêm $quantity × ${food['name']} vào giỏ');
                  Navigator.pop(context);
                },
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBlue, width: 2),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: kBlue, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Thêm vào giỏ',
                        style: TextStyle(color: kBlue, fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}