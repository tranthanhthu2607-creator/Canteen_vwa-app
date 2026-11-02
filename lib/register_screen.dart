// ============================================================
// REGISTER SCREEN — Đăng ký tài khoản (Có hiệu ứng động)
// ============================================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'api.dart';

// Màu sắc chủ đạo
const Color kOceanBanner = Color(0xFF1E88E5); 
const Color kOceanBtn = Color(0xFF005BAA);    
const Color kTextPrimary = Color(0xFF172033);
const Color kTextMuted = Color(0xFF64748B);
const Color kBorder = Color(0xFFE5E9EF);
const Color kRed = Color(0xFFEF4444);
const Color kBgLight = Color(0xFFF8FAFC);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _mssvCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirmPass = true;
  bool _agreeTerms = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _mssvCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  // ============================================================
  // HÀM XỬ LÝ ĐĂNG KÝ (ĐÃ FIX GỌI API THẬT)
  // ============================================================
  Future<void> _submitRegister() async {
    // 1. Validate dữ liệu đầu vào
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim().toLowerCase();
    final phone = _phoneCtrl.text.trim();
    final mssv = _mssvCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final confirmPass = _confirmPassCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || pass.isEmpty || confirmPass.isEmpty) {
      setState(() => _error = 'Vui lòng nhập đầy đủ thông tin bắt buộc (*)');
      return;
    }
    
    // Regex kiểm tra email
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _error = 'Email không hợp lệ');
      return;
    }

    if (phone.isNotEmpty && (phone.length < 10 || phone.length > 11)) {
      setState(() => _error = 'Số điện thoại phải từ 10-11 số');
      return;
    }

    if (pass.length < 6) {
      setState(() => _error = 'Mật khẩu phải từ 6 ký tự');
      return;
    }

    if (pass != confirmPass) {
      setState(() => _error = 'Mật khẩu xác nhận không khớp!');
      return;
    }

    if (!_agreeTerms) {
      setState(() => _error = 'Bạn cần đồng ý với Điều khoản & Chính sách');
      return;
    }

    // 2. Bắt đầu gọi API
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Chuẩn bị payload gửi lên Backend
      final payload = {
        'name': name,
        'email': email,
        'phone': phone,
        'password': pass,
      };
      // Nếu có MSSV thì gửi thêm
      if (mssv.isNotEmpty) {
        payload['student_code'] = mssv;
      }

      // 🔥 GỌI API ĐĂNG KÝ THẬT
      final result = await Api.register(payload);

      if (!mounted) return;
      setState(() => _loading = false);

      // Backend thường trả về { ok: true, token: '...', user: {...} }
      // hoặc { token: '...', user: {...} } tùy bạn thiết kế
      if (result['ok'] == true || result['token'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Đăng ký thành công! Vui lòng đăng nhập.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Quay lại màn hình đăng nhập
        Navigator.pop(context);
      } else {
        // Nếu API trả về lỗi (ví dụ: Email đã tồn tại)
        setState(() {
          _error = result['message'] ?? 'Đăng ký thất bại. Vui lòng thử lại.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Lỗi kết nối: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ==========================================
            // 1. BANNER XANH VỚI HIỆU ỨNG ĐỘNG (Giữ nguyên)
            // ==========================================
            Container(
              height: screenHeight * 0.28, 
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                child: Stack(
                  children: [
                    const Positioned(top: 10, left: -40, child: _MovingCloud(size: 100, speed: 0.1)),
                    const Positioned(top: 60, right: -60, child: _MovingCloud(size: 140, speed: 0.15)),
                    Positioned(top: -20, right: -20, child: _buildCircle(120, Colors.white.withOpacity(0.08))),
                    Positioned(bottom: -30, left: 20, child: _buildCircle(100, Colors.white.withOpacity(0.05))),
                    Positioned(
                      left: 0, right: 0, top: 30,
                      child: Column(
                        children: [
                          Container(
                            width: 60, height: 60,
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3))]),
                            child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.asset('assets/LOGO.jpg', fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.school, size: 25, color: kOceanBtn))),
                          ),
                          const SizedBox(height: 8),
                          const Text('CANTEEN VWA', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                          const Text('HỌC VIỆN PHỤ NỮ VN', style: TextStyle(color: Color(0xFF90CAF9), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                        ],
                      ),
                    ),
                    Positioned(bottom: 70, left: 30, child: _FloatingIcon(icon: Icons.cake, size: 22, delay: 0.5)),
                    Positioned(bottom: 30, left: 80, child: _FloatingIcon(icon: Icons.fastfood, size: 26, delay: 1.5)),
                    Positioned(top: 40, right: 30, child: _FloatingIcon(icon: Icons.local_cafe, size: 24, delay: 0)),
                    Positioned(top: 90, right: 70, child: _FloatingIcon(icon: Icons.lunch_dining, size: 30, delay: 1)),
                    Positioned(bottom: 40, right: 30, child: _FloatingIcon(icon: Icons.icecream, size: 20, delay: 2)),
                    Positioned(top: 60, left: 150, child: _TwinklingStar(delay: 0.2)),
                    Positioned(top: 120, right: 120, child: _TwinklingStar(delay: 0.8)),
                    Positioned(bottom: 50, left: 150, child: _TwinklingStar(delay: 1.2)),
                  ],
                ),
              ),
            ),

            // ==========================================
            // 2. FORM ĐĂNG KÝ
            // ==========================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Center(child: Text('Tạo tài khoản mới', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kTextPrimary))),
                  const SizedBox(height: 8),
                  const Center(child: Text('Đăng ký miễn phí — chỉ mất 30 giây.', style: TextStyle(fontSize: 14, color: kTextMuted))),
                  const SizedBox(height: 24),

                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: kRed.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(_error!, style: const TextStyle(color: kRed, fontSize: 13)),
                    ),
                    const SizedBox(height: 16),
                  ],

                  _buildField(controller: _nameCtrl, label: 'Họ và tên', hint: 'Nguyễn Văn A', icon: Icons.person_outline, isRequired: true),
                  const SizedBox(height: 16),
                  _buildField(controller: _emailCtrl, label: 'Email', hint: 'email@vwa.vn', icon: Icons.email_outlined, isRequired: true, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _buildField(controller: _phoneCtrl, label: 'Số điện thoại', hint: '0901234567', icon: Icons.phone_outlined, isRequired: false, keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  _buildField(controller: _mssvCtrl, label: 'Mã số sinh viên (MSSV)', hint: 'VD: 2374820202', icon: Icons.school_outlined, isRequired: false),
                  const SizedBox(height: 16),
                  _buildField(controller: _passCtrl, label: 'Mật khẩu', hint: 'Tối thiểu 6 ký tự', icon: Icons.lock_outline, isRequired: true, isPassword: true, obscureText: _obscurePass, onToggleVisibility: () => setState(() => _obscurePass = !_obscurePass)),
                  const SizedBox(height: 16),
                  _buildField(controller: _confirmPassCtrl, label: 'Xác nhận mật khẩu', hint: 'Nhập lại mật khẩu', icon: Icons.check, isRequired: true, isPassword: true, obscureText: _obscureConfirmPass, onToggleVisibility: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass)),
                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 24, height: 24, child: Checkbox(value: _agreeTerms, onChanged: (val) => setState(() => _agreeTerms = val ?? false), activeColor: kOceanBtn, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)))),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: 'Tôi đồng ý với ',
                            style: TextStyle(fontSize: 13, color: kTextMuted),
                            children: [
                              TextSpan(text: 'Điều khoản & Chính sách', style: TextStyle(color: kOceanBtn, fontWeight: FontWeight.bold)),
                              TextSpan(text: ' của Canteen VWA'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submitRegister,
                      style: ElevatedButton.styleFrom(backgroundColor: kOceanBtn, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                      child: _loading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Đăng ký', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)), SizedBox(width: 8), Icon(Icons.arrow_forward, color: Colors.white, size: 20)]),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Row(children: [Expanded(child: Divider(color: kBorder)), Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('HOẶC ĐĂNG KÝ VỚI', style: TextStyle(fontSize: 11, color: kTextMuted, fontWeight: FontWeight.bold))), Expanded(child: Divider(color: kBorder))]),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_buildSocialButton(Icons.g_mobiledata, Colors.red), _buildSocialButton(Icons.facebook, Colors.blue), _buildSocialButton(Icons.grid_view, Colors.orange)]),
                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Đã có tài khoản? ', style: TextStyle(fontSize: 14, color: kTextMuted)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text('Đăng nhập ngay', style: TextStyle(fontSize: 14, color: kOceanBtn, fontWeight: FontWeight.bold)),
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
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isRequired,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87),
            children: [if (isRequired) const TextSpan(text: ' *', style: TextStyle(color: kRed))],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: kTextMuted, fontSize: 14),
            prefixIcon: Icon(icon, color: kTextMuted, size: 20),
            suffixIcon: isPassword
                ? IconButton(icon: Icon(obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: kTextMuted, size: 20), onPressed: onToggleVisibility)
                : null,
            filled: true,
            fillColor: kBgLight,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kOceanBtn, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(IconData icon, Color color) {
    return Container(
      width: 80,
      height: 48,
      decoration: BoxDecoration(border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color, size: 28),
    );
  }
}

