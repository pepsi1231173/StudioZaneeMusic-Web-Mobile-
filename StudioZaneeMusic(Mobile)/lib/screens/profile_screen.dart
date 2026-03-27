import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ProfileScreen({super.key, required this.userData});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController fullNameController;
  late TextEditingController usernameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController currentPasswordController;
  late TextEditingController newPasswordController;

  File? _avatarImage;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;

  @override
  void initState() {
    super.initState();
    fullNameController = TextEditingController(text: widget.userData["fullName"] ?? "");
    usernameController = TextEditingController(text: widget.userData["userName"] ?? "");
    emailController = TextEditingController(text: widget.userData["email"] ?? "");
    phoneController = TextEditingController(text: widget.userData["phoneNumber"] ?? "");
    currentPasswordController = TextEditingController();
    newPasswordController = TextEditingController();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _avatarImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Không tìm thấy ID người dùng")),
      );
      return;
    }

    final uri = Uri.parse("http://192.168.1.22:5167/api/User/update/$userId");
    var request = http.MultipartRequest('POST', uri);

    request.fields['FullName'] = fullNameController.text;
    request.fields['UserName'] = usernameController.text;
    request.fields['Email'] = emailController.text;
    request.fields['PhoneNumber'] = phoneController.text;
    request.fields['CurrentPassword'] = currentPasswordController.text;
    request.fields['NewPassword'] = newPasswordController.text;

    if (_avatarImage != null) {
      request.files.add(await http.MultipartFile.fromPath('AvatarFile', _avatarImage!.path));
    }

    try {
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "✅ Cập nhật thành công")),
        );

        setState(() {
          widget.userData["fullName"] = data["user"]["fullName"];
          widget.userData["userName"] = data["user"]["userName"];
          widget.userData["email"] = data["user"]["email"];
          widget.userData["phoneNumber"] = data["user"]["phoneNumber"];
          widget.userData["avatar"] = data["user"]["avatar"];
          _avatarImage = null;
        });
      } else {
        final data = json.decode(responseBody);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "❌ Lỗi khi cập nhật thông tin")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Lỗi kết nối máy chủ: $e")),
      );
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatar = widget.userData["avatar"] ?? "";
    final avatarUrl = _avatarImage != null
        ? FileImage(_avatarImage!)
        : (avatar.startsWith("http")
        ? NetworkImage(avatar)
        : NetworkImage("http://192.168.1.22:5167$avatar")) as ImageProvider;


    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 🌌 Nền
          Positioned.fill(
            child: Image.asset(
              "assets/images/BACKROUND.jpg",
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.6),
              colorBlendMode: BlendMode.darken,
            ),
          ),

          // 🔸 Nội dung cuộn (avatar + form)
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickAvatar,
                  child: Container(
                    padding: const EdgeInsets.all(3.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Colors.amber, Colors.orangeAccent],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 63,
                      backgroundImage: avatarUrl,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Nhấn để thay đổi ảnh đại diện",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 25),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField("Họ và tên", fullNameController),
                      _buildTextField("Tên đăng nhập", usernameController),
                      _buildTextField("Email", emailController, type: TextInputType.emailAddress),
                      _buildTextField("Số điện thoại", phoneController, type: TextInputType.phone),
                      _buildTextField(
                        "Mật khẩu hiện tại",
                        currentPasswordController,
                        obscure: _obscureCurrentPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrentPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.amberAccent,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureCurrentPassword = !_obscureCurrentPassword;
                            });
                          },
                        ),
                      ),
                      _buildTextField(
                        "Mật khẩu mới",
                        newPasswordController,
                        obscure: _obscureNewPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.amberAccent,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureNewPassword = !_obscureNewPassword;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 25),
                      ElevatedButton.icon(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 36),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 8,
                          shadowColor: Colors.amberAccent,
                        ),
                        icon: const Icon(Icons.save, color: Colors.black),
                        label: const Text(
                          "Lưu thay đổi",
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 🟡 Header cố định (đè lên khi cuộn, nền đen đặc)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 90,
              color: Colors.black, // 🔥 Nền đen đặc
              padding: const EdgeInsets.only(top: 35, left: 20, right: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Cập nhật thông tin cá nhân",
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.amberAccent, size: 26),
                    onPressed: _logout,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller, {
        bool obscure = false,
        TextInputType type = TextInputType.text,
        Widget? suffixIcon,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: type,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.amberAccent, fontSize: 15),
          filled: true,
          fillColor: Colors.black.withOpacity(0.35),
          suffixIcon: suffixIcon,
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFFFB300), width: 2.8),
            borderRadius: BorderRadius.circular(14),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.amberAccent, width: 3.2),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
