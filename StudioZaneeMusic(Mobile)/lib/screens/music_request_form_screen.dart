import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/music_request.dart';
import '../services/api_service.dart';
import 'music_invoice_screen.dart'; // ✅ Thêm dòng này

class MusicRequestFormScreen extends StatefulWidget {
  final Map<String, dynamic>? userData; // ✅ Thêm dòng này

  const MusicRequestFormScreen({super.key,this.userData});



  @override
  _MusicRequestFormScreenState createState() => _MusicRequestFormScreenState();
}

class _MusicRequestFormScreenState extends State<MusicRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService apiService = ApiService();

  final TextEditingController genreController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // ✅ Ưu tiên đổ thông tin từ widget.userData nếu có
    nameController.text = widget.userData?["fullName"] ?? '';
    emailController.text = widget.userData?["email"] ?? '';
    phoneController.text = widget.userData?["phoneNumber"] ?? '';

    // ✅ Nếu chưa có thông tin thì load từ SharedPreferences
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty) {
      _loadUserProfile();
    }
  }


  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        if (nameController.text.isEmpty) {
          nameController.text = prefs.getString('user_fullname') ?? '';
        }
        if (emailController.text.isEmpty) {
          emailController.text = prefs.getString('user_email') ?? '';
        }
        if (phoneController.text.isEmpty) {
          phoneController.text = prefs.getString('user_phone') ?? '';
        }
      });
    } catch (e) {
      debugPrint("⚠️ Không thể tải thông tin người dùng: $e");
    }
  }


  // 📨 Gửi yêu cầu làm nhạc
  void submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final request = MusicRequest(
      musicGenre: genreController.text.trim(),
      musicDescription: descriptionController.text.trim(),
      customerName: nameController.text.trim(),
      customerEmail: emailController.text.trim(),
      customerPhone: phoneController.text.trim(),
    );

    try {
      final success = await apiService.createMusicRequest(request);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.greenAccent,
            content: Text(
              '✅ Gửi yêu cầu thành công! Đang chuyển đến trang xác nhận...',
              style: TextStyle(color: Colors.black),
            ),
          ),
        );

        // ✅ Chuyển trực tiếp sang trang hóa đơn (không cần route tên)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MusicInvoiceScreen(
              data: {
                'musicGenre': request.musicGenre,
                'musicDescription': request.musicDescription,
                'customerName': request.customerName,
                'customerEmail': request.customerEmail,
                'customerPhone': request.customerPhone,
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              '❌ Gửi yêu cầu thất bại! Vui lòng thử lại.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('❌ Lỗi khi gửi yêu cầu: $e'),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    genreController.dispose();
    descriptionController.dispose();
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🎸 Ảnh nền
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/BACKROUND.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Lớp phủ tối mờ
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.85),
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.85),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 🧩 Nội dung chính
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.amberAccent,
                        size: 26,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.amber, Colors.orangeAccent],
                    ).createShader(bounds),
                    child: const Text(
                      "🎶 DỊCH VỤ LÀM NHẠC 🎶",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.amberAccent.withOpacity(0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: genreController,
                            label: 'Thể loại nhạc',
                            icon: Icons.music_note_rounded,
                            validator: (v) =>
                            v!.isEmpty ? 'Vui lòng nhập thể loại nhạc' : null,
                          ),
                          _buildTextField(
                            controller: descriptionController,
                            label: 'Mô tả yêu cầu',
                            icon: Icons.edit_note_rounded,
                            maxLines: 3,
                            validator: (v) =>
                            v!.isEmpty ? 'Vui lòng nhập mô tả' : null,
                          ),
                          _buildTextField(
                            controller: nameController,
                            label: 'Họ và tên',
                            icon: Icons.person_rounded,
                            validator: (v) =>
                            v!.isEmpty ? 'Vui lòng nhập họ và tên' : null,
                          ),
                          _buildTextField(
                            controller: emailController,
                            label: 'Email',
                            icon: Icons.email_rounded,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Vui lòng nhập email';
                              final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                              if (!regex.hasMatch(v)) return 'Email không hợp lệ';
                              return null;
                            },
                          ),
                          _buildTextField(
                            controller: phoneController,
                            label: 'Số điện thoại',
                            icon: Icons.phone_android_rounded,
                            keyboardType: TextInputType.phone,
                            validator: (v) =>
                            v!.isEmpty ? 'Vui lòng nhập số điện thoại' : null,
                          ),
                          const SizedBox(height: 25),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.amberAccent, Colors.orangeAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
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
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 28),
                              ),
                              onPressed: _isLoading ? null : submitRequest,
                              icon: _isLoading
                                  ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : const Icon(Icons.send_rounded,
                                  color: Colors.black87),
                              label: Text(
                                _isLoading ? 'Đang gửi...' : 'GỬI YÊU CẦU',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.amberAccent),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.amberAccent),
          filled: true,
          fillColor: Colors.black.withOpacity(0.25),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.amberAccent, width: 1.2),
            borderRadius: BorderRadius.circular(15),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.orangeAccent, width: 2),
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}
