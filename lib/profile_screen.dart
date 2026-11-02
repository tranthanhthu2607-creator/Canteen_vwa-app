// ============================================================
// PROFILE SCREEN — Giao diện Tài khoản (Đồng bộ hạng theo chi tiêu)
// ============================================================
import 'dart:io';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api.dart';
import 'login_screen.dart';
import 'custom_app_bar.dart';
import 'app_localizations.dart'; 
import 'wallet_screen.dart';
import 'edit_profile_screen.dart'; // 🔥 Đã import màn hình Hồ sơ mới

const Color pBlue = Color(0xFF2563EB);
const Color pBg = Color(0xFFF9FAFB);
const Color pTextPrimary = Color(0xFF172033);
const Color pTextMuted = Color(0xFF64748B);
const Color pBorder = Color(0xFFE5E9EF);

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  final ThemeMode themeMode;           
  final Function(ThemeMode) onChangeThemeMode; 
  
  final Locale locale;
  final Function(Locale) onChangeLocale;

  const ProfileScreen({
    super.key,
    this.onLogout,
    required this.themeMode,          
    required this.onChangeThemeMode,  
    required this.locale,             
    required this.onChangeLocale,     
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  int _totalSpent = 0;
  bool _loading = true;
  
  XFile? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = await Api.getMe();
    final spent = await Api.getTotalSpent(); 
    
    if (mounted) {
      setState(() {
        _user = user;
        _totalSpent = spent;
        _loading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _pickedImage = image;
        });
        _showSnack('Đã chọn ảnh mới!');
      }
    } catch (e) {
      _showSnack('Lỗi khi chọn ảnh: $e');
    }
  }

  // 🔥 Tính hạng dựa trên TỔNG CHI TIÊU
  Map<String, dynamic> _getMembershipTierBySpending(int totalSpent) {
    if (totalSpent >= 10000000) {
      return {
        'name': 'Kim Cương', 
        'tier': 4,
        'gradient': [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
        'icon': Icons.diamond,
        'nextSpend': 10000000,
      };
    } else if (totalSpent >= 3000000) {
      return {
        'name': 'Vàng', 
        'tier': 3,
        'gradient': [const Color(0xFFF59E0B), const Color(0xFFD97706)],
        'icon': Icons.stars,
        'nextSpend': 10000000,
      };
    } else if (totalSpent >= 1000000) {
      return {
        'name': 'Bạc', 
        'tier': 2,
        'gradient': [const Color(0xFF94A3B8), const Color(0xFF64748B)],
        'icon': Icons.workspace_premium,
        'nextSpend': 3000000,
      };
    } else {
      return {
        'name': 'Đồng', 
        'tier': 1,
        'gradient': [const Color(0xFFB87333), const Color(0xFF8B5A2B)], 
        'icon': Icons.military_tech,
        'nextSpend': 1000000, 
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator(color: pBlue)),
      );
    }

    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const Scaffold(body: Center(child: Text('Lỗi tải ngôn ngữ')));
    }

    final name = _user?['name'] ?? 'Người dùng';
    final phone = _user?['phone'] ?? 'Chưa có SĐT';
    final avatar = _user?['avatar'] ?? '';
    
    final tier = _getMembershipTierBySpending(_totalSpent);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: pBlue,
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CustomAppBar(
                    title: '', 
                    showBackButton: true,
                    customHeight: 160, 
                    themeMode: widget.themeMode,                 
                    onChangeThemeMode: widget.onChangeThemeMode, 
                    locale: widget.locale,                   
                    onChangeLocale: widget.onChangeLocale,   
                  ),
                  
                  Positioned(
                    top: 80, 
                    left: 16,
                    right: 16,
                    child: _ShinyMembershipCard(
                      name: name,
                      phone: phone,
                      totalSpent: _totalSpent,
                      avatar: avatar,
                      pickedImage: _pickedImage,
                      tier: tier,
                      nextTierName: _getNextTierName(tier['tier']),
                      onAvatarTap: _pickImage,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 130),

              // ===== DANH SÁCH MENU =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: pBorder), 
                  ),
                  child: Column(
                    children: [
                      // 1. Ngôn ngữ & Khu vực
                      _buildMenuItem(
                        icon: Icons.language,
                        iconColor: const Color(0xFF0891B2),
                        title: l10n.translate('language'), 
                        subtitle: widget.locale.languageCode == 'en' ? 'English' : 'Tiếng Việt',
                        trailing: Switch(
                          value: widget.locale.languageCode == 'en',
                          activeColor: pBlue,
                          onChanged: (val) {
                            final newLocale = Locale(val ? 'en' : 'vi');
                            widget.onChangeLocale(newLocale); 
                          },
                        ),
                        onTap: () {}, 
                      ),
                      const Divider(height: 1, color: pBorder),
                      
                      // 2. Ví VWA & Thẻ sinh viên
                      _buildMenuItem(
                        icon: Icons.credit_card,
                        iconColor: const Color(0xFF10B981),
                        title: 'Ví VWA & Thẻ sinh viên',
                        subtitle: 'Số dư, liên kết ngân hàng, mã PIN',
                        badge: 'PIN',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const WalletScreen()),
                          );
                        },
                      ),
                      const Divider(height: 1, color: pBorder),

                      // 3. Đổi mật khẩu
                      _buildMenuItem(
                        icon: Icons.security,
                        iconColor: const Color(0xFF6366F1),
                        title: 'Đổi mật khẩu',
                        subtitle: 'Cập nhật mật khẩu đăng nhập',
                        onTap: () => _showSnack('Chức năng đổi mật khẩu đang phát triển'),
                      ),
                      const Divider(height: 1, color: pBorder),
                      
                      // 4. Hồ sơ cá nhân (🔥 ĐÃ SỬA CHUYỂN TRANG)
                      _buildMenuItem(
                        icon: Icons.person_outline,
                        iconColor: const Color(0xFF8B5CF6),
                        title: 'Hồ sơ cá nhân',
                        subtitle: 'Xem và chỉnh sửa thông tin tài khoản',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                          );
                        },
                      ),
                      const Divider(height: 1, color: pBorder),
                      
                      // 5. Trợ giúp & Quy chế
                      _buildMenuItem(
                        icon: Icons.help_outline,
                        iconColor: const Color(0xFF64748B),
                        title: 'Trợ giúp & Quy chế',
                        subtitle: 'Câu hỏi thường gặp, quy định Canteen VWA',
                        onTap: () => _showSnack('Chức năng đang phát triển'),
                      ),
                      const Divider(height: 1, color: pBorder),
                      
                      // 6. Đăng xuất
                      _buildMenuItem(
                        icon: Icons.logout,
                        iconColor: Colors.red,
                        title: l10n.translate('logout'), 
                        titleColor: Colors.red,
                        onTap: _confirmLogout,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  String _getNextTierName(int currentTier) {
    if (currentTier == 1) return 'Bạc';
    if (currentTier == 2) return 'Vàng';
    if (currentTier == 3) return 'Kim Cương';
    return '';
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    String? badge,
    Color? titleColor,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: titleColor ?? Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color),
                    ),
                  ],
                ],
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: pBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: pBlue),
                ),
              ),
            if (trailing != null) 
              trailing
            else
              Icon(Icons.arrow_forward_ios, size: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(l10n.translate('logout'), style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: Text(l10n.translate('logout_confirm'), style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.translate('cancel'), style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.translate('logout_btn'), style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      Api.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => LoginScreen(
            onLoginSuccess: () {},
          ),
        ),
        (Route<dynamic> route) => false,
      );
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: pBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ============================================================
// WIDGET THẺ HẠNG (Cập nhật theo chi tiêu)
// ============================================================
class _ShinyMembershipCard extends StatefulWidget {
  final String name;
  final String phone;
  final int totalSpent; 
  final String avatar;
  final XFile? pickedImage;
  final Map<String, dynamic> tier;
  final String nextTierName;
  final VoidCallback onAvatarTap;

  const _ShinyMembershipCard({
    required this.name,
    required this.phone,
    required this.totalSpent,
    required this.avatar,
    required this.pickedImage,
    required this.tier,
    required this.nextTierName,
    required this.onAvatarTap,
  });

  @override
  State<_ShinyMembershipCard> createState() => _ShinyMembershipCardState();
}

class _ShinyMembershipCardState extends State<_ShinyMembershipCard> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), 
    )..repeat(); 
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Widget _buildAvatarLetter(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: pBlue,
          fontSize: 24, 
          fontWeight: FontWeight.w900,
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

  @override
  Widget build(BuildContext context) {
    final tierName = widget.tier['name'] as String;
    final tierLevel = widget.tier['tier'] as int;
    final gradientColors = widget.tier['gradient'] as List<Color>;
    final icon = widget.tier['icon'] as IconData;
    final nextSpend = widget.tier['nextSpend'] as int;
    final totalSpent = widget.totalSpent;

    double progress = 0.0;
    if (tierLevel < 4) { 
      int currentMin = tierLevel == 1 ? 0 : (tierLevel == 2 ? 1000000 : 3000000);
      int targetMax = nextSpend;
      progress = ((totalSpent - currentMin) / (targetMax - currentMin)).clamp(0.0, 1.0);
    } else {
      progress = 1.0; 
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -30,
              child: Container(
                width: 200,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      -300 + (_shimmerController.value * 600), 
                      0,
                    ),
                    child: Transform.rotate(
                      angle: -0.5,
                      child: Container(
                        width: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.4),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: widget.onAvatarTap,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: ClipOval(
                                child: widget.pickedImage != null
                                    ? (kIsWeb 
                                        ? Image.network(widget.pickedImage!.path, fit: BoxFit.cover)
                                        : Image.file(File(widget.pickedImage!.path), fit: BoxFit.cover))
                                    : widget.avatar.isNotEmpty
                                        ? Image.network(widget.avatar, fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => _buildAvatarLetter(widget.name))
                                        : _buildAvatarLetter(widget.name),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, size: 12, color: pBlue), 
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.name.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.phone,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'HỘI VIÊN HẠNG ${tierName.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tierLevel < 4 ? 'Còn ${_formatPrice(nextSpend - totalSpent)}đ để lên hạng' : 'Bạn đã đạt hạng cao nhất!',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}