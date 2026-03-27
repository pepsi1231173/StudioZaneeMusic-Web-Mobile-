import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'home_screen.dart'; // ✅ Đổi import sang HomeScreen

class InvoiceScreen extends StatelessWidget {
  final Map<String, dynamic> invoiceData;
  final Map<String, dynamic> userData; // ✅ Thêm dòng này

  const InvoiceScreen({
    super.key,
    required this.invoiceData,
    required this.userData, // ✅ Thêm dòng này
  });

  String formatCurrency(dynamic value) {
    if (value == null) return "0 VNĐ";
    try {
      final numVal = value is num
          ? value
          : num.tryParse(value.toString().replaceAll(RegExp(r'[^\d]'), "")) ?? 0;
      final format = NumberFormat("#,###", "vi_VN");
      return "${format.format(numVal)} VNĐ";
    } catch (_) {
      return value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Lấy phần dữ liệu invoice chính xác
    final Map<String, dynamic> data =
    (invoiceData["invoice"] is Map) ? invoiceData["invoice"] : invoiceData;

    final totalMoney =
        data["Tổng_Tiền"] ?? formatCurrency(data["tongTien"] ?? 0);

    // ✅ Lấy thông tin người dùng từ dữ liệu invoice (nếu có)

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Hóa đơn đặt phòng"),
        backgroundColor: Colors.amber.shade700,
        centerTitle: true,
        elevation: 5,
      ),
      body: Stack(
        children: [
          // 🌄 Ảnh nền
          Positioned.fill(
            child: Image.asset(
              "assets/images/BACKROUND.jpg",
              fit: BoxFit.cover,
            ),
          ),

          // 🌫️ Lớp phủ
          Container(color: Colors.black.withOpacity(0.55)),

          // 📜 Nội dung hóa đơn
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 🧾 Tiêu đề
                    Text(
                      "HÓA ĐƠN ĐẶT PHÒNG",
                      style: GoogleFonts.lobster(
                        textStyle: const TextStyle(
                          fontSize: 28,
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Mã đơn
                    Text(
                      "Mã đơn: ${data["MaDon"] ?? data["Mã_Đơn"] ?? "#----"}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 10),
                    const Divider(color: Colors.amber, thickness: 1.5),
                    const SizedBox(height: 10),

                    // 🧩 Chi tiết hóa đơn
                    ..._buildInvoiceDetails(data),

                    const SizedBox(height: 20),

                    // 💰 Tổng tiền nổi bật
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "💰 Tổng tiền:",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            totalMoney.toString(),
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // 🔙 Nút quay lại trang chủ (HomeScreen)
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HomeScreen(userData: userData),
                              // ✅ sửa ở đây
                            ),
                                (route) => false,
                          );
                        },


                        icon: const Icon(Icons.home),
                        label: const Text("Quay lại trang chủ"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 6,
                        ),
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

  // 🧩 Chi tiết hóa đơn
  List<Widget> _buildInvoiceDetails(Map<String, dynamic> data) {
    final List<Widget> details = [];

    data.forEach((key, value) {
      if (key == "tongTien" || key == "Tổng_Tiền") return;

      if (value is Map) {
        details.add(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$key:",
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            ...value.entries.map(
                  (e) => Padding(
                padding: const EdgeInsets.only(left: 10, bottom: 4),
                child: Text(
                  "• ${e.key}: ${e.value}",
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ));
      } else {
        details.add(Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              key.replaceAll("_", " "),
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Flexible(
              child: Text(
                value.toString(),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ));
        details.add(const SizedBox(height: 8));
      }
    });

    return details;
  }
}
