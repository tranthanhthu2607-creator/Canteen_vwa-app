// ============================================================
// 🤖 CHATBOT LOGIC (Đã fix lỗi hiển thị và so sánh giá)
// ============================================================

String normalizeText(String s) {
  return s
      .toLowerCase()
      .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
      .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
      .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
      .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
      .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
      .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
      .replaceAll('đ', 'd')
      .trim();
}

Map<String, dynamic>? getBotReply(String userText, List<dynamic> menuItems) {
  final text = normalizeText(userText);
  if (text.isEmpty) return null;

  // 1. Kiểm tra chào hỏi
  if (text.contains('chao') || text.contains('hi') || text.contains('hello') || text.contains('alo')) {
    return {
      'text': 'Xin chào! 👋 Mình là trợ lý Canteen VWA. Bạn muốn ăn gì hôm nay?',
      'items': [],
    };
  }

  // 2. Lọc theo giá (dưới 30k)
  if (text.contains('duoi') || text.contains('gia re') || text.contains('sinh vien') || text.contains('tiet kiem')) {
    final items = menuItems.where((m) {
      final price = int.tryParse(m['price']?.toString() ?? '0') ?? 0;
      return price <= 30000;
    }).take(3).toList();

    if (items.isEmpty) {
       return {'text': 'Hiện chưa có món nào dưới 30k.', 'items': []};
    }
    return {
      'text': '💰 Món dưới 30k cho bạn đây:',
      'items': items,
    };
  }

  // 3. Lọc món chay
  if (text.contains('chay')) {
    final items = menuItems
        .where((m) => (m['category'] ?? '').toString().toLowerCase().contains('chay'))
        .take(3)
        .toList();
    if (items.isEmpty) {
       return {'text': 'Hiện chưa có món chay trong thực đơn.', 'items': []};
    }
    return {
      'text': '🥗 Món chay ngon tại Canteen:',
      'items': items,
    };
  }

  // 4. Lọc đồ uống
  if (text.contains('nuoc') || text.contains('uong')) {
    final items = menuItems
        .where((m) => (m['category'] ?? '').toString().toLowerCase().contains('uống'))
        .take(3)
        .toList();
    if (items.isEmpty) {
       return {'text': 'Hiện chưa có đồ uống trong thực đơn.', 'items': []};
    }
    return {
      'text': '🥤 Đồ uống tại Canteen:',
      'items': items,
    };
  }

  // 5. Lọc món bán chạy
  if (text.contains('ban chay') || text.contains('hot') || text.contains('ngon')) {
    final items = [...menuItems]..sort((a, b) {
      final soldA = int.tryParse(a['sold']?.toString() ?? '0') ?? 0;
      final soldB = int.tryParse(b['sold']?.toString() ?? '0') ?? 0;
      return soldB.compareTo(soldA);
    });
    return {
      'text': '🔥 Top món bán chạy:',
      'items': items.take(3).toList(),
    };
  }

  // 6. Lọc món cay
  if (text.contains('cay')) {
    final items = menuItems
        .where((m) => normalizeText(m['name'] ?? '').contains('cay'))
        .take(3)
        .toList();
    if (items.isEmpty) {
       return {'text': 'Hiện chưa có món cay trong thực đơn.', 'items': []};
    }
    return {
      'text': '🌶️ Món cay bạn có thể thử:',
      'items': items,
    };
  }

  // 7. Fallback nếu không hiểu
  return {
    'text': 'Mình chưa hiểu câu hỏi này. 🤔 Bạn thử hỏi: "dưới 30k", "chay", "nước", "cay", "bán chạy".',
    'items': [],
  };
}