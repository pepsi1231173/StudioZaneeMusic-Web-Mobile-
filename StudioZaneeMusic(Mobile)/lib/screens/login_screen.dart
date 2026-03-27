import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: "733911398737-5lp5cj8u69t5sogse349mh3equn0i6ef.apps.googleusercontent.com",
    scopes: ['email', 'profile'],
  );

  Future<void> _loginWithGoogle() async {
    try {
      setState(() => _isLoading = true);
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      print("✅ ID Token: ${googleAuth.idToken}");

      final response = await http.post(
        Uri.parse('http://192.168.1.22:5167/api/AuthApi/LoginWithGoogle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': googleAuth.idToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Map<String, dynamic> user = {};
        if (data['user'] != null) {
          user = Map<String, dynamic>.from(data['user']);
        } else {
          user = {
            'id': '',
            'fullName': googleUser.displayName ?? '',
            'email': googleUser.email,
            'avatar': googleUser.photoUrl ?? '',
            'userName': googleUser.email.split('@')[0], // 👈 tự đặt userName mặc định
            'phoneNumber': '', // 👈 thêm phoneNumber trống để Profile không lỗi
          };

        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', user['id'] ?? '');
        await prefs.setString('user_fullname', user['fullName'] ?? '');
        await prefs.setString('user_email', user['email'] ?? '');
        await prefs.setString('user_avatar', user['avatar'] ?? '');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng nhập Google thành công!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(userData: user)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server từ chối đăng nhập Google (${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi Google Sign-In: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('http://192.168.1.22:5167/api/AuthApi/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'] ?? {};
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', user['id'] ?? '');
        await prefs.setString('user_fullname', user['fullName'] ?? '');
        await prefs.setString('user_email', user['email'] ?? '');
        await prefs.setString('user_avatar', user['avatar'] ?? '');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng nhập thành công!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(userData: user)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sai email hoặc mật khẩu')),
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
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/BACKROUND.jpg', fit: BoxFit.cover),
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
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.deepOrangeAccent.shade100,
                    highlightColor: Colors.yellowAccent,
                    period: const Duration(seconds: 3),
                    child: Image.asset(
                      'assets/images/logo5.png',
                      height: screenHeight * 0.16,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLoginForm(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amberAccent, width: 2),
        ),
        child: Column(
          children: [
            Text('Đăng nhập',
                style: GoogleFonts.lobster(
                    fontSize: 26, color: Colors.amberAccent)),
            const SizedBox(height: 24),
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Email', Icons.email_outlined),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Mật khẩu', Icons.lock_outline,
                  suffix: IconButton(
                    icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.amberAccent),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  )),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator(color: Colors.amberAccent)
                : ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amberAccent,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Đăng nhập'),
            ),
            const SizedBox(height: 16),
            SignInButton(Buttons.GoogleDark,
                text: "Đăng nhập với Google", onPressed: _loginWithGoogle),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RegisterScreen()));
              },
              child: const Text('Chưa có tài khoản? Đăng ký ngay',
                  style: TextStyle(
                      color: Colors.amberAccent,
                      decoration: TextDecoration.underline)),
            )
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon,
      {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.amberAccent),
      suffixIcon: suffix,
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.amberAccent),
        borderRadius: BorderRadius.circular(16),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.amber),
        borderRadius: BorderRadius.circular(16),
      ),
      filled: true,
      fillColor: Colors.black.withOpacity(0.4),
    );
  }
}
