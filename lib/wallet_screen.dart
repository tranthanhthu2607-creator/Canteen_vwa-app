// ============================================================
// 💳 WALLET SCREEN — VWA Smart Pay (Đồng bộ & Fix lỗi Nạp tiền)
// ============================================================
import 'package:flutter/material.dart';
import 'api.dart';
import 'custom_app_bar.dart';
import 'green_screen.dart';
import 'voucher_screen.dart';
import 'vwa_points_screen.dart';
import 'main.dart';
import 'app_theme.dart';

// ═══════════════════════════════════════════════════════════
// 🎨 MÀU SẮC
// ═══════════════════════════════════════════════════════════
const Color kWBlue = Color(0xFF2563EB);
const Color kWBlueDark = Color(0xFF1D4ED8);
const Color kWBlueDeep = Color(0xFF1E40AF);
const Color kWBg = Color(0xFFF5F7FA);
const Color kWTextPrimary = Color(0xFF172033);
const Color kWTextMuted = Color(0xFF64748B);
const Color kWGreen = Color(0xFF16A34A);
const Color kWGreenLight = Color(0xFF22C55E);
const Color kWGreenDeep = Color(0xFF15803D);
const Color kWRed = Color(0xFFEF4444);
const Color kWBorder = Color(0xFFE5E9EF);
const Color kWGold = Color(0xFFFBBF24);
const Color kWGoldDark = Color(0xFFF59E0B);

