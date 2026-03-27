import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SupportPolicyPage extends StatelessWidget {
  const SupportPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final policies = [
      "🔒 Bảo mật thông tin khách hàng tuyệt đối.",
      "⏰ Hỗ trợ 24/7 qua email và hotline.",
      "💰 Hoàn tiền nếu dịch vụ gặp sự cố kỹ thuật.",
      "🎵 Tất cả thiết bị được bảo trì định kỳ hàng tuần.",
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("🧾 Chính Sách & Hỗ Trợ",
            style: GoogleFonts.lobster(color: Colors.amberAccent, fontSize: 24)),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: policies.length,
        itemBuilder: (context, i) => Card(
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.check_circle_outline, color: Colors.amber),
            title: Text(policies[i],
                style: GoogleFonts.lato(color: Colors.white70, fontSize: 16)),
          ),
        ),
      ),
    );
  }
}
