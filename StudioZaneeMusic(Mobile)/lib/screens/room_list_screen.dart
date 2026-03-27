import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'book_room_screen.dart';

class RoomListScreen extends StatelessWidget {
  final Map<String, dynamic> userData; // ✅ thêm dòng này

  const RoomListScreen({super.key, required this.userData}); // ✅ required


  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> rooms = [
      {
        "name": "Phòng A",
        "type": "Standard",
        "weekdayPrice": 180000,
        "weekendPrice": 200000,
        "goldenPrice": 120000,
        "maxPeople": 10,
        "isMaintenance": false,
        "image": "assets/images/rooms/roomA.webp"
      },
      {
        "name": "Phòng B",
        "type": "VIP",
        "weekdayPrice": 360000,
        "weekendPrice": 400000,
        "goldenPrice": 240000,
        "maxPeople": 20,
        "isMaintenance": false,
        "image": "assets/images/rooms/roomB.webp"
      },
      {
        "name": "Phòng C",
        "type": "SVIP",
        "weekdayPrice": 540000,
        "weekendPrice": 600000,
        "goldenPrice": 360000,
        "maxPeople": 30,
        "isMaintenance": false,
        "image": "assets/images/rooms/roomC.webp"
      },
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 🌌 Background
          Positioned.fill(
            child: Image.asset(
              "assets/images/BACKROUND.jpg",
              fit: BoxFit.cover,
            ),
          ),
          // 🌫️ Lớp phủ mờ
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),

          SafeArea(
            child: Column(
              children: [
                AppBar(
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  centerTitle: true,
                  title: Text(
                    "Danh Sách Phòng",
                    style: GoogleFonts.lobster(
                      fontSize: 30,
                      color: const Color(0xFFFFD700),
                      shadows: const [
                        Shadow(blurRadius: 15, color: Colors.amberAccent),
                      ],
                    ),
                  ),
                ),

                // Danh sách phòng
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      final isMt = room["isMaintenance"] == true;

                      // 🎨 Kiểu chữ theo loại phòng
                      TextStyle nameStyle;
                      switch (room["type"]) {
                        case "VIP":
                          nameStyle = GoogleFonts.lobster(
                            fontSize: 28,
                            color: const Color(0xFFFFD700),
                            shadows: const [
                              Shadow(blurRadius: 15, color: Colors.amber),
                              Shadow(blurRadius: 30, color: Colors.yellowAccent),
                            ],
                          );
                          break;
                        case "SVIP":
                          nameStyle = GoogleFonts.lobster(
                            fontSize: 28,
                            color: const Color(0xFF00E5FF),
                            shadows: const [
                              Shadow(blurRadius: 20, color: Colors.cyanAccent),
                              Shadow(blurRadius: 35, color: Colors.lightBlueAccent),
                            ],
                          );
                          break;
                        default:
                          nameStyle = GoogleFonts.lobster(
                            fontSize: 28,
                            color: const Color(0xFFFF9800),
                            shadows: const [
                              Shadow(blurRadius: 10, color: Colors.orangeAccent),
                            ],
                          );
                          break;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 22),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.amberAccent, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.6),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Ảnh phòng
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                room["image"],
                                height: 230,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            // Overlay mờ
                            Container(
                              height: 230,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withOpacity(0.85),
                                    Colors.black.withOpacity(0.45),
                                    Colors.black.withOpacity(0.85),
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                            ),
                            // Nội dung
                            Positioned(
                              bottom: 16,
                              left: 16,
                              right: 16,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(room["name"], style: nameStyle),
                                  const SizedBox(height: 6),
                                  Text(
                                    "${room["type"]} • Tối đa ${room["maxPeople"]} người",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "📅 T2–T6: ${room["weekdayPrice"]} VNĐ/h\n"
                                        "🌟 T7, CN, Lễ: ${room["weekendPrice"]} VNĐ/h\n"
                                        "🔥 Golden Hours (14h–17h): ${room["goldenPrice"]} VNĐ/h",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton(
                                      onPressed: isMt
                                          ? null
                                          : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => BookRoomScreen(
                                              room: room,
                                              userData: userData, // ✅ truyền userData từ RoomListScreen
                                            ),

                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 28, vertical: 12),
                                        backgroundColor: isMt
                                            ? Colors.grey
                                            : Colors.amberAccent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 4,
                                      ),
                                      child: Text(
                                        isMt ? "🔧 Bảo trì" : "Đặt ngay",
                                        style: GoogleFonts.lobster(
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isMt)
                              Positioned(
                                top: 14,
                                right: 14,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    "Đang bảo trì",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
