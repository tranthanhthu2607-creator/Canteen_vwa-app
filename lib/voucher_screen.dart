import 'package:flutter/material.dart';
import 'custom_app_bar.dart';
import 'api.dart';

class VoucherScreen extends StatefulWidget {
  const VoucherScreen({super.key});

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> with SingleTickerProviderStateMixin {
  // Bảng màu
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color bgColor = Color(0xFFF5F7FA);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textGrey = Color(0xFF64748B);
  static const Color orangeTag = Color(0xFFEE4D2D);
  static const Color redTag = Color(0xFFEF4444);
  static const Color pinkTag = Color(0xFFEC4899);
  static const Color kVBorder = Color(0xFFE5E9EF); // 👈 Viền xám cố định

  final TextEditingController _searchController = TextEditingController();
  int _selectedTabIndex = 0;

  // Animation cho viền nhấp nháy
  late AnimationController _animationController;
  late Animation<Color?> _borderColorAnimation;

  // Dữ liệu từ API
  List<dynamic> _vouchers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _borderColorAnimation = ColorTween(
      begin: redTag.withOpacity(0.2),
      end: redTag,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Gọi API lấy danh sách voucher
      final data = await Api.getMyVouchers();
      
      if (mounted) {
        setState(() {
          _vouchers = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Không tải được danh sách voucher: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Đổi màu nền
      appBar: const CustomAppBar(
        title: 'Voucher',
        showBackButton: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Theme.of(context).textTheme.bodyMedium?.color),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadVouchers,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 20),
                      _buildStatusTabs(),
                      const SizedBox(height: 20),
                      if (_selectedTabIndex == 0) ...[
                        _buildHotVoucher(),
                        const SizedBox(height: 24),
                        _buildOtherVouchersHeader(),
                        const SizedBox(height: 12),
                        _buildOtherVoucherList(),
                      ] else ...[
                        _buildUsedVoucherList(),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // Đổi màu theo Theme
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Theme.of(context).textTheme.bodyMedium?.color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: 'Nhập mã voucher...',
                hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 16),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: primaryBlue,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text(
              'Áp dụng', 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatusTabs() {
    final tabs = ['Tất cả', 'Đã dùng'];
    
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kVBorder, width: 1)), // 👈 Viền xám cố định
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = index),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? primaryBlue : Colors.transparent,
                      width: 2.5, 
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    tabs[index],
                    style: TextStyle(
                      color: isSelected ? primaryBlue : Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHotVoucher() {
    if (_vouchers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor, // Đổi màu theo Theme
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kVBorder), // 👈 Viền xám cố định
        ),
        child: Center(
          child: Text(
            'Hiện chưa có voucher nào.\nHãy quay lại sau!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
          ),
        ),
      );
    }

    final hotVoucher = _vouchers[0];

    return AnimatedBuilder(
      animation: _borderColorAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor, // Đổi màu theo Theme
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColorAnimation.value ?? redTag, width: 2),
            boxShadow: [
              BoxShadow(
                color: (_borderColorAnimation.value ?? redTag).withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: orangeTag.withOpacity(0.5), width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department, color: orangeTag, size: 14),
                        SizedBox(width: 4),
                        Text('VOUCHER HOT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: orangeTag, letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _buildCountdownBox('01', 'Ngày'),
                      Text(' : ', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 12)),
                      _buildCountdownBox('02', 'Giờ'),
                      Text(' : ', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 12)),
                      _buildCountdownBox('30', 'Phút'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _HoverScaleCard(
                onTap: () {},
                child: _buildTicketCardFromData(hotVoucher, isHot: true, isUsed: false),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCountdownBox(String time, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor, // Đổi màu theo Theme
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: kVBorder, width: 1), // 👈 Viền xám cố định
          ),
          child: Text(time, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 8, color: Theme.of(context).textTheme.bodyMedium?.color)),
      ],
    );
  }

  Widget _buildOtherVouchersHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.local_offer, color: Theme.of(context).textTheme.bodyLarge?.color, size: 20),
            const SizedBox(width: 8),
            Text('Các voucher khác', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
          ],
        ),
        Text('Tự động chọn mã tốt nhất', style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8))),
      ],
    );
  }

  Widget _buildOtherVoucherList() {
    final otherVouchers = _vouchers.skip(1).toList();

    if (otherVouchers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text('Không có voucher nào khác.', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
        ),
      );
    }

    return Column(
      children: otherVouchers.map((v) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildTicketCardFromData(v, isHot: false, isUsed: false),
        );
      }).toList(),
    );
  }

  Widget _buildUsedVoucherList() {
    final usedVouchers = [
      {
        'name': 'Giảm 10.000đ',
        'description': 'Đã áp dụng cho đơn hàng #12345',
        'code': 'USED10K',
        'expiryDate': '12/10/2025 - 11:30',
      },
      {
        'name': 'Giảm 20.000đ',
        'description': 'Đã áp dụng cho đơn hàng #67890',
        'code': 'USED20K',
        'expiryDate': '05/10/2025 - 12:15',
      },
    ];

    return Column(
      children: usedVouchers.map((v) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildTicketCardFromData(v, isHot: false, isUsed: true),
        );
      }).toList(),
    );
  }

  // =====================================================
  // HÀM TẠO THẺ TICKET (Đã sửa để hiển thị giá trị giảm)
  // =====================================================
  Widget _buildTicketCardFromData(dynamic voucher, {required bool isHot, required bool isUsed}) {
    final String code = voucher['code'] ?? 'VOUCHER';
    
    // Lấy giá trị giảm giá
    final num priceValue = voucher['price'] ?? voucher['discount'] ?? voucher['value'] ?? 0;
    
    // Tạo tiêu đề
    String title = voucher['name'] ?? voucher['title'] ?? '';
    if (title.isEmpty || title == 'Voucher') {
      if (priceValue > 0) {
        title = 'Giảm ${_formatPrice(priceValue)}đ';
      } else {
        title = 'Voucher ưu đãi';
      }
    }

    final String subtitle = voucher['description'] ?? 'Áp dụng cho đơn hàng';
    final String expiry = voucher['expiryDate'] ?? 'Không thời hạn';
    
    final Color colorLeft = isUsed 
        ? Colors.grey.shade400 
        : (isHot ? redTag : primaryBlue);
        
    final Color textColor = isUsed ? Colors.grey.shade500 : Theme.of(context).textTheme.bodyLarge?.color ?? textDark;
    final Color subTextColor = isUsed ? Colors.grey.shade500 : Theme.of(context).textTheme.bodyMedium?.color ?? textGrey;
    
    final IconData iconLeft = isHot ? Icons.local_fire_department : Icons.local_offer;

    return Container(
      decoration: BoxDecoration(
        color: isUsed ? Theme.of(context).scaffoldBackgroundColor : Theme.of(context).cardColor, // Đổi màu theo Theme
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 100,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: colorLeft,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(iconLeft, color: Colors.white, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    'MÃ:\n$code',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, height: 1.2),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 12,
              child: CustomPaint(painter: DashedLinePainter(isUsed: isUsed)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isUsed 
                                ? Theme.of(context).disabledColor
                                : (isHot ? const Color(0xFFFEF2F2) : const Color(0xFFDBEAFE)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isUsed ? 'Đã sử dụng' : (isHot ? 'Ưu đãi đặc biệt' : 'Voucher'),
                            style: TextStyle(
                              fontSize: 9, 
                              fontWeight: FontWeight.bold, 
                              color: isUsed 
                                  ? Theme.of(context).textTheme.bodyMedium?.color
                                  : (isHot ? redTag : primaryBlue)
                            ),
                          ),
                        ),
                        Text(expiry, style: TextStyle(fontSize: 9, color: subTextColor)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title, 
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle, 
                      style: TextStyle(fontSize: 11, color: subTextColor), 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Điều kiện', style: TextStyle(fontSize: 10, color: subTextColor, decoration: TextDecoration.underline)),
                        SizedBox(
                          height: 28,
                          child: ElevatedButton(
                            onPressed: isUsed ? null : () {}, 
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isUsed ? Theme.of(context).disabledColor : colorLeft,
                              foregroundColor: isUsed ? Theme.of(context).textTheme.bodyMedium?.color : Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: Text(
                              isUsed ? 'Đã dùng' : 'Dùng ngay', 
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hàm format tiền tệ
  String _formatPrice(num price) {
    final str = price.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}

// LỚP VẼ ĐƯỜNG NÉT ĐỨT
class DashedLinePainter extends CustomPainter {
  final bool isUsed;
  DashedLinePainter({this.isUsed = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isUsed ? Colors.grey.shade300 : const Color(0xFFE5E9EF) // 👈 Sửa lỗi gạch đỏ
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const double dashHeight = 6.0;
    const double dashSpace = 4.0;

    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// WIDGET TẠO HIỆU ỨNG NỔI LÊN KHI CHẠM
class _HoverScaleCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _HoverScaleCard({required this.child, required this.onTap});

  @override
  State<_HoverScaleCard> createState() => _HoverScaleCardState();
}

class _HoverScaleCardState extends State<_HoverScaleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isHovered = true),
        onTapUp: (_) => setState(() => _isHovered = false),
        onTapCancel: () => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: const Color(0xFFEF4444).withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                )
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}