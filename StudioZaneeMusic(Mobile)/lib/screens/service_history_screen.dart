import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'invoice_screen.dart';
import 'instrument_invoice_screen.dart';
import 'invoice_recording_screen.dart';
import 'music_invoice_screen.dart';



class ServiceHistoryScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ServiceHistoryScreen({super.key, required this.userData});

  @override
  State<ServiceHistoryScreen> createState() => _ServiceHistoryScreenState();
}

class _ServiceHistoryScreenState extends State<ServiceHistoryScreen> {
  Map<String, dynamic>? historyData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    final response = await http.get(Uri.parse(
        "http://192.168.1.22:5167/api/ServiceHistoryApi/${widget.userData["email"]}"));
    if (response.statusCode == 200) {
      setState(() {
        historyData = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  // 🎨 Màu trạng thái giống Web ASP.NET
  Color _getStatusColor(String? status) {
    final s = (status ?? "").toLowerCase().trim();
    switch (s) {
      case "pending":
      case "chờ duyệt":
      case "đang chờ":
        return const Color(0xFFFFA500); // 🟠 cam
      case "active":
      case "confirmed":
      case "đang sử dụng":
      case "đã duyệt":
        return const Color(0xFF00FF00); // 🟢 xanh lá
      case "completed":
      case "hoàn tất":
        return const Color(0xFF808080); // ⚪ xám
      case "cancelled":
      case "canceled":
      case "đã hủy":
      case "từ chối":
        return const Color(0xFFFF0000); // 🔴 đỏ
      default:
        return Colors.white70;
    }
  }

  String _getStatusText(String? status) {
    final s = (status ?? "").toLowerCase().trim();
    switch (s) {
      case "pending":
        return "Chờ duyệt";
      case "active":
      case "confirmed":
        return "Đang sử dụng";
      case "completed":
        return "Hoàn tất";
      case "cancelled":
        return "Đã hủy";
      default:
        return "Không xác định";
    }
  }

  IconData _getStatusIcon(String? status) {
    final s = (status ?? "").toLowerCase().trim();
    switch (s) {
      case "pending":
        return Icons.hourglass_bottom;
      case "active":
      case "confirmed":
        return Icons.play_circle_fill;
      case "completed":
        return Icons.check_circle;
      case "cancelled":
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  // 🗓️ Hàm format ngày
  String _formatDate(dynamic dateStr) {
    if (dateStr == null || dateStr.toString().isEmpty) return "Không rõ";
    try {
      final date = DateTime.parse(dateStr.toString());
      return "${date.day}/${date.month}/${date.year}";
    } catch (_) {
      return dateStr.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/images/BACKROUND.jpg", fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.75)),
          ),
          SafeArea(
            child: Column(
              children: [
                AppBar(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  elevation: 0,
                  title: Text("📜 Lịch Sử Dịch Vụ",
                      style: GoogleFonts.lobster(
                          color: Colors.amber, fontSize: 26)),
                  centerTitle: true,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      _buildSection("🏠 Thuê Phòng", historyData!["bookingHistory"], "rentalDate", "Ngày thuê"),
                      _buildInstrumentSection("🎸 Thuê Nhạc Cụ",
                          historyData!["instrumentHistory"], "rentalDate", "Ngày thuê"),
                      _buildRecordingSection(
                        "🎤 Thu Âm",
                        historyData!["recordingHistory"],
                        "recordingDate",
                        "Ngày thu âm",
                      ),
                      _buildMusicSection(
                        "🎼 Làm Nhạc",
                        historyData!["musicRequestHistory"],
                        "requestDate",
                        "Ngày yêu cầu",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Section chung (không có hình)
  // 🔹 Section chung (không có hình)
  Widget _buildSection(
      String title, List<dynamic>? list, String dateField, String dateLabel) {
    if (list == null || list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          "$title: Không có dữ liệu",
          style: GoogleFonts.lobster(color: Colors.white70, fontSize: 18),
        ),
      );
    }

    return Card(
      color: Colors.black.withOpacity(0.55),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ExpansionTile(
        iconColor: Colors.amber,
        collapsedIconColor: Colors.white,
        title: Text(
          title,
          style: GoogleFonts.lobster(color: Colors.amber, fontSize: 22),
        ),
        children: list.map((item) {
          final status = item["status"] ?? "Không xác định";
          final color = _getStatusColor(status);
          final text = _getStatusText(status);
          final date = _formatDate(item[dateField]);
          final showCurrency = title != "🎼 Làm Nhạc";
          final bookingId = item["id"]; // ✅ ID đơn để tải lại hóa đơn

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 2.5),
              borderRadius: BorderRadius.circular(10),
              color: color.withOpacity(0.1),
            ),
            child: ListTile(
              leading: Icon(_getStatusIcon(status), color: color, size: 30),
              title: Text(
                item["roomId"] ??
                    item["recordingPackage"] ??
                    item["musicGenre"] ??
                    "Dịch vụ",
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "$dateLabel: $date\nTrạng thái: $text",
                style: const TextStyle(color: Colors.white70, height: 1.4),
              ),
              trailing: Text(
                showCurrency
                    ? "${item["price"] ?? ""} VNĐ"
                    : "${item["price"] ?? ""}",
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 16),
              ),

              // ✅ Khi bấm vào 1 đơn thuê → chỉ tải lại hóa đơn cũ
              onTap: () async {
                if (bookingId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Không tìm thấy mã đơn!")),
                  );
                  return;
                }

                try {
                  // 🔹 Gọi API GET hóa đơn cũ
                  final response = await http.get(
                    Uri.parse(
                        "http://192.168.1.22:5167/api/InvoiceApi/$bookingId"),
                  );

                  if (response.statusCode == 200) {
                    final invoice = json.decode(response.body);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InvoiceScreen(
                          invoiceData: invoice,
                          userData: widget.userData, // ✅ truyền đúng dữ liệu người dùng
                        ),
                      ),
                    );
                  } else if (response.statusCode == 404) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Không tìm thấy hóa đơn cho đơn này.")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              "Lỗi tải hóa đơn: ${response.statusCode} ${response.reasonPhrase}")),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Lỗi kết nối server: $e")),
                  );
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }


  // 🎸 Section riêng cho thuê nhạc cụ — có hình ảnh lấy từ API
  Widget _buildInstrumentSection(
      String title,
      List<dynamic>? list,
      String dateField,
      String dateLabel,
      ) {
    if (list == null || list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          "$title: Không có dữ liệu",
          style: GoogleFonts.lobster(color: Colors.white70, fontSize: 18),
        ),
      );
    }

    return Card(
      color: Colors.black.withOpacity(0.55),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ExpansionTile(
        iconColor: Colors.amber,
        collapsedIconColor: Colors.white,
        title: Text(
          title,
          style: GoogleFonts.lobster(color: Colors.amber, fontSize: 22),
        ),
        children: list.map((item) {
          final status = item["status"] ?? "Không xác định";
          final color = _getStatusColor(status);
          final text = _getStatusText(status);
          final date = _formatDate(item[dateField]);

          // ✅ Cập nhật xử lý ảnh đúng key "imageUrl"
          final rawImage = item["imageUrl"]?.toString() ?? "";
          final imageUrl = rawImage.startsWith("http")
              ? rawImage
              : "http://192.168.1.22:5167$rawImage";

          final rentalId = item["id"];

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 2.5),
              borderRadius: BorderRadius.circular(12),
              color: color.withOpacity(0.08),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 55,
                  height: 55,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
              title: Text(
                item["name"] ?? item["instrumentName"] ?? "Nhạc cụ",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                "$dateLabel: $date\nTrạng thái: $text",
                style: const TextStyle(color: Colors.white70, height: 1.4),
              ),
              trailing: Text(
                "${item["price"] ?? ""} VNĐ",
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              onTap: () async {
                if (rentalId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Không tìm thấy mã đơn!")),
                  );
                  return;
                }

                try {
                  final response = await http.get(Uri.parse(
                      "http://192.168.1.22:5167/api/InstrumentInvoiceApi/$rentalId"));

                  if (response.statusCode == 200) {
                    final invoiceData = json.decode(response.body);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InstrumentInvoiceScreen(
                          rentalId: rentalId,
                          userData: widget.userData,
                        ),
                      ),
                    );
                  } else if (response.statusCode == 404) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Không tìm thấy hóa đơn cho đơn này.")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Lỗi tải hóa đơn: ${response.statusCode} ${response.reasonPhrase}",
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Lỗi kết nối server: $e")),
                  );
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }


  // 🎤 Section riêng cho Thu Âm — mở hóa đơn thu âm khi click
  Widget _buildRecordingSection(
      String title,
      List<dynamic>? list,
      String dateField,
      String dateLabel,
      ) {
    if (list == null || list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          "$title: Không có dữ liệu",
          style: GoogleFonts.lobster(color: Colors.white70, fontSize: 18),
        ),
      );
    }

    return Card(
      color: Colors.black.withOpacity(0.55),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ExpansionTile(
        iconColor: Colors.amber,
        collapsedIconColor: Colors.white,
        title: Text(
          title,
          style: GoogleFonts.lobster(color: Colors.amber, fontSize: 22),
        ),
        children: list.map((item) {
          final status = item["status"] ?? "Không xác định";
          final color = _getStatusColor(status);
          final text = _getStatusText(status);
          final date = _formatDate(item[dateField]);
          final recordingId = item["id"]; // 🆔 ID để tải hóa đơn thu âm

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 2.5),
              borderRadius: BorderRadius.circular(12),
              color: color.withOpacity(0.08),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ListTile(
              leading: Icon(Icons.music_note, color: color, size: 35),
              title: Text(
                item["recordingPackage"] ?? "Gói thu âm",
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "$dateLabel: $date\nTrạng thái: $text",
                style: const TextStyle(color: Colors.white70, height: 1.4),
              ),
              trailing: Text(
                "${item["price"] ?? ""} VNĐ",
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 16),
              ),

              // 🟢 Khi click → mở hóa đơn thu âm
              onTap: () async {
                if (recordingId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Không tìm thấy mã đơn!")),
                  );
                  return;
                }

                try {
                  final response = await http.get(Uri.parse(
                      "http://192.168.1.22:5167/api/RecordingInvoiceApi/$recordingId"));

                  if (response.statusCode == 200) {
                    final invoiceData = json.decode(response.body);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InvoiceRecordingScreen(
                          booking: {"id": recordingId, "invoice": invoiceData},
                          userData: widget.userData,
                        ),
                      ),
                    );
                  } else if (response.statusCode == 404) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Không tìm thấy hóa đơn cho đơn này.")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Lỗi tải hóa đơn: ${response.statusCode} ${response.reasonPhrase}",
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Lỗi kết nối server: $e")),
                  );
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
  // 🎼 Section riêng cho Làm Nhạc — mở hóa đơn làm nhạc khi click
  Widget _buildMusicSection(
      String title,
      List<dynamic>? list,
      String dateField,
      String dateLabel,
      ) {
    if (list == null || list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          "$title: Không có dữ liệu",
          style: GoogleFonts.lobster(color: Colors.white70, fontSize: 18),
        ),
      );
    }

    return Card(
      color: Colors.black.withOpacity(0.55),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ExpansionTile(
        iconColor: Colors.amber,
        collapsedIconColor: Colors.white,
        title: Text(
          title,
          style: GoogleFonts.lobster(color: Colors.amber, fontSize: 22),
        ),
        children: list.map((item) {
          final status = item["status"] ?? "Không xác định";
          final color = _getStatusColor(status);
          final text = _getStatusText(status);
          final date = _formatDate(item[dateField]);
          final requestId = item["id"];

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 2.5),
              borderRadius: BorderRadius.circular(12),
              color: color.withOpacity(0.08),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ListTile(
              leading: Icon(Icons.music_video, color: color, size: 35),
              title: Text(
                item["musicGenre"] ?? "Thể loại nhạc",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                "$dateLabel: $date\nTrạng thái: $text",
                style: const TextStyle(color: Colors.white70, height: 1.4),
              ),
              trailing: Text(
                item["price"] != null ? "${item["price"]} VNĐ" : "",
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              // 🟢 Khi click → xem lại hóa đơn làm nhạc
              onTap: () async {
                if (requestId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Không tìm thấy mã yêu cầu!")),
                  );
                  return;
                }

                try {
                  final response = await http.get(Uri.parse(
                      "http://192.168.1.22:5167/api/MusicRequestApi/$requestId"));

                  if (response.statusCode == 200) {
                    final invoiceData = json.decode(response.body);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MusicInvoiceScreen(data: invoiceData),
                      ),
                    );
                  } else if (response.statusCode == 404) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                          Text("Không tìm thấy hóa đơn cho yêu cầu này.")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Lỗi tải hóa đơn: ${response.statusCode} ${response.reasonPhrase}",
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Lỗi kết nối server: $e")),
                  );
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

