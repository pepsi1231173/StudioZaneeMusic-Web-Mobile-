import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/signalr_service.dart';
import 'book_room_screen.dart';

class RoomScheduleScreen extends StatefulWidget {
  final String roomName;
  final String roomType;
  final Map<String, dynamic> userData;

  const RoomScheduleScreen({
    super.key,
    required this.roomName,
    required this.roomType,
    required this.userData,
  });

  @override
  State<RoomScheduleScreen> createState() => _RoomScheduleScreenState();
}

class _RoomScheduleScreenState extends State<RoomScheduleScreen> {
  final ApiService api = ApiService();
  final SignalRService _signalR =
  SignalRService(hubUrl: "http://192.168.1.22:5167/bookingHub");

  final List<DateTime> days = List.generate(7, (i) {
    final d = DateTime.now().add(Duration(days: i));
    return DateTime(d.year, d.month, d.day);
  });

  final int startHour = 8;
  final int endHour = 21;
  final Map<String, String> bookingStatus = {};
  late Color mainColor, glowColor;
  late String typeDisplay;
  DateTime selectedDay = DateTime.now();
  bool _signalRInitialized = false;
  String? selectedSlot; // ✅ slot đang chọn

  @override
  void initState() {
    super.initState();
    _setThemeByRoomType();
    _loadRoomSchedule();
    _initSignalR();

    // ✅ Tự động refresh mỗi phút để cập nhật “Đã qua”
    Future.doWhile(() async {
      await Future.delayed(const Duration(minutes: 1));
      if (mounted) setState(() {});
      return mounted;
    });
  }

  void _setThemeByRoomType() {
    switch (widget.roomType.toUpperCase()) {
      case "VIP":
        mainColor = const Color(0xFFFFD700);
        glowColor = Colors.amberAccent;
        typeDisplay = "VIP";
        break;
      case "SVIP":
        mainColor = const Color(0xFF00E5FF);
        glowColor = Colors.cyanAccent;
        typeDisplay = "SVIP";
        break;
      default:
        mainColor = const Color(0xFFFF9800);
        glowColor = Colors.deepOrangeAccent;
        typeDisplay = "STANDARD";
        break;
    }
  }

