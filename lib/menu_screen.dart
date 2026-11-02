// ============================================================
// MENU SCREEN — Giao diện gọn gàng (Có Header, Tìm kiếm nhỏ gọn)
// ============================================================
import 'package:flutter/material.dart';
import 'api.dart';
import 'cart_provider.dart';
import 'cart_screen.dart';
import 'placeholder_screens.dart';
import 'app_theme.dart';
import 'notification_screen.dart';
import 'custom_success_toast.dart';

// ============================================================
// MÀU SẮC CƠ BẢN
// ============================================================
const Color kBlue = Color(0xFF2563EB);
const Color kBg = Color(0xFFF9FAFB);
const Color kTextPrimary = Color(0xFF172033);
const Color kTextMuted = Color(0xFF64748B);
const Color kGreen = Color(0xFF18A967);
const Color kGold = Color(0xFFFBBF24);
const Color kBorder = Color(0xFFE5E9EF); 
const Color kRed = Color(0xFFEF4444);

// ============================================================
// MENU SCREEN
// ============================================================
class MenuScreen extends StatefulWidget {
  final String? externalCategory;

  const MenuScreen({
    super.key,
    this.externalCategory,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<dynamic> allFoods = [];
  List<dynamic> filteredFoods = [];
  List<String> categories = [];
  String selectedCategory = 'Tất cả';
  String searchQuery = '';
  bool loading = true;
  String error = '';

  final TextEditingController _searchController = TextEditingController();

  // --- BIẾN TRẠNG THÁI BỘ LỌC ---
  String _sortBy = 'recommended';
  bool _filterUnder60k = false;
  bool _filterPromotion = false;
  bool _filterBestSeller = false;

  @override
  void initState() {
    super.initState();
    if (widget.externalCategory != null) {
      selectedCategory = widget.externalCategory!;
    }
    _loadFoods();
  }

  @override
  void didUpdateWidget(MenuScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.externalCategory != null &&
        widget.externalCategory != oldWidget.externalCategory) {
      setState(() {
        selectedCategory = widget.externalCategory!;
      });
      _applyFilter();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFoods() async {
    setState(() {
      loading = true;
      error = '';
    });

    final data = await Api.getMenu();

    if (mounted) {
      setState(() {
        allFoods = data;

        final cats = <String>{'Tất cả'};
        for (final food in data) {
          final cat = food['category']?.toString();
          if (cat != null && cat.isNotEmpty) {
            cats.add(cat);
          }
        }
        categories = cats.toList();

        loading = false;
        if (data.isEmpty) error = 'Không có món ăn nào';
      });
      _applyFilter();
    }
  }

  // ============================================================
  // LOGIC LỌC KẾT HỢP (Category + Search + Filter)
  // ============================================================
  void _applyFilter() {
    setState(() {
      List<dynamic> result = allFoods.where((food) {
        final matchCategory = selectedCategory == 'Tất cả' ||
            food['category']?.toString() == selectedCategory;

        final matchSearch = searchQuery.isEmpty ||
            food['name']
                    ?.toString()
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()) ==
                true;

        return matchCategory && matchSearch;
      }).toList();

      if (_filterUnder60k) {
        result = result.where((food) {
          final price = int.tryParse(food['price']?.toString() ?? '0') ?? 0;
          return price < 60000;
        }).toList();
      }

      if (_filterPromotion) {
        result = result.where((food) {
          final discount = int.tryParse(food['discount_percent']?.toString() ?? '0') ?? 0;
          final price = int.tryParse(food['price']?.toString() ?? '0') ?? 0;
          final origPrice = int.tryParse(food['original_price']?.toString() ?? '0') ?? 0;
          return discount > 0 || origPrice > price;
        }).toList();
      }

      if (_sortBy == 'rating5s') {
        result = result.where((food) {
          final rating = double.tryParse(food['rating']?.toString() ?? '0') ?? 0.0;
          return rating >= 4.8; 
        }).toList();
        
        result.sort((a, b) {
          final ratingA = double.tryParse(a['rating']?.toString() ?? '0') ?? 0.0;
          final ratingB = double.tryParse(b['rating']?.toString() ?? '0') ?? 0.0;
          return ratingB.compareTo(ratingA);
        });
      } else if (_sortBy == 'recommended') {
        result.sort((a, b) {
          final soldA = int.tryParse(a['sold']?.toString() ?? '0') ?? 0;
          final soldB = int.tryParse(b['sold']?.toString() ?? '0') ?? 0;
          return soldB.compareTo(soldA);
        });
      }

      if (_filterBestSeller) {
        result.sort((a, b) {
          final soldA = int.tryParse(a['sold']?.toString() ?? '0') ?? 0;
          final soldB = int.tryParse(b['sold']?.toString() ?? '0') ?? 0;
          return soldB.compareTo(soldA);
        });
      }

      filteredFoods = result;
    });
  }

  // ============================================================
  // BOTTOM SHEET: CHỌN DANH MỤC
  // ============================================================
  void _showCategoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: kBorder),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isActive = selectedCategory == cat;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            selectedCategory = cat;
                          });
                          _applyFilter();
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: kBorder, width: 1)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                                  color: isActive ? kBlue : Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                              if (isActive)
                                const Icon(Icons.check_circle, color: kBlue, size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // 🆕 SIDE SHEET: BỘ LỌC
  // ============================================================
  void _showFilterSideSheet() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Filter',
      barrierColor: Colors.black.withOpacity(0.4), 
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight, 
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20), 
            child: Material(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                bottomLeft: Radius.circular(24),
              ),
              clipBehavior: Clip.antiAlias,
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  return Container(
                    width: MediaQuery.of(context).size.width * 0.5, 
                    padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 20),
                    child: SafeArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Lọc theo',
                                style: TextStyle(
                                  fontSize: 18, 
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: Icon(Icons.close, color: Theme.of(context).textTheme.bodyMedium?.color, size: 24),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFilterRadio(
                                    label: 'Được đề xuất',
                                    icon: Icons.thumb_up_alt_outlined,
                                    value: 'recommended',
                                    groupValue: _sortBy,
                                    onChanged: (val) => setModalState(() => _sortBy = val!),
                                  ),
                                  _buildFilterRadio(
                                    label: 'Đánh giá 5 sao',
                                    icon: Icons.star_border,
                                    value: 'rating5s',
                                    groupValue: _sortBy,
                                    onChanged: (val) => setModalState(() => _sortBy = val!),
                                  ),

                                  const SizedBox(height: 12),
                                  const Divider(color: kBorder, thickness: 1),
                                  const SizedBox(height: 12),

                                  Text(
                                    'Tùy chọn quán',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildFilterCheckbox(
                                    label: 'Dưới 60.000đ',
                                    icon: Icons.attach_money,
                                    value: _filterUnder60k,
                                    onChanged: (val) => setModalState(() => _filterUnder60k = val!),
                                  ),
                                  _buildFilterCheckbox(
                                    label: 'Khuyến mãi',
                                    icon: Icons.local_offer_outlined,
                                    value: _filterPromotion,
                                    onChanged: (val) => setModalState(() => _filterPromotion = val!),
                                  ),
                                  _buildFilterCheckbox(
                                    label: 'Bán chạy',
                                    icon: Icons.local_fire_department_outlined,
                                    value: _filterBestSeller,
                                    onChanged: (val) => setModalState(() => _filterBestSeller = val!),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const Divider(color: kBorder, thickness: 1),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    setModalState(() {
                                      _sortBy = 'recommended';
                                      _filterUnder60k = false;
                                      _filterPromotion = false;
                                      _filterBestSeller = false;
                                    });
                                  },
                                  icon: const Icon(Icons.refresh, size: 18, color: kBlue),
                                  label: const Text(
                                    'Đặt lại',
                                    style: TextStyle(
                                      color: kBlue,
                                      fontSize: 13, 
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    side: const BorderSide(color: kBlue, width: 1.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _applyFilter();
                                    Navigator.pop(context);
                                  },
                                  icon: const Icon(Icons.check, size: 18, color: Colors.white),
                                  label: const Text(
                                    'Áp dụng',
                                    style: TextStyle(
                                      fontSize: 14, 
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); 
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  Widget _buildFilterRadio({
    required String label,
    required IconData icon,
    required String value,
    required String groupValue,
    required Function(String?) onChanged,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? kBlue : const Color(0xFF7B8FA1), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? kGreen : const Color(0xFF7B8FA1),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCheckbox({
    required String label,
    required IconData icon,
    required bool value,
    required Function(bool?) onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: value ? kBlue : const Color(0xFF7B8FA1), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: value ? FontWeight.w700 : FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            Icon(
              value ? Icons.check_box : Icons.check_box_outline_blank,
              color: value ? kBlue : const Color(0xFF7B8FA1),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD GIAO DIỆN CHÍNH
  // ============================================================
  @override
  Widget build(BuildContext context) {
    int activeFilterCount = 0;
    if (_filterUnder60k) activeFilterCount++;
    if (_filterPromotion) activeFilterCount++;
    if (_filterBestSeller) activeFilterCount++;
    if (_sortBy != 'recommended') activeFilterCount++;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ===== HEADER XANH =====
          Container(
            width: double.infinity,
            color: kBlue,
            padding: EdgeInsets.fromLTRB(
              16, 
              MediaQuery.of(context).padding.top + 8, // Tự động né tai thỏ
              16, 
              12
            ),
            child: Column(
              children: [
                // Hàng 1: Logo & Các nút tiện ích
                Row(
                  children: [
                    // Logo
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/LOGO.jpg', // Đường dẫn ảnh logo của bạn
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(Icons.school, color: kBlue),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Nút thông báo
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => const NotificationScreen(),
                        );
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Avatar
                    GestureDetector(
                      onTap: () {
                        // Điều hướng sang trang cá nhân nếu cần
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_outline, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),

                // Hàng 2: Thanh tìm kiếm
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(Icons.search, color: Theme.of(context).textTheme.bodyMedium?.color, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            searchQuery = value;
                            _applyFilter();
                          },
                          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Tìm món ngon...',
                            hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 14),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.only(bottom: 12),
                          ),
                        ),
                      ),
                      if (searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            searchQuery = '';
                            _applyFilter();
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Icon(Icons.close, color: Theme.of(context).textTheme.bodyMedium?.color, size: 18),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Hàng 3: Nút Danh mục & Nút Lọc
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _showCategoryBottomSheet,
                      child: Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min, 
                          children: [
                            Text(
                              selectedCategory,
                              style: TextStyle(
                                fontSize: 13, 
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down, color: Theme.of(context).textTheme.bodyMedium?.color, size: 18),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _showFilterSideSheet, 
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.tune, color: Theme.of(context).textTheme.bodyLarge?.color, size: 18),
                          ),
                          if (activeFilterCount > 0)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: kRed,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '$activeFilterCount',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ===== GRID MÓN ĂN =====
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator(color: kBlue))
                : error.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, color: Theme.of(context).textTheme.bodyMedium?.color, size: 60),
                            const SizedBox(height: 16),
                            Text(error, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 14)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadFoods,
                              style: ElevatedButton.styleFrom(backgroundColor: kBlue),
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : filteredFoods.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, color: Theme.of(context).textTheme.bodyMedium?.color, size: 60),
                                const SizedBox(height: 16),
                                Text('Không tìm thấy món "$searchQuery"', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 14)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadFoods,
                            color: kBlue,
                            child: GridView.builder(
                              padding: const EdgeInsets.all(12),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                mainAxisExtent: 125, 
                              ),
                              itemCount: filteredFoods.length,
                              itemBuilder: (context, index) {
                                final food = filteredFoods[index];
                                return _FoodCard(food: food);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 🍽️ FOOD CARD
// ============================================================
class _FoodCard extends StatefulWidget {
  final Map<String, dynamic> food;

  const _FoodCard({required this.food});

  @override
  State<_FoodCard> createState() => _FoodCardState();
}

class _FoodCardState extends State<_FoodCard> {
  int _qty = 1;

  void _openDetail(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (_) => FoodDetailScreen(food: widget.food),
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0đ';
    final num = int.tryParse(price.toString()) ?? 0;
    return '${num.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    )}đ';
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final price = int.tryParse(food['price']?.toString() ?? '0') ?? 0;
    final originalPrice = int.tryParse(food['original_price']?.toString() ?? '0') ?? 0;
    final hasOriginal = originalPrice > price;
    final discountPercent = int.tryParse(food['discount_percent']?.toString() ?? '0') ?? (hasOriginal ? (((originalPrice - price) / originalPrice) * 100).round() : 0);
    final rating = food['rating']?.toString() ?? '5.0';
    final prepTime = food['prep_time']?.toString() ?? '12';

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child: (food['image'] != null && food['image'].toString().isNotEmpty)
                              ? Image.network(
                                  food['image'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, st) => Container(
                                    color: kBorder,
                                    child: Icon(Icons.restaurant, color: Theme.of(context).textTheme.bodyMedium?.color, size: 22),
                                  ),
                                )
                              : Container(
                                  color: kBorder,
                                  child: Icon(Icons.restaurant, color: Theme.of(context).textTheme.bodyMedium?.color, size: 22),
                                ),
                        ),
                      ),
                      if (discountPercent > 0)
                        Positioned(
                          top: 3,
                          left: 3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(color: kRed, borderRadius: BorderRadius.circular(3)),
                            child: Text('$discountPercent%', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                food['name'] ?? 'Không tên',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.bodyLarge?.color, height: 1.15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasOriginal) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(gradient: const LinearGradient(colors: [kRed, Color(0xFFDC2626)]), borderRadius: BorderRadius.circular(3)),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.flash_on, color: Colors.white, size: 7),
                                    SizedBox(width: 1),
                                    Text('Flash Sale', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w800)),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_formatPrice(price), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: kBlue)),
                            if (hasOriginal) ...[
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(_formatPrice(originalPrice), style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodyMedium?.color, decoration: TextDecoration.lineThrough), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 22,
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: kBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _qtyBtn(Icons.remove, () { if (_qty > 1) setState(() => _qty--); }),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text('$_qty', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.bodyLarge?.color)),
                                ),
                                _qtyBtn(Icons.add, () => setState(() => _qty++)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: kGold, size: 10),
                  const SizedBox(width: 1),
                  Text(rating, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.bodyMedium?.color)),
                  const SizedBox(width: 6),
                  Icon(Icons.access_time, color: Theme.of(context).textTheme.bodyMedium?.color, size: 10),
                  const SizedBox(width: 1),
                  Text('$prepTime\'', style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodyMedium?.color)),
                  const Spacer(),
                  SizedBox(
                    height: 24,
                    width: 60,
                    child: ElevatedButton(
                      onPressed: () => _openDetail(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBlue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        elevation: 0,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                      child: const Text('Thêm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        child: Icon(icon, size: 10, color: kBlue),
      ),
    );
  }
}