// ============================================================
// 💬 CHAT BUBBLE WIDGET (Hỗ trợ Dark Mode + Hiển thị món ăn)
// ============================================================
import 'package:flutter/material.dart';
import 'api.dart';
import 'chatbot_logic.dart';

const Color kChatBlue = Color(0xFF2563EB);
const Color kChatTextPrimary = Color(0xFF172033);
const Color kChatTextMuted = Color(0xFF64748B);
const Color kChatBorder = Color(0xFFE5E9EF); // 👈 Viền xám cố định
const Color kChatBotColor = Color(0xFF2563EB);
const Color kChatStaffColor = Color(0xFF8B5CF6);

class ChatBubble extends StatefulWidget {
  const ChatBubble({super.key});

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  double _xPosition = 0;
  double _yPosition = 0;
  bool _isInitialized = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    if (!_isInitialized) {
      _xPosition = size.width - 64;
      _yPosition = size.height - 140 - bottomPadding;
      _isInitialized = true;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Khung Chat
        if (_isOpen)
          Positioned(
            left: _xPosition > size.width / 2 ? _xPosition - 280 : _xPosition,
            top: _yPosition - 440,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: Container(
                width: 300,
                height: 450,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const ChatScreen(),
              ),
            ),
          ),

        // 2. Nút bong bóng Chat
        Positioned(
          left: _xPosition,
          top: _yPosition,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _xPosition += details.delta.dx;
                _yPosition += details.delta.dy;
                _xPosition = _xPosition.clamp(0, size.width - 48);
                _yPosition = _yPosition.clamp(0, size.height - 48);
              });
            },
            onTap: () {
              setState(() {
                _isOpen = !_isOpen;
              });
            },
            child: SizedBox(
              width: 120,
              height: 120,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Hiệu ứng sóng
                    if (!_isOpen) ...[
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 48 + (_pulseAnimation.value * 48),
                            height: 48 + (_pulseAnimation.value * 48),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kChatBlue.withOpacity(1 - _pulseAnimation.value),
                            ),
                          );
                        },
                      ),
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          final delayedValue = (_pulseAnimation.value + 0.5) % 1.0;
                          return Container(
                            width: 48 + (delayedValue * 48),
                            height: 48 + (delayedValue * 48),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kChatBlue.withOpacity(1 - delayedValue),
                            ),
                          );
                        },
                      ),
                    ],

                    // Nút chính
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: kChatBlue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: kChatBlue.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isOpen ? Icons.close : Icons.forum_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// 💬 CHAT SCREEN
// ============================================================
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String _currentTab = 'ai';

  final List<Map<String, dynamic>> _aiMessages = [];
  final TextEditingController _aiController = TextEditingController();
  final ScrollController _aiScrollController = ScrollController();
  bool _aiTyping = false;
  List<dynamic> _menuItems = [];

  final List<String> _quickReplies = [
    'Dưới 30k',
    'Món chay',
    'Đồ uống',
    'Món cay',
    'Bán chạy',
    'Gợi ý'
  ];

  final List<dynamic> _staffMessages = [];
  final TextEditingController _staffController = TextEditingController();
  final ScrollController _staffScrollController = ScrollController();
  bool _staffLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMenu();
    _initAiChat();
  }

  void _initAiChat() {
    final String userName = Api.currentUser?['name'] ?? 'bạn';

    final List<Map<String, String>> smartSuggestions = [
      {'icon': '🥗', 'text': 'Gợi ý món ít calo dưới 300 kcal'},
      {'icon': '⚡', 'text': 'Món nào ra nhanh dưới 10 phút?'},
      {'icon': '🌱', 'text': 'Thực đơn chay thanh đạm'},
      {'icon': '💰', 'text': 'Món ngon sinh viên tiết kiệm'},
      {'icon': '⚠️', 'text': 'Món cam kết KHÔNG có hạt'},
    ];

    _aiMessages.clear();
    _aiMessages.add({
      'from': 'bot',
      'text': 'Xin chào $userName! 👋 Mình là Trợ lý AI của Canteen VWA.\nMình có thể giúp gì cho bạn hôm nay?',
      'items': [],
      'suggestions': smartSuggestions,
      'time': DateTime.now(),
    });
  }

  Future<void> _loadMenu() async {
    final menu = await Api.getMenu();
    setState(() => _menuItems = menu);
  }

  Future<void> _loadStaffMessages() async {
    setState(() => _staffLoading = true);
    final msgs = await Api.getChatMessages();
    setState(() {
      _staffMessages.clear();
      _staffMessages.addAll(msgs);
      _staffLoading = false;
    });
    _scrollToBottom(_staffScrollController);
  }

  void _scrollToBottom(ScrollController controller) {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (controller.hasClients) {
        controller.animateTo(
          controller.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendAiMessage([String? quickText]) {
    final text = quickText ?? _aiController.text.trim();
    if (text.isEmpty || _aiTyping) return;

    setState(() {
      _aiMessages.add({'from': 'user', 'text': text, 'time': DateTime.now()});
      if (quickText == null) _aiController.clear();
      _aiTyping = true;
    });
    _scrollToBottom(_aiScrollController);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final reply = getBotReply(text, _menuItems);
      setState(() {
        _aiTyping = false;
        _aiMessages.add({
          'from': 'bot',
          'text': reply?['text'] ?? 'Xin lỗi, tôi không hiểu.',
          'items': reply?['items'] ?? [],
          'time': DateTime.now(),
        });
      });
      _scrollToBottom(_aiScrollController);
    });
  }

  Future<void> _sendStaffMessage() async {
    final text = _staffController.text.trim();
    if (text.isEmpty) return;

    _staffController.clear();
    final msg = await Api.sendChatMessage(text);
    if (msg != null) {
      setState(() {
        _staffMessages.add(msg);
      });
      _scrollToBottom(_staffScrollController);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // HEADER
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            border: const Border(bottom: BorderSide(color: kChatBorder)),
          ),
          child: Row(
            children: [
              const Icon(Icons.smart_toy, color: kChatBotColor, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Canteen VWA Assistant',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              
              if (_currentTab == 'ai')
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentTab = 'staff';
                      if (_staffMessages.isEmpty) _loadStaffMessages();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.headset_mic_outlined, size: 12, color: Theme.of(context).textTheme.bodyLarge?.color),
                        const SizedBox(width: 2),
                        Text(
                          'Quầy Bếp',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(width: 8),
              
              GestureDetector(
                onTap: () {
                  if (_currentTab == 'ai') {
                    setState(() {
                      _initAiChat();
                    });
                  } else {
                    _loadStaffMessages();
                  }
                },
                child: Icon(Icons.refresh, size: 18, color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
            ],
          ),
        ),

        // NỘI DUNG
        Expanded(
          child: _currentTab == 'ai' 
              ? _buildAiTab() 
              : _buildStaffTab(),
        ),
      ],
    );
  }

  Widget _buildAiTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _aiScrollController,
            padding: const EdgeInsets.all(10),
            itemCount: _aiMessages.length + (_aiTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _aiMessages.length && _aiTyping) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Row(
                      children: [
                        const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: kChatBotColor)),
                        const SizedBox(width: 6),
                        Text('Đang gõ...', style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color)),
                      ],
                    ),
                  ),
                );
              }
              final msg = _aiMessages[index];
              return _buildAiMessage(msg);
            },
          ),
        ),
        
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: _quickReplies.length,
            itemBuilder: (context, index) {
              final text = _quickReplies[index];
              return GestureDetector(
                onTap: () => _sendAiMessage(text),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border.all(color: kChatBorder),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                ),
              );
            },
          ),
        ),

        _buildInputArea(_aiController, _sendAiMessage, 'Hỏi AI...'),
      ],
    );
  }

  // ============================================================
  // 👈 ĐÃ FIX: THÊM HIỂN THỊ DANH SÁCH MÓN ĂN (ITEMS)
  // ============================================================
  Widget _buildAiMessage(Map<String, dynamic> msg) {
    final isUser = msg['from'] == 'user';
    final suggestions = msg['suggestions'] as List<dynamic>?;
    final items = msg['items'] as List<dynamic>?; // Lấy danh sách món ăn

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75), // Tăng chiều rộng để chứa thẻ món
        decoration: BoxDecoration(
          color: isUser ? kChatBotColor : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: isUser ? const Radius.circular(14) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(14),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              const Row(
                children: [
                  Icon(Icons.smart_toy, size: 12, color: kChatBotColor),
                  SizedBox(width: 3),
                  Text('Canteen VWA', 
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kChatBotColor)
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            Text(
              msg['text'],
              style: TextStyle(
                color: isUser ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 12,
                height: 1.3,
              ),
            ),
            
            // 👈 HIỂN THỊ DANH SÁCH MÓN ĂN TẠI ĐÂY
            if (items != null && items.isNotEmpty) ...[
              const SizedBox(height: 10),
              Column(
                children: items.map((it) => _buildFoodCard(it)).toList(),
              ),
            ],

            if (suggestions != null && suggestions.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...suggestions.map((s) => GestureDetector(
                onTap: () => _sendAiMessage(s['text'] as String),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kChatBorder),
                  ),
                  child: Row(
                    children: [
                      Text(s['icon'] as String, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          s['text'] as String,
                          style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              )).toList(),
            ],
          ],
        ),
      ),
    );
  }

  // 👈 Hàm vẽ thẻ món ăn
  Widget _buildFoodCard(dynamic food) {
    final price = int.tryParse(food['price']?.toString() ?? '0') ?? 0;
    final imageUrl = food['image'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kChatBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ảnh món ăn
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
            child: SizedBox(
              width: 70,
              height: 70,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.fastfood, color: Colors.grey)),
                    )
                  : Container(color: Colors.grey[200], child: const Icon(Icons.fastfood, color: Colors.grey)),
            ),
          ),
          
          // Thông tin món ăn
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food['name'] ?? 'Món ăn',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kChatBotColor),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          // Xử lý thêm vào giỏ hàng (nếu cần)
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: kChatBotColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Thêm', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffTab() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          color: Theme.of(context).scaffoldBackgroundColor,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _currentTab = 'ai';
              });
            },
            child: Row(
              children: [
                Icon(Icons.arrow_back_ios, size: 10, color: Theme.of(context).textTheme.bodyMedium?.color),
                const SizedBox(width: 4),
                Text(
                  'Quay lại Trợ lý AI',
                  style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        
        Expanded(
          child: _staffLoading
              ? const Center(child: CircularProgressIndicator(color: kChatStaffColor))
              : _staffMessages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.support_agent, size: 40, color: Theme.of(context).textTheme.bodyMedium?.color),
                          const SizedBox(height: 8),
                          Text('Chưa có tin nhắn nào.\nHãy gửi lời chào đến quầy bếp!', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _staffScrollController,
                      padding: const EdgeInsets.all(10),
                      itemCount: _staffMessages.length,
                      itemBuilder: (context, index) {
                        final msg = _staffMessages[index];
                        return _buildStaffMessage(msg);
                      },
                    ),
        ),
        _buildInputArea(_staffController, _sendStaffMessage, 'Nhập tin nhắn...'),
      ],
    );
  }

  Widget _buildStaffMessage(dynamic msg) {
    final isUser = msg['from'] == 'customer'; 
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
        decoration: BoxDecoration(
          color: isUser ? kChatStaffColor : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: isUser ? const Radius.circular(14) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(14),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Text(
                msg['from_name'] ?? 'Nhân viên',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kChatStaffColor),
              ),
            Text(
              msg['content'] ?? '',
              style: TextStyle(
                color: isUser ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(TextEditingController controller, VoidCallback onSend, String hint) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        border: const Border(top: BorderSide(color: kChatBorder)),
        color: Theme.of(context).cardColor,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onSend,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: kChatBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}