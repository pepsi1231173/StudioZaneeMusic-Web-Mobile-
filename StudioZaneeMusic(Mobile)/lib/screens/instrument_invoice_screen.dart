import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import 'home_screen.dart';

class InstrumentInvoiceScreen extends StatefulWidget {
  final int rentalId;

  final Map<String, dynamic> userData; // ✅ Thêm dòng này

  const InstrumentInvoiceScreen({
    super.key,
    required this.rentalId,
    required this.userData, // ✅ Thêm dòng này
  });


  @override
  State<InstrumentInvoiceScreen> createState() => _InstrumentInvoiceScreenState();
}

class _InstrumentInvoiceScreenState extends State<InstrumentInvoiceScreen> {
  bool isLoading = true;
  String? errorMessage;
  Map<String, dynamic>? invoice;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    try {
      final url = Uri.parse("${ApiService.baseUrl}/InstrumentInvoiceApi/${widget.rentalId}");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        List<Map<String, dynamic>> instrumentList = [];
        int total = 0;

        if (json["danhSachNhacCu"] != null && json["danhSachNhacCu"] is List) {
          for (var i in json["danhSachNhacCu"]) {
            final num rawPrice = i["price"] ?? 0;
            final int price = rawPrice.round();
            total += price;

            instrumentList.add({
              "name": i["name"] ?? "Không rõ",
              "price": price,
              "priceFormatted": "${price.toString().replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                    (m) => '${m[1]}.',
              )} VNĐ",
              "imageUrl": i["imageUrl"] ?? "",
            });
          }
        }

        String tongTien = json["tongTien"] ??
            "${total.toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                  (m) => '${m[1]}.',
            )} VNĐ";

        setState(() {
          invoice = {
            "maDon": json["maDon"] ?? "N/A",
            "tenKhachHang": json["tenKhachHang"] ?? "",
            "soDienThoai": json["soDienThoai"] ?? "",
            "email": json["email"] ?? "",
            "ngayThue": json["ngayThue"] ?? "",
            "ngayTao": json["ngayTao"] ?? "",
            "danhSachNhacCu": instrumentList,
            "tongTien": tongTien,
            "note": "🎵 Đơn thuê đã được ghi nhận. Vui lòng thanh toán khi đến nhận nhạc cụ.",
          };
          isLoading = false;
        });
      } else {
        throw Exception("Không thể tải chi tiết hóa đơn (${response.statusCode})");
      }
    } catch (e) {
      setState(() {
        errorMessage = "Lỗi khi tải hóa đơn: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("🎸 Hóa đơn thuê nhạc cụ"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 🌆 Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/BACKROUND.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 🧾 Nội dung
          isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : errorMessage != null
              ? Center(
            child: Text(errorMessage!,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
          )
              : invoice == null
              ? const Center(
            child: Text("Không có dữ liệu hóa đơn",
                style: TextStyle(color: Colors.white)),
          )
              : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              margin: const EdgeInsets.only(top: 80, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🎶 Tiêu đề
                    Center(
                      child: Text(
                        "🎶 Hóa Đơn Thuê Nhạc Cụ 🎶",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow("🧾 Mã đơn:", invoice!["maDon"]),
                    _buildInfoRow("👤 Khách hàng:", invoice!["tenKhachHang"]),
                    _buildInfoRow("📞 SĐT:", invoice!["soDienThoai"]),
                    _buildInfoRow("📧 Email:", invoice!["email"]),
                    _buildInfoRow("📅 Ngày thuê:", invoice!["ngayThue"]),
                    _buildInfoRow("🕒 Ngày tạo:", invoice!["ngayTao"]),
                    const SizedBox(height: 16),
                    const Divider(thickness: 1.2),

                    // 🎸 Danh sách nhạc cụ
                    const Text(
                      "🎸 Danh sách nhạc cụ",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 10),
                    ...invoice!["danhSachNhacCu"].map<Widget>((item) {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade50,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          leading: item["imageUrl"] != ""
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              "http://10.0.2.2:5167${item["imageUrl"]}",
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          )
                              : const Icon(Icons.music_note,
                              size: 45, color: Colors.blueGrey),
                          title: Text(item["name"],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(item["priceFormatted"],
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600)),
                        ),
                      );
                    }).toList(),

                    const Divider(),
                    Center(
                      child: Text(
                        "💰 Tổng tiền: ${invoice!["tongTien"]}",
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 📝 Ghi chú
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.yellow.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        invoice!["note"],
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 🏠 Nút về trang chủ
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HomeScreen(userData: widget.userData), // ✅ Quay về kèm userData
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amberAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                        ),
                        icon: const Icon(Icons.home_rounded),
                        label: const Text(
                          'Về trang chủ',
                          style: TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        "$label $value",
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }
}
