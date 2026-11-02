import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- GIAO DIỆN SÁNG (LIGHT) ---
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF9FAFB), // Màu nền xám nhạt
      primaryColor: const Color(0xFF2563EB),           // Màu xanh chủ đạo
      useMaterial3: true,
      
      // 👇 ĐỊNH NGHĨA MÀU VIỀN CỐ ĐỊNH LÀ XÁM NHẠT
      dividerColor: const Color(0xFFE5E9EF),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E9EF),
        thickness: 1,
        space: 1,
      ),

      // Định nghĩa màu cho các thành phần mặc định
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF2563EB),
        surface: Colors.white,
        background: Color(0xFFF9FAFB),
        outline: Color(0xFFE5E9EF), // Thêm màu viền cho colorScheme
      ),
      
      // Màu cho BottomSheet, Dialog
      dialogBackgroundColor: Colors.white,
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.white),
      
      // ✅ Font chữ
      textTheme: GoogleFonts.robotoTextTheme(ThemeData.light().textTheme),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF2563EB),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18, 
          fontWeight: FontWeight.w600, 
          color: Colors.white,
        ),
      ),
    );
  }

  // --- GIAO DIỆN TỐI (DARK) ---
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      // Màu nền tổng thể: Xanh đen rất đậm (Slate 900)
      scaffoldBackgroundColor: const Color(0xFF0F172A), 
      primaryColor: const Color(0xFF2563EB),
      useMaterial3: true,
      
      // 👇 ĐỊNH NGHĨA MÀU VIỀN CỐ ĐỊNH LÀ XÁM NHẠT (Dù ở Dark Mode vẫn giữ màu xám)
      dividerColor: const Color(0xFFE5E9EF),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E9EF),
        thickness: 1,
        space: 1,
      ),

      // Định nghĩa màu cho các thành phần mặc định
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF2563EB),
        surface: Color(0xFF1E293B), // Thẻ màu xám đen (Slate 800)
        background: Color(0xFF0F172A),
        outline: Color(0xFFE5E9EF), // Thêm màu viền cho colorScheme
      ),
      
      // Màu cho BottomSheet, Dialog
      dialogBackgroundColor: const Color(0xFF1E293B),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Color(0xFF1E293B)),

      // ✅ Font chữ
      textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E293B),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18, 
          fontWeight: FontWeight.w600, 
          color: Colors.white,
        ),
      ),
    );
  }
}