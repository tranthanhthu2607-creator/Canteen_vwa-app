import 'package:flutter/material.dart';
import 'api.dart';

// Màu sắc chuẩn theo Web
const Color kGreenPrimary = Color(0xFF16A34A);
const Color kGreenLightBg = Color(0xFFF0FDF4);
const Color kGreenBorder = Color(0xFFDCFCE7);
const Color kTextDark = Color(0xFF1E293B);
const Color kTextGrey = Color(0xFF64748B);

// ============================================================
// 🌿 HÀM HIỂN THỊ POPUP VWA GREEN
// ============================================================
void showGreenPopup(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const GreenPopupDialog(),
  );
}

class GreenPopupDialog extends StatefulWidget {
  const GreenPopupDialog({super.key});

  @override
  State<GreenPopupDialog> createState() => _GreenPopupDialogState();
}

class _GreenPopupDialogState extends State<GreenPopupDialog> {
  int _greenPoints = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGreenProfile();
  }

  Future<void> _loadGreenProfile() async {
    try {
      final pointsRes = await Api.getPoints();
      final profile = await Api.getGreenProfile();

      if (!mounted) return;
      setState(() {
        if (pointsRes != null && pointsRes['points'] != null) {
          _greenPoints = (pointsRes['points'] as num).toInt();
        } else {
          _greenPoints = (profile?['points'] ?? profile?['vwa_coin'] ?? 0) as int;
        }
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Hàm format tiền (VD: 9145 -> 9.145)
  String _formatNumber(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER: TAG VÀ NÚT CLOSE ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kGreenPrimary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'SINH THÁI HỌC ĐƯỜNG',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: kGreenPrimary, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- TIÊU ĐỀ ---
            const Text(
              'VWA Green Points',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kTextDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tích điểm khi mang bình nước / dùng khay tái chế',
              style: TextStyle(fontSize: 13, color: kTextGrey),
            ),
            const SizedBox(height: 24),

            // --- 2 Ô THỐNG KÊ ---
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: kGreenPrimary)))
            else
              Row(
                children: [
                  // Ô Điểm tích lũy
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Điểm tích lũy', style: TextStyle(fontSize: 13, color: kTextGrey)),
                          const SizedBox(height: 8),
                          Text('${_formatNumber(_greenPoints)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kTextDark)),
                          const SizedBox(height: 4),
                          const Text('VWA Points hiện có', style: TextStyle(fontSize: 11, color: kTextGrey)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Ô Giá trị quy đổi
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Giá trị quy đổi', style: TextStyle(fontSize: 13, color: kTextGrey)),
                          const SizedBox(height: 8),
                          Text('${_formatNumber(_greenPoints)}đ', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kTextDark)),
                          const SizedBox(height: 4),
                          const Text('Theo tỷ lệ quy đổi điểm', style: TextStyle(fontSize: 11, color: kTextGrey)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),

            // --- KHỐI CÁCH NHẬN XU XANH ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kGreenLightBg,
                border: Border.all(color: kGreenBorder),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon lá cây
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.eco, color: kGreenPrimary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  // Nội dung
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cách nhận Xu xanh',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kTextDark),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Mang bình nước cá nhân hoặc sử dụng khay tái chế khi mua đồ ăn tại canteen để góp phần giảm rác thải nhựa và xây dựng môi trường học đường xanh hơn.',
                          style: TextStyle(fontSize: 12.5, color: kTextGrey, height: 1.5),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Chung tay sống xanh mỗi ngày',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: kGreenPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- NÚT XEM CHI TIẾT ---
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const RulesDialog(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGreenPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 20),
                    SizedBox(width: 8),
                    Text('Xem chi tiết', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 🪙 QUY TẮC TÍCH VÀ SỬ DỤNG XU VWA (Giữ nguyên nội dung cũ)
// ============================================================
class RulesDialog extends StatelessWidget {
  const RulesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Theme.of(context).cardColor,
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
                  Expanded(
                    child: Text(
                      'Quy tắc tích và sử dụng Xu VWA',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.bodyLarge?.color),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: Theme.of(context).textTheme.bodyMedium?.color, size: 24),
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
        color: Theme.of(context).cardColor,
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
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
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
            style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color, height: 1.5),
          ),
        ],
      ),
    );
  }
}