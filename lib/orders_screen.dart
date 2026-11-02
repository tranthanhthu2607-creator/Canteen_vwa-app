// ============================================================
// ORDERS SCREEN — Bản Full (Auto Sort & Auto Reload)
// ============================================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'api.dart';
import 'custom_app_bar.dart';
import 'main.dart'; // Import để lấy routeObserver

// ============================================================
// MÀU SẮC
// ============================================================
const Color kBlue = Color(0xFF2563EB);
const Color kBg = Color(0xFFF9FAFB);
const Color kTextPrimary = Color(0xFF172033);
const Color kTextMuted = Color(0xFF64748B);
const Color kGreen = Color(0xFF18A967);
const Color kOrange = Color(0xFFF59E0B);
const Color kRed = Color(0xFFEF4444);
const Color kBorder = Color(0xFFE5E9EF);
const Color kBlueLight = Color(0xFFEFF6FF);

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with WidgetsBindingObserver, RouteAware {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _orders = [];
  Timer? _pollingTimer;

  int _tabIndex = 0; 
  
  final List<String> _tabs = [
    'Tất cả đơn',
    'Đang chuẩn bị',
    'Chờ nhận món',
    'Đã hoàn thành',
    'Đã hủy'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadOrders();
    _startPolling(); 
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    _pollingTimer?.cancel(); 
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadOrders(silent: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadOrders(silent: true);
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) _loadOrders(silent: true);
    });
  }

  Future<void> _loadOrders({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    if (!Api.isLoggedIn) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Bạn chưa đăng nhập';
        });
      }
      return;
    }

    try {
      final data = await Api.getMyOrders();

      if (!mounted) return;

      List<Map<String, dynamic>> newOrders = List<Map<String, dynamic>>.from(data);
      newOrders.sort((a, b) {
        final dateA = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      setState(() {
        _orders = newOrders;
        _loading = false;
        if (data.isEmpty) _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Lỗi tải đơn hàng: $e';
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    if (_tabIndex == 0) return _orders;
    final target = _tabs[_tabIndex];
    return _orders.where((o) {
      final status = o['status']?.toString().toLowerCase() ?? '';
      
      if (target == 'Đang chuẩn bị') {
        return status.contains('chuẩn bị') || status.contains('xác nhận') || status.contains('chờ');
      }
      if (target == 'Chờ nhận món') {
        return status.contains('sẵn sàng');
      }
      if (target == 'Đã hoàn thành') {
        return status.contains('hoàn thành') || status.contains('xong');
      }
      if (target == 'Đã hủy') {
        return status.contains('hủy');
      }
      return true;
    }).toList();
  }

  int _getCountForTab(int index) {
    if (index == 0) return _orders.length;
    final target = _tabs[index];
    return _orders.where((o) {
      final status = o['status']?.toString().toLowerCase() ?? '';
      if (target == 'Đang chuẩn bị') return status.contains('chuẩn bị') || status.contains('xác nhận') || status.contains('chờ');
      if (target == 'Chờ nhận món') return status.contains('sẵn sàng');
      if (target == 'Đã hoàn thành') return status.contains('hoàn thành') || status.contains('xong');
      if (target == 'Đã hủy') return status.contains('hủy');
      return false;
    }).length;
  }

  Future<void> _cancelOrder(dynamic orderId) async {
    try {
      final res = await Api.cancelOrder(orderId);
      if (res['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hủy đơn hàng thành công'), backgroundColor: kGreen),
        );
        _loadOrders(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Hủy đơn thất bại'), backgroundColor: kRed),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối: $e'), backgroundColor: kRed),
      );
    }
  }

  Future<void> _remindOrder(dynamic orderId, bool enabled) async {
    try {
      final res = await Api.remindOrder(orderId, enabled: enabled);
      if (res['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enabled ? 'Đã đặt nhắc nhở khi món sẵn sàng' : 'Đã hủy nhắc nhở'),
            backgroundColor: kBlue,
          ),
        );
      }
    } catch (e) {
      debugPrint('Lỗi nhắc đơn: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Đơn Hàng',
        showBackButton: false, 
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: _loading && _orders.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: kBlue))
                  : _error != null
                      ? _buildError()
                      : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(_tabs.length, (index) {
            final isActive = index == _tabIndex;
            final count = _getCountForTab(index);

            return GestureDetector(
              onTap: () => setState(() => _tabIndex = index),
              child: Container(
                margin: const EdgeInsets.only(right: 24),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? kGreen : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  '${_tabs[index]}${count > 0 ? " ($count)" : ""}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    color: isActive 
                        ? Theme.of(context).textTheme.bodyLarge?.color 
                        : Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final orders = _filteredOrders;

    if (orders.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _loadOrders(),
      color: kBlue,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(orders[index]);
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final items = (order['items'] as List?) ?? [];
    final code = order['code'] ?? order['_id'] ?? '#N/A';
    final total = order['total'] as int? ?? 0;
    final discount = order['discount'] as int? ?? 0;
    final originalTotal = total + discount;
    final status = order['status']?.toString() ?? 'Chờ xác nhận';
    
    final pin = order['pickup_pin']?.toString() ?? (code.length >= 2 ? code.substring(code.length - 2).toUpperCase() : '—');

    // 🔥 KIỂM TRA SỐNG XANH
    final isGreen = order['isGreen'] == true;
    final greenStatus = order['green_status']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#$code',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                          const SizedBox(width: 4),
                          Text(_formatDate(order['created_at']), style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color)),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusPill(status),
              ],
            ),
          ),

          const Divider(height: 1, color: kBorder),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DANH SÁCH MÓN ĐÃ GỌI',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.bodyMedium?.color),
                    ),
                    if (status.contains('sẵn sàng'))
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: kGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Row(
                          children: [
                            const Icon(Icons.qr_code, size: 14, color: kGreen),
                            const SizedBox(width: 4),
                            Text('Mã PIN: #$pin', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kGreen)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                ...items.map((item) {
                  final it = item as Map;
                  final itPrice = it['price'] as int? ?? 0;
                  final qty = it['qty'] ?? 1;
                  
                  String sizeText = '';
                  if (it['size'] != null) {
                    if (it['size'] is String) {
                      sizeText = 'Size: ${it['size']}';
                    } else if (it['size'] is Map) {
                      sizeText = 'Size: ${it['size']['name'] ?? it['size']['id'] ?? ''}';
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 60, height: 60,
                            child: it['image'] != null
                                ? Image.network(it['image'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildImageFallback())
                                : _buildImageFallback(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                it['name'] ?? 'Món ăn',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.bodyLarge?.color),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${qty}x suất ăn ${sizeText.isNotEmpty ? "• $sizeText" : ""}',
                                style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatPrice((itPrice * qty).toInt()), 
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Theme.of(context).textTheme.bodyLarge?.color),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          // 🔥 HIỂN THỊ TRẠNG THÁI SỐNG XANH (NẾU CÓ)
          if (isGreen) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: greenStatus == 'approved' 
                      ? kGreen.withOpacity(0.1) 
                      : (greenStatus == 'rejected' ? kRed.withOpacity(0.1) : kOrange.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: greenStatus == 'approved' 
                        ? kGreen 
                        : (greenStatus == 'rejected' ? kRed : kOrange),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      greenStatus == 'approved' 
                          ? Icons.check_circle 
                          : (greenStatus == 'rejected' ? Icons.cancel : Icons.hourglass_empty),
                      size: 14,
                      color: greenStatus == 'approved' 
                          ? kGreen 
                          : (greenStatus == 'rejected' ? kRed : kOrange),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      greenStatus == 'approved' 
                          ? 'Đã duyệt Sống Xanh (+${order['green_points'] ?? 10} Xu)'
                          : (greenStatus == 'rejected' 
                              ? 'Sống Xanh bị từ chối' 
                              : 'Chờ duyệt Sống Xanh'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: greenStatus == 'approved' 
                            ? kGreen 
                            : (greenStatus == 'rejected' ? kRed : kOrange),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                _buildPriceRow('Tổng giá niêm yết:', originalTotal),
                if (discount > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: kGreen, size: 14),
                          const SizedBox(width: 4),
                          Text('Hỗ trợ suất ăn sinh viên VWA:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyMedium?.color)),
                        ],
                      ),
                      Text(
                        '-${_formatPrice(discount)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kGreen),
                      ),
                    ],
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: kBorder),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: kGreen, size: 14),
                        const SizedBox(width: 4),
                        Text('Thực thanh toán:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.bodyLarge?.color)),
                      ],
                    ),
                    Text(
                      _formatPrice(total),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kBlue),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showOrderDetailBottomSheet(order), 
                      icon: Icon(Icons.receipt_long, size: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
                      label: Text('Chi tiết', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyLarge?.color)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        side: const BorderSide(color: kBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        backgroundColor: Theme.of(context).cardColor,
                      ),
                    ),
                    const SizedBox(width: 8),

                    OutlinedButton.icon(
                      onPressed: () => _showSupportChatBottomSheet(order), 
                      icon: Icon(Icons.headset_mic, size: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
                      label: Text('Hỗ trợ', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyLarge?.color)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        side: const BorderSide(color: kBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        backgroundColor: Theme.of(context).cardColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    if (status.contains('chờ') || status.contains('xác nhận'))
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _remindOrder(order['_id'] ?? order['id'] ?? '', true),
                          icon: const Icon(Icons.notifications_active, size: 18),
                          label: const Text('Báo tôi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    
                    if (status.contains('chờ')) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _confirmCancelOrder(order['_id'] ?? order['id'] ?? ''),
                          icon: const Icon(Icons.cancel, size: 18),
                          label: const Text('Hủy đơn', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kRed.withOpacity(0.1),
                            foregroundColor: kRed,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 4. BOTTOM SHEET CHI TIẾT (GIAO DIỆN HỦY ĐƠN MỚI)
  // ============================================================
  void _showOrderDetailBottomSheet(Map<String, dynamic> order) {
    final code = order['code'] ?? '#N/A';
    final status = order['status'] ?? 'Chờ xác nhận';
    final items = (order['items'] as List?) ?? [];
    final total = order['total'] as int? ?? 0;
    final note = order['note'] ?? '';
    
    final isCancelled = status.toLowerCase().contains('hủy');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40, height: 4,
                decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isCancelled ? const Color(0xFF10B981) : kBlue,
                        borderRadius: BorderRadius.circular(12)
                      ),
                      child: const Icon(Icons.inventory_2, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Chi tiết đơn hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Theme.of(context).textTheme.bodyLarge?.color)),
                          Text(code, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kBlue)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Theme.of(context).textTheme.bodyMedium?.color),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: kBorder),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isCancelled) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDECEC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.close_rounded, color: Colors.red.shade600, size: 40),
                              const SizedBox(height: 8),
                              Text(
                                'Đơn hàng đã bị hủy',
                                style: TextStyle(
                                  color: Colors.red.shade800,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ] else ...[
                        _buildCircularTimeline(status),
                        const SizedBox(height: 24),
                      ],

                      _buildInfoRow('Thời gian đặt hàng', _formatDate(order['created_at']), isToday: true),
                      _buildInfoRow('Trạng thái', status, isStatus: !isCancelled),
                      _buildInfoRow('Phương thức thanh toán', order['payment'] ?? 'CARD'),
                      
                      const SizedBox(height: 24),
                      Text('Món đã đặt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.bodyLarge?.color)),
                      const SizedBox(height: 12),

                      ...items.map((item) {
                        final it = item as Map;
                        String sizeText = '';
                        if (it['size'] != null) {
                          if (it['size'] is String) {
                            sizeText = 'Size: ${it['size']}';
                          } else if (it['size'] is Map) {
                            sizeText = 'Size: ${it['size']['name'] ?? it['size']['id'] ?? ''}';
                          }
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${it['qty'] ?? 1} × ${it['name'] ?? 'Món'}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.bodyLarge?.color)),
                                  if (sizeText.isNotEmpty)
                                    Text(sizeText, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color)),
                                ],
                              ),
                              Text(_formatPrice((it['price'] as int? ?? 0) * (it['qty'] as int? ?? 1)), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.bodyLarge?.color)),
                            ],
                          ),
                        );
                      }).toList(),

                      const Divider(height: 32, color: kBorder),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tổng cộng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.bodyLarge?.color)),
                          Text(_formatPrice(total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kBlue)),
                        ],
                      ),
                      if (note.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [
                            Text('Ghi chú: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                            Expanded(child: Text(note, style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color))),
                          ]),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Theme.of(context).cardColor, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))]),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (status.contains('sẵn sàng'))
                        SizedBox(
                          width: double.infinity, height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final orderId = order['_id'] ?? order['id'];
                              final res = await Api.receiveOrder(orderId);
                              if (res['ok'] == true) {
                                Navigator.pop(context);
                                _loadOrders();
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xác nhận nhận món thành công!'), backgroundColor: kGreen));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Lỗi xác nhận'), backgroundColor: kRed));
                              }
                            },
                            icon: const Icon(Icons.check_circle, size: 20),
                            label: const Text('Xác nhận đã nhận món', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                          ),
                        ),
                      if (status.contains('hoàn thành'))
                        SizedBox(
                          width: double.infinity, height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chức năng đánh giá đang phát triển'), backgroundColor: kOrange));
                            },
                            icon: const Icon(Icons.star, size: 20),
                            label: const Text('Đánh giá đơn hàng (+300 điểm)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(backgroundColor: kOrange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                          ),
                        ),
                      if (status.contains('chờ'))
                        SizedBox(
                          width: double.infinity, height: 48,
                          child: OutlinedButton(
                            onPressed: () { Navigator.pop(context); _confirmCancelOrder(order['_id'] ?? order['id'] ?? ''); },
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: kRed, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: const Text('Hủy đơn hàng', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kRed)),
                          ),
                        ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity, height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: kBorder), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: Text('Đóng', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.bodyLarge?.color)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // 5. POPUP CHAT HỖ TRỢ
  // ============================================================
  void _showSupportChatBottomSheet(Map<String, dynamic> order) {
    final code = order['code'] ?? '#N/A';
    final status = order['status'] ?? 'Chờ xác nhận';
    final total = order['total'] as int? ?? 0;
    final items = (order['items'] as List?) ?? [];

    String itemSummary = items.map((item) {
      final name = item['name'] ?? 'Món ăn';
      final qty = item['qty'] ?? 1;
      return '$name x$qty';
    }).join(', ');

    final defaultMessage = 'Xin chào nhà hàng, mình cần hỗ trợ sớm về đơn #$code. '
        'Trạng thái: $status. '
        'Món: ${itemSummary.isNotEmpty ? itemSummary : "Vui lòng xem chi tiết đơn hàng"}. '
        'Tổng thanh toán: ${_formatPrice(total)}. '
        'Nhờ nhà hàng kiểm tra đơn này và phản hồi giúp mình sớm nhé.';

    final TextEditingController _msgCtrl = TextEditingController(text: defaultMessage);
    List<dynamic> _chatMessages = [];
    bool _isLoadingChat = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) { 
        return StatefulBuilder(
          builder: (context, setModalState) {
            
            Future<void> loadMessages() async {
              final msgs = await Api.getChatMessages();
              if (mounted) {
                setModalState(() {
                  _chatMessages = msgs;
                  _isLoadingChat = false;
                });
              }
            }

            if (_isLoadingChat) {
              loadMessages();
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.75,
                decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), border: const Border(bottom: BorderSide(color: kBorder))),
                      child: Row(
                        children: [
                          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: kBlue, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.headset_mic, color: Colors.white, size: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Nhân viên Canteen', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                                const Text('Đang mở ca trưa • Phản hồi < 1 phút', style: TextStyle(fontSize: 12, color: kGreen)),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              if (Navigator.canPop(sheetContext)) {
                                Navigator.pop(sheetContext);
                              }
                            }, 
                            icon: const Icon(Icons.close, color: kTextMuted)
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _isLoadingChat 
                          ? const Center(child: CircularProgressIndicator(color: kBlue))
                          : _chatMessages.isEmpty
                              ? const Center(child: Text('Chưa có tin nhắn nào. Hãy gửi yêu cầu hỗ trợ!', style: TextStyle(color: kTextMuted)))
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _chatMessages.length,
                                  itemBuilder: (context, index) {
                                    final msg = _chatMessages[index];
                                    final isCustomer = msg['from'] == 'customer';
                                    final content = msg['content'] ?? '';
                                    final time = _formatDate(msg['created_at']).split('•').last.trim();
                                    final senderName = msg['from_name'] ?? 'Nhân viên';

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: isCustomer
                                          ? Align(
                                              alignment: Alignment.centerRight,
                                              child: Container(
                                                padding: const EdgeInsets.all(12),
                                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                                decoration: const BoxDecoration(color: kBlue, borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(4), bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16))),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Text(content, style: const TextStyle(color: Colors.white, fontSize: 14)),
                                                    const SizedBox(height: 4),
                                                    Text(time, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                                                  ],
                                                ),
                                              ),
                                            )
                                          : Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                CircleAvatar(backgroundColor: kBlue, radius: 16, child: const Icon(Icons.headset_mic, size: 16, color: Colors.white)),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.all(12),
                                                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                                  decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(16), bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16))),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(senderName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kBlue)),
                                                      const SizedBox(height: 4),
                                                      Text(content, style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color)),
                                                      const SizedBox(height: 4),
                                                      Text(time, style: const TextStyle(fontSize: 10, color: kTextMuted)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                    );
                                  },
                                ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Theme.of(context).cardColor, border: const Border(top: BorderSide(color: kBorder))),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _msgCtrl,
                              maxLines: null,
                              decoration: InputDecoration(
                                hintText: 'Nhập tin nhắn...',
                                hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                                filled: true,
                                fillColor: Theme.of(context).scaffoldBackgroundColor,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: kBlue,
                            radius: 24,
                            child: IconButton(
                              icon: const Icon(Icons.send, color: Colors.white, size: 20),
                              onPressed: () async {
                                final content = _msgCtrl.text.trim();
                                if (content.isEmpty) return;
                                
                                _msgCtrl.clear();
                                final res = await Api.sendChatMessage(content);
                                
                                if (res != null) {
                                  loadMessages(); 
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Gửi tin nhắn thất bại. Vui lòng thử lại.'), backgroundColor: kRed),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCircularTimeline(String status) {
    int currentStep = 1; 
    final s = status.toLowerCase();
    if (s.contains('xác nhận')) currentStep = 2;
    if (s.contains('chuẩn bị') || s.contains('chế biến')) currentStep = 3;
    if (s.contains('sẵn sàng')) currentStep = 4;
    if (s.contains('hoàn thành')) currentStep = 5;

    final steps = [
      {'icon': Icons.access_time, 'label': 'Chờ xác nhận'},
      {'icon': Icons.check, 'label': 'Đã xác nhận'},
      {'icon': Icons.room_service, 'label': 'Đang chuẩn bị'},
      {'icon': Icons.notifications_active, 'label': 'Sẵn sàng'},
      {'icon': Icons.check_circle, 'label': 'Hoàn thành'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isDone = index < (currentStep - 1);
          final isActive = index == (currentStep - 1);
          final Color circleColor = (isDone || isActive) ? kGreen : kBorder;
          final Color iconColor = (isDone || isActive) ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color ?? kTextMuted;

          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Container(height: 2, color: index == 0 ? Colors.transparent : ((isDone || isActive) ? kGreen : kBorder))),
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: circleColor, border: Border.all(color: circleColor, width: 2)),
                      child: Icon(steps[index]['icon'] as IconData, size: 16, color: iconColor),
                    ),
                    Expanded(child: Container(height: 2, color: index == steps.length - 1 ? Colors.transparent : (isDone ? kGreen : kBorder))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  steps[index]['label'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.w500, color: isActive ? kGreen : (isDone ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).textTheme.bodyMedium?.color)),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  void _confirmCancelOrder(dynamic orderId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('Hủy đơn hàng?', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: Text('Bạn có chắc chắn muốn hủy đơn hàng này không?', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Không', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color))),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _cancelOrder(orderId); },
            style: ElevatedButton.styleFrom(backgroundColor: kRed),
            child: const Text('Hủy đơn', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg; Color fg; IconData icon;
    final s = status.toLowerCase();

    if (s.contains('chờ')) { bg = const Color(0xFFFEF3C7); fg = kOrange; icon = Icons.access_time; }
    else if (s.contains('xác nhận')) { bg = const Color(0xFFDBEAFE); fg = kBlue; icon = Icons.check_circle; }
    else if (s.contains('chuẩn bị')) { bg = const Color(0xFFEDE9FE); fg = const Color(0xFF8B5CF6); icon = Icons.restaurant; }
    else if (s.contains('sẵn sàng')) { bg = const Color(0xFFD1FAE5); fg = kGreen; icon = Icons.notifications_active; }
    else if (s.contains('hoàn thành') || s.contains('xong')) { bg = const Color(0xFFD1FAE5); fg = kGreen; icon = Icons.check_circle; }
    else if (s.contains('hủy')) { bg = const Color(0xFFFEE2E2); fg = kRed; icon = Icons.cancel; }
    else { bg = kBorder; fg = kTextMuted; icon = Icons.info; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isToday = false, bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color)),
          Text(
            value, 
            style: TextStyle(
              fontSize: 14, 
              fontWeight: FontWeight.w700, 
              color: isStatus ? kOrange : Theme.of(context).textTheme.bodyLarge?.color
            )
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, int price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyMedium?.color)),
        Text(_formatPrice(price), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyMedium?.color)),
      ],
    );
  }

  Widget _buildImageFallback() {
    return Container(color: kBorder, child: Icon(Icons.restaurant, color: Theme.of(context).textTheme.bodyMedium?.color, size: 24));
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 72, color: Theme.of(context).textTheme.bodyMedium?.color),
          const SizedBox(height: 16),
          Text('Chưa có đơn hàng nào', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.bodyLarge?.color)),
          const SizedBox(height: 6),
          Text('Các đơn hàng sẽ xuất hiện ở đây', style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 60, color: Theme.of(context).textTheme.bodyMedium?.color),
          const SizedBox(height: 12),
          Text(_error ?? 'Đã có lỗi xảy ra', style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadOrders, style: ElevatedButton.styleFrom(backgroundColor: kBlue), child: const Text('Thử lại')),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    final s = price.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf.toString()}đ';
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final dt = DateTime.parse(date.toString()).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return date.toString();
    }
  }
}