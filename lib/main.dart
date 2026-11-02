// ============================================================
// CANTEEN VWA — Flutter App (Full - Hỗ trợ Sáng/Tối/Ngôn ngữ)
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'api.dart';
import 'cart_provider.dart';
import 'menu_screen.dart';
import 'placeholder_screens.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import 'wallet_screen.dart';
import 'cart_screen.dart';
import 'checkout_screen.dart';
import 'login_screen.dart';
import 'order_success_screen.dart';
import 'notification_screen.dart';
import 'green_screen.dart';
import 'custom_app_bar.dart';
import 'voucher_screen.dart';
import 'membership_screen.dart';
import 'membership_provider.dart';
import 'app_theme.dart';
import 'chat_bubble.dart';
import 'vwa_points_screen.dart';
import 'app_localizations.dart';
import 'dart:async';

// ============================================================
// MÀU SẮC CƠ BẢN
// ============================================================
const Color kBlue = Color(0xFF2563EB);
const Color kBlueDark = Color(0xFF1D4ED8);
const Color kBlueLight = Color(0xFF3B82F6);
const Color kBg = Color(0xFFF9FAFB);
const Color kTextPrimary = Color(0xFF172033);
const Color kTextMuted = Color(0xFF64748B);
const Color kGreen = Color(0xFF18A967);
const Color kRed = Color(0xFFEF4444);
const Color kBorder = Color(0xFFE5E9EF);
const Color kGold = Color(0xFFFBBF24);

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

// ============================================================
// HELPER
// ============================================================
String formatPrice(dynamic price) {
  if (price == null) return '0đ';
  final num = int.parse(price.toString());
  return '${num.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  )}đ';
}

// ============================================================
// MAIN
// ============================================================
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CanteenApp());
}

class CanteenApp extends StatefulWidget {
  const CanteenApp({super.key});

  @override
  State<CanteenApp> createState() => _CanteenAppState();
}

class _CanteenAppState extends State<CanteenApp> {
  final CartProvider _cartProvider = CartProvider();
  final MembershipProvider _membershipProvider = MembershipProvider();
  bool _isLoggedIn = false;
  
  final ValueNotifier<ThemeMode> _themeModeNotifier = ValueNotifier(ThemeMode.system);
  final ValueNotifier<Locale> _localeNotifier = ValueNotifier(const Locale('vi'));

  void toggleTheme() {
    if (_themeModeNotifier.value == ThemeMode.light) {
      _themeModeNotifier.value = ThemeMode.dark;
    } else if (_themeModeNotifier.value == ThemeMode.dark) {
      _themeModeNotifier.value = ThemeMode.system;
    } else {
      _themeModeNotifier.value = ThemeMode.light;
    }
  }

  void setThemeMode(ThemeMode mode) => _themeModeNotifier.value = mode;
  void setLocale(Locale locale) => _localeNotifier.value = locale;

