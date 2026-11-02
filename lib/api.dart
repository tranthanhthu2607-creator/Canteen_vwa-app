// ============================================================
// API SERVICE — Kết nối backend NodeJS (Đã Fix toàn bộ URL)
// ============================================================
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class Api {
  // ============================================================
  // 🔥 CHỖ DUY NHẤT BẠN CẦN SỬA: DÁN URL NGROK CỦA BẠN VÀO ĐÂY
  // ============================================================
  static String get baseUrl {
    // Nếu bạn dùng ngrok, hãy dán URL vào đây (nhớ giữ lại /api)
    // Ví dụ: 'https://abc-xyz-123.ngrok-free.app/api'
    const String ngrokUrl = 'https://velvet-identify-thickness.ngrok-free.dev/api'; // <-- SỬA DÒNG NÀY
    
    if (kIsWeb) {
      return ngrokUrl; 
    } else if (Platform.isAndroid) {
      return ngrokUrl; 
    } else {
      return ngrokUrl;
    }
  }

  // ===== TOKEN =====
  static String? _token;
  static Map<String, dynamic>? _currentUser;

  static String? get token => _token;
  static Map<String, dynamic>? get currentUser => _currentUser;
  static bool get isLoggedIn => _token != null;

  static Map<String, String> get _authHeaders => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
        // Ngrok free chặn request mặc định, cần thêm header này để bỏ qua
        'ngrok-skip-browser-warning': 'true',
      };

  // ============================================================
  // AUTH
  // ============================================================
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('📡 POST $baseUrl/auth/login');
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('✅ Status: ${response.statusCode}');
      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && data['token'] != null) {
        _token = data['token'];
        _currentUser = data['user'];
        print('👤 Đăng nhập: ${_currentUser?['name']} (${_currentUser?['role']})');
        return {'ok': true, 'data': data};
      } else {
        return {'ok': false, 'message': data['message'] ?? 'Đăng nhập thất bại'};
      }
    } catch (e) {
      print('❌ Lỗi login: $e');
      return {'ok': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      print('📡 POST $baseUrl/auth/register');
      final res = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
        body: jsonEncode(data),
      );
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      if (res.statusCode == 200 || res.statusCode == 201) {
        return {'ok': true, ...body};
      }
      return {'ok': false, 'message': body['message'] ?? 'Đăng ký thất bại'};
    } catch (e) {
      print('❌ Lỗi register: $e');
      return {'ok': false, 'message': e.toString()};
    }
  }

  static void logout() {
    _token = null;
    _currentUser = null;
  }

  // ============================================================
  // MENU
  // ============================================================
  static Future<List<dynamic>> getMenu() async {
    try {
      print('📡 GET $baseUrl/menu');
      final response = await http.get(
        Uri.parse('$baseUrl/menu'),
        headers: {'Accept': 'application/json', 'ngrok-skip-browser-warning': 'true'},
      );
      print('✅ Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        print('📦 Nhận ${data.length} món ăn');
        return data;
      }
      return [];
    } catch (e) {
      print('❌ Lỗi getMenu: $e');
      return [];
    }
  }

  // ============================================================
  // ORDERS
  // ============================================================
  static Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> items,
    required String payment,
    String note = '',
    int discount = 0,
    String? voucherCode,
    bool? isGreen,
  }) async {
    try {
      if (_token == null) {
        return {'ok': false, 'message': 'Chưa đăng nhập'};
      }

      final body = {
        'items': items,
        'payment': payment,
        'note': note,
        'discount': discount,
        if (voucherCode != null && voucherCode.isNotEmpty) 'voucherCode': voucherCode,
        if (isGreen == true) 'isGreen': true,
      };

      print('📡 POST $baseUrl/orders');
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: _authHeaders,
        body: jsonEncode(body),
      );

      print('✅ Status: ${response.statusCode}');
      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'ok': true, 'order': data};
      } else {
        return {'ok': false, 'message': data['message'] ?? 'Đặt hàng thất bại'};
      }
    } catch (e) {
      print('❌ Lỗi createOrder: $e');
      return {'ok': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  static Future<List<dynamic>> getMyOrders() async {
    try {
      if (_token == null) return [];
      final response = await http.get(
        Uri.parse('$baseUrl/orders/me'),
        headers: _authHeaders,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data is List ? data : [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> cancelOrder(dynamic orderId) async {
    try {
      if (_token == null) return {'ok': false, 'message': 'Chưa đăng nhập'};
      final response = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/cancel'),
        headers: _authHeaders,
      );
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) return {'ok': true};
      return {'ok': false, 'message': data['message'] ?? 'Hủy đơn thất bại'};
    } catch (e) {
      return {'ok': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  static Future<Map<String, dynamic>> remindOrder(dynamic orderId, {required bool enabled}) async {
    try {
      if (_token == null) return {'ok': false, 'message': 'Chưa đăng nhập'};
      final response = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/reminder'),
        headers: _authHeaders,
        body: jsonEncode({'enabled': enabled}),
      );
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) return {'ok': true, 'data': data};
      return {'ok': false, 'message': data['message'] ?? 'Không thể đặt nhắc nhở'};
    } catch (e) {
      return {'ok': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  static Future<Map<String, dynamic>> receiveOrder(dynamic orderId) async {
    try {
      if (_token == null) return {'ok': false, 'message': 'Chưa đăng nhập'};
      final response = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/received'),
        headers: _authHeaders,
      );
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) return {'ok': true};
      return {'ok': false, 'message': data['message'] ?? 'Nhận hàng thất bại'};
    } catch (e) {
      return {'ok': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // ============================================================
  // USER
  // ============================================================
  static Future<Map<String, dynamic>?> getMe() async {
    try {
      if (_token == null) return null;
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _authHeaders,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        _currentUser = data;
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      if (_token == null) return {'ok': false, 'message': 'Chưa đăng nhập'};
      
      final res = await http.put(
        Uri.parse('$baseUrl/users/profile'),
        headers: _authHeaders,
        body: jsonEncode(data),
      );

      final body = jsonDecode(utf8.decode(res.bodyBytes));
      if (res.statusCode == 200) {
        _currentUser = {...?_currentUser, ...data};
        return {'ok': true, ...body};
      }
      return {'ok': false, 'message': body['message'] ?? 'Cập nhật thất bại'};
    } catch (e) {
      print('❌ Lỗi updateProfile: $e');
      return {'ok': false, 'message': e.toString()};
    }
  }

  // ============================================================
  // WALLET
  // ============================================================
  static Future<Map<String, dynamic>?> getWallet() async {
    try {
      if (_token == null) return null;
      final response = await http.get(
        Uri.parse('$baseUrl/wallet/me'),
        headers: _authHeaders,
      );
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<dynamic>?> getWalletTransactions() async {
    try {
      if (_token == null) return null;
      final response = await http.get(
        Uri.parse('$baseUrl/wallet/transactions'),
        headers: _authHeaders,
      );
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> topUpWallet(int amount, {String method = 'QR', String note = ''}) async {
    try {
      if (_token == null) return {'ok': false, 'message': 'Chưa đăng nhập'};
      final response = await http.post(
        Uri.parse('$baseUrl/wallet/deposit'),
        headers: _authHeaders,
        body: jsonEncode({'amount': amount, 'method': method, 'note': note}),
      );
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'ok': true, 'transaction': data['transaction']};
      }
      return {'ok': false, 'message': data['message'] ?? 'Nạp tiền thất bại'};
    } catch (e) {
      return {'ok': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateWalletLock(bool locked) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/wallet/lock'),
        headers: _authHeaders,
        body: jsonEncode({'is_locked': locked}),
      );
      if (res.statusCode == 200) return {'ok': true};
      final body = jsonDecode(res.body);
      return {'ok': false, 'message': body['message'] ?? 'Lỗi cập nhật ví'};
    } catch (e) {
      return {'ok': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createDepositRequest({required int amount, required String method, String? note}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/wallet/deposit-request'),
        headers: _authHeaders,
        body: jsonEncode({'amount': amount, 'method': method, 'note': note ?? ''}),
      );
      if (res.statusCode == 200 || res.statusCode == 201) return {'ok': true};
      final body = jsonDecode(res.body);
      return {'ok': false, 'message': body['message'] ?? 'Lỗi tạo yêu cầu nạp'};
    } catch (e) {
      return {'ok': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> transferMoney({required int amount, required String method, String? bankAccount, String? bankName, String? note}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/wallet/transfer'),
        headers: _authHeaders,
        body: jsonEncode({'amount': amount, 'method': method, 'bank_account': bankAccount, 'bank_name': bankName, 'note': note ?? ''}),
      );
      if (res.statusCode == 200) return {'ok': true};
      final body = jsonDecode(res.body);
      return {'ok': false, 'message': body['message'] ?? 'Chuyển tiền thất bại'};
    } catch (e) {
      return {'ok': false, 'message': e.toString()};
    }
  }

  // ============================================================
  // PROMOTIONS, POINTS, VOUCHERS
  // ============================================================
  static Future<List<dynamic>> getMyVouchers() async {
    try {
      if (_token == null) return [];
      final response = await http.get(Uri.parse('$baseUrl/vouchers/me'), headers: _authHeaders);
      if (response.statusCode == 200) return jsonDecode(utf8.decode(response.bodyBytes));
      return [];
    } catch (e) { return []; }
  }

  static Future<Map<String, dynamic>?> getPoints() async {
    try {
      if (_token == null) return null;
      final response = await http.get(Uri.parse('$baseUrl/points/me'), headers: _authHeaders);
      if (response.statusCode == 200) return jsonDecode(utf8.decode(response.bodyBytes));
      return null;
    } catch (e) { return null; }
  }

  static Future<Map<String, dynamic>> redeemPoints(int points) async {
    try {
      if (_token == null) return {'ok': false, 'message': 'Chưa đăng nhập'};
      final response = await http.post(
        Uri.parse('$baseUrl/points/redeem'),
        headers: _authHeaders,
        body: jsonEncode({'points': points}),
      );
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 || response.statusCode == 201) return {'ok': true, 'voucher': data};
      return {'ok': false, 'message': data['message'] ?? 'Đổi điểm thất bại'};
    } catch (e) { return {'ok': false, 'message': e.toString()}; }
  }

  // ============================================================
  // 🌿 VWA GREEN
  // ============================================================
  static Future<Map<String, dynamic>?> getGreenProfile() async {
    try {
      if (_token == null) return null;
      final response = await http.get(
        Uri.parse('$baseUrl/green/profile'), 
        headers: _authHeaders,
      );
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) {
      print('❌ Lỗi getGreenProfile: $e');
      return null;
    }
  }

  static Future<List<dynamic>> getGreenHistory() async {
    try {
      if (_token == null) return [];
      final response = await http.get(
        Uri.parse('$baseUrl/green/history'), 
        headers: _authHeaders,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data is List ? data : [];
      }
      return [];
    } catch (e) {
      print('❌ Lỗi getGreenHistory: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> createEcoReward({
    required String orderId,
    required String method, // 'bottle' | 'container'
  }) async {
    try {
      if (_token == null) return {'ok': false, 'message': 'Chưa đăng nhập'};
      
      final response = await http.post(
        Uri.parse('$baseUrl/eco-rewards'),
        headers: _authHeaders,
        body: jsonEncode({
          'orderId': orderId,
          'method': method,
        }),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'ok': true, 'data': data};
      }
      return {'ok': false, 'message': data['message'] ?? 'Lỗi gửi yêu cầu'};
    } catch (e) {
      return {'ok': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // ============================================================
  // NOTIFICATIONS, SUBSIDY, CHAT...
  // ============================================================
  static Future<Map<String, dynamic>> getStudentSubsidy() async {
    try {
      if (_token == null) return {};
      final response = await http.get(Uri.parse('$baseUrl/subsidy/me'), headers: _authHeaders);
      if (response.statusCode == 200) return jsonDecode(utf8.decode(response.bodyBytes));
      return {};
    } catch (e) { return {}; }
  }

  static Future<List<dynamic>> getChatMessages() async {
    try {
      if (_token == null) return [];
      final response = await http.get(Uri.parse('$baseUrl/chat/me'), headers: _authHeaders);
      if (response.statusCode == 200) return jsonDecode(utf8.decode(response.bodyBytes));
      return [];
    } catch (e) { return []; }
  }

  static Future<Map<String, dynamic>?> sendChatMessage(String content) async {
    try {
      if (_token == null) return null;
      int? targetId;
      try {
        final convRes = await http.get(Uri.parse('$baseUrl/chat/conversations'), headers: _authHeaders);
        if (convRes.statusCode == 200) {
          final list = jsonDecode(utf8.decode(convRes.bodyBytes)) as List;
          if (list.isNotEmpty) targetId = list[0]['user_id'] as int?;
        }
      } catch (_) {}

      final body = {'content': content, if (targetId != null) 'toUserId': targetId};
      final response = await http.post(Uri.parse('$baseUrl/chat/send'), headers: _authHeaders, body: jsonEncode(body));
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 || response.statusCode == 201) return data;
      return null;
    } catch (e) { return null; }
  }

  static Future<int> getTotalSpent() async {
    try {
      if (_token == null) return 0;
      final orders = await getMyOrders();
      int total = 0;
      for (final order in orders) {
        final status = order['status']?.toString().toLowerCase() ?? '';
        final isCancelled = status.contains('cancelled') || status.contains('rejected') || status.contains('hủy') || status.contains('từ chối');
        if (!isCancelled) {
          total += int.tryParse(order['total']?.toString() ?? '0') ?? 0;
        }
      }
      return total;
    } catch (e) { return 0; }
  }

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      if (_token == null) return [];
      print('📡 GET $baseUrl/notifications');
      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: _authHeaders,
      );
      print('✅ Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is Map && data['list'] is List) {
          print('📦 Nhận ${data['list'].length} thông báo');
          return List<Map<String, dynamic>>.from(data['list']);
        }
      }
      return [];
    } catch (e) {
      print('❌ Lỗi getNotifications: $e');
      return [];
    }
  }

  static Future<bool> markNotificationRead(String id) async {
    try {
      if (_token == null) return false;
      print('📡 POST $baseUrl/notifications/$id/read');
      final response = await http.post(
        Uri.parse('$baseUrl/notifications/$id/read'),
        headers: _authHeaders,
      );
      print('✅ Status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Lỗi markNotificationRead: $e');
      return false;
    }
  }

  static Future<bool> markAllNotificationsAsRead() async {
    try {
      if (_token == null) return false;
      print('📡 POST $baseUrl/notifications/read-all');
      final response = await http.post(
        Uri.parse('$baseUrl/notifications/read-all'),
        headers: _authHeaders,
      );
      print('✅ Status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Lỗi markAllNotificationsAsRead: $e');
      return false;
    }
  }
}