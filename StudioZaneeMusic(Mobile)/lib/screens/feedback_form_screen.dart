import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class FeedbackFormScreen extends StatefulWidget {
  final Map<String, dynamic> userData; // ✅ Thêm userData

  const FeedbackFormScreen({super.key, required this.userData});

  @override
  State<FeedbackFormScreen> createState() => _FeedbackFormScreenState();
}

class _FeedbackFormScreenState extends State<FeedbackFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();

  String name = '';
  String email = '';
  String phone = '';
  String message = '';
  int rating = 0;
  bool isLoading = false;

  final LatLng _studioLocation = const LatLng(10.8018, 106.7149);

  // 📤 Gửi phản hồi
  void submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;
    if (rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn số sao đánh giá 🌟')),
      );
      return;
    }

    _formKey.currentState!.save();
    setState(() => isLoading = true);

    final feedbackData = {
      "name": name,
      "email": email,
      "phone": phone,
      "rating": rating,
      "message": message,
    };

    final success = await _api.sendFeedback(feedbackData);
    setState(() => isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Gửi phản hồi thành công!")),
      );
      // ✅ Quay lại HomeScreen có dữ liệu user
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(userData: widget.userData),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Gửi phản hồi thất bại!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ AppBar với nút quay lại
      appBar: AppBar(
        backgroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.amber),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => HomeScreen(userData: widget.userData),
              ),
            );
          },
        ),
        title: const Text(
          "Gửi Phản Hồi",
          style: TextStyle(color: Colors.amber),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/BACKROUND.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 15),

                    // 🎶 Thông tin liên hệ + bản đồ
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.amber, width: 1.2),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "🎶 Thông tin liên hệ Zanee's Studio",
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFD700)),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Hãy để lại đánh giá để giúp chúng tôi phục vụ tốt hơn!",
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "📍 161 Nguyễn Gia Trí, Bình Thạnh, TP.HCM\n"
                                "📞 028 567 3405\n"
                                "📧 contact@zaneestudio.com",
                            style:
                            TextStyle(color: Colors.white, fontSize: 14.5),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 15),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              height: 220,
                              child: GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: _studioLocation,
                                  zoom: 15,
                                ),
                                markers: {
                                  Marker(
                                    markerId: const MarkerId('studio'),
                                    position: _studioLocation,
                                    infoWindow: const InfoWindow(
                                      title: "Zanee's Studio",
                                      snippet:
                                      "161 Nguyễn Gia Trí, Bình Thạnh, HCM",
                                    ),
                                  ),
                                },
                                zoomControlsEnabled: false,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ✏️ Form nhập liệu
                    _buildInput("Họ và tên", (v) => name = v,
                        "Vui lòng nhập họ tên"),
                    const SizedBox(height: 12),
                    _buildInput("Email", (v) => email = v,
                        "Vui lòng nhập email",
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Vui lòng nhập email";
                          if (!v.contains('@')) return "Email không hợp lệ";
                          return null;
                        }),
                    const SizedBox(height: 12),
                    _buildInput("Số điện thoại", (v) => phone = v,
                        "Vui lòng nhập số điện thoại"),
                    const SizedBox(height: 20),

                    // ⭐ Đánh giá sao
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Đánh giá dịch vụ:",
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starIndex = index + 1;
                        return IconButton(
                          onPressed: () => setState(() => rating = starIndex),
                          icon: Icon(
                            Icons.star,
                            color: rating >= starIndex
                                ? Colors.amber
                                : Colors.white38,
                            size: 32,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 15),

                    _buildInput("Nội dung góp ý", (v) => message = v,
                        "Vui lòng nhập nội dung",
                        maxLines: 5),
                    const SizedBox(height: 25),

                    ElevatedButton(
                      onPressed: isLoading ? null : submitFeedback,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 60, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text(
                        "Gửi Phản Hồi",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 17),
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

  Widget _buildInput(String label, Function(String) onSave, String errorMessage,
      {int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.amberAccent),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.amberAccent),
        ),
      ),
      validator: validator ?? (v) => v == null || v.isEmpty ? errorMessage : null,
      onSaved: (v) => onSave(v ?? ''),
    );
  }
}