  @override
  void dispose() {
    _cartProvider.dispose();
    _membershipProvider.dispose();
    _themeModeNotifier.dispose();
    _localeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CartScope(
      provider: _cartProvider,
      child: MembershipScope(
        provider: _membershipProvider,
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: _themeModeNotifier,
          builder: (context, currentThemeMode, child) {
            return ValueListenableBuilder<Locale>(
              valueListenable: _localeNotifier,
              builder: (context, currentLocale, child) {
                return MaterialApp(
                  title: 'Canteen VWA',
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: currentThemeMode,
                  
                  navigatorObservers: [routeObserver],
                  
                  locale: currentLocale,
                  supportedLocales: const [Locale('vi'), Locale('en')],
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],

                  home: _isLoggedIn
                      ? MainShell(
                          themeMode: currentThemeMode,
                          onToggleTheme: toggleTheme,
                          onChangeThemeMode: setThemeMode,
                          locale: currentLocale,
                          onChangeLocale: setLocale,
                        )
                      : LoginScreen(
                          onLoginSuccess: () {
                            setState(() => _isLoggedIn = true);
                          },
                        ),
                 
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// MAIN SHELL
// ============================================================
class MainShell extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final Function(ThemeMode) onChangeThemeMode;
  final Locale locale;                  
  final Function(Locale) onChangeLocale; 

  const MainShell({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
    required this.onChangeThemeMode,
    required this.locale,             
    required this.onChangeLocale,     
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  String _selectedCategory = 'Tất cả';

  void switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    bool showChatBubble = _currentIndex == 0 || _currentIndex == 1;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: [
              HomePage(
                onCategorySelected: _onCategorySelected,
                onNavigateToMenu: _navigateToMenu,
                themeMode: widget.themeMode,
                onToggleTheme: widget.onToggleTheme,
                onChangeThemeMode: widget.onChangeThemeMode,
                locale: widget.locale,             
                onChangeLocale: widget.onChangeLocale, 
              ),
              MenuScreen(externalCategory: _selectedCategory),
                               CartScreen(
                onNavigateToMenu: () {
                  setState(() {
                    _currentIndex = 1;
                    _selectedCategory = 'Tất cả';
                  });
                },
              ),
              const OrdersScreen(),
              const WalletScreen(),
            ],
          ),
          if (showChatBubble)
            const Positioned.fill(
              child: ChatBubble(),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _currentIndex = 1;
    });
  }

  void _navigateToMenu() {
    setState(() {
      _selectedCategory = 'Tất cả';
      _currentIndex = 1;
    });
  }

  Widget _buildBottomNav() {
    final cart = CartScope.of(context);
    final cartCount = cart.totalItems;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTabItem(0, Icons.home_outlined, Icons.home, l10n.translate('Trang chủ')),
            ),
            Expanded(
              child: _buildTabItem(1, Icons.menu_book_outlined, Icons.menu_book, l10n.translate('Menu')),
            ),
            _buildFloatingCartButton(cartCount),
            Expanded(
              child: _buildTabItem(3, Icons.receipt_long_outlined, Icons.receipt_long, l10n.translate('Đơn')),
            ),
            Expanded(
              child: _buildTabItem(4, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, l10n.translate('Ví')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentIndex == index;
    final inactiveColor = Theme.of(context).textTheme.bodyMedium?.color ?? kTextMuted;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            duration: const Duration(milliseconds: 200),
            scale: isActive ? 1.15 : 1.0,
            child: Icon(
              isActive ? activeIcon : icon,
              color: isActive ? kBlue : inactiveColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              color: isActive ? kBlue : inactiveColor,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingCartButton(int badgeCount) {
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 2),
      child: Transform.translate(
        offset: const Offset(0, -14),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kBlue, kBlueDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).cardColor, width: 4),
            boxShadow: [
              BoxShadow(
                color: kBlue.withOpacity(0.4),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Center(
                child: Icon(Icons.shopping_cart, color: Colors.white, size: 26),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    constraints: const BoxConstraints(minWidth: 18),
                    decoration: BoxDecoration(
                      color: kRed,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Theme.of(context).cardColor, width: 1.5),
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HOME PAGE
// ============================================================
class HomePage extends StatefulWidget {
  final Function(String) onCategorySelected;
  final VoidCallback onNavigateToMenu;
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final Function(ThemeMode) onChangeThemeMode;
  final Locale locale;                  
  final Function(Locale) onChangeLocale;

  const HomePage({
    super.key,
    required this.onCategorySelected,
    required this.onNavigateToMenu,
    required this.themeMode,
    required this.onToggleTheme,
    required this.onChangeThemeMode,
    required this.locale,
    required this.onChangeLocale,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _flashSaleKey = GlobalKey();

  void _scrollToFlashSale() {
    final context = _flashSaleKey.currentContext;
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeaderSection(
                onNavigateToMenu: widget.onNavigateToMenu,
                onCategorySelected: widget.onCategorySelected,
                onScrollToFlashSale: _scrollToFlashSale,
                themeMode: widget.themeMode,
                onChangeThemeMode: widget.onChangeThemeMode,
                locale: widget.locale,
                onChangeLocale: widget.onChangeLocale,
              ),
              const SizedBox(height: 80),
              UtilitiesSection(
                themeMode: widget.themeMode,
                onToggleTheme: widget.onToggleTheme,
                locale: widget.locale,             
                onChangeLocale: widget.onChangeLocale, 
              ),
              CategoriesSection(onCategorySelected: widget.onCategorySelected),
              FlashSaleSection(key: _flashSaleKey),
              const SignatureSection(),
              const BestSellersSection(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HEADER & BANNER SLIDESHOW
// ============================================================
class HeaderSection extends StatelessWidget {
  final VoidCallback onNavigateToMenu;
  final Function(String) onCategorySelected;
  final VoidCallback onScrollToFlashSale;
  final ThemeMode themeMode;
  final Function(ThemeMode) onChangeThemeMode;
  final Locale locale;                  
  final Function(Locale) onChangeLocale;

  const HeaderSection({
    super.key,
    required this.onNavigateToMenu,
    required this.onCategorySelected,
    required this.onScrollToFlashSale,
    required this.themeMode,
    required this.onChangeThemeMode,
    required this.locale,
    required this.onChangeLocale,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CustomAppBar(
          title: '',
          showBackButton: false,
          customHeight: 200,
          themeMode: themeMode,
          onChangeThemeMode: onChangeThemeMode,
          locale: locale,
          onChangeLocale: onChangeLocale,
          titleWidget: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Image.asset(
                      'assets/LOGO.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.school, color: kBlue, size: 24);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 75,
          left: 14,
          right: 14,
          child: BannerSlideshow(
            onNavigateToMenu: onNavigateToMenu,
            onCategorySelected: onCategorySelected,
            onScrollToFlashSale: onScrollToFlashSale,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// BANNER SLIDESHOW
// ============================================================
class BannerSlideshow extends StatefulWidget {
  final VoidCallback onNavigateToMenu;
  final Function(String) onCategorySelected;
  final VoidCallback onScrollToFlashSale;

  const BannerSlideshow({
    super.key,
    required this.onNavigateToMenu,
    required this.onCategorySelected,
    required this.onScrollToFlashSale,
  });

  @override
  State<BannerSlideshow> createState() => _BannerSlideshowState();
}

class _BannerSlideshowState extends State<BannerSlideshow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _banners = [
    {'image': 'assets/banner1.png', 'action': 'menu'},
    {'image': 'assets/banner2.png', 'action': 'flashsale'},
    {'image': 'assets/banner3.png', 'action': 'voucher'},
    {'image': 'assets/banner4.png', 'action': 'green'},
  ];

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % _banners.length;
        _pageController.animateToPage(nextPage,
            duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      }
      _startAutoPlay();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleBannerTap(String action) {
    switch (action) {
      case 'menu':
        widget.onNavigateToMenu();
        break;
      case 'flashsale':
        widget.onScrollToFlashSale();
        break;
      case 'voucher':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VoucherScreen()),
        );
        break;

      case 'green':
        showGreenPopup(context);
        break;

      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 175,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _banners.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                final banner = _banners[index];
                final imageUrl = banner['image']!;
                final isAsset = imageUrl.startsWith('assets/');

                return GestureDetector(
                  onTap: () => _handleBannerTap(banner['action']!),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      isAsset
                          ? Image.asset(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: kBlue.withOpacity(0.15),
                                    child: const Center(
                                        child: Icon(Icons.image_not_supported,
                                            color: kBlue, size: 40)),
                                  ),
                            )
                          : Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  color: kBlue.withOpacity(0.1),
                                  child: const Center(
                                      child: CircularProgressIndicator(
                                          color: kBlue, strokeWidth: 2)),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: kBlue.withOpacity(0.15),
                                    child: const Center(
                                        child: Icon(Icons.image_not_supported,
                                            color: kBlue, size: 40)),
                                  ),
                            ),
                    ],
                  ),
                );
              },
            ),
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_banners.length, (i) {
                  final isActive = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 🆕 TIỆN ÍCH (ĐÃ FIX LỖI TRÀN VIỀN)
// ============================================================
class UtilitiesSection extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final Locale locale;                   
  final Function(Locale) onChangeLocale; 

  const UtilitiesSection({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
    required this.locale,             
    required this.onChangeLocale,     
  });

  @override
  State<UtilitiesSection> createState() => _UtilitiesSectionState();
}

class _UtilitiesSectionState extends State<UtilitiesSection> {
  IconData get _shiftIcon {
    if (widget.themeMode == ThemeMode.light) return Icons.light_mode;
    if (widget.themeMode == ThemeMode.dark) return Icons.dark_mode;
    return Icons.brightness_auto;
  }

  List<Map<String, dynamic>> get _allItems => [
    {'id': 'points', 'icon': Icons.star, 'name': 'VWA Coin', 'color': const Color(0xFFF59E0B)},
    {'id': 'member', 'icon': Icons.badge, 'name': 'Thành viên', 'color': const Color(0xFF8B5CF6)},
    {'id': 'voucher', 'icon': Icons.local_offer, 'name': 'Voucher', 'color': const Color(0xFFEC4899)},
    {'id': 'green', 'icon': Icons.eco, 'name': 'VWA Green', 'color': const Color(0xFF18A967)},
    {'id': 'subsidy', 'icon': Icons.school, 'name': 'Trợ giá', 'color': const Color(0xFF2563EB)},
    {'id': 'shift', 'icon': _shiftIcon, 'name': 'Sáng/Tối', 'color': const Color(0xFF6366F1)},
    {'id': 'calendar', 'icon': Icons.calendar_month, 'name': 'Lịch', 'color': const Color(0xFF14B8A6)},
    {'id': 'transfer', 'icon': Icons.swap_horiz, 'name': 'Chuyển tiền', 'color': const Color(0xFF0EA5E9)}, 
    {'id': 'deposit', 'icon': Icons.account_balance_wallet, 'name': 'Nạp tiền', 'color': const Color(0xFF10B981)},
    {'id': 'language', 'icon': Icons.language, 'name': 'Ngôn ngữ', 'color': const Color(0xFFF97316)}, 
  ];

  List<String> _activeIds = ['points', 'member', 'voucher', 'green', 'subsidy', 'shift', 'calendar', 'language'];

  List<Map<String, dynamic>> get _visibleItems => _activeIds
      .map((id) => _allItems.firstWhere((item) => item['id'] == id))
      .toList();

  List<Map<String, dynamic>> get _hiddenItems => _allItems
      .where((item) => !_activeIds.contains(item['id']))
      .toList();

  void _openEditScreen() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 10),
              child: Column(
                children: [
                  Text(l10n.translate('Các phím sẵn có'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  const SizedBox(height: 16),
                  
                  if (_hiddenItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(l10n.translate('Đã thêm tất cả tiện ích'), style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _hiddenItems.map((item) {
                          return Container(
                            width: 80, 
                            margin: const EdgeInsets.only(right: 12),
                            child: InkWell(
                              onTap: () {
                                setSheetState(() {
                                  _activeIds.add(item['id']);
                                });
                                setState(() {}); 
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 56, height: 56, 
                                    decoration: BoxDecoration(
                                      color: kBorder.withOpacity(0.5), 
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(item['icon'] as IconData, color: Theme.of(context).textTheme.bodyMedium?.color, size: 26),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.translate(item['name'] as String),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11, 
                                      fontWeight: FontWeight.w600, 
                                      color: Theme.of(context).textTheme.bodyLarge?.color, 
                                      height: 1.2,
                                    ),
                                    maxLines: 2, 
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  const Divider(thickness: 1, color: kBorder),
                  const SizedBox(height: 16),

                  Text(l10n.translate('Hãy chạm và giữ để di chuyển phím.'), style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color)),
                  const SizedBox(height: 16),
                  
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.85, 
                      ),
                      itemCount: _activeIds.length,
                      itemBuilder: (context, index) {
                        final itemId = _activeIds[index];
                        final item = _allItems.firstWhere((e) => e['id'] == itemId);
                        
                        return DragTarget<String>(
                          onAcceptWithDetails: (details) {
                            setSheetState(() {
                              _activeIds.remove(details.data);
                              _activeIds.insert(index, details.data);
                            });
                            setState(() {});
                          },
                          builder: (context, candidateData, rejectedData) {
                            final isDragging = candidateData.isNotEmpty;
                            
                            return LongPressDraggable<String>(
                              data: itemId,
                              feedback: Material(
                                color: Colors.transparent,
                                child: Container(
                                  width: 56, height: 56,
                                  decoration: BoxDecoration(
                                    color: (item['color'] as Color).withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(item['icon'] as IconData, color: Colors.white, size: 28),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.3,
                                child: _buildIconWidget(item, false),
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  setSheetState(() {
                                    _activeIds.remove(itemId);
                                  });
                                  setState(() {});
                                },
                                child: _buildIconWidget(item, isDragging),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            _activeIds = ['points', 'member', 'voucher', 'green', 'subsidy', 'shift', 'calendar', 'language'];
                          });
                          setState(() {});
                        },
                        child: Text(l10n.translate('Đặt lại'), style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
                      ),
                      Container(width: 1, height: 20, color: kBorder),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.translate('Hoàn tất'), style: const TextStyle(fontSize: 16, color: kBlue, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIconWidget(Map<String, dynamic> item, bool isHighlight) {
    final l10n = AppLocalizations.of(context)!;
    final color = item['color'] as Color;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: isHighlight ? color.withOpacity(0.3) : color.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: isHighlight ? color : color.withOpacity(0.25), width: 1.5),
          ),
          child: Icon(item['icon'] as IconData, color: color, size: 26),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.translate(item['name'] as String),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color, height: 1.2),
          maxLines: 2, overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _handleTap(String id, String name) async {
    final l10n = AppLocalizations.of(context)!;
    switch (id) {
      case 'green':
        showGreenPopup(context); 
        break;
      case 'voucher':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VoucherScreen()));
        break;
      case 'member':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MembershipScreen()));
        break;
      case 'subsidy':
        showDialog(context: context, builder: (_) => const StudentSubsidyDialog());
        break;
        
      case 'calendar':
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Theme.of(context).cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.translate('Lịch của tôi'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: kTextMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const AppCalendar(), 
                ],
              ),
            ),
          ),
        );
        break;
      
      case 'deposit':
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => const WalletScreen())
        );
        break;

      case 'transfer':
        showTransferDialog(context);
        break;

      case 'points':
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => const VwaPointsScreen()),
        );
        break;

      case 'shift':
        widget.onToggleTheme();
        break;

      case 'language':
        showModalBottomSheet(
          context: context,
          backgroundColor: Theme.of(context).cardColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      l10n.translate('Chọn ngôn ngữ'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Text('🇻🇳', style: TextStyle(fontSize: 24)),
                    title: Text(l10n.translate('Tiếng Việt')),
                    trailing: widget.locale.languageCode == 'vi' ? const Icon(Icons.check, color: kBlue) : null,
                    onTap: () {
                      widget.onChangeLocale(const Locale('vi'));
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
                    title: Text(l10n.translate('English')),
                    trailing: widget.locale.languageCode == 'en' ? const Icon(Icons.check, color: kBlue) : null,
                    onTap: () {
                      widget.onChangeLocale(const Locale('en'));
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
        break;

      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.translate('Bấm')}: ${l10n.translate(name)}'), duration: const Duration(seconds: 1)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Text(l10n.translate('Tiện ích'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.bodyLarge?.color)),
          ),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 12,
              // 🔥 FIX: Giảm tỷ lệ xuống 0.85 để tăng chiều cao ô, không bị tràn chữ
              childAspectRatio: 0.85, 
            ),
            itemCount: _visibleItems.length + 1, 
            itemBuilder: (context, index) {
              if (index == _visibleItems.length) {
                return InkWell(
                  onTap: _openEditScreen, 
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).textTheme.bodyMedium?.color ?? kTextMuted, width: 1.5),
                        ),
                        child: Icon(Icons.add, color: Theme.of(context).textTheme.bodyMedium?.color, size: 26),
                      ),
                      const SizedBox(height: 6),
                      Text(l10n.translate('Thêm'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyMedium?.color)),
                    ],
                  ),
                );
              }

              final item = _visibleItems[index];
              final color = item['color'] as Color;
              final name = item['name'] as String;
              final id = item['id'] as String;

              return GestureDetector(
                onTap: () => _handleTap(id, name),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: color.withOpacity(0.25), width: 1.2),
                      ),
                      child: Icon(item['icon'] as IconData, color: color, size: 24),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.translate(name),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color, height: 1.1),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ⚡ FLASH SALE (ĐÃ FIX LỖI TRÀN VIỀN)
// ============================================================
class FlashSaleSection extends StatefulWidget {
  const FlashSaleSection({super.key});
  @override
  State<FlashSaleSection> createState() => _FlashSaleSectionState();
}

class _FlashSaleSectionState extends State<FlashSaleSection>
    with SingleTickerProviderStateMixin {
  List<dynamic> items = [];
  bool loading = true;

  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  Duration _timeLeft = const Duration(hours: 2, minutes: 45, seconds: 30);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _blinkAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    _load();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft.inSeconds > 0) {
          _timeLeft = _timeLeft - const Duration(seconds: 1);
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  String _formatTime(int value) {
    return value.toString().padLeft(2, '0');
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await Api.getMenu();
    if (mounted) {
      setState(() {
        items = data.take(6).toList();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (loading || items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // BÊN TRÁI: Tiêu đề FLASH SALE & Đồng hồ
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.flash_on, color: Color(0xFFEF4444), size: 24),
                    const SizedBox(width: 2),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: l10n.translate('FLASH '),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFEF4444),
                              letterSpacing: -0.5,
                            ),
                          ),
                          TextSpan(
                            text: l10n.translate('SALE'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFB91C1C),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Đồng hồ đếm ngược
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 12, color: Color(0xFFEF4444)),
                          const SizedBox(width: 2),
                          Text(
                            '${_formatTime(_timeLeft.inHours)}:${_formatTime(_timeLeft.inMinutes % 60)}:${_formatTime(_timeLeft.inSeconds % 60)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // BÊN PHẢI: Nút "Đang diễn ra" (Thu nhỏ lại)
              FadeTransition(
                opacity: _blinkAnimation,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    l10n.translate('Đang diễn ra'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.translate('Săn deal hời — Giá rẻ bất ngờ!'),
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          
          SizedBox(
            height: 195,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final price = int.tryParse(item['price'].toString()) ?? 0;
                final oldPrice = (price * 1.4).round();

                return GestureDetector(
                  onTap: () => showDialog(
                    context: context,
                    barrierDismissible: true,
                    barrierColor: Colors.transparent,
                    builder: (_) => FoodDetailScreen(food: item),
                  ),
                  child: Container(
                    width: 145,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: kBorder,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                              child: SizedBox(
                                height: 100,
                                width: double.infinity,
                                child: item['image'] != null &&
                                        item['image'].toString().isNotEmpty
                                    ? Image.network(item['image'],
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                              color: kBorder,
                                              child: Icon(Icons.restaurant,
                                                  color: Theme.of(context).textTheme.bodyMedium?.color, size: 30),
                                            ))
                                    : Container(
                                        color: kBorder,
                                        child: Icon(Icons.restaurant,
                                            color: Theme.of(context).textTheme.bodyMedium?.color, size: 30),
                                      ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('-30%',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800)),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['name'] ?? 'Món',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context).textTheme.bodyLarge?.color),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(formatPrice(price),
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFEF4444))),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(formatPrice(oldPrice),
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Theme.of(context).textTheme.bodyMedium?.color,
                                            decoration:
                                                TextDecoration.lineThrough),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: 0.7,
                                  minHeight: 5,
                                  backgroundColor: const Color(0xFFFEE2E2),
                                  valueColor: const AlwaysStoppedAnimation(
                                      Color(0xFFEF4444)),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.local_fire_department,
                                      color: Color(0xFFEF4444), size: 12),
                                  const SizedBox(width: 3),
                                  Text(l10n.translate('Đã bán 35/50'),
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF9F1239),
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DANH MỤC (ĐÃ FIX LỖI TRÀN VIỀN)
// ============================================================
class CategoriesSection extends StatefulWidget {
  final Function(String) onCategorySelected;

  const CategoriesSection({
    super.key,
    required this.onCategorySelected,
  });

  @override
  State<CategoriesSection> createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends State<CategoriesSection> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final data = await Api.getMenu();
    if (!mounted) return;

    final Set<String> uniqueCats = {'Tất cả'};
    for (final food in data) {
      final cat = food['category']?.toString();
      if (cat != null && cat.isNotEmpty) {
        uniqueCats.add(cat);
      }
    }

    final List<Map<String, dynamic>> cats = [];
    for (final name in uniqueCats) {
      cats.add({
        'name': name,
        'icon': _getIcon(name),
        'color': _getColor(name),
      });
    }

    setState(() {
      _categories = cats;
      _loading = false;
    });
  }

  IconData _getIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('tất cả') || lower.contains('all'))
      return Icons.restaurant_menu;
    if (lower.contains('cơm')) return Icons.rice_bowl_outlined;
    if (lower.contains('bún') ||
        lower.contains('phở') ||
        lower.contains('cháo')) {
      return Icons.ramen_dining_outlined;
    }
    if (lower.contains('coffee') ||
        lower.contains('cà phê') ||
        lower.contains('trà')) {
      return Icons.local_cafe_outlined;
    }
    if (lower.contains('chay')) return Icons.eco_outlined;
    if (lower.contains('pizza')) return Icons.local_pizza_outlined;
    if (lower.contains('tráng miệng') || lower.contains('ngọt'))
      return Icons.icecream_outlined;
    if (lower.contains('uống') ||
        lower.contains('nước') ||
        lower.contains('sinh tố')) {
      return Icons.local_bar_outlined;
    }
    if (lower.contains('combo')) return Icons.set_meal_outlined;
    if (lower.contains('bánh mì') || lower.contains('xôi'))
      return Icons.bakery_dining_outlined;
    if (lower.contains('ăn vặt')) return Icons.fastfood_outlined;
    if (lower.contains('nhanh')) return Icons.local_dining_outlined;
    if (lower.contains('nướng')) return Icons.outdoor_grill_outlined;
    if (lower.contains('hải sản')) return Icons.set_meal_outlined;
    if (lower.contains('salad')) return Icons.grass_outlined;
    return Icons.restaurant_outlined;
  }

  Color _getColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('tất cả') || lower.contains('all'))
      return const Color(0xFF2563EB);
    if (lower.contains('cơm')) return const Color(0xFF16A34A);
    if (lower.contains('bún') ||
        lower.contains('phở') ||
        lower.contains('cháo')) {
      return const Color(0xFFEA580C);
    }
    if (lower.contains('coffee') ||
        lower.contains('cà phê') ||
        lower.contains('trà')) {
      return const Color(0xFF2563EB);
    }
    if (lower.contains('chay')) return const Color(0xFF16A34A);
    if (lower.contains('pizza')) return const Color(0xFFEF4444);
    if (lower.contains('tráng miệng') || lower.contains('ngọt'))
      return const Color(0xFFEC4899);
    if (lower.contains('uống') ||
        lower.contains('nước') ||
        lower.contains('sinh tố')) {
      return const Color(0xFF0891B2);
    }
    if (lower.contains('combo')) return const Color(0xFFF59E0B);
    if (lower.contains('bánh mì') || lower.contains('xôi'))
      return const Color(0xFFDC2626);
    if (lower.contains('ăn vặt')) return const Color(0xFF9333EA);
    if (lower.contains('nhanh')) return const Color(0xFFF97316);
    if (lower.contains('nướng')) return const Color(0xFF78350F);
    if (lower.contains('hải sản')) return const Color(0xFF0891B2);
    if (lower.contains('salad')) return const Color(0xFF16A34A);
    return const Color(0xFF2563EB);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading || _categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 20),
        child: SizedBox(
          height: 105,
          child: Center(child: CircularProgressIndicator(color: kBlue)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.list_alt_outlined, color: kBlue, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      l10n.translate('Danh mục món ăn'),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _onTap(0),
                  child: Row(
                    children: [
                      Text(
                        l10n.translate('Tất cả'),
                        style: const TextStyle(
                          fontSize: 13,
                          color: kBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward, color: kBlue, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            // 🔥 FIX: Tăng chiều cao lên 135 để chữ không bị tràn xuống dưới
            height: 135,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isActive = index == _selectedIndex;
                final color = cat['color'] as Color;

                return GestureDetector(
                  onTap: () => _onTap(index),
                  child: SizedBox(
                    width: 78,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          // 🔥 FIX: Giảm nhẹ kích thước icon xuống 52 để nhường chỗ cho chữ
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: isActive ? color : kBorder.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: AnimatedScale(
                              scale: isActive ? 1.1 : 1.0,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutBack,
                              child: Icon(
                                cat['icon'] as IconData,
                                size: 24,
                                color: isActive ? Colors.white : color,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.translate(cat['name'] as String),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                            color: isActive ? color : Theme.of(context).textTheme.bodyLarge?.color,
                            letterSpacing: 0.1,
                            // 🔥 FIX: Ép dòng chữ sát nhau để không bị tràn
                            height: 1.1, 
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: isActive ? 18 : 0,
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onTap(int index) {
    setState(() => _selectedIndex = index);
    widget.onCategorySelected(_categories[index]['name'] as String);
  }
}

// ============================================================
// SIGNATURE
// ============================================================
class SignatureSection extends StatefulWidget {
  const SignatureSection({super.key});

  @override
  State<SignatureSection> createState() => _SignatureSectionState();
}

class _SignatureSectionState extends State<SignatureSection> {
  List<dynamic> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await Api.getMenu();
    if (mounted) {
      setState(() {
        items = data.skip(10).take(8).toList();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (loading || items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 14),
          child: Row(
            children: [
              const Icon(Icons.star_outline, color: kBlue, size: 22),
              const SizedBox(width: 6),
              Text(
                l10n.translate('Các món Signature'),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 195,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _SignatureCard(item: items[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _SignatureCard extends StatefulWidget {
  final Map<String, dynamic> item;
  const _SignatureCard({required this.item});

  @override
  State<_SignatureCard> createState() => _SignatureCardState();
}

class _SignatureCardState extends State<_SignatureCard> {
  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    final price = int.tryParse(item['price']?.toString() ?? '0') ?? 0;
    final originalPrice = int.tryParse(
          item['original_price']?.toString() ?? '${(price * 1.41).round()}',
        ) ??
        price;
    final discount = int.tryParse(
          item['discount_percent']?.toString() ?? '0',
        ) ??
        0;

    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        builder: (_) => FoodDetailScreen(food: item),
      ),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 120,
                    child: item['image'] != null &&
                            item['image'].toString().isNotEmpty
                        ? Image.network(
                            item['image'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: kBorder,
                              child: Icon(Icons.restaurant,
                                  color: Theme.of(context).textTheme.bodyMedium?.color, size: 36),
                            ),
                          )
                        : Container(
                            color: kBorder,
                            child: Icon(Icons.restaurant,
                                color: Theme.of(context).textTheme.bodyMedium?.color, size: 36),
                          ),
                  ),
                ),
                if (discount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: kRed,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '-$discount%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item['name'] ?? 'Món ăn',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatPrice(price),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (originalPrice > price)
                              Text(
                                formatPrice(originalPrice),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                  decoration: TextDecoration.lineThrough,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            barrierDismissible: true,
                            barrierColor: Colors.transparent,
                            builder: (_) => FoodDetailScreen(food: item),
                          );
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: kBlue,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: kBlue.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
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

// ============================================================
// BEST SELLERS (ĐÃ FIX LỖI TRÀN VIỀN)
// ============================================================
class BestSellersSection extends StatefulWidget {
  const BestSellersSection({super.key});

  @override
  State<BestSellersSection> createState() => _BestSellersSectionState();
}

class _BestSellersSectionState extends State<BestSellersSection> {
  List<dynamic> foods = [];
  bool loading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  Future<void> _loadFoods() async {
    setState(() {
      loading = true;
      error = '';
    });
    final data = await Api.getMenu();
    if (mounted) {
      setState(() {
        foods = data.take(6).toList();
        loading = false;
        if (data.isEmpty) error = 'Không có món ăn nào';
      });
    }
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0đ';
    final num = int.tryParse(price.toString()) ?? 0;
    return '${num.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    )}đ';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_fire_department, color: kBlue, size: 22),
                  const SizedBox(width: 6),
                  Text(
                    l10n.translate('Các món bán chạy'),
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _loadFoods,
                child: Row(
                  children: [
                    Text(
                      l10n.translate('Tải lại'),
                      style: const TextStyle(
                          fontSize: 13,
                          color: kBlue,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.refresh, color: kBlue, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: loading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: kBlue),
                  ),
                )
              : error.isNotEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.error_outline,
                                color: Theme.of(context).textTheme.bodyMedium?.color, size: 40),
                            const SizedBox(height: 12),
                            Text(l10n.translate(error),
                                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadFoods,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: kBlue),
                              child: Text(l10n.translate('Thử lại')),
                            ),
                          ],
                        ),
                      ),
                    )
                                    : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        mainAxisExtent: 155, // Chiều cao vừa đủ cho thẻ
                      ),
                      itemCount: foods.length,
                      itemBuilder: (context, index) {
                        final item = foods[index];
                        final food = Map<String, dynamic>.from(item);

                        final price = int.tryParse(food['price']?.toString() ?? '0') ?? 0;
                        final rating = food['rating']?.toString() ?? '5.0';
                        final prepTime = food['prep_time']?.toString() ?? '12';

                        return GestureDetector(
                          onTap: () => showDialog(
                            context: context,
                            barrierDismissible: true,
                            barrierColor: Colors.transparent,
                            builder: (_) => FoodDetailScreen(food: food),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kBorder),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // HÀNG 1: Ảnh món ăn
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 60, // Chiều cao của ảnh
                                      child: food['image'] != null && food['image'].toString().isNotEmpty
                                          ? Image.network(
                                              food['image'],
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                color: kBorder,
                                                child: Icon(Icons.restaurant, color: Theme.of(context).textTheme.bodyMedium?.color, size: 24),
                                              ),
                                            )
                                          : Container(
                                              color: kBorder,
                                              child: Icon(Icons.restaurant, color: Theme.of(context).textTheme.bodyMedium?.color, size: 24),
                                            ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 6),
                                  
                                  // HÀNG 2: Tên món
                                  Text(
                                    food['name'] ?? 'Món',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                      height: 1.1,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  
                                  const SizedBox(height: 2),
                                  
                                  // HÀNG 3: Giá tiền
                                  Text(
                                    _formatPrice(price),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF16A34A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  
                                  // HÀNG 4: Đánh giá (dưới cùng bên trái) & Nút + (dưới cùng bên phải)
                                  const Spacer(), // Đẩy hàng này xuống sát đáy
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Đánh giá & Thời gian
                                      Row(
                                        children: [
                                          const Icon(Icons.star, color: kGold, size: 11),
                                          const SizedBox(width: 2),
                                          Text(rating, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyMedium?.color)),
                                          const SizedBox(width: 4),
                                          Icon(Icons.access_time, color: Theme.of(context).textTheme.bodyMedium?.color, size: 11),
                                          const SizedBox(width: 2),
                                          Text('$prepTime\'', style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodyMedium?.color)),
                                        ],
                                      ),
                                      
                                      // Nút dấu cộng
                                      GestureDetector(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            barrierDismissible: true,
                                            barrierColor: Colors.black.withOpacity(0.3),
                                            builder: (_) => FoodDetailScreen(food: food),
                                          );
                                        },
                                        child: Container(
                                          width: 26, // Thu nhỏ nút + một chút
                                          height: 26,
                                          decoration: BoxDecoration(
                                            color: kBlue,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.add, color: Colors.white, size: 16),
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
        ),
      ],
    );
  }
}

// ============================================================
// POPUP TRỢ GIÁ SINH VIÊN
// ============================================================
class StudentSubsidyDialog extends StatefulWidget {
  const StudentSubsidyDialog({super.key});

  @override
  State<StudentSubsidyDialog> createState() => _StudentSubsidyDialogState();
}

class _StudentSubsidyDialogState extends State<StudentSubsidyDialog> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await Api.getStudentSubsidy();

    if (mounted) {
      setState(() {
        if (data.isEmpty) {
          _data = {
            'maxQuota': 300000,
            'remainingQuota': 220000,
            'usedSuat': 18,
            'totalSuat': 40,
            'percentage': 45,
            'lastUpdated': '01/04/2025',
            'autoApply': true,
          };
        } else {
          _data = data;
        }
        _loading = false;
      });
    }
  }

  String _formatMoney(num price) {
    return '${price.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    )}đ';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Theme.of(context).cardColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: _loading
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator(color: kBlue)),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: kBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kBlue.withOpacity(0.3)),
                        ),
                        child: Text(
                          l10n.translate('QUỸ HỌC ĐƯỜNG'),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: kBlue,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: kBorder.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.close, size: 18, color: Theme.of(context).textTheme.bodyMedium?.color),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.translate('Trợ Giá Sinh Viên Kỳ II'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  Text(
                    l10n.translate('Năm học 2024 - 2025'),
                    style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.translate('Hạn mức trợ giá còn lại:'),
                        style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color),
                      ),
                      Text(
                        _formatMoney(_data!['remainingQuota']),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF18A967),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.translate('Tương đương') + ' ${_data!['totalSuat'] - _data!['usedSuat']} ' + l10n.translate('suất ăn (10.000đ/suất học viên hỗ trợ)'),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF18A967), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.translate('Đã sử dụng trong tháng:') + ' ${_data!['usedSuat']}/${_data!['totalSuat']} ' + l10n.translate('suất'),
                    style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _data!['usedSuat'] / _data!['totalSuat'],
                            minHeight: 8,
                            backgroundColor: kBorder,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF18A967)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_data!['percentage']}%',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.auto_awesome, color: Color(0xFF18A967), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.translate('Trợ giá tối đa 10.000đ cho mỗi phần cơm/trữa phí 25.000đ trở lên khi quẹt mã tại quầy.'),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF166534),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.translate('Chu kỳ làm mới:') + ' ${_data!['lastUpdated']}',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color),
                      ),
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: _data!['autoApply'],
                              onChanged: (val) {},
                              activeColor: kBlue,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.translate('Tự động cộng lại'),
                            style: const TextStyle(fontSize: 12, color: kBlue, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

// ============================================================
// 📅 WIDGET LỊCH
// ============================================================
class AppCalendar extends StatefulWidget {
  const AppCalendar({super.key});

  @override
  State<AppCalendar> createState() => _AppCalendarState();
}

class _AppCalendarState extends State<AppCalendar> {
  DateTime _currentMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  final List<String> _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                });
              },
              icon: const Icon(Icons.chevron_left, color: kBlue),
            ),
            Text(
              l10n.translate('Tháng') + ' ${_currentMonth.month}, ${_currentMonth.year}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                });
              },
              icon: const Icon(Icons.chevron_right, color: kBlue),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _weekdays.map((day) => Text(
            day,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color),
          )).toList(),
        ),
        const SizedBox(height: 10),
        _buildCalendarGrid(),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday; 
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final blankDays = firstWeekday - 1; 

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: blankDays + daysInMonth,
      itemBuilder: (context, index) {
        if (index < blankDays) {
          return const SizedBox.shrink();
        }

        final day = index - blankDays + 1;
        final date = DateTime(_currentMonth.year, _currentMonth.month, day);
        
        final isSelected = date.day == _selectedDate.day && 
                           date.month == _selectedDate.month && 
                           date.year == _selectedDate.year;
        
        final isToday = date.day == DateTime.now().day && 
                        date.month == DateTime.now().month && 
                        date.year == DateTime.now().year;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
          },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected 
                  ? kBlue 
                  : (isToday ? kBlue.withOpacity(0.1) : Colors.transparent),
              shape: BoxShape.circle,
              border: isToday && !isSelected ? Border.all(color: kBlue, width: 1) : null,
            ),
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 14,
                fontWeight: (isSelected || isToday) ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        );
      },
    );
  }
}