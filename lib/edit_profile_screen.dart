import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api.dart';
import 'custom_app_bar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  bool _isSaving = false;

  // Trạng thái chỉnh sửa
  bool _isEditing = false;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _gender = 'nam';
  String _avatarBase64 = '';
  XFile? _pickedImage;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final user = await Api.getMe();
    if (mounted) {
      setState(() {
        _user = user;
        _nameCtrl.text = user?['name'] ?? '';
        _phoneCtrl.text = user?['phone'] ?? '';
        _addressCtrl.text = user?['address'] ?? '';
        _gender = user?['gender'] ?? 'nam';
        _avatarBase64 = user?['avatar'] ?? '';
        _pickedImage = null; // Reset ảnh đã chọn
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // XỬ LÝ CHỌN ẢNH
  // ============================================================
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 500,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        String base64String = base64Encode(bytes);
        
        if (!mounted) return;
        setState(() {
          _pickedImage = image;
          _avatarBase64 = 'data:image/jpeg;base64,$base64String';
        });
        _showSnack('Đã chọn ảnh mới!');
      }
    } catch (e) {
      _showSnack('Lỗi khi chọn ảnh: $e', isError: true);
    }
  }

  // ============================================================
  // XỬ LÝ LƯU THAY ĐỔI (ĐÃ THÊM THÔNG BÁO THÀNH CÔNG)
  // ============================================================
  Future<void> _saveProfile() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _showSnack('Họ tên không được để trống', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final payload = {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'gender': _gender,
        // Chỉ gửi avatar nếu là ảnh mới (Base64), tránh gửi lại URL cũ gây lỗi Backend
        if (_avatarBase64.startsWith('data:image')) 'avatar': _avatarBase64,
      };

      final res = await Api.updateProfile(payload);
      
      if (!mounted) return;

      if (res['ok'] == true) {
        setState(() => _isEditing = false);
        _showSnack('🎉 Lưu thông tin thành công!', isError: false); // Báo xanh lá
        _loadUserData(); // Tải lại dữ liệu mới nhất
      } else {
        _showSnack(res['message'] ?? 'Lỗi khi lưu thông tin. Vui lòng thử lại.', isError: true);
      }
    } catch (e) {
      _showSnack('Lỗi kết nối: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(
        title: 'Hồ sơ cá nhân',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 24),
                  _isEditing ? _buildEditForm() : _buildDetailInfoCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // ============================================================
  // 1. THẺ HEADER
  // ============================================================
  Widget _buildHeaderCard() {
    final name = _user?['name'] ?? 'Người dùng VWA';
    final email = _user?['email'] ?? 'Chưa cập nhật email';
    final avatarUrl = _avatarBase64;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _isEditing ? _pickImage : null,
                child: Stack(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6),
                        borderRadius: BorderRadius.circular(12),
                        border: _isEditing ? Border.all(color: const Color(0xFF2563EB), width: 2) : null,
                      ),
                      child: avatarUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: _pickedImage != null
                                ? (kIsWeb 
                                    ? Image.network(_pickedImage!.path, fit: BoxFit.cover)
                                    : Image.file(File(_pickedImage!.path), fit: BoxFit.cover))
                                : Image.network(avatarUrl, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _buildAvatarLetter(name)),
                            )
                          : _buildAvatarLetter(name),
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                        ),
                      )
                    else if (avatarUrl.isNotEmpty)
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 20),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: Color(0xFF2563EB), size: 18),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          const Row(
            children: [
              Icon(Icons.sync, color: Color(0xFF94A3B8), size: 14),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Đồng bộ SSO VWA • Cập nhật 10 phút trước',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // 🔥 NÚT LƯU (HIỂN THỊ KHI ĐANG SỬA)
          if (_isEditing) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveProfile,
                icon: _isSaving 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save, size: 18),
                label: Text(_isSaving ? 'Đang lưu...' : 'Lưu thay đổi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
          
          // 🔥 NÚT CHỈNH SỬA (HIỂN THỊ KHI ĐANG XEM)
          if (!_isEditing) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Chỉnh sửa hồ sơ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatarLetter(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ============================================================
  // 2. FORM CHỈNH SỬA
  // ============================================================
  Widget _buildEditForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chỉnh sửa thông tin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 20),
          
          _buildTextField('Họ và tên', _nameCtrl, Icons.person),
          const SizedBox(height: 16),
          _buildTextField('Số điện thoại', _phoneCtrl, Icons.phone, keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          _buildTextField('Địa chỉ', _addressCtrl, Icons.location_on),
          const SizedBox(height: 16),

          const Text('Giới tính', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          const SizedBox(height: 8),
          Row(
            children: ['nam', 'nu', 'khac'].map((g) {
              final label = g == 'nam' ? 'Nam' : (g == 'nu' ? 'Nữ' : 'Khác');
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: ChoiceChip(
                  label: Text(label),
                  selected: _gender == g,
                  onSelected: (val) => setState(() => _gender = g),
                  selectedColor: const Color(0xFF2563EB).withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: _gender == g ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                    fontWeight: _gender == g ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          _buildLockedField('Mã số sinh viên (MSSV)', _user?['student_code'] ?? 'Chưa liên kết', Icons.badge),
          const SizedBox(height: 12),
          _buildLockedField('Khoa / Ngành học', _user?['faculty'] ?? '—', Icons.school),
          const SizedBox(height: 12),
          _buildLockedField('Email', _user?['email'] ?? '—', Icons.email),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : () => setState(() => _isEditing = false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveProfile,
                  icon: _isSaving 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save, size: 18),
                  label: Text(_isSaving ? 'Đang lưu...' : 'Lưu thay đổi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, IconData icon, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildLockedField(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
            const SizedBox(width: 6),
            const Icon(Icons.lock, size: 12, color: Color(0xFF94A3B8)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF94A3B8), size: 20),
              const SizedBox(width: 12),
              Text(value, style: const TextStyle(fontSize: 15, color: Color(0xFF64748B))),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 3. CHI TIẾT THÔNG TIN
  // ============================================================
  Widget _buildDetailInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, color: Color(0xFF1E293B), size: 22),
              const SizedBox(width: 8),
              const Text(
                'Thông tin chi tiết',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 800 ? 4 : (constraints.maxWidth > 500 ? 3 : 2);
              
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 3.2, 
                ),
                itemCount: 10,
                itemBuilder: (context, index) {
                  return _buildInfoItem(index);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(int index) {
    final studentCode = _user?['student_code'] ?? 'Chưa liên kết';
    final major = _user?['major'] ?? '—';
    final faculty = _user?['faculty'] ?? '—';
    final phone = _user?['phone'] ?? 'Chưa cập nhật';
    final email = _user?['email'] ?? '—';
    final enrollYear = _user?['enroll_year']?.toString() ?? '—';
    final className = _user?['class_name'] ?? '—';
    final gender = _user?['gender'] ?? '—';
    final dob = _user?['dob'] ?? '—';
    final address = _user?['address'] ?? '—';

    final List<Map<String, dynamic>> items = [
      {'icon': Icons.badge_outlined, 'label': 'MÃ SỐ SINH VIÊN', 'value': studentCode, 'isBold': studentCode == 'Chưa liên kết'},
      {'icon': Icons.school_outlined, 'label': 'NGÀNH HỌC', 'value': major},
      {'icon': Icons.account_balance_outlined, 'label': 'KHOA', 'value': faculty},
      {'icon': Icons.phone_outlined, 'label': 'SỐ ĐIỆN THOẠI', 'value': phone, 'isBold': phone == 'Chưa cập nhật'},
      {'icon': Icons.email_outlined, 'label': 'EMAIL', 'value': email},
      {'icon': Icons.calendar_today_outlined, 'label': 'NĂM NHẬP HỌC', 'value': enrollYear},
      {'icon': Icons.class_outlined, 'label': 'LỚP', 'value': className},
      {'icon': Icons.person_outline, 'label': 'GIỚI TÍNH', 'value': gender == 'nam' ? 'Nam' : (gender == 'nu' ? 'Nữ' : 'Khác')},
      {'icon': Icons.cake_outlined, 'label': 'NGÀY SINH', 'value': dob},
      {'icon': Icons.location_on_outlined, 'label': 'ĐỊA CHỈ', 'value': address},
    ];

    final item = items[index];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(item['icon'] as IconData, color: const Color(0xFF64748B), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item['label'] as String,
                  style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600, letterSpacing: 0.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item['value'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: (item['isBold'] == true) ? FontWeight.bold : FontWeight.w500,
                    color: const Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}