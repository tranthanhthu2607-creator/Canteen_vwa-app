import 'dart:math';
import 'package:flutter/material.dart';
import 'api.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> with SingleTickerProviderStateMixin {
  int _totalSpent = 0;
  bool _isLoading = true;

  // Biến lưu hạng thực tế của bạn (Không bị thay đổi khi gạt thẻ)
  int _userTierIndex = 0;
  
  // Biến lưu vị trí thẻ đang xem trên màn hình (Bị thay đổi khi gạt)
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _tiers = [
    {
      'name': 'Đồng',
      'gradient': [const Color(0xFFB87333), const Color(0xFF8B5A2B), const Color(0xFFD4AF37)],
      'textColor': Colors.white,
      'icon': Icons.workspace_premium,
      'minSpend': 0,
      'maxSpend': 1000000,
      'benefits': [
        'Tích điểm cơ bản 1%',
        'Miễn phí giao hàng nội bộ',
        'Hỗ trợ cơ bản',
      ],
    },
    {
      'name': 'Bạc',
      'gradient': [const Color(0xFFE2E8F0), const Color(0xFF94A3B8), const Color(0xFFF8FAFC)],
      'textColor': Colors.black87,
      'icon': Icons.workspace_premium,
      'minSpend': 1000000,
      'maxSpend': 3000000,
      'benefits': [
        'Tích điểm 2% cho mỗi đơn hàng',
        'Giảm 10k phí giao hàng nội bộ',
        'Voucher sinh nhật 20k',
        'Ưu tiên lấy món',
      ],
    },
    {
      'name': 'Vàng',
      'gradient': [const Color(0xFFFDE047), const Color(0xFFB45309), const Color(0xFFFEF08A)],
      'textColor': Colors.black87,
      'icon': Icons.workspace_premium,
      'minSpend': 3000000,
      'maxSpend': 10000000,
      'benefits': [
        'Tích điểm 3% cho mỗi đơn hàng',
        'Miễn phí giao hàng nội bộ',
        'Voucher sinh nhật 50k',
        'Đổi quà không giới hạn',
        'Hỗ trợ VIP',
      ],
    },
    {
      'name': 'Kim Cương',
      'gradient': [const Color(0xFFFDFBF7), const Color(0xFFF0EDE6), const Color(0xFFE5E0D8)],
      'textColor': const Color(0xFF8B5A2B),
      'icon': Icons.diamond,
      'minSpend': 10000000,
      'maxSpend': null,
      'benefits': [
        'Tích điểm 5% cho mỗi đơn hàng',
        'Miễn phí giao hàng toàn hệ thống',
        'Voucher sinh nhật 100k',
        'Đặc quyền VWA Green (Nhân đôi điểm)',
        'Quà tặng đặc biệt từ Canteen',
      ],
    },
  ];

  final PageController _pageController = PageController(viewportFraction: 0.75);
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    // Đảm bảo Api.getTotalSpent() trả về số tiền thực tế
    final spent = await Api.getTotalSpent();
    
    if (mounted) {
      setState(() {
        _totalSpent = spent;
        
        // 1. Tính toán hạng thực tế của người dùng
        for (int i = _tiers.length - 1; i >= 0; i--) {
          if (spent >= (_tiers[i]['minSpend'] as int)) {
            _userTierIndex = i;
            break;
          }
        }
        
        // 2. Đặt vị trí thẻ ban đầu trùng với hạng thực tế
        _currentIndex = _userTierIndex;
        
        _isLoading = false;
      });
      
      // Tự động cuộn đến thẻ hạng thực tế khi mới mở lên
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_userTierIndex);
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F0F),
        body: Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }

    // 🔥 ĐỒNG BỘ LOGIC TÍNH TOÁN VỚI WEB
    int currentMin = _tiers[_userTierIndex]['minSpend'] as int;
    int? targetMax = _tiers[_userTierIndex]['maxSpend'] as int?;
    
    // Nếu đã đạt hạng cao nhất (Kim Cương) thì thanh tiến độ đầy 100%
    double progress = 1.0;
    int amountLeft = 0;
    
    if (targetMax != null) {
      // Web tính tiến độ dựa trên số tiền cần đạt tới của mốc tiếp theo
      progress = ((_totalSpent - currentMin) / (targetMax - currentMin)).clamp(0.0, 1.0);
      amountLeft = targetMax - _totalSpent;
      if (amountLeft < 0) amountLeft = 0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Thẻ thành viên',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),

            // PHẦN 1: GẠT THẺ
            SizedBox(
              height: 420,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _tiers.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildCard(index);
                },
              ),
            ),

            const SizedBox(height: 10),

            // PHẦN 2: THÔNG TIN BÊN DƯỚI (Hiển thị dựa trên hạng THỰC TẾ)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Ô Tổng chi tiêu (Màu tối giống Web)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tổng chi tiêu năm nay: ${_formatPrice(_totalSpent)}đ',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Chu kỳ hiện tại đến 31/12/2026',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. Thanh tiến độ
                  if (targetMax != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tiến độ lên Hạng ${_tiers[_userTierIndex + 1]['name']}',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Còn ${_formatPrice(amountLeft)}đ',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ] else ...[
                    const Text(
                      'Đã đạt hạng cao nhất',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                  
                  const SizedBox(height: 12),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: const Color(0xFF333333),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  
                  if (targetMax != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // PHẦN 3: QUYỀN LỢI (Hiển thị dựa trên hạng THỰC TẾ)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ưu đãi hạng ${_tiers[_userTierIndex]['name']}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  ...(_tiers[_userTierIndex]['benefits'] as List).map((benefit) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.blue, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              benefit,
                              style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WIDGET VẼ THẺ THÀNH VIÊN (CÓ LỚP PHỦ ĐEN MỜ NẾU CHƯA ĐẠT HẠNG)
  // ============================================================
  Widget _buildCard(int index) {
    double scale = 1.0;
    if (_pageController.position.hasContentDimensions) {
      double page = _pageController.page ?? _currentIndex.toDouble();
      double distance = (page - index).abs();
      scale = 1 - (distance * 0.15);
      if (scale < 0.8) scale = 0.8;
    }

    final tier = _tiers[index];
    final List<Color> gradientColors = tier['gradient'] as List<Color>;
    final Color textColor = tier['textColor'] as Color;
    final bool isDiamond = tier['name'] == 'Kim Cương';
    
    // 🔥 KIỂM TRA XEM THẺ NÀY ĐÃ ĐƯỢC MỞ KHÓA CHƯA
    final bool isUnlocked = index <= _userTierIndex;
    
    const Color goldColor = Color(0xFFB8860B); 

    return Transform.scale(
      scale: scale,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: AspectRatio(
          aspectRatio: 1 / 1.58,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isDiamond 
                      ? goldColor.withOpacity(0.15)
                      : gradientColors.first.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // NỘI DUNG THẺ
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),

                  if (isDiamond)
                    Center(
                      child: SizedBox(
                        width: 180,
                        height: 180,
                        child: CustomPaint(
                          painter: SpiralPatternPainter(
                            color: goldColor,
                          ),
                        ),
                      ),
                    ),

                  AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (context, child) {
                      return Positioned.fill(
                        child: FractionalTranslation(
                          translation: Offset((_shimmerController.value * 2) - 1, 0),
                          child: Transform.rotate(
                            angle: -0.5,
                            child: Container(
                              width: 150,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.0),
                                    Colors.white.withOpacity(isDiamond ? 0.4 : 0.3),
                                    Colors.white.withOpacity(0.0),
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CANTEEN',
                                  style: TextStyle(
                                    color: isDiamond ? goldColor : textColor.withOpacity(0.8),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'VWA MEMBER',
                                  style: TextStyle(
                                    color: isDiamond ? goldColor : textColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 4,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.wifi, 
                              color: isDiamond ? goldColor : Colors.white.withOpacity(0.8), 
                              size: 28,
                            ),
                          ],
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '**** **** **** VWA',
                              style: TextStyle(
                                color: isDiamond ? goldColor : textColor.withOpacity(0.6),
                                fontSize: 14,
                                letterSpacing: 2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            
                            Text(
                              tier['name'].toString().toUpperCase(),
                              style: TextStyle(
                                color: isDiamond ? goldColor : textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 🔥 LỚP PHỦ ĐEN MỜ VÀ ICON Ổ KHÓA NẾU CHƯA MỞ KHÓA
                  if (!isUnlocked)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.6),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.lock_outline,
                                color: Colors.white,
                                size: 50,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Chưa đạt hạng',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Chi tiêu ${_formatPrice(_tiers[index]['minSpend'] as int)}đ để mở khóa',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatPrice(int price) {
    final str = price.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}

// ============================================================
// CLASS VẼ KHỐI XOẮN ỐC (SPIRAL PATTERN)
// ============================================================
class SpiralPatternPainter extends CustomPainter {
  final Color color;
  SpiralPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 36; i++) {
      final path = Path();
      final angle = (i * pi) / 18;
      
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..shader = SweepGradient(
          colors: [
            color.withOpacity(0.9),
            color.withOpacity(0.2),
            color.withOpacity(0.9),
          ],
          stops: const [0.0, 0.5, 1.0],
          startAngle: angle,
          endAngle: angle + (pi / 18),
        ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

      path.moveTo(center.dx, center.dy);
      path.quadraticBezierTo(
        center.dx + maxRadius * 0.5 * cos(angle - 0.15),
        center.dy + maxRadius * 0.5 * sin(angle - 0.15),
        center.dx + maxRadius * cos(angle),
        center.dy + maxRadius * sin(angle),
      );
      path.quadraticBezierTo(
        center.dx + maxRadius * 0.5 * cos(angle + 0.15),
        center.dy + maxRadius * 0.5 * sin(angle + 0.15),
        center.dx,
        center.dy,
      );
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}