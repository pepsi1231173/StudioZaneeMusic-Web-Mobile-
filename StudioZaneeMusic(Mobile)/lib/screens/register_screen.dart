import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _register() async {
    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();

    if (fullName.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('http://192.168.1.22:5167/api/AuthApi/register');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'phoneNumber': phone,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng ký thành công!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Đăng ký thất bại: ${error['message'] ?? 'Lỗi không xác định'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🌆 Ảnh nền
          Image.asset(
            'assets/images/BACKROUND.jpg',
            fit: BoxFit.cover,
          ),

          // Overlay tối gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.5),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 🌟 Nội dung chính
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔥 Logo có hiệu ứng shimmer
                  Shimmer.fromColors(
                    baseColor: Colors.deepOrangeAccent.shade100,
                    highlightColor: Colors.yellowAccent,
                    period: const Duration(seconds: 3),
                    child: Image.asset(
                      'assets/images/logo5.png',
                      height: 130,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 🧾 Form đăng ký
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amberAccent, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Đăng ký tài khoản',
                            style: GoogleFonts.lobster(
                              fontSize: 26,
                              color: Colors.amberAccent,
                              shadows: const [
                                Shadow(
                                    blurRadius: 6,
                                    color: Colors.black,
                                    offset: Offset(1, 1))
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Họ và tên
                          TextField(
                            controller: fullNameController,
                            style: const TextStyle(color: Colors.white),
                            decoration:
                            _inputDecoration('Họ và tên', Icons.person),
                          ),
                          const SizedBox(height: 16),

                          // Email
                          TextField(
                            controller: emailController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration(
                                'Email', Icons.email_outlined),
                          ),
                          const SizedBox(height: 16),

                          // Số điện thoại
                          TextField(
                            controller: phoneController,
                            style: const TextStyle(color: Colors.white),
                            decoration:
                            _inputDecoration('Số điện thoại', Icons.phone),
                          ),
                          const SizedBox(height: 16),

                          // Mật khẩu
                          TextField(
                            controller: passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration(
                              'Mật khẩu',
                              Icons.lock_outline,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.amberAccent,
                                ),
                                onPressed: () => setState(() =>
                                _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Nút đăng ký
                          _isLoading
                              ? const CircularProgressIndicator(
                              color: Colors.amberAccent)
                              : ElevatedButton(
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amberAccent,
                              foregroundColor: Colors.black,
                              minimumSize:
                              const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Đăng ký'),
                          ),
                          const SizedBox(height: 16),

                          // Liên kết sang đăng nhập
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const LoginScreen()),
                              );
                            },
                            child: const Text(
                              'Đã có tài khoản? Đăng nhập ngay',
                              style: TextStyle(
                                color: Colors.amberAccent,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
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

  // 🎨 Trang trí input
  InputDecoration _inputDecoration(String label, IconData icon,
      {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.amberAccent),
      suffixIcon: suffix,
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.amberAccent),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.amberAccent, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
    );
  }
}
