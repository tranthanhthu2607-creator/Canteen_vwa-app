// ============================================================
// 🔔 NOTIFICATION SCREEN — Đồng bộ dữ liệu từ Web
// ============================================================
import 'package:flutter/material.dart';
import 'api.dart';

const Color kNBlue = Color(0xFF2563EB);
const Color kNBorder = Color(0xFFE5E9EF);

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  // ============================================================
  // LẤY DỮ LIỆU TỪ API
  // ============================================================
  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    try {
      final data = await Api.getNotifications();
      
      if (mounted) {
        setState(() {
          _notifications = data;
          // Đếm số lượng chưa đọc dựa trên trường 'read' từ Backend
          _unreadCount = _notifications.where((n) => n['read'] == false || n['read'] == 0).length;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải thông báo. Vui lòng thử lại!')),
        );
      }
    }
  }

  // ============================================================
  // ĐÁNH DẤU TẤT CẢ ĐÃ ĐỌC
  // ============================================================
  Future<void> _markAllAsRead() async {
    if (_unreadCount == 0) return;
    
    final success = await Api.markAllNotificationsAsRead();
    
    if (mounted && success) {
      setState(() {
        for (var notif in _notifications) {
          notif['read'] = true;
        }
        _unreadCount = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đánh dấu tất cả là đã đọc'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // ĐÁNH DẤU 1 THÔNG BÁO ĐÃ ĐỌC
  // ============================================================
  Future<void> _markOneAsRead(int index) async {
    final notif = _notifications[index];
    if (notif['read'] == true) return;

    final id = notif['id']?.toString() ?? '';
    if (id.isEmpty) return;

    // Cập nhật UI ngay lập tức (Optimistic UI)
    setState(() {
      notif['read'] = true;
      _unreadCount = (_unreadCount - 1).clamp(0, 999);
    });

    await Api.markNotificationRead(id);
  }

  // ============================================================
  // HELPER: Format thời gian (Vừa xong, X phút trước...)
  // ============================================================
  String _timeAgo(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Vừa xong';
      if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
      if (diff.inHours < 24) return '${diff.inHours} giờ trước';
      if (diff.inDays < 7) return '${diff.inDays} ngày trước';
      
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return '—';
    }
  }

  // ============================================================
  // HELPER: Lấy Icon & Màu theo loại thông báo (Giống Web)
  // ============================================================
  Map<String, dynamic> _getTypeStyle(String? type) {
    switch (type) {
      case 'order':
        return {'icon': Icons.shopping_bag, 'bg': const Color(0xFFFEF3C7), 'color': const Color(0xFFF59E0B)};
      case 'voucher':
        return {'icon': Icons.card_giftcard, 'bg': const Color(0xFFFCE7F3), 'color': const Color(0xFFEC4899)};
      case 'wallet':
        return {'icon': Icons.account_balance_wallet, 'bg': const Color(0xFFF3E8FF), 'color': const Color(0xFF8B5CF6)};
      case 'chat':
        return {'icon': Icons.chat_bubble, 'bg': const Color(0xFFE0E7FF), 'color': const Color(0xFF2634D5)};
      case 'system':
        return {'icon': Icons.info, 'bg': const Color(0xFFDCFCE7), 'color': const Color(0xFF18A967)};
      default:
        return {'icon': Icons.inventory_2, 'bg': const Color(0xFFF1F5F9), 'color': const Color(0xFF64748B)};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.only(top: 70, right: 16, left: 16, bottom: 80), 
      alignment: Alignment.topRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 550,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // === HEADER ===
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: kNBorder)),
              ),
              child: Row(
                children: [
                  Text(
                    'Thông báo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  if (_unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_unreadCount mới',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (_unreadCount > 0)
                    GestureDetector(
                      onTap: _markAllAsRead,
                      child: const Text(
                        'Đọc tất cả',
                        style: TextStyle(
                          fontSize: 13, 
                          color: kNBlue, 
                          fontWeight: FontWeight.w600
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.close, color: Theme.of(context).textTheme.bodyMedium?.color, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // === DANH SÁCH THÔNG BÁO ===
            Flexible(
              child: _loading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32), 
                        child: CircularProgressIndicator(color: kNBlue)
                      )
                    )
                  : _notifications.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.notifications_off_outlined, size: 48, color: Theme.of(context).textTheme.bodyMedium?.color),
                              const SizedBox(height: 12),
                              Text('Không có thông báo nào', style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _notifications.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: kNBorder),
                          itemBuilder: (context, index) {
                            final notif = _notifications[index];
                            final isRead = notif['read'] == true;
                            
                            // Lấy dữ liệu đúng theo Web
                            final title = notif['title'] ?? 'Thông báo';
                            final content = notif['content'] ?? '';
                            final createdAt = notif['created_at']?.toString();
                            final typeStyle = _getTypeStyle(notif['type']?.toString());

                            return InkWell(
                              onTap: () => _markOneAsRead(index),
                              child: Container(
                                color: isRead 
                                    ? Theme.of(context).cardColor 
                                    : kNBlue.withOpacity(0.05), // Nền xanh nhạt nếu chưa đọc
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Icon tròn theo loại thông báo
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: typeStyle['bg'] as Color,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        typeStyle['icon'] as IconData,
                                        color: typeStyle['color'] as Color,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    
                                    // Nội dung
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  title.toString(),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              // Chấm xanh nếu chưa đọc
                                              if (!isRead)
                                                Container(
                                                  margin: const EdgeInsets.only(top: 4, left: 8),
                                                  width: 8,
                                                  height: 8,
                                                  decoration: const BoxDecoration(
                                                    color: kNBlue,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          if (content.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              content.toString(),
                                              style: TextStyle(
                                                fontSize: 13, 
                                                color: Theme.of(context).textTheme.bodyMedium?.color, 
                                                height: 1.4
                                              ),
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                          const SizedBox(height: 6),
                                          Text(
                                            _timeAgo(createdAt),
                                            style: TextStyle(
                                              fontSize: 11, 
                                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)
                                            ),
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
      ),
    );
  }
}