import 'package:flutter/material.dart';
import 'api.dart';
import 'custom_app_bar.dart';
import 'membership_provider.dart';

class VwaPointsScreen extends StatefulWidget {
  const VwaPointsScreen({super.key});

  @override
  State<VwaPointsScreen> createState() => _VwaPointsScreenState();
}

class _VwaPointsScreenState extends State<VwaPointsScreen> {
  // Bảng màu chủ đạo: VÀNG (GOLD)
  static const Color kGoldPrimary = Color(0xFFF59E0B); // Vàng đậm
  static const Color kGoldLight = Color(0xFFFEF3C7); // Vàng nhạt
  static const Color kGoldDark = Color(0xFFD97706); // Vàng cam
  static const Color textDark = Color(0xFF1E293B);
  static const Color textGrey = Color(0xFF64748B);
  static const Color kVBorder = Color(0xFFE5E9EF);

  // Dữ liệu từ API
  int _points = 0;
  List<dynamic> _history = [];
  List<dynamic> _pendingReviews = [];
  bool _isLoading = true;
  String? _error;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _historyKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final pointsRes = await Api.getPoints();

      int currentPoints = 0;
      List<dynamic> currentHistory = [];

      if (pointsRes != null && pointsRes['points'] != null) {
        currentPoints = (pointsRes['points'] as num).toInt();
        currentHistory = (pointsRes['history'] as List?) ?? [];
      } else {
        final profile = await Api.getGreenProfile();
        
        int fallbackPoints = 0;
        if (profile != null) {
          var val = profile['points'] ?? profile['vwa_coin'] ?? profile['xu'];
          if (val is num) {
            fallbackPoints = val.toInt();
          } else if (val is String) {
            fallbackPoints = int.tryParse(val) ?? 0;
          }
        }
        currentPoints = fallbackPoints;

        final histRes = await Api.getGreenHistory();
        currentHistory = histRes ?? [];
      }

      final totalSpent = await Api.getTotalSpent();

