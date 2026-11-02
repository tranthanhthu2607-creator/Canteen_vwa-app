import 'package:flutter/material.dart';
import 'api.dart';

class WalletCardPopup extends StatefulWidget {
  final bool isLocked;
  final Function(bool) onLockStatusChanged;
  final String userName;
  final String studentId;

  const WalletCardPopup({
    super.key,
    required this.isLocked,
    required this.onLockStatusChanged,
    required this.userName,
    required this.studentId,
  });

  @override
  State<WalletCardPopup> createState() => _WalletCardPopupState();
}

class _WalletCardPopupState extends State<WalletCardPopup> {
  int _balance = 0;
  bool _isLoading = true;
  bool _localIsLocked = false;

  @override
  void initState() {
    super.initState();
    _localIsLocked = widget.isLocked;
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    final wallet = await Api.getWallet();
    if (mounted) {
      setState(() {
        _balance = (wallet?['balance'] ?? 0) as int;
        _isLoading = false;
      });
    }
  }

  String _formatMoney(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ';
  }

  void _showPinDialog() {
    final TextEditingController pinCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_localIsLocked ? 'Nhập PIN để mở khóa thẻ sinh viên:' : 'Nhập PIN để khóa thẻ sinh viên:'),
        content: TextField(
          controller: pinCtrl,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          decoration: const InputDecoration(
            hintText: 'Nhập mã PIN (6 số)',
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Gọi API kiểm tra PIN thực tế
              // Ở đây giả lập PIN là "123456"
              if (pinCtrl.text == '123456') {
                Navigator.pop(ctx);
                setState(() {
                  _localIsLocked = !_localIsLocked;
                });
                widget.onLockStatusChanged(_localIsLocked);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_localIsLocked ? 'Đã khóa thẻ!' : 'Đã mở khóa thẻ!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mã PIN không đúng!'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.credit_card, size: 24, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ví VWA & Thẻ sinh viên', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Số dư, liên kết ngân hàng, mã PIN', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            const Divider(height: 1),

            // Nội dung
            Padding(
              padding: const EdgeInsets.all(16),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        // Thẻ số dư
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('SỐ DƯ VÍ VWA PAY', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(_formatMoney(_balance), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _localIsLocked ? null : () {}, // TODO: Nạp tiền
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(0xFF2563EB),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text('+ Nạp tiền'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _localIsLocked ? null : () {}, // TODO: Xem chi tiết
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(color: Colors.white),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text('Xem chi tiết →'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Thẻ sinh viên
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.credit_card, color: Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Thẻ sinh viên VWA', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text('${widget.studentId} • ${widget.userName}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _localIsLocked ? Colors.red.withOpacity(0.1) : Colors.amber.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _localIsLocked ? 'Thẻ đang khóa' : 'Thẻ đang hoạt động',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: _localIsLocked ? Colors.red : Colors.amber.shade800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: _showPinDialog,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _localIsLocked ? const Color(0xFF10B981) : Colors.red,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(100, 32),
                                    ),
                                    child: Text(_localIsLocked ? 'Mở khóa thẻ' : 'Khóa thẻ'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Ngân hàng liên kết
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.security, color: Colors.blue),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Tài khoản ngân hàng liên kết', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text('MBB • 0328866959', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                child: const Text('Đã liên kết', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Nút Đến trang Ví
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.wallet),
                            label: const Text('Đến trang Ví Canteen'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            // Bottom Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Quay lại')),
                  const SizedBox(width: 12),
                  ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Xong')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}