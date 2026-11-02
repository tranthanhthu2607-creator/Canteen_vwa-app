// ============================================================
// 💳 CHECKOUT SCREEN — Đồng bộ logic & Fix lỗi Toppings
// ============================================================
import 'package:flutter/material.dart';
import 'cart_provider.dart';
import 'api.dart';
import 'order_success_screen.dart';
import 'custom_app_bar.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _payMethod = 0;
  bool _showUserInfo = true;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _voucherCtrl = TextEditingController();

  String? _timeSlot;
  bool _loading = false;

  int _vwaBalance = 0;
  int _vwaXu = 0; 
  bool _useVwaXu = false;
  bool _useGreen = false; 
  int _voucherDiscount = 0;
  List<dynamic> _myVouchers = []; 
  String? _selectedVoucherCode;
  List<Map<String, dynamic>> _timeSlots = [];

  static const _primary = Color(0xFF2563EB); 
  static const _oceanBlue = Color(0xFF005BAA); 
  static const _border = Color(0xFFE5E9EF);
  static const _purple = Color(0xFF7C3AED);

  @override
  void initState() {
    super.initState();
    _timeSlots = _generateTimeSlots();
    _loadUserInfo();
    _loadWalletAndPoints();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _noteCtrl.dispose();
    _voucherCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _generateTimeSlots() {
    final now = DateTime.now();
    final minMinutes = now.hour * 60 + now.minute + 15;
    final slots = <Map<String, dynamic>>[];
    for (int h = 7; h <= 18; h++) {
      for (int m in [0, 30]) {
        final startMin = h * 60 + m;
        if (startMin + 30 > 19 * 60) break;
        final endMin = startMin + 30;
        final startStr = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
        final endH = endMin ~/ 60;
        final endM = endMin % 60;
        final endStr = '${endH.toString().padLeft(2, '0')}:${endM.toString().padLeft(2, '0')}';
        slots.add({
          'value': '$startStr-$endStr',
          'label': '$startStr - $endStr',
          'disabled': startMin < minMinutes,
        });
      }
    }
    return slots;
  }

  void _loadUserInfo() {
    final user = Api.currentUser;
    if (user != null) {
      _nameCtrl.text = (user['name'] ?? user['fullName'] ?? '').toString();
      _phoneCtrl.text = (user['phone'] ?? user['phoneNumber'] ?? '').toString();
    }
    if (_nameCtrl.text.isEmpty) _nameCtrl.text = 'ĐOÀN THỊ MINH HÀ';
    if (_phoneCtrl.text.isEmpty) _phoneCtrl.text = '0987654321';
  }

  Future<void> _loadWalletAndPoints() async {
    try {
      final wallet = await Api.getWallet();
      final pointsRes = await Api.getPoints(); 
      final vouchers = await Api.getMyVouchers(); 
      
      if (!mounted) return;
      
      setState(() {
        _vwaBalance = (wallet?['balance'] ?? 0) as int;
        _vwaXu = (pointsRes?['points'] ?? 0) as int; 
        _myVouchers = vouchers ?? [];
      });
    } catch (e) {
      debugPrint('⚠️ Lỗi tải dữ liệu: $e');
    }
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

  @override
  Widget build(BuildContext context) {
    final cart = CartScope.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBar(title: 'Thanh toán', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserCard(),
            const SizedBox(height: 14),
            _buildItemsCard(cart),
            const SizedBox(height: 14),
            _buildPaymentCard(),
            const SizedBox(height: 14),
            _buildVoucherAndOptionsCard(), 
            const SizedBox(height: 14),
            _buildSummaryCard(cart),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context, cart),
    );
  }

  Widget _buildUserCard() {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _showUserInfo = !_showUserInfo),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: const Text('MH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_nameCtrl.text.toUpperCase(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                        const SizedBox(height: 2),
                        Text('MSSV: 2151010088 • Trợ giá SV 2025', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color)),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _showUserInfo ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).textTheme.bodyMedium?.color, size: 26),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, color: _border),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildField('Họ tên', Icons.person_outline, _nameCtrl)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildField('Số điện thoại', Icons.phone_outlined, _phoneCtrl)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('Giờ nhận món', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _timeSlot,
                    isExpanded: true,
                    decoration: _inputDeco(Icons.access_time),
                    hint: Text('-- Chọn khung giờ --', style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color)),
                    items: _timeSlots.map<DropdownMenuItem<String>>((slot) {
                      final disabled = slot['disabled'] as bool;
                      return DropdownMenuItem<String>(
                        value: disabled ? null : slot['value'] as String,
                        enabled: !disabled,
                        child: Text(disabled ? '${slot['label']} (đã qua)' : slot['label'] as String,
                            style: TextStyle(fontSize: 14, color: disabled ? Colors.grey[400] : Theme.of(context).textTheme.bodyLarge?.color)),
                      );
                    }).toList(),
                    onChanged: (v) { if (v != null) setState(() => _timeSlot = v); },
                  ),
                ],
              ),
            ),
            crossFadeState: _showUserInfo ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, size: 18, color: Theme.of(context).textTheme.bodyMedium?.color),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
      filled: true,
      fillColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  Widget _buildField(String label, IconData icon, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
        const SizedBox(height: 6),
        TextField(controller: ctrl, decoration: _inputDeco(icon)),
      ],
    );
  }

  Widget _buildItemsCard(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Món đã chọn (${cart.items.length})', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
          const SizedBox(height: 8),
          ...cart.items.map((it) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(child: Text(it.name, style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color))),
                Text('x${it.quantity}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPaymentCard() {
    final methods = [
      {'icon': Icons.account_balance_wallet, 'color': _primary, 'title': 'Ví VWA Pay', 'subtitle': 'Số dư: ${_fmt(_vwaBalance)}'},
      {'icon': Icons.qr_code_2, 'color': _purple, 'title': 'Mã VietQR', 'subtitle': 'Quét mã tại quầy'},
      {'icon': Icons.payments_outlined, 'color': _oceanBlue, 'title': 'Tiền mặt', 'subtitle': 'Thanh toán tại quầy'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Phương thức thanh toán', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
          const SizedBox(height: 12),
          ...List.generate(methods.length, (i) {
            final m = methods[i];
            final active = _payMethod == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => setState(() => _payMethod = i),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: active ? _oceanBlue.withValues(alpha: 0.04) : Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: active ? _oceanBlue : _border, width: active ? 1.5 : 1),
                  ),
                  child: Row(
                    children: [
                      Icon(m['icon'] as IconData, color: m['color'] as Color, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m['title'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
                            Text(m['subtitle'] as String, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color)),
                          ],
                        ),
                      ),
                      if (active) const Icon(Icons.check_circle, color: _oceanBlue, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildVoucherAndOptionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.confirmation_number_outlined, color: _primary, size: 20),
              const SizedBox(width: 8),
              Text('Voucher & Ưu đãi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _voucherCtrl,
                  decoration: _inputDeco(Icons.local_offer_outlined).copyWith(hintText: 'Nhập mã voucher'),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final code = _voucherCtrl.text.trim().toUpperCase();
                  int discount = 0;
                  if (code == 'VWA10') discount = 5000;
                  if (code == 'VWA20') discount = 10000;
                  setState(() => _voucherDiscount = discount);
                },
                style: ElevatedButton.styleFrom(backgroundColor: _oceanBlue),
                child: const Text('Áp dụng', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const Divider(height: 24, color: _border),
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: Color(0xFFFFB300), size: 22),
              const SizedBox(width: 10),
              Expanded(child: Text('Dùng $_vwaXu VWA Xu', style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color))),
              Switch(
                value: _useVwaXu,
                activeColor: _oceanBlue, 
                onChanged: (val) => setState(() => _useVwaXu = val),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.eco_rounded, color: _oceanBlue, size: 22), 
              const SizedBox(width: 10),
              Expanded(child: Text('Mang hộp cơm/ bình nước', style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color))),
              Switch(
                value: _useGreen,
                activeColor: _oceanBlue, 
                onChanged: (val) => setState(() => _useGreen = val),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(CartProvider cart) {
    final total = cart.totalPrice;
    int pointsDiscount = _useVwaXu ? _vwaXu : 0; 
    if (pointsDiscount > total) pointsDiscount = total;
    final finalTotal = (total - pointsDiscount - _voucherDiscount).clamp(0, 1 << 31);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Tổng tiền hàng'), Text(_fmt(total))]),
          if (_voucherDiscount > 0) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Giảm giá voucher'), Text('-${_fmt(_voucherDiscount)}', style: const TextStyle(color: _oceanBlue))]),
          if (pointsDiscount > 0) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Điểm VWA Xu'), Text('-${_fmt(pointsDiscount)}', style: const TextStyle(color: _oceanBlue))]),
          const Divider(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('TỔNG THANH TOÁN', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(_fmt(finalTotal), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _primary)),
          ]),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, CartProvider cart) {
    final total = cart.totalPrice;
    int pointsDiscount = _useVwaXu ? _vwaXu : 0;
    if (pointsDiscount > total) pointsDiscount = total;
    final finalTotal = (total - pointsDiscount - _voucherDiscount).clamp(0, 1 << 31);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -2))]),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Tổng cộng', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color)),
                  Text(_fmt(finalTotal), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _oceanBlue)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _loading ? null : () => _submitOrder(cart, finalTotal),
              style: ElevatedButton.styleFrom(backgroundColor: _oceanBlue, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
              child: _loading 
                ? const CircularProgressIndicator(color: Colors.white) 
                : const Text('Đặt hàng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitOrder(CartProvider cart, int finalTotal) async {
    if (_timeSlot == null) {
      _showError('Vui lòng chọn khung giờ nhận món');
      return;
    }
    setState(() => _loading = true);

    try {
      final orderItems = cart.items.map((it) => {
        'menuItem': it.id,
        'qty': it.quantity,
        'size': it.size,
        // 🔥 FIX LỖI EP KIỂU TOPPINGS
        'toppings': it.toppings.map((t) => (t as Map<String, dynamic>)['_id'] ?? t).toList(),
      }).toList();

      final result = await Api.createOrder(
        items: orderItems,
        payment: _payMethod == 0 ? 'Ví Canteen' : 'Tiền mặt',
        note: _noteCtrl.text,
        discount: _voucherDiscount,
        voucherCode: _voucherCtrl.text.trim().isNotEmpty ? _voucherCtrl.text.trim() : null,
        isGreen: _useGreen,
      );

      if (!mounted) return;
      setState(() => _loading = false);

      if (result['ok'] == true) {
        cart.clearCart();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => OrderSuccessScreen(order: result['order'], timeSlot: _timeSlot, note: '', phone: '')),
        );
      } else {
        _showError(result['message']);
      }
    } catch (e) {
      setState(() => _loading = false);
      _showError('Lỗi: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }
}