      final orders = await Api.getMyOrders();
      List<dynamic> reviews = [];
      for (var order in orders) {
        if (order['status'] == 'Hoàn thành') {
          if (order['reviewed'] == true) continue;

          final items = order['items'] as List? ?? [];
          if (items.isNotEmpty) {
            reviews.add({
              'orderId': order['_id'] ?? order['id'],
              'itemName': items[0]['name'],
              'date': order['created_at'],
              'image': items[0]['image'],
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          _points = currentPoints;
          _history = currentHistory;
          _pendingReviews = reviews.take(3).toList();
          _isLoading = false;
        });

        MembershipScope.of(context).updateTierBySpending(totalSpent);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Lỗi tải dữ liệu: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToHistory() {
    final context = _historyKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const CustomAppBar(
        title: '',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kGoldPrimary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: textDark)))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: kGoldPrimary,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPassCard(),
                        const SizedBox(height: 24),
                        _buildHistoryHeader(),
                        const SizedBox(height: 12),
                        _buildHistoryList(),
                        const SizedBox(height: 24),
                        _buildReviewHeader(),
                        const SizedBox(height: 12),
                        _buildReviewSection(),
                      ],
                    ),
                  ),
                ),
    );
  }

  // ============================================================
  // 1. THẺ VWA POINTS (MÀU VÀNG)
  // ============================================================
  Widget _buildPassCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kGoldPrimary, kGoldDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kGoldPrimary.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('VWA Points', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Hạng Vàng', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text('Số dư xu thưởng khả dụng', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$_points', style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold, height: 1)),
              const SizedBox(width: 6),
              const Text('Xu', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('~ ${_formatNumber(_points)}đ', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              )
            ],
          ),
          const SizedBox(height: 10),

          const Text(
            'Trừ trực tiếp vào hóa đơn cơm trưa & cà phê tại căng-tin VWA',
            style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _scrollToHistory,
                  icon: const Icon(Icons.history, color: kGoldDark, size: 18),
                  label: const Text('Lịch sử xu', style: TextStyle(color: kGoldDark, fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const RulesDialog(),
                    );
                  },
                  icon: const Icon(Icons.rule, color: Colors.white, size: 18),
                  label: const Text('Quy tắc xu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // ============================================================
  // 2. LỊCH SỬ CỘNG XU (MÀU VÀNG)
  // ============================================================
  Widget _buildHistoryHeader() {
    return Row(
      key: _historyKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kGoldPrimary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.history, color: kGoldPrimary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Lịch sử cộng Xu (Tích điểm)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textDark)),
              const SizedBox(height: 2),
              const Text('Ghi nhận các lần bạn được cộng Xu từ hệ thống', style: TextStyle(fontSize: 11, color: textGrey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList() {
    if (_history.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kVBorder),
        ),
        child: const Center(child: Text('Chưa có lịch sử nhận xu', style: TextStyle(color: textGrey))),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kVBorder),
      ),
      child: Column(
        children: _history.map((item) {
          final type = item['type'] ?? 'Hành động';
          final points = int.tryParse(item['points']?.toString() ?? '0') ?? 0;
          final date = _formatDateString(item['date']?.toString());

          IconData icon = Icons.star;
          Color iconColor = kGoldPrimary;
          if (type.toString().contains('hộp')) { icon = Icons.fastfood; iconColor = kGoldPrimary; }
          if (type.toString().contains('bình')) { icon = Icons.coffee; iconColor = Colors.blue; }
          if (type.toString().contains('rác')) { icon = Icons.recycling; iconColor = Colors.orange; }

          final sign = points > 0 ? '+' : '';
          final displayType = type.toString().toLowerCase() == 'redeem' ? 'Đổi điểm' : type;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: Icon(icon, color: iconColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayType.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark)),
                          const SizedBox(height: 2),
                          Text(date, style: const TextStyle(fontSize: 11, color: textGrey)),
                        ],
                      ),
                    ),
                    Text(
                      '$sign$points Xu', 
                      style: TextStyle(
                        color: points > 0 ? kGoldPrimary : Colors.red, 
                        fontSize: 14, 
                        fontWeight: FontWeight.bold
                      )
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: kVBorder),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // 3. ĐÁNH GIÁ MÓN ĂN (MÀU CAM ĐẤT)
  // ============================================================
  Widget _buildReviewHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEE4D2D).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.rate_review, color: Color(0xFFEE4D2D), size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Đánh Giá Món Ăn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textDark)),
              const SizedBox(height: 2),
              const Text('Góp ý vì một căng-tin ngon sạch, chuẩn dinh dưỡng', style: TextStyle(fontSize: 11, color: textGrey)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEE4D2D).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text('+300 Xu/món', style: TextStyle(color: Color(0xFFEE4D2D), fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildReviewSection() {
    if (_pendingReviews.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kVBorder),
        ),
        child: const Center(child: Text('Bạn chưa có món nào cần đánh giá', style: TextStyle(color: textGrey))),
      );
    }

    return Column(
      children: _pendingReviews.map((review) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kVBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: review['image'] != null
                  ? Image.network(review['image'], width: 60, height: 60, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(width: 60, height: 60, color: kVBorder, child: const Icon(Icons.fastfood, color: Colors.grey)))
                  : Container(width: 60, height: 60, color: kVBorder, child: const Icon(Icons.fastfood, color: Colors.grey)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review['itemName'] ?? 'Món ăn', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDark)),
                    const SizedBox(height: 4),
                    Text('Đơn vừa ăn lúc ${_formatDate(review['date'])}', style: const TextStyle(fontSize: 11, color: textGrey)),
                    const SizedBox(height: 8),

                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (index) => const Icon(Icons.star_border, color: Color(0xFFEE4D2D), size: 18)),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chức năng đánh giá đang phát triển')));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C2D12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                            minimumSize: const Size(0, 30),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Gửi đánh giá', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward, color: Colors.white, size: 12),
                            ],
                          ),
                        )
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Hôm nay';
    try {
      final dt = DateTime.parse(date.toString()).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} hôm nay';
    } catch (_) {
      return 'Hôm nay';
    }
  }

  String _formatDateString(String? dateStr) {
    if (dateStr == null) return 'Gần đây';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'Gần đây';
    }
  }

  String _formatNumber(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}