// ═══════════════════════════════════════════════════════════
// 💳 WALLET SCREEN
// ═══════════════════════════════════════════════════════════
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  int _balance = 0;
  int _points = 0;
  String _cardHolder = '';
  String _cardNumber = '•••• 0000';
  String _cardExpiry = '12/30';
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;
  String? _error;
  String _txFilter = 'all';

  // 🔥 TRẠNG THÁI KHÓA VÍ
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final wallet = await Api.getWallet();
      final transactions = await Api.getWalletTransactions();

      final pointsRes = await Api.getPoints();

      if (!mounted) return;

      if (wallet == null) {
        setState(() {
          _loading = false;
          _error = 'Không tải được ví.\nVui lòng đăng nhập lại.';
        });
        return;
      }

      final txList = <Map<String, dynamic>>[];
      if (transactions != null && transactions is List) {
        for (final t in transactions) {
          final type = t['type']?.toString() ?? 'deposit';
          final amount = (t['amount'] ?? 0) as int;
          final status = t['status']?.toString() ?? 'pending';
          final isIncome = type == 'deposit' || type == 'refund';

          String title;
          if (type == 'deposit') {
            final methodName = t['method']?.toString() == 'QR' ? 'VietQR' : 'Tiền mặt';
            title = 'Nạp tiền từ $methodName';
          } else if (type == 'withdraw') {
            title = 'Rút tiền về ngân hàng';
          } else if (type == 'payment') {
            title = t['note']?.toString() ?? 'Thanh toán đơn hàng';
          } else if (type == 'transfer') {
            title = t['note']?.toString() ?? 'Chuyển tiền';
          } else {
            title = t['note']?.toString() ?? 'Giao dịch';
          }

          txList.add({
            'icon': isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            'title': title,
            'time': _formatTime(t['created_at']?.toString()),
            'amount': amount,
            'isIncome': isIncome,
            'status': status,
          });
        }
      }

      int xuBalance = 0;
      if (pointsRes != null && pointsRes['points'] != null) {
        xuBalance = (pointsRes['points'] as num).toInt();
      } else {
        xuBalance = (wallet['points'] ?? 0) as int;
      }

      setState(() {
        _balance = (wallet['balance'] ?? 0) as int;
        _points = xuBalance;
        _cardHolder = (Api.currentUser?['name'] ?? 'SINH VIÊN VWA').toString().toUpperCase();
        final bankAcc = wallet['bank_account']?.toString() ?? '';
        _cardNumber = bankAcc.length >= 4 ? '•••• ${bankAcc.substring(bankAcc.length - 4)}' : '•••• 0000';
        _cardExpiry = '12/30';
        _transactions = txList;
        _isLocked = wallet['is_locked'] == true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Lỗi: $e';
        _loading = false;
      });
    }
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day/$month/$year · $hour:$minute';
    } catch (e) {
      return iso;
    }
  }

  // ============================================================
  // POPUP NHẬP PIN
  // ============================================================
  void _showPinDialog() {
    final pinCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).cardColor,
        title: Row(
          children: [
            Icon(_isLocked ? Icons.lock_open : Icons.lock_outline, color: kWBlue, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _isLocked ? 'Mở khóa ví' : 'Khóa ví',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isLocked
                  ? 'Nhập mã PIN để mở khóa ví. Sau khi mở, bạn có thể nạp/chuyển/thanh toán bằng ví.'
                  : 'Nhập mã PIN để khóa ví. Sau khi khóa, mọi giao dịch từ ví sẽ bị chặn.',
              style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: pinCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              autofocus: true,
              style: const TextStyle(fontSize: 20, letterSpacing: 8, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '••••••',
                counterText: '',
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kWBlue, width: 1.5)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '💡 PIN mặc định: 123456',
              style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (pinCtrl.text != '123456') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('❌ Mã PIN không đúng!'), backgroundColor: kWRed),
                );
                return;
              }

              Navigator.pop(ctx);

              final newLockState = !_isLocked;
              try {
                final res = await Api.updateWalletLock(newLockState);
                if (res['ok'] != true) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(res['message'] ?? 'Không thể cập nhật trạng thái ví'),
                        backgroundColor: kWRed,
                      ),
                    );
                  }
                  return;
                }

                if (!mounted) return;
                setState(() => _isLocked = newLockState);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_isLocked ? '🔒 Đã khóa ví thành công!' : '🔓 Đã mở khóa ví thành công!'),
                    backgroundColor: _isLocked ? kWRed : kWGreen,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi kết nối: $e'), backgroundColor: kWRed),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: kWBlue, foregroundColor: Colors.white),
            child: const Text('Xác nhận', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: '',
        showBackButton: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kWBlue))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadWallet,
                  color: kWBlue,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isLocked) _buildLockedBanner(),

                        SizedBox(
                          height: 175, 
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 6, child: _buildSmartPayCard()),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 4,
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: _buildSmallCard(
                                        icon: Icons.school_outlined,
                                        gradient: const LinearGradient(
                                          colors: [kWBlue, kWBlueDark],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        title: 'TRỢ GIÁ',
                                        subtitle: 'SINH VIÊN',
                                        badge: '-20%',
                                        desc: 'Giảm giá món',
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => const StudentSubsidyDialog(),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Expanded(
                                      child: _buildSmallCard(
                                        icon: Icons.eco_outlined,
                                        gradient: const LinearGradient(
                                          colors: [kWGreenLight, kWGreenDeep],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        title: 'VWA GREEN',
                                        subtitle: 'SINH THÁI',
                                        badge: 'Sinh thái',
                                        desc: 'Học đường xanh',
                                        onTap: () => showGreenPopup(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildQuickActionsMenu(),
                        const SizedBox(height: 20),
                        Text(
                          'Lịch sử giao dịch',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildFilterTabs(),
                        const SizedBox(height: 16),
                        if (_getFilteredTransactions().isEmpty)
                          _buildEmptyTransactions()
                        else
                          ..._getFilteredTransactions().map(_buildTransactionItem),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildLockedBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kWRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kWRed),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock, color: kWRed, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Ví đang bị khóa. Vui lòng mở khóa để thực hiện giao dịch.',
              style: TextStyle(color: kWRed, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: _showPinDialog,
            child: const Text('Mở khóa', style: TextStyle(color: kWRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kWBorder, width: 1)),
      ),
      child: Row(
        children: [
          _buildFilterTab('all', 'Tất cả', _countAll),
          _buildFilterTab('in', 'Tiền vào', _countIn),
          _buildFilterTab('out', 'Tiền ra', _countOut),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String key, String label, int count) {
    final isActive = _txFilter == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _txFilter = key),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? kWGreen : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Center(
            child: Text(
              count > 0 ? '$label ($count)' : label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredTransactions() {
    if (_txFilter == 'all') return _transactions;
    if (_txFilter == 'in') {
      return _transactions.where((tx) => tx['isIncome'] == true).toList();
    }
    return _transactions.where((tx) => tx['isIncome'] == false).toList();
  }

  int get _countAll => _transactions.length;
  int get _countIn => _transactions.where((t) => t['isIncome'] == true).length;
  int get _countOut => _transactions.where((t) => t['isIncome'] == false).length;

  Widget _buildEmptyTransactions() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kWBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 60, color: Theme.of(context).textTheme.bodyMedium?.color),
          const SizedBox(height: 12),
          Text(
            _txFilter == 'in' ? 'Chưa có giao dịch tiền vào' : _txFilter == 'out' ? 'Chưa có giao dịch tiền ra' : 'Chưa có giao dịch nào',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyMedium?.color),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: kWRed),
            const SizedBox(height: 16),
            Text(_error ?? 'Có lỗi xảy ra', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadWallet,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(backgroundColor: kWBlue, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartPayCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isLocked
              ? [Colors.grey[600]!, Colors.grey[800]!]
              : [kWBlue, kWBlueDark, kWBlueDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: (_isLocked ? Colors.grey : kWBlue).withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                child: Icon(_isLocked ? Icons.lock : Icons.account_balance_wallet, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_isLocked ? 'Ví đang khóa' : 'VWA Smart Pay', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              IconButton(
                onPressed: _showPinDialog,
                icon: Icon(_isLocked ? Icons.lock_open : Icons.lock_outline, color: Colors.white, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: _isLocked ? 'Mở khóa ví' : 'Khóa ví',
              ),
            ],
          ),
          Row(
            children: [
              Container(
                width: 24,
                height: 18,
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [kWGold, kWGoldDark]), borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text('THẺ SINH VIÊN ĐA NĂNG', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SỐ DƯ KHẢ DỤNG', style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_formatPrice(_balance), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1, letterSpacing: -0.3)),
                  const SizedBox(width: 2),
                  const Padding(padding: EdgeInsets.only(bottom: 2), child: Text('đ', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700))),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CHỦ THẺ', style: TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(_cardHolder, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('SỐ THẺ · HẠN', style: TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('$_cardNumber · $_cardExpiry', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallCard({
    required IconData icon,
    required Gradient gradient,
    required String title,
    required String subtitle,
    required String badge,
    required String desc,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, height: 1), maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 8, fontWeight: FontWeight.w600, height: 1), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(4)),
              child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
            ),
            Row(
              children: [
                Expanded(child: Text(desc, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 9.5, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                const Icon(Icons.chevron_right, color: Colors.white, size: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsMenu() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kWBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMenuAction(
              icon: _isLocked ? Icons.lock : Icons.account_balance_wallet_outlined,
              label: 'Nạp\ntiền',
              onTap: _isLocked ? _showLockedMessage : () => _showTopUpDialog(context),
              isLocked: _isLocked,
            ),
          ),
          Expanded(
            child: _buildMenuAction(
              icon: _isLocked ? Icons.lock : Icons.send_outlined,
              label: 'Chuyển\ntiền',
              onTap: _isLocked ? _showLockedMessage : () => showTransferDialog(context, onSuccess: _loadWallet),
              isLocked: _isLocked,
            ),
          ),
          Expanded(
            child: _buildMenuAction(
              icon: _isLocked ? Icons.lock : Icons.qr_code_scanner,
              label: 'QR Thanh\ntoán/Nhận',
              onTap: _isLocked ? _showLockedMessage : _showQrDialog,
              isLocked: _isLocked,
            ),
          ),
          Expanded(
            child: _buildMenuAction(
              icon: Icons.confirmation_number_outlined,
              label: 'Kho\nvoucher',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const VoucherScreen()));
              },
              isLocked: _isLocked,
            ),
          ),
          Expanded(
            child: _buildMenuAction(
              icon: Icons.stars,
              label: 'Tích\nXu',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const VwaPointsScreen()))
                    .then((_) => _loadWallet());
              },
              isLocked: _isLocked,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLocked = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isLocked ? kWRed : kWBlue, size: 32),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isLocked ? kWRed : Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showLockedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ví đang bị khóa. Vui lòng mở khóa để sử dụng chức năng này!'),
        backgroundColor: kWRed,
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> tx) {
    final isIncome = tx['isIncome'] as bool;
    final amount = tx['amount'] as int;
    final status = tx['status']?.toString() ?? 'approved';
    final isPending = status == 'pending';
    final isRejected = status == 'rejected';

    final themeColor = isIncome ? kWGreen : kWRed;
    final bgColor = isIncome ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kWBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(tx['icon'] as IconData, color: themeColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx['title'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.bodyLarge?.color)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(tx['time'] as String, style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color)),
                    if (isPending) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(4)),
                        child: const Text('Chờ duyệt', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
                      ),
                    ] else if (isRejected) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(4)),
                        child: const Text('Bị từ chối', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF991B1B))),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${_formatPrice(amount.abs())}đ',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: (isPending || isRejected) ? Theme.of(context).textTheme.bodyMedium?.color : themeColor),
          ),
        ],
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

  void _showQrDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Mã QR quầy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.bodyLarge?.color)),
              const SizedBox(height: 6),
              Text('Đưa mã này cho nhân viên quầy', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color)),
              const SizedBox(height: 20),
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: kWBorder, width: 1.5)),
                child: Icon(Icons.qr_code_2, size: 160, color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              const SizedBox(height: 16),
              Text('Mã SV: ${Api.currentUser?['studentId'] ?? 'SV2025001'}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.bodyLarge?.color)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: kWBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTopUpDialog(BuildContext context) {
    final amountCtrl = TextEditingController(text: '100000');
    final noteCtrl = TextEditingController();
    String selectedMethod = 'QR';
    int quickAmount = 100000;
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          int amount = int.tryParse(amountCtrl.text.replaceAll('.', '')) ?? 0;

          Future<void> handleTopUp() async {
            if (amount < 10000) return;

            setDialogState(() => isProcessing = true);

            try {
              final res = await Api.createDepositRequest(
                amount: amount,
                method: selectedMethod,
                note: noteCtrl.text.trim(),
              );

              if (!ctx.mounted) return;
              setDialogState(() => isProcessing = false);

              if (res['ok'] != true) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(res['message'] ?? 'Không thể tạo yêu cầu nạp'), backgroundColor: kWRed),
                );
                return;
              }

              Navigator.of(ctx).pop(); 
              
              final methodName = selectedMethod == 'QR' ? 'VietQR' : 'Tiền mặt';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('✅ Đã gửi yêu cầu nạp ${_formatPrice(amount)}đ ($methodName)'),
                      const SizedBox(height: 4),
                      const Text('Vui lòng chờ Admin duyệt!', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  backgroundColor: kWGreen,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                ),
              );

              await _loadWallet();
            } catch (e) {
              if (!ctx.mounted) return;
              setDialogState(() => isProcessing = false);
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text('Lỗi kết nối: $e'), backgroundColor: kWRed),
              );
            }
          }

          return Dialog(
            backgroundColor: Theme.of(ctx).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 440),
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: kWBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.add, color: kWBlue, size: 20)),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Nạp tiền', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Theme.of(ctx).textTheme.bodyLarge?.color))),
                        IconButton(
                          onPressed: isProcessing ? null : () => Navigator.pop(ctx), 
                          icon: Icon(Icons.close, color: Theme.of(ctx).textTheme.bodyMedium?.color)
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    Row(children: [
                      Text('Số tiền', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(ctx).textTheme.bodyLarge?.color)),
                      const Text(' *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kWRed)),
                    ]),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      enabled: !isProcessing,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kWBlue),
                      onChanged: (v) {
                        final clean = v.replaceAll(RegExp(r'[^\d]'), '');
                        if (clean != v) {
                          amountCtrl.text = clean;
                          amountCtrl.selection = TextSelection.fromPosition(TextPosition(offset: clean.length));
                        }
                        setDialogState(() {});
                      },
                      decoration: InputDecoration(
                        hintText: '0',
                        suffixText: 'đ',
                        suffixStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(ctx).textTheme.bodyMedium?.color),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        filled: true,
                        fillColor: Theme.of(ctx).scaffoldBackgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kWBlue, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [50000, 100000, 200000, 500000].map((amt) {
                        final isSelected = quickAmount == amt && amount == amt;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: GestureDetector(
                              onTap: isProcessing ? null : () {
                                amountCtrl.text = amt.toString();
                                setDialogState(() { quickAmount = amt; });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? kWBlue : Theme.of(ctx).scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isSelected ? kWBlue : kWBorder, width: 1),
                                ),
                                alignment: Alignment.center,
                                child: Text(_shortAmount(amt), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : Theme.of(ctx).textTheme.bodyLarge?.color)),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    
                    Text('Phương thức', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(ctx).textTheme.bodyLarge?.color)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildMethodOption(context: ctx, label: 'VietQR', sub: 'VietQR', icon: Icons.qr_code_2, selected: selectedMethod == 'QR', onTap: isProcessing ? () {} : () => setDialogState(() => selectedMethod = 'QR'))),
                        const SizedBox(width: 12),
                        Expanded(child: _buildMethodOption(context: ctx, label: 'Tiền mặt', sub: 'Nộp tại quầy', icon: Icons.payments_outlined, selected: selectedMethod == 'CASH', onTap: isProcessing ? () {} : () => setDialogState(() => selectedMethod = 'CASH'))),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    Text('Ghi chú', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(ctx).textTheme.bodyLarge?.color)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteCtrl,
                      maxLines: 2,
                      enabled: !isProcessing,
                      style: TextStyle(fontSize: 14, color: Theme.of(ctx).textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        hintText: 'Ghi chú thêm (không bắt buộc)',
                        hintStyle: TextStyle(fontSize: 13, color: Theme.of(ctx).textTheme.bodyMedium?.color),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        filled: true,
                        fillColor: Theme.of(ctx).scaffoldBackgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kWBlue, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: isProcessing ? null : () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(foregroundColor: Theme.of(ctx).textTheme.bodyLarge?.color, side: const BorderSide(color: kWBorder, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: const Text('Hủy', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: (amount >= 10000 && !isProcessing) ? handleTopUp : null,
                              style: ElevatedButton.styleFrom(backgroundColor: kWBlue, foregroundColor: Colors.white, disabledBackgroundColor: Theme.of(ctx).disabledColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                              child: isProcessing
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text('Nạp tiền ${amount > 0 ? _formatPrice(amount) : ''}đ', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// 🔥 HÀM PUBLIC CHUYỂN TIỀN
// ============================================================
void showTransferDialog(BuildContext context, {VoidCallback? onSuccess}) {
  final amountCtrl = TextEditingController(text: '100000');
  final stkCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  String selectedMethod = 'QR';
  const List<String> banks = ['MB Bank', 'Vietcombank', 'Techcombank', 'BIDV', 'VietinBank', 'Agribank', 'TPBank'];
  String selectedBank = 'MB Bank';
  int quickAmount = 100000;
  bool isProcessing = false;

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        int amount = int.tryParse(amountCtrl.text.replaceAll('.', '')) ?? 0;

        Future<void> handleTransfer() async {
          if (amount < 10000) return;
          if (selectedMethod == 'BANK' && stkCtrl.text.trim().isEmpty) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content: Text('Vui lòng nhập số tài khoản'), backgroundColor: kWRed),
            );
            return;
          }

          setDialogState(() => isProcessing = true);

          try {
            final res = await Api.transferMoney(
              amount: amount,
              method: selectedMethod,
              bankAccount: selectedMethod == 'BANK' ? stkCtrl.text.trim() : null,
              bankName: selectedMethod == 'BANK' ? selectedBank : null,
              note: noteCtrl.text.trim(),
            );

            if (!ctx.mounted) return;
            setDialogState(() => isProcessing = false);

            if (res['ok'] != true) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text(res['message'] ?? 'Chuyển tiền thất bại'), backgroundColor: kWRed),
              );
              return;
            }

            Navigator.of(ctx).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Đã chuyển ${_formatPriceGlobal(amount)}đ thành công!'),
                backgroundColor: kWGreen,
                behavior: SnackBarBehavior.floating,
              ),
            );

            onSuccess?.call();
          } catch (e) {
            if (!ctx.mounted) return;
            setDialogState(() => isProcessing = false);
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text('Lỗi: $e'), backgroundColor: kWRed),
            );
          }
        }

        return Dialog(
          backgroundColor: Theme.of(ctx).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: kWBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.send, color: kWBlue, size: 20)),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Chuyển tiền', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Theme.of(ctx).textTheme.bodyLarge?.color))),
                      IconButton(onPressed: isProcessing ? null : () => Navigator.pop(ctx), icon: Icon(Icons.close, color: Theme.of(ctx).textTheme.bodyMedium?.color)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Phương thức', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(ctx).textTheme.bodyLarge?.color)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildMethodOption(context: ctx, label: 'Quét mã QR', sub: 'Mở Camera', icon: Icons.qr_code_scanner, selected: selectedMethod == 'QR', onTap: isProcessing ? () {} : () => setDialogState(() => selectedMethod = 'QR'))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMethodOption(context: ctx, label: 'Ngân hàng', sub: 'Chuyển khoản', icon: Icons.account_balance, selected: selectedMethod == 'BANK', onTap: isProcessing ? () {} : () => setDialogState(() => selectedMethod = 'BANK'))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (selectedMethod == 'BANK') ...[
                    Text('Số tài khoản', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(ctx).textTheme.bodyLarge?.color)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: stkCtrl,
                      keyboardType: TextInputType.number,
                      enabled: !isProcessing,
                      style: TextStyle(fontSize: 16, color: Theme.of(ctx).textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        hintText: 'Nhập số tài khoản người nhận',
                        hintStyle: TextStyle(color: Theme.of(ctx).textTheme.bodyMedium?.color),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        filled: true,
                        fillColor: Theme.of(ctx).scaffoldBackgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kWBlue, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Chọn ngân hàng', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(ctx).textTheme.bodyLarge?.color)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: Theme.of(ctx).cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: kWBlue, width: 1.5)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedBank,
                          isExpanded: true,
                          dropdownColor: Theme.of(ctx).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          icon: const Icon(Icons.keyboard_arrow_down, color: kWBlue),
                          items: banks.map((String bank) {
                            return DropdownMenuItem<String>(value: bank, child: Text(bank, style: TextStyle(fontSize: 15, color: Theme.of(ctx).textTheme.bodyLarge?.color)));
                          }).toList(),
                          onChanged: isProcessing ? null : (val) {
                            if (val != null) setDialogState(() => selectedBank = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Row(children: [
                    Text('Số tiền', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(ctx).textTheme.bodyLarge?.color)),
                    const Text(' *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kWRed)),
                  ]),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    enabled: !isProcessing,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kWBlue),
                    onChanged: (v) {
                      final clean = v.replaceAll(RegExp(r'[^\d]'), '');
                      if (clean != v) {
                        amountCtrl.text = clean;
                        amountCtrl.selection = TextSelection.fromPosition(TextPosition(offset: clean.length));
                      }
                      setDialogState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: '0',
                      suffixText: 'đ',
                      suffixStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(ctx).textTheme.bodyMedium?.color),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      filled: true,
                      fillColor: Theme.of(ctx).scaffoldBackgroundColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kWBlue, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [50000, 100000, 200000, 500000].map((amt) {
                      final isSelected = quickAmount == amt && amount == amt;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: GestureDetector(
                            onTap: isProcessing ? null : () {
                              amountCtrl.text = amt.toString();
                              setDialogState(() { quickAmount = amt; });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? kWBlue : Theme.of(ctx).scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isSelected ? kWBlue : kWBorder, width: 1),
                              ),
                              alignment: Alignment.center,
                              child: Text(_shortAmount(amt), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : Theme.of(ctx).textTheme.bodyLarge?.color)),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text('Ghi chú', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(ctx).textTheme.bodyLarge?.color)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 2,
                    enabled: !isProcessing,
                    style: TextStyle(fontSize: 14, color: Theme.of(ctx).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: 'Ghi chú thêm (không bắt buộc)',
                      hintStyle: TextStyle(fontSize: 13, color: Theme.of(ctx).textTheme.bodyMedium?.color),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      filled: true,
                      fillColor: Theme.of(ctx).scaffoldBackgroundColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kWBlue, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: isProcessing ? null : () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(foregroundColor: Theme.of(ctx).textTheme.bodyLarge?.color, side: const BorderSide(color: kWBorder, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: const Text('Hủy', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: (amount >= 10000 && !isProcessing) ? handleTransfer : null,
                            style: ElevatedButton.styleFrom(backgroundColor: kWBlue, foregroundColor: Colors.white, disabledBackgroundColor: Theme.of(ctx).disabledColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                            child: isProcessing
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text('Chuyển tiền ${amount > 0 ? _formatPriceGlobal(amount) : ''}đ', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

String _formatPriceGlobal(int price) {
  final str = price.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
    buffer.write(str[i]);
  }
  return buffer.toString();
}

String _shortAmount(int amount) {
  if (amount >= 1000) {
    return '${(amount / 1000).toStringAsFixed(0)}.000đ';
  }
  return '${_formatPriceGlobal(amount)}đ';
}

Widget _buildMethodOption({
  required BuildContext context,
  required String label,
  required String sub,
  required IconData icon,
  required bool selected,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: selected ? kWBlue.withValues(alpha: 0.06) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? kWBlue : kWBorder, width: selected ? 1.5 : 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: selected ? kWBlue : Theme.of(context).textTheme.bodyMedium?.color),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: selected ? kWBlue : Theme.of(context).textTheme.bodyLarge?.color)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(fontSize: 11, color: selected ? kWBlue : Theme.of(context).textTheme.bodyMedium?.color)),
        ],
      ),
    ),
  );
}