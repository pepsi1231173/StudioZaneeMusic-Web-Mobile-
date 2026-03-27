import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'invoice_screen.dart';
import 'room_schedule_screen.dart';

class BookRoomScreen extends StatefulWidget {
  final Map<String, dynamic> room;
  final DateTime? selectedDate; // ✅ Ngày truyền vào
  final int? startHour;         // ✅ Giờ truyền vào
  final Map<String, dynamic> userData; // ✅ Thêm dòng này

  const BookRoomScreen({
    super.key,
    required this.room,
    this.selectedDate,
    this.startHour,
    required this.userData,
  });

  @override
  State<BookRoomScreen> createState() => _BookRoomScreenState();
}
class _BookRoomScreenState extends State<BookRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final guestController = TextEditingController(text: '1');
  final durationController = TextEditingController(text: '1');
  final ApiService api = ApiService();

  DateTime? selectedDate;
  int startHour = 8;
  bool isLoading = false;
  late Color mainColor;
  late Color glowColor;

  @override
  void initState() {
    super.initState();
    _setThemeColors();

    // ✅ Ưu tiên lấy từ userData
    nameController.text = widget.userData["fullName"] ?? '';
    emailController.text = widget.userData["email"] ?? '';
    phoneController.text = widget.userData["phoneNumber"] ?? '';

    // ✅ Nếu userData chưa có thì mới load SharedPreferences
    if ((nameController.text.isEmpty || emailController.text.isEmpty || phoneController.text.isEmpty)) {
      _loadUserProfile();
    }

    if (widget.selectedDate != null) {
      selectedDate = widget.selectedDate;
    }
    if (widget.startHour != null) {
      startHour = widget.startHour!;
    }
  }



  void _setThemeColors() {
    final type = widget.room["type"];
    if (type == "VIP") {
      mainColor = const Color(0xFFFFD700);
      glowColor = Colors.amberAccent;
    } else if (type == "SVIP") {
      mainColor = const Color(0xFF00E5FF);
      glowColor = Colors.cyanAccent;
    } else {
      mainColor = const Color(0xFFFF9800);
      glowColor = Colors.orangeAccent;
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fullName = prefs.getString('user_fullname') ?? '';
      final email = prefs.getString('user_email') ?? '';
      final phone = prefs.getString('user_phone') ?? '';

      setState(() {
        nameController.text = fullName;
        emailController.text = email;
        phoneController.text = phone;
      });
    } catch (e) {
      print("⚠️ Không thể tải thông tin người dùng: $e");
    }
  }

  String? _validateBooking() {
    if (selectedDate == null) return "❌ Vui lòng chọn ngày thuê";

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // ❌ Không cho chọn ngày quá khứ
    if (selectedDate!.isBefore(today)) {
      return "❌ Không thể chọn ngày trong quá khứ";
    }

    final duration = int.tryParse(durationController.text) ?? 1;
    final endHour = startHour + duration;

    // ✅ Nếu chọn ngày hôm nay thì không cho đặt giờ đã qua
    if (selectedDate!.isAtSameMomentAs(today)) {
      if (startHour <= now.hour) {
        return "❌ Giờ này đã qua, vui lòng chọn khung giờ khác.";
      }
    }

    // ❌ Phòng chỉ mở từ 8h–22h
    if (startHour < 8 || endHour > 22) {
      return "❌ Phòng chỉ hoạt động từ 8:00 đến 22:00.";
    }

    // ⚙️ Kiểm tra số khách vượt giới hạn
    final guests = int.tryParse(guestController.text) ?? 1;
    final maxGuests = widget.room["maxPeople"] ?? 8;

    if (guests > maxGuests) {
      final extra = guests - maxGuests;
      final surcharge = extra * 30000;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚠️ Vượt quá $maxGuests khách. Phụ thu: ${surcharge.toStringAsFixed(0)}đ"),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    if (nameController.text.trim().isEmpty || phoneController.text.trim().isEmpty) {
      return "❌ Vui lòng nhập đầy đủ họ tên và số điện thoại.";
    }

    return null; // ✅ Hợp lệ
  }


  // ✅ Kiểm tra trùng giờ đặt phòng qua API BookingApi
  Future<bool> _checkDuplicateTime() async {
    final roomId = widget.room["name"].toString().replaceAll("Phòng ", "").trim();
    final url = Uri.parse("http://192.168.1.22:5167/api/BookingApi/room/$roomId");

    try {
      final response = await http.get(url);
      if (response.statusCode != 200) {
        print("⚠️ Không thể tải lịch phòng (${response.statusCode})");
        return false;
      }

      final List bookings = jsonDecode(response.body);
      final newStart = startHour;
      final newEnd = startHour + int.parse(durationController.text);
      final dateStr = selectedDate!.toString().split(" ")[0];

      for (final b in bookings) {
        if (b["rentalDate"].toString().split("T")[0] == dateStr) {
          final bookedStart = int.tryParse(b["startHour"].toString()) ?? 0;
          final bookedEnd = int.tryParse(b["endHour"].toString()) ?? 0;
          if (!(newEnd <= bookedStart || newStart >= bookedEnd)) {
            return true; // trùng giờ
          }
        }
      }
    } catch (e) {
      print("❌ Lỗi kiểm tra trùng lịch: $e");
    }
    return false;
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    final validationMessage = _validateBooking();
    if (validationMessage != null) {
      _showDialog("Cảnh báo", validationMessage);
      return;
    }

    if (selectedDate == null) {
      _showDialog("Lỗi", "Vui lòng chọn ngày thuê phòng!");
      return;
    }

    // ✅ Kiểm tra trùng giờ
    if (await _checkDuplicateTime()) {
      _showDialog("⚠️ Lịch trùng", "Khung giờ này đã có người đặt rồi!");
      return;
    }

    setState(() => isLoading = true);

    final bookingData = {
      "CustomerName": nameController.text.trim(),
      "CustomerPhone": phoneController.text.trim(),
      "CustomerEmail": emailController.text.trim(),
      "RentalDate": selectedDate!.toIso8601String(),
      "StartTime": "${startHour.toString().padLeft(2, '0')}:00:00",
      "RentalDuration": int.parse(durationController.text),
      "GuestCount": int.parse(guestController.text),
      "RoomId": widget.room["name"].toString().replaceAll("Phòng ", "").trim(),
    };

    try {
      final response = await http.post(
        Uri.parse("http://192.168.1.22:5167/api/InvoiceApi/Create"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(bookingData),
      );

      print("📤 Gửi booking: ${jsonEncode(bookingData)}");
      print("📥 Phản hồi: ${response.statusCode} | ${response.body}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        _showDialog("✅ Thành công", "Đặt phòng thành công!");
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InvoiceScreen(
              invoiceData: result,
              userData: widget.userData, // ✅ Truyền userData sang
            ),
          ),
        );
      } else {
        final msg = jsonDecode(response.body)["message"] ?? "Lỗi không xác định";
        _showDialog("Lỗi", "❌ Đặt phòng thất bại: $msg");
      }
    } catch (e) {
      _showDialog("Lỗi kết nối", "⚠️ Không thể kết nối đến server: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: TextStyle(color: mainColor, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Đóng", style: TextStyle(color: glowColor)),
          )
        ],
      ),
    );
  }

  // ========================= UI ===========================
  @override
  Widget build(BuildContext context) {
    final room = widget.room;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "🎸 Đặt Phòng ${room["name"]}",
          style: GoogleFonts.lobster(
            fontSize: 28,
            color: mainColor,
            shadows: [Shadow(blurRadius: 15, color: glowColor)],
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/images/BACKROUND.jpg", fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildRoomInfo(room),
                  const SizedBox(height: 28),
                  _buildCustomerSection(),
                  const SizedBox(height: 25),
                  _buildBookingSection(),
                  const SizedBox(height: 30),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 UI phụ
  Widget _buildRoomInfo(Map room) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: mainColor, width: 2),
      gradient: LinearGradient(
        colors: [
          Colors.black.withOpacity(0.6),
          mainColor.withOpacity(0.15),
          Colors.black.withOpacity(0.6),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: glowColor.withOpacity(0.4),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    ),
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("${room["name"]} - ${room["type"]}",
            style: GoogleFonts.lobster(
                fontSize: 28,
                color: mainColor,
                shadows: [Shadow(blurRadius: 10, color: glowColor)])),
        const SizedBox(height: 8),
        Text(
          "👥 Tối đa ${room["maxPeople"]} người\n"
              "📅 T2–T6: ${room["weekdayPrice"]}đ/h\n"
              "🌟 T7, CN, Lễ: ${room["weekendPrice"]}đ/h\n"
              "🔥 Golden Hours: ${room["goldenPrice"]}đ/h",
          style:
          const TextStyle(color: Colors.white70, height: 1.6, fontSize: 15),
        ),
      ],
    ),
  );

  Widget _buildCustomerSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionTitle("Thông tin khách hàng"),
      const SizedBox(height: 12),
      _buildTextField(nameController, "Họ và tên", Icons.person,
          validator: (v) =>
          v == null || v.isEmpty ? 'Vui lòng nhập họ tên' : null),
      const SizedBox(height: 12),
      _buildTextField(phoneController, "Số điện thoại", Icons.phone,
          keyboardType: TextInputType.phone,
          validator: (v) =>
          v == null || v.isEmpty ? 'Vui lòng nhập số điện thoại' : null),
      const SizedBox(height: 12),
      _buildTextField(emailController, "Email (tùy chọn)", Icons.email,
          keyboardType: TextInputType.emailAddress),
    ],
  );

  Widget _buildBookingSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionTitle("Thông tin đặt lịch"),
      const SizedBox(height: 12),

      // ✅ Hiển thị ngày thuê & giờ bắt đầu (tự động điền khi bấm từ lịch)
      if (selectedDate != null || startHour != 0)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: mainColor, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "📅 Ngày thuê: ${selectedDate != null
                    ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"
                    : "Chưa chọn"}",
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                "🕒 Giờ bắt đầu: ${startHour != 0
                    ? "${startHour.toString().padLeft(2, '0')}:00"
                    : "Chưa chọn"}",
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),

      // 🗓 Date picker
      _buildDatePicker(context),
      const SizedBox(height: 15),

      // ⏰ Dropdown chọn giờ bắt đầu
      _buildStartHourDropdown(),
      const SizedBox(height: 15),

      // ⏱ Thời lượng thuê
      _buildTextField(durationController, "Thời gian thuê (1–14 giờ)", Icons.timer,
          keyboardType: TextInputType.number,
          validator: (v) {
            final h = int.tryParse(v ?? "");
            if (h == null || h < 1 || h > 14) {
              return 'Thời gian thuê phải từ 1–14 giờ';
            }
            return null;
          }),
      const SizedBox(height: 15),

      // 👥 Số lượng khách
      _buildTextField(
        guestController,
        "Số lượng khách (tối đa ${widget.room["maxPeople"]})",
        Icons.people,
        keyboardType: TextInputType.number,
      ),
    ],
  );

  Widget _buildActionButtons(BuildContext context) => Column(
    children: [
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RoomScheduleScreen(
                  roomName: widget.room["name"],
                  roomType: widget.room["type"],
                  userData: widget.userData, // ✅ thêm dòng này
                ),
              ),
            );
          },
          icon: Icon(Icons.calendar_today_outlined, color: mainColor),
          label: Text("XEM LỊCH TRỐNG",
              style:
              GoogleFonts.lobster(fontSize: 20, color: mainColor)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: mainColor, width: 2),
            padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.black.withOpacity(0.2),
          ),
        ),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : _submitBooking,
          icon: isLoading
              ? const CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2)
              : const Icon(Icons.check_circle_outline,
              color: Colors.white),
          label: Text(isLoading ? "Đang xử lý..." : "ĐẶT LỊCH NGAY",
              style: GoogleFonts.lobster(
                  fontSize: 22, color: Colors.white, letterSpacing: 1)),
          style: ElevatedButton.styleFrom(
            backgroundColor: mainColor,
            padding: const EdgeInsets.symmetric(
                vertical: 16, horizontal: 40),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            elevation: 10,
          ),
        ),
      ),
    ],
  );

  Widget _buildSectionTitle(String title) => Align(
    alignment: Alignment.centerLeft,
    child: Text(title,
        style: GoogleFonts.lobster(
          fontSize: 22,
          color: mainColor,
          shadows: [Shadow(blurRadius: 8, color: glowColor)],
        )),
  );

  Widget _buildTextField(TextEditingController c, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text,
        String? Function(String?)? validator}) =>
      TextFormField(
        controller: c,
        style: const TextStyle(color: Colors.white),
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: mainColor),
          labelText: label,
          labelStyle: TextStyle(color: mainColor),
          filled: true,
          fillColor: Colors.white.withOpacity(0.08),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: mainColor),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: glowColor, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

  Widget _buildDatePicker(BuildContext context) => GestureDetector(
    onTap: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 60)),
        builder: (context, child) => Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
                primary: mainColor, onSurface: Colors.white),
          ),
          child: child!,
        ),
      );
      if (picked != null) setState(() => selectedDate = picked);
    },
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: mainColor),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month, color: mainColor),
          const SizedBox(width: 10),
          Text(
            selectedDate == null
                ? "Chọn ngày thuê"
                : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
            style:
            const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    ),
  );

  Widget _buildStartHourDropdown() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: mainColor),
    ),
    child: DropdownButtonFormField<int>(
      dropdownColor: Colors.black87,
      value: startHour,
      items: List.generate(
        15,
            (i) {
          final h = 8 + i;
          return DropdownMenuItem(
            value: h,
            child: Text("${h.toString().padLeft(2, '0')}:00",
                style: const TextStyle(color: Colors.white)),
          );
        },
      ),
      onChanged: (val) => setState(() => startHour = val!),
      decoration: InputDecoration(
        icon: Icon(Icons.access_time, color: mainColor),
        labelText: "Giờ bắt đầu",
        labelStyle: TextStyle(color: mainColor),
        border: InputBorder.none,
      ),
    ),
  );
}