// ============================================================
// 🪙 QUY TẮC TÍCH VÀ SỬ DỤNG XU VWA
// ============================================================
class RulesDialog extends StatelessWidget {
  const RulesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E9EF))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.settings, color: Color(0xFF2563EB), size: 24),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Quy tắc tích và sử dụng Xu VWA',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Color(0xFF64748B), size: 24),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '1. Quy tắc tích và sử dụng Xu VWA',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(height: 12),
                    _buildRuleItem(
                      context: context,
                      icon: '📦',
                      title: 'Hoàn thành đơn hàng',
                      points: '+100 Xu',
                      desc: 'Điều kiện nhận thưởng: Đơn hàng được hoàn thành thành công.\nCách cộng Xu: Hệ thống tự động cộng Xu vào tài khoản sau khi đơn hàng hoàn thành.\nTrường hợp không được thưởng: Đơn hàng chưa hoàn thành hoặc đã bị hủy sẽ không được nhận Xu thưởng.\nKiểm tra Xu: Xem số Xu được cộng trong mục Lịch sử Xu.',
                    ),
                    const SizedBox(height: 12),
                    _buildRuleItem(
                      context: context,
                      icon: '🍃',
                      title: 'Sống Xanh Học Đường',
                      points: '+200 Xu',
                      desc: 'Điều kiện tham gia: Mang hộp đựng cá nhân khi mua đồ ăn mang về.\nCách nhận thưởng: Thông báo với nhân viên tại quầy để được kiểm tra và xác nhận hợp lệ. Sau khi được duyệt, bạn nhận Xu.\nGiới hạn thưởng: Mỗi đơn hàng chỉ được nhận thưởng Sống Xanh một lần.\nLưu ý: Mang hộp cá nhân nhưng chưa được nhân viên xác nhận thì chưa đủ điều kiện nhận Xu.',
                    ),
                    const SizedBox(height: 12),
                    _buildRuleItem(
                      context: context,
                      icon: '⭐',
                      title: 'Đánh giá món ăn',
                      points: '+300 Xu',
                      desc: 'Điều kiện nhận thưởng: Đơn hàng đã hoàn thành và món ăn được đánh giá là món bạn đã mua.\nCách nhận thưởng: Chọn số sao và gửi nhận xét về món ăn thông qua chức năng đánh giá.\nMức thưởng: Nhận Xu cho mỗi lượt đánh giá hợp lệ.\nGiới hạn thưởng: Mỗi tài khoản chỉ được nhận thưởng một lần cho mỗi món ăn; đánh giá trùng lặp không được cộng thêm Xu.',
                    ),
                    const SizedBox(height: 12),
                    _buildRuleItem(
                      context: context,
                      icon: '💰',
                      title: 'Sử dụng Xu khi thanh toán',
                      points: '1 Xu = 1 VNĐ',
                      desc: 'Tỷ lệ quy đổi: 1 Xu = 1 VNĐ. Cách sử dụng: Dùng Xu để giảm trực tiếp số tiền cần thanh toán khi đặt hàng. Giới hạn sử dụng: Số Xu được dùng tối đa bằng 30% giá trị đơn hàng và không vượt quá số dư Xu hiện có trong tài khoản. Thanh toán phần còn lại: Số tiền chưa được trừ bằng Xu sẽ được thanh toán theo phương thức hệ thống hỗ trợ. Ví dụ: Với đơn hàng 100.000đ, bạn có thể sử dụng tối đa 30.000 Xu để giảm 30.000đ, còn phải thanh toán 70.000đ. Lưu ý: Xu dùng để giảm trực tiếp tiền đơn hàng, không phải voucher và không được quy đổi trực tiếp thành tiền mặt.',
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '2. Ưu đãi khác',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(height: 12),
                    _buildRuleItem(
                      context: context,
                      icon: '🎓',
                      title: 'Trợ giá sinh viên — Quỹ Học Đường',
                      points: 'Tối đa -10.000đ',
                      desc: 'Chương trình hỗ trợ một phần chi phí bữa ăn cho sinh viên đủ điều kiện. Khoản trợ giá được tính bằng VNĐ và được trừ trực tiếp vào tiền suất ăn, không cộng vào số dư Xu.\nMức trợ giá: Hỗ trợ tối đa 10.000đ cho mỗi suất ăn đủ điều kiện.\nĐiều kiện áp dụng: Suất ăn có giá trị từ 25.000đ trở lên và thanh toán theo hình thức được chương trình quy định tại quầy.\nCách nhận trợ giá: Chọn suất ăn đủ điều kiện và thực hiện thanh toán tại quầy theo hướng dẫn của căng tin. Khoản trợ giá được áp dụng khi giao dịch đáp ứng điều kiện chương trình.\nHạn mức hỗ trợ: Số tiền trợ giá phụ thuộc vào ngân sách quỹ và số suất ăn còn được hỗ trợ trong kỳ.\nTheo dõi quyền lợi: Bạn có thể xem hạn mức trợ giá còn lại, số suất đã sử dụng trong tháng và tiến độ sử dụng trên giao diện chương trình.\nLưu ý: Trợ giá là khoản giảm trực tiếp bằng VNĐ, không phải Xu. Mức hỗ trợ thực tế không vượt quá 10.000đ cho mỗi suất ăn và phụ thuộc vào điều kiện, hạn mức còn lại của chương trình.',
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Đóng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem({
    required BuildContext context,
    required String icon,
    required String title,
    required String points,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E9EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
              ),
              Text(
                points,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF16A34A)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
          ),
        ],
      ),
    );
  }
}