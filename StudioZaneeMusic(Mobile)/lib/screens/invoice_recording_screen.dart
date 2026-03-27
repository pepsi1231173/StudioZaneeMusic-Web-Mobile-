import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class InvoiceRecordingScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  final Map<String, dynamic>? userData;

  const InvoiceRecordingScreen({
    super.key,
    required this.booking,
    this.userData,
  });

  @override
  State<InvoiceRecordingScreen> createState() => _InvoiceRecordingScreenState();
}

class _InvoiceRecordingScreenState extends State<InvoiceRecordingScreen> {
  Map<String, dynamic>? invoiceData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoiceData();
  }

  Future<void> _loadInvoiceData() async {
    try {
      final bookingId = widget.booking['id'] ?? widget.booking['bookingId'];

      if (bookingId != null) {
        final url =
        Uri.parse('http://10.0.2.2:5167/api/RecordingInvoiceApi/$bookingId');
        final response = await http.get(url);

        if (response.statusCode == 200) {
          setState(() {
            invoiceData = jsonDecode(response.body);
            isLoading = false;
          });
        } else {
          throw Exception('Không lấy được dữ liệu hóa đơn');
        }
      } else {
        setState(() {
          invoiceData = widget.booking;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi load hóa đơn: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.amberAccent),
        ),
      );
    }

    final invoice = invoiceData ?? {};

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/BACKROUND.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.75)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amberAccent, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        '🎵 HÓA ĐƠN THU ÂM',
                        style: TextStyle(
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ✅ Sửa toàn bộ key thành chữ thường
                    _buildRow('Mã đơn', invoice['maDon'] ?? '---'),
                    _buildRow('Tên khách hàng', invoice['tenKhachHang'] ?? '---'),
                    _buildRow('Số điện thoại', invoice['soDienThoai'] ?? '---'),
                    _buildRow('Email', invoice['email'] ?? '---'),
                    _buildRow('Gói dịch vụ', invoice['goiDichVu'] ?? '---'),
                    _buildRow('Ngày thu âm', invoice['ngayThuAm'] ?? '---'),
                    _buildRow('Giờ thu âm', invoice['gioThuAm'] ?? '---'),
                    _buildRow('Giá', invoice['gia'] ?? '0 VNĐ'),
                    _buildRow('Trạng thái', invoice['trangThai'] ?? 'Chờ duyệt'),
                    _buildRow('Ngày tạo', invoice['ngayTao'] ?? '---'),

                    const Divider(color: Colors.amberAccent, thickness: 1),

                    _buildRow(
                      '💰 Tổng tiền',
                      invoice['tongTien'] ?? '0 VNĐ',
                      color: Colors.amberAccent,
                      fontWeight: FontWeight.bold,
                    ),

                    const SizedBox(height: 25),

                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amberAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 14),
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

  static Widget _buildRow(
      String label,
      String value, {
        Color color = Colors.white,
        FontWeight fontWeight = FontWeight.normal,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: fontWeight,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
