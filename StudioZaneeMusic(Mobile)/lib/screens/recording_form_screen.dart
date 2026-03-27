import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'invoice_recording_screen.dart';

class RecordingFormScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const RecordingFormScreen({super.key, this.userData});

  @override
  _RecordingFormScreenState createState() => _RecordingFormScreenState();
}

class _RecordingFormScreenState extends State<RecordingFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? recordingPackage;
  DateTime recordingDate = DateTime.now();
  int recordingStartHour = 8;
  int recordingDuration = 1;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;

  final Color accent = const Color(0xFFFFC107);

  @override
  void initState() {
    super.initState();

    // ✅ Nếu có userData (ví dụ từ Google / ProfileScreen)
    if (widget.userData != null) {
      _nameController.text = widget.userData!["fullName"] ?? '';
      _emailController.text = widget.userData!["email"] ?? '';
      _phoneController.text = widget.userData!["phoneNumber"] ?? '';
    }

    // ✅ Nếu vẫn trống => load SharedPreferences
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      _loadUserProfile();
    }
  }


  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        if (_nameController.text.isEmpty) {
          _nameController.text = prefs.getString('user_fullname') ?? '';
        }
        if (_emailController.text.isEmpty) {
          _emailController.text = prefs.getString('user_email') ?? '';
        }
        if (_phoneController.text.isEmpty) {
          _phoneController.text = prefs.getString('user_phone') ?? '';
        }
      });
    } catch (e) {
      debugPrint("⚠️ Không thể tải thông tin người dùng: $e");
    }
  }


  // ====================== Giao diện ======================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🎸 Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/BACKROUND.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.9),
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.9),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.amberAccent),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.amber, Colors.orangeAccent],
                      ).createShader(bounds),
                      child: const Text(
                        "🎤 DỊCH VỤ THU ÂM CHUYÊN NGHIỆP",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // 🧊 Form Card
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                            color: Colors.amberAccent.withOpacity(0.4)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.2),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildRadioCard(
                            value: 'Thu âm thô',
                            label: '🎙 Thu âm thô - 200.000VNĐ',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7B1FA2), Color(0xFF9C27B0)],
                            ),
                          ),
                          _buildRadioCard(
                            value: 'Thu âm chỉnh sửa',
                            label: '🎧 Thu âm chỉnh sửa - 400.000VNĐ',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1976D2), Color(0xFF2196F3)],
                            ),
                          ),
                          _buildRadioCard(
                            value: 'Full chỉnh sửa & tư vấn kỹ thuật',
                            label:
                            '🎚 Full chỉnh sửa & tư vấn kỹ thuật - 900.000VNĐ',
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF9800), Color(0xFFFFC107)],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 🔹 Ngày & giờ
                          Row(
                            children: [
                              Expanded(child: _buildDatePicker()),
                              const SizedBox(width: 10),
                              Expanded(child: _buildTimeDropdown()),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 🔹 Thời lượng
                          _buildInput(
                            controller: TextEditingController(
                                text: recordingDuration.toString()),
                            label: 'Thời lượng (giờ)',
                            icon: Icons.timer_rounded,
                            keyboardType: TextInputType.number,
                            onChanged: (v) => recordingDuration =
                                int.tryParse(v) ?? 1,
                          ),
                          const SizedBox(height: 12),

                          // 🔹 Thông tin khách
                          _buildInput(
                            controller: _nameController,
                            label: 'Họ và tên',
                            icon: Icons.person,
                          ),
                          _buildInput(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email,
                          ),
                          _buildInput(
                            controller: _phoneController,
                            label: 'Số điện thoại',
                            icon: Icons.phone_android,
                          ),

                          const SizedBox(height: 25),
                          _buildSubmitButton(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ====================== Widgets ======================

  Widget _buildRadioCard({
    required String value,
    required String label,
    required Gradient gradient,
  }) {
    return GestureDetector(
      onTap: () => setState(() => recordingPackage = value),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: recordingPackage == value
              ? gradient
              : const LinearGradient(colors: [Colors.black26, Colors.black38]),
          border: Border.all(
            color: recordingPackage == value ? accent : Colors.grey.shade700,
            width: 1.8,
          ),
        ),
        child: Row(
          children: [
            Icon(
              recordingPackage == value
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: recordingPackage == value
                      ? Colors.white
                      : Colors.grey.shade300,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        validator: (v) =>
        v == null || v.isEmpty ? 'Vui lòng nhập $label' : null,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.amberAccent),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white30),
            borderRadius: BorderRadius.circular(15),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.amberAccent, width: 1.8),
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() => InputDecorator(
    decoration: _inputDecoration('Ngày thu'),
    child: InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: recordingDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) setState(() => recordingDate = picked);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          DateFormat('yyyy-MM-dd').format(recordingDate),
          style: const TextStyle(color: Colors.white),
        ),
      ),
    ),
  );

  Widget _buildTimeDropdown() => DropdownButtonFormField<int>(
    value: recordingStartHour,
    decoration: _inputDecoration('Giờ bắt đầu'),
    dropdownColor: Colors.black87,
    style: const TextStyle(color: Colors.white),
    items: List.generate(14, (i) => 8 + i)
        .map((h) => DropdownMenuItem(
      value: h,
      child: Text('${h.toString().padLeft(2, '0')}:00'),
    ))
        .toList(),
    onChanged: (v) => setState(() => recordingStartHour = v ?? 8),
  );

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white70),
    filled: true,
    fillColor: Colors.white.withOpacity(0.15),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
  );

  Widget _buildSubmitButton() => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Colors.amber, Colors.orangeAccent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: Colors.amberAccent.withOpacity(0.5),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        padding:
        const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      ),
      onPressed: _isLoading ? null : _submitForm,
      icon: _isLoading
          ? const CircularProgressIndicator(
          color: Colors.white, strokeWidth: 2)
          : const Icon(Icons.check_circle_outline,
          color: Colors.black87),
      label: Text(
        _isLoading ? 'Đang gửi...' : '🚀 XÁC NHẬN',
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    ),
  );

  // ====================== Submit ======================
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || recordingPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin 🎵')),
      );
      return;
    }

    // 🕒 Kiểm tra giờ hiện tại
    final now = DateTime.now();
    final selectedDateTime = DateTime(
      recordingDate.year,
      recordingDate.month,
      recordingDate.day,
      recordingStartHour,
    );

    // ❌ Không cho đặt trong quá khứ hoặc giờ đã qua hôm nay
    if (selectedDateTime.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⏰ Không thể đặt lịch trong quá khứ!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 📡 Lấy danh sách booking hiện tại để kiểm tra trùng giờ
      final checkResponse = await http.get(
        Uri.parse('http://10.0.2.2:5167/api/RecordingApi'),
      );

      if (checkResponse.statusCode == 200) {
        final existingBookings = jsonDecode(checkResponse.body) as List<dynamic>;

        bool isConflict = false;

        for (var booking in existingBookings) {
          final existingDate = DateTime.parse(booking['recordingDate']);
          final existingTimeParts = booking['recordingTime'].split(':');
          final existingStartHour = int.parse(existingTimeParts[0]);
          final existingDuration = booking['duration'];
          final existingEndHour = existingStartHour + existingDuration;

          // ✅ Kiểm tra cùng ngày
          if (existingDate.year == recordingDate.year &&
              existingDate.month == recordingDate.month &&
              existingDate.day == recordingDate.day) {
            // 🕒 Nếu thời gian overlap
            if (recordingStartHour < existingEndHour &&
                recordingStartHour + recordingDuration > existingStartHour) {
              isConflict = true;
              break;
            }
          }
        }

        if (isConflict) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('⚠️ Khung giờ này đã có người đặt, vui lòng chọn giờ khác.')),
          );
          return;
        }
      }

      // ✅ Nếu không trùng giờ, gửi đơn mới
      final data = {
        'customerName': _nameController.text,
        'customerEmail': _emailController.text,
        'customerPhone': _phoneController.text,
        'recordingPackage': recordingPackage,
        'recordingDate': DateFormat('yyyy-MM-dd').format(recordingDate),
        'recordingTime':
        '${recordingStartHour.toString().padLeft(2, '0')}:00:00',
        'duration': recordingDuration,
      };

      final response = await http.post(
        Uri.parse('http://10.0.2.2:5167/api/RecordingApi'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final invoice = jsonDecode(response.body);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎶 Gửi yêu cầu thu âm thành công!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => InvoiceRecordingScreen(
              booking: invoice,
              userData: {
                'fullname': _nameController.text,
                'email': _emailController.text,
                'phone': _phoneController.text,
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi kết nối server: $e')),
      );
    }

    setState(() => _isLoading = false);
  }


}