  // 🔹 Kết nối SignalR
  Future<void> _initSignalR() async {
    if (_signalRInitialized) return;
    _signalRInitialized = true;

    try {
      await _signalR.start(
        onBookingCreated: (_) => _loadRoomSchedule(),

        onBookingStatusChanged:
            (bookingId, roomId, date, startHour, duration, status) {
          final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.parse(date));
          setState(() {
            for (int h = 0; h < duration; h++) {
              bookingStatus["${dateStr}_${startHour + h}"] =
                  status.toLowerCase();
            }
          });
        },

        // 🔸 Khi admin HỦY đơn
        onBookingDeleted: (bookingId, roomId, date, startHour, duration) {
          final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.parse(date));
          setState(() {
            for (int h = 0; h < duration; h++) {
              final key = "${dateStr}_${startHour + h}";
              bookingStatus[key] = "available"; // trở lại trống
            }
            selectedSlot = null;
          });
        },

        // 🔧 Cập nhật bảo trì
        onMaintenanceUpdated: (rooms) {
          if (rooms.contains(widget.roomName.replaceAll("Phòng ", ""))) {
            setState(() {
              bookingStatus.updateAll((key, value) => "maintenance");
            });
          }
        },

        onReceiveTime: (now) => debugPrint("🕒 Server time: $now"),
      );
    } catch (e) {
      debugPrint("⚠️ Lỗi khởi tạo SignalR: $e");
    }
  }

  // 🔹 Load lịch từ API
  Future<void> _loadRoomSchedule() async {
    try {
      final roomId = widget.roomName.replaceAll("Phòng ", "");
      final data = await api.getRoomSchedule(roomId);
      setState(() {
        bookingStatus.clear();
        for (var booking in data) {
          final dateStr =
          DateFormat('yyyy-MM-dd').format(DateTime.parse(booking['rentalDate']));
          final start = booking['startHour'] as int;
          final duration = booking['rentalDuration'] as int;
          final status = booking['status'].toString().toLowerCase();
          for (int h = 0; h < duration; h++) {
            bookingStatus["${dateStr}_${start + h}"] = status;
          }
        }
      });
    } catch (e) {
      debugPrint("⚠️ Lỗi tải lịch phòng: $e");
    }
  }

  // 🔹 Text trạng thái
  String getStatusText(String? status) {
    switch (status) {
      case "pending":
        return "Chờ duyệt";
      case "booked":
        return "Đã đặt";
      case "active":
        return "Đang dùng";
      case "maintenance":
        return "Bảo trì";
      case "passed":
        return "Đã qua";
      default:
        return "Trống";
    }
  }

  // 🔹 Màu trạng thái
  Color getStatusColor(String? status) {
    switch (status) {
      case "pending":
        return Colors.amber;
      case "booked":
        return Colors.redAccent;
      case "active":
        return Colors.orangeAccent;
      case "maintenance":
        return Colors.grey;
      case "passed":
        return Colors.blueAccent;
      default:
        return Colors.green;
    }
  }

  // ✅ Logic xác định “Đã qua” theo trạng thái
  bool isPastHour(DateTime day, int hour, String status) {
    final now = DateTime.now();
    final slotStart = DateTime(day.year, day.month, day.day, hour);
    final slotEnd = DateTime(day.year, day.month, day.day, hour + 1);

    if (status == "available" || status == "pending") {
      return now.isAfter(slotStart);
    } else if (status == "booked" || status == "active") {
      return now.isAfter(slotEnd);
    }
    return false;
  }

  @override
  void dispose() {
    _signalR.stop().catchError((e) => debugPrint("⚠️ Lỗi dừng SignalR: $e"));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('yyyy-MM-dd');
    final int maxPeople = widget.roomName == "Phòng A"
        ? 10
        : widget.roomName == "Phòng B"
        ? 20
        : 30;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          "Lịch Phòng ${widget.roomName} ($typeDisplay)",
          style: GoogleFonts.lobster(
            fontSize: 26,
            color: mainColor,
            shadows: [Shadow(color: glowColor, blurRadius: 10)],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadRoomSchedule,
          ),
        ],
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset("assets/images/BACKROUND.jpg", fit: BoxFit.cover),
            ),
            Container(color: Colors.black.withOpacity(0.7)),
            Column(
              children: [
                const SizedBox(height: 10),
                _buildDateSelector(),
                const SizedBox(height: 12),
                _buildLegend(),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: endHour - startHour + 1,
                    itemBuilder: (context, i) {
                      final hour = startHour + i;
                      final dayKey = dateFormatter.format(selectedDay);
                      final key = "${dayKey}_$hour";
                      String status = bookingStatus[key] ?? "available";

                      // ✅ cập nhật logic “đã qua”
                      if (isPastHour(selectedDay, hour, status)) {
                        status = "passed";
                      }

                      final isAvailable = status == "available" || status == "pending";
                      final isClickable =
                          isAvailable && !isPastHour(selectedDay, hour, status);
                      final isSelected = selectedSlot == key;

                      return Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        child: GestureDetector(
                          onTap: isClickable
                              ? () async {
                            setState(() => selectedSlot = key);
                            final result = await Navigator.push<String?>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookRoomScreen(
                                  room: {
                                    "name": widget.roomName,
                                    "type": widget.roomType,
                                    "maxPeople": maxPeople,
                                    "weekdayPrice": 150000,
                                    "weekendPrice": 200000,
                                    "goldenPrice": 250000,
                                  },
                                  selectedDate: selectedDay,
                                  startHour: hour,
                                  userData: widget.userData,
                                ),
                              ),
                            );
                            if (result == "booked") {
                              setState(() => bookingStatus[key] = "pending");
                            }
                          }
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: getStatusColor(status).withOpacity(0.9),
                              borderRadius: BorderRadius.circular(14),
                              border: isSelected
                                  ? Border.all(color: mainColor, width: 1.5)
                                  : null,
                              boxShadow: status != "available"
                                  ? [
                                BoxShadow(
                                  color: glowColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.access_time,
                                        color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      "$hour:00 - ${hour + 1}:00",
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                                Text(
                                  getStatusText(status),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Thanh chọn ngày
  Widget _buildDateSelector() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (context, i) {
          final day = days[i];
          final isSelected = day.year == selectedDay.year &&
              day.month == selectedDay.month &&
              day.day == selectedDay.day;
          return GestureDetector(
            onTap: () => setState(() => selectedDay = day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? mainColor : Colors.white10,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [BoxShadow(color: glowColor, blurRadius: 15)]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ["CN", "T2", "T3", "T4", "T5", "T6", "T7"][day.weekday % 7],
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${day.day}/${day.month}",
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 🔹 Ghi chú
  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          _legend("🟩 Trống", Colors.green),
          _legend("🟨 Chờ duyệt", Colors.amber),
          _legend("🟥 Đã đặt", Colors.redAccent),
          _legend("🟧 Đang dùng", Colors.orangeAccent),
          _legend("⬜ Bảo trì", Colors.grey),
          _legend("🟦 Đã qua", Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _legend(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: const TextStyle(color: Colors.white, fontSize: 13),
    ),
  );
}
