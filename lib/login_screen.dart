// ============================================================
// LOGIN SCREEN — BẢN HOÀN THIỆN (Đã fix nút Social)
// ============================================================
import 'package:flutter/material.dart';
import 'api.dart';
import 'package:flutter_lucide_animated/flutter_lucide_animated.dart';
import 'register_screen.dart';

// ============================================================
// MÀU SẮC
// ============================================================
const Color kOceanBanner = Color(0xFF1E88E5); 
const Color kOceanBtn = Color(0xFF005BAA);    
const Color kTextPrimary = Color(0xFF172033);
const Color kTextMuted = Color(0xFF64748B);
const Color kBorder = Color(0xFFE5E9EF);
const Color kRed = Color(0xFFEF4444);
const Color kBgLight = Color(0xFFF8FAFC);

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const LoginScreen({super.key, this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _loading = false;
  bool _rememberMe = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final result = await Api.login(email, password);

    if (!mounted) return;

    if (result['ok'] == true) {
      final user = result['data']['user'];
      setState(() => _loading = false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          Future.delayed(const Duration(milliseconds: 2000), () {
            if (mounted) {
              Navigator.of(ctx).pop();
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  widget.onLoginSuccess?.call();
                }
              });
            }
          });

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(horizontal: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LucideAnimatedIcon(
                    icon: check,
                    size: 60,
                    color: kOceanBtn,
                    trigger: AnimationTrigger.loop,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Xin chào ${user['name']}!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text('Đăng nhập thành công', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: kTextMuted)),
                ],
              ),
            ),
          );
        },
      );
    } else {
      setState(() {
        _loading = false;
        _error = result['message'] ?? 'Đăng nhập thất bại';
      });
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
            // 1. PHẦN TRÊN: BANNER XANH
            // ==========================================
            Container(
              height: screenHeight * 0.32, 
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
                      left: 20,
                      top: 25,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 55,
                            height: 55,
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3))],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/LOGO.jpg',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(Icons.school, size: 25, color: kOceanBtn),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CANTEEN VWA',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'HỌC VIỆN PHỤ NỮ VN',
                                style: TextStyle(color: Color(0xFF90CAF9), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                              ),
                            ],
                          ),
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

                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: _MovingCartAcrossScreen(screenWidth: screenWidth),
                    ),
                  ],
                ),
              ),
            ),

            // ==========================================
            // 2. PHẦN DƯỚI: FORM ĐĂNG NHẬP
            // ==========================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10), 

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(hint: 'Email', icon: Icons.mail_outline),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
                      decoration: _inputDecoration(hint: 'Mật khẩu', icon: Icons.lock_outline, isPassword: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                        if (v.length < 6) return 'Mật khẩu ít nhất 6 ký tự';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                activeColor: kOceanBtn,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                side: const BorderSide(color: kBorder, width: 1.5),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('Ghi nhớ 7 ngày', style: TextStyle(fontSize: 13, color: kTextMuted)),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Chức năng đang phát triển'), behavior: SnackBarBehavior.floating),
                            );
                          },
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          child: const Text('Quên mật khẩu?', style: TextStyle(fontSize: 13, color: kOceanBtn, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: kRed.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: kRed.withOpacity(0.3))),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: kRed, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error!, style: const TextStyle(fontSize: 13, color: kRed, fontWeight: FontWeight.w600))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kOceanBtn,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: kOceanBtn.withValues(alpha: 0.6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Đăng nhập', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward, size: 20, color: Colors.white),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ===== HOẶC TIẾP TỤC VỚI =====
                    Row(
                      children: [
                        Expanded(child: Divider(color: kBorder)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('HOẶC TIẾP TỤC VỚI', style: TextStyle(fontSize: 12, color: kTextMuted, fontWeight: FontWeight.bold)),
                        ),
                        Expanded(child: Divider(color: kBorder)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 🔥 3 NÚT SOCIAL (ĐÃ THÊM LẠI)
                    Row(
                      children: [
                        Expanded(
                          child: _buildSocialButton(
                            iconWidget: const Icon(Icons.g_mobiledata, color: Colors.red, size: 32),
                            label: '',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSocialButton(
                            iconWidget: const Icon(Icons.facebook, color: Colors.blue, size: 28),
                            label: '',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSocialButton(
                            iconWidget: const Icon(Icons.window, color: Colors.orange, size: 28),
                            label: '',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // ===== CHUYỂN SANG ĐĂNG KÝ =====
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Chưa có tài khoản? ", style: TextStyle(fontSize: 14, color: kTextMuted)),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            );
                          },
                          child: const Text('Đăng ký ngay', style: TextStyle(fontSize: 14, color: kOceanBtn, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ===== TÀI KHOẢN DEMO =====
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _emailController.text = 'sinhvien@vwa.vn';
                            _passwordController.text = '123456';
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã điền tài khoản Demo!'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)),
                          );
                        },
                        icon: const Icon(Icons.vpn_key_outlined, size: 18, color: Color(0xFFF59E0B)),
                        label: const Text('Tài khoản demo', style: TextStyle(fontSize: 14, color: kTextMuted)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon, bool isPassword = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: kTextMuted, fontSize: 14),
      prefixIcon: Icon(icon, color: kTextMuted, size: 20),
      suffixIcon: isPassword
          ? IconButton(
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: kTextMuted, size: 20),
            )
          : null,
      filled: true,
      fillColor: kBgLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kOceanBtn, width: 1.5)),
    );
  }

  Widget _buildSocialButton({required Widget iconWidget, required String label}) {
    return Container(
      height: 50,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconWidget,
          if (label.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTextPrimary)),
          ]
        ],
      ),
    );
  }
}

// ============================================================
// CÁC WIDGET TRANG TRÍ & HIỆU ỨNG
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
    super.initState(); // ✅ Gọi super trước
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
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000 + (widget.delay * 500).toInt()),
    )..repeat(reverse: true);
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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.2, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: const Icon(Icons.star, color: Colors.yellow, size: 12),
        );
      },
    );
  }
}

class _MovingCartAcrossScreen extends StatefulWidget {
  final double screenWidth;
  const _MovingCartAcrossScreen({required this.screenWidth});

  @override
  State<_MovingCartAcrossScreen> createState() => _MovingCartAcrossScreenState();
}

class _MovingCartAcrossScreenState extends State<_MovingCartAcrossScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animationX;
  late Animation<double> _animationY;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
    _animationX = Tween<double>(begin: -100, end: widget.screenWidth + 100).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
    _animationY = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -5), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -5, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_animationX.value, _animationY.value),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shopping_cart, color: Colors.white, size: 70),
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 20),
                child: Row(
                  children: [
                    Container(width: 25, height: 3, color: Colors.white.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    Container(width: 15, height: 3, color: Colors.white.withOpacity(0.3)),
                    const SizedBox(width: 4),
                    Container(width: 8, height: 3, color: Colors.white.withOpacity(0.1)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}