// ============================================================
// CÁC WIDGET HIỆU ỨNG ĐỘNG (COPY TỪ LOGIN)
// ============================================================
Widget _buildCircle(double size, Color color) {
  return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}

class _MovingCloud extends StatefulWidget {
  final double size;
  final double speed;
  const _MovingCloud({required this.size, required this.speed});

  @override
  State<_MovingCloud> createState() => _MovingCloudState();
}

class _MovingCloudState extends State<_MovingCloud> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _animation = Tween<double>(begin: -100, end: 500).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_animation.value * widget.speed, 0),
          child: Icon(Icons.cloud, size: widget.size, color: Colors.white.withOpacity(0.1)),
        );
      },
    );
  }
}

class _FloatingIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final double delay;
  const _FloatingIcon({required this.icon, required this.size, required this.delay});

  @override
  State<_FloatingIcon> createState() => _FloatingIconState();
}

class _FloatingIconState extends State<_FloatingIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 2000 + (widget.delay * 500).toInt()))..repeat(reverse: true);
    _animation = Tween<double>(begin: -10, end: 10).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Opacity(opacity: 0.3, child: Icon(widget.icon, size: widget.size, color: Colors.white)),
        );
      },
    );
  }
}

class _TwinklingStar extends StatefulWidget {
  final double delay;
  const _TwinklingStar({required this.delay});

  @override
  State<_TwinklingStar> createState() => _TwinklingStarState();
}

class _TwinklingStarState extends State<_TwinklingStar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.2, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(opacity: _animation.value, child: const Icon(Icons.star, color: Colors.yellow, size: 12));
      },
    );
  }
}