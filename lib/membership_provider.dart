import 'package:flutter/material.dart';

class MembershipProvider extends ChangeNotifier {
  int _currentTierIndex = 0;
  int _totalSpent = 0;

  static const List<Map<String, dynamic>> tiers = [
    {
      'name': 'Đồng',
      'color': Color(0xFFCD7F32),
      'minSpend': 0,
      'maxSpend': 1000000,
      'benefits': [
        'Tích điểm cơ bản 1%',
        'Miễn phí giao hàng nội bộ',
        'Hỗ trợ cơ bản'
      ],
    },
    {
      'name': 'Bạc',
      'color': Color(0xFFC0C0C0),
      'minSpend': 1000000,
      'maxSpend': 3000000,
      'benefits': [
        'Tích điểm 2%',
        'Giảm 10k ship',
        'Voucher sinh nhật 20k',
        'Ưu tiên lấy món'
      ],
    },
    {
      'name': 'Vàng',
      'color': Color(0xFFD4AF37),
      'minSpend': 3000000,
      'maxSpend': 10000000,
      'benefits': [
        'Tích điểm 3%',
        'Miễn phí ship',
        'Voucher sinh nhật 50k',
        'Đổi quà không giới hạn',
        'Hỗ trợ VIP'
      ],
    },
    {
      'name': 'Kim Cương',
      'color': Color(0xFF00B4DB),
      'minSpend': 10000000,
      'maxSpend': null,
      'benefits': [
        'Tích điểm 5%',
        'Miễn phí ship',
        'Voucher sinh nhật 100k',
        'Đặc quyền VWA Green',
        'Quà tặng đặc biệt'
      ],
    },
  ];

  int get currentTierIndex => _currentTierIndex;
  int get totalSpent => _totalSpent;
  Map<String, dynamic> get currentTier => tiers[_currentTierIndex];
  
  Map<String, dynamic>? get nextTier {
    if (_currentTierIndex < tiers.length - 1) {
      return tiers[_currentTierIndex + 1];
    }
    return null;
  }

  void updateTierBySpending(int totalSpent) {
    _totalSpent = totalSpent;
    int newIndex = 0;
    
    for (int i = tiers.length - 1; i >= 0; i--) {
      if (totalSpent >= (tiers[i]['minSpend'] as int)) {
        newIndex = i;
        break;
      }
    }
    
    if (_currentTierIndex != newIndex) {
      _currentTierIndex = newIndex;
      notifyListeners();
    }
  }
}

class MembershipScope extends InheritedNotifier<MembershipProvider> {
  const MembershipScope({
    super.key,
    required MembershipProvider provider,
    required super.child,
  }) : super(notifier: provider);

  static MembershipProvider of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MembershipScope>();
    if (scope == null) {
      throw FlutterError(
        'MembershipScope not found in widget tree.\n'
        'Wrap your widget tree with MembershipScope(provider: ..., child: ...)',
      );
    }
    return scope.notifier!;
  }
}