// ============================================================
// CUSTOM APP BAR — Hỗ trợ Đa ngôn ngữ và Dark Mode
// ============================================================
import 'package:flutter/material.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? titleWidget; 
  final bool showBackButton;
  final double? customHeight;
  
  // CÁC THAM SỐ ĐÃ ĐƯỢC THÊM
  final ThemeMode? themeMode;
  final Function(ThemeMode)? onChangeThemeMode;
  final Locale? locale;
  final Function(Locale)? onChangeLocale;

  static const Color primaryBlue = Color(0xFF2563EB); 

  const CustomAppBar({
    super.key,
    required this.title,
    this.titleWidget, 
    this.showBackButton = true,
    this.customHeight,
    this.themeMode,             
    this.onChangeThemeMode,
    this.locale,                
    this.onChangeLocale,        
  });

  @override
  Widget build(BuildContext context) {
    // 👇 LOG KIỂM TRA DỮ LIỆU (Có thể xóa sau khi test)
    print('📱 CustomAppBar nhận locale: ${locale?.languageCode}');

    final statusBarHeight = MediaQuery.of(context).padding.top;
    final height = customHeight ?? (64.0 + statusBarHeight);

    return Container(
      height: height, 
      decoration: const BoxDecoration(
        color: primaryBlue,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: statusBarHeight + 12, 
          left: 16,
          right: 16,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            if (showBackButton) ...[
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            
            if (titleWidget != null) 
              SizedBox(
                width: 40,
                height: 40,
                child: titleWidget,
              )
            else if (title.isNotEmpty)
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(),
            
            const Spacer(),
            
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  barrierColor: Colors.black.withValues(alpha: 0.1),
                  builder: (_) => const NotificationScreen(),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Center(
                      child: Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4ADE80),
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryBlue, width: 1.2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            GestureDetector(
              onTap: () {
                // 👇 KIỂM TRA XEM CÓ TRUYỀN ĐÚNG KHÔNG
                print('🟢 Mở ProfileScreen với locale: ${locale?.languageCode}');
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(
                      themeMode: themeMode ?? ThemeMode.system,
                      onChangeThemeMode: onChangeThemeMode ?? (mode) {},
                      locale: locale ?? const Locale('vi'),          
                      onChangeLocale: onChangeLocale ?? (loc) {},    
                    ),
                  ),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.person_outline, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize {
    if (customHeight != null) return Size.fromHeight(customHeight!);
    
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final topPadding = view.padding.top;
    return Size.fromHeight(64.0 + topPadding); 
  }